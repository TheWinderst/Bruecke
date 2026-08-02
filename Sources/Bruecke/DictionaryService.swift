import Foundation

// Arama yönü. .auto: metindeki harf ipuçlarından karar verilir, belirsizse Almanca.
enum LookupDirection {
    case deToTr, trToDe, auto
}

@MainActor
final class DictionaryService {

    // Türkçeye özgü harfler (ö/ü iki dilde de olduğundan ayırt etmez).
    private static let turkishMarks = CharacterSet(charactersIn: "ıİşŞğĞ")
    // Almancaya özgü harfler.
    private static let germanMarks = CharacterSet(charactersIn: "ßäÄ")

    // İstenen yönü metindeki harf ipuçlarıyla düzeltir: "ğ/ş/ı" varsa kelime
    // Türkçedir, "ß/ä" varsa Almancadır — düğme ne derse desin doğru yöne gider.
    private func resolve(_ direction: LookupDirection, term: String) -> LookupDirection {
        if term.rangeOfCharacter(from: Self.turkishMarks) != nil { return .trToDe }
        if term.rangeOfCharacter(from: Self.germanMarks) != nil { return .deToTr }
        return direction == .auto ? .deToTr : direction
    }

    // Hangi çeviri motoru kullanılacak (kullanıcı ayarından).
    private var engine: TranslateEngineConfig {
        switch AppSettings.shared.translationEngine {
        case .google: return .google
        case .libre:  return .libre(endpoint: AppSettings.shared.libreEndpoint)
        }
    }

    // Hedef dil (Türkçe ya da English) ve ona bağlı önbellek anahtarı öneki:
    // aynı Almanca kelimenin iki dildeki kartı ayrı saklanır ki dil değişince
    // eski dildeki kart gelmesin.
    private var targetLang: String { AppSettings.shared.translationLanguage.code }
    private var cachePrefix: String { targetLang == "tr" ? "" : "de→en|" }

    func lookup(_ raw: String, direction: LookupDirection = .auto, completion: @escaping (WordEntry?) -> Void) {
        let term = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { completion(nil); return }

        // Türkçe hedef dilken harf ipucu olan ters arama; English seçiliyse TR
        // dili kapalı, metin her zaman Almanca sayılır (DE→EN).
        if targetLang == "tr", resolve(direction, term: term) == .trToDe {
            reverseLookup(term, completion: completion)
            return
        }

        let tl = targetLang
        let cacheKey = cachePrefix + HistoryStore.normalize(term)

        // Önce edat kalıbı mı diye bak (sich beschweren über, warten auf ...).
        // Kullanıcı tam kalıbı, sadece fiili ya da fiil+edatı seçmiş olabilir.
        // (Yerleşik kalıplar Türkçe anlamlıdır; English modunda atlanır.)
        if tl == "tr", let p = PatternDictionary.lookup(term) {
            HistoryStore.shared.record(term: cacheKey, entry: p)
            completion(p)
            return
        }

        if tl == "tr", let hit = SampleDictionary.lookup(term) {
            HistoryStore.shared.record(term: cacheKey, entry: hit)
            completion(hit)
            return
        }

        // Daha önce bakıldıysa ağa hiç çıkma: anında ve çevrimdışı da çalışır.
        if let cached = HistoryStore.shared.cached(cacheKey) {
            HistoryStore.shared.record(term: cacheKey, entry: cached)   // geçmişte öne taşı
            completion(cached)
            return
        }

        let engine = self.engine

        // Google ucunun çevirebildiği pratik uzunluğun üstündeki metni cümle
        // sınırlarından parçalara bölüp sırayla çevirir (uzun paragraf desteği).
        if term.count > 1500 {
            let parts = Self.splitForTranslation(term)
            var translated = [String?](repeating: nil, count: parts.count)
            var anyFailed = false
            let group = DispatchGroup()
            for (i, part) in parts.enumerated() {
                group.enter()
                TranslateClient.simple(part, to: tl, engine: engine) { t, failed in
                    translated[i] = t; if failed { anyFailed = true }
                    group.leave()
                }
            }
            group.notify(queue: .main) {
                let joined = translated.map { $0 ?? "" }.joined(separator: " ")
                var e = self.makeEntry(word: term, result: nil,
                                       translation: joined.isEmpty ? "—" : joined,
                                       alternates: [], english: nil, synonyms: [], examples: [],
                                       translationFailed: joined.isEmpty && anyFailed)
                e.kind = .phrase
                e.posLabel = "metin"
                HistoryStore.shared.record(term: cacheKey, entry: e)
                completion(e)
            }
            return
        }

        if term.contains(" ") {
            // Uzun metin: tek çeviri yeterli; ağ yükünü ve bekleme süresini azaltır.
            // (Daha önce İngilizce referans çevirisi de çekiliyordu, kart onu zaten
            // ayrı satırda göstermediği için kaldırıldı.)
            TranslateClient.word(term, to: tl, engine: engine) { main, _, failed in
                DispatchQueue.main.async {
                    var e = self.makeEntry(word: term, result: nil, translation: main ?? "—",
                                           alternates: [], english: nil, synonyms: [], examples: [],
                                           translationFailed: failed && main == nil)
                    e.kind = .phrase
                    e.posLabel = term.count > 160 ? "metin" : "cümle"
                    HistoryStore.shared.record(term: cacheKey, entry: e)
                    completion(e)
                }
            }
            return
        }

        let word = term.trimmingCharacters(in: CharacterSet.letters.inverted)
        guard !word.isEmpty else { completion(nil); return }

        let wordKey = cachePrefix + HistoryStore.normalize(word)
        if let cached = HistoryStore.shared.cached(wordKey) {
            HistoryStore.shared.record(term: wordKey, entry: cached)
            completion(cached)
            return
        }

        WiktionaryClient.fetch(word) { result in
            DispatchQueue.main.async {
                self.buildEntry(word: word, result: result, engine: engine) { entry in
                    if let entry { HistoryStore.shared.record(term: wordKey, entry: entry) }
                    completion(entry)
                }
            }
        }
    }

    // Türkçe → Almanca: önce Türkçe kelime Almancaya çevrilir, sonra bulunan
    // Almanca kelime normal sözlük hattından geçirilip tam kart çıkarılır
    // (artikel, çoğul, çekim, örnekler). Kartın "Türkçe" kutusunda kullanıcının
    // sorduğu kelime gösterilir; hattın kendi geri-çevirisi farklıysa
    // "diğer anlamlar"a iner.
    private func reverseLookup(_ term: String, completion: @escaping (WordEntry?) -> Void) {
        // Ters aramalar Türkçe anahtarla da saklanır; "tr→de|" öneki, Türkçe
        // kelimenin olası bir Almanca eş yazımıyla (Bank gibi) çakışmasını önler.
        let cacheKey = "tr→de|" + term
        if let cached = HistoryStore.shared.cached(cacheKey) {
            HistoryStore.shared.record(term: cacheKey, entry: cached)
            completion(cached)
            return
        }

        let engine = self.engine

        TranslateClient.word(term, from: "tr", to: "de", engine: engine) { main, alts, failed in
            DispatchQueue.main.async {
                let de = (main ?? "").trimmingCharacters(in: CharacterSet(charactersIn: " .,;!?"))
                guard !de.isEmpty else {
                    var e = WordEntry(lemma: term, kind: .other, gender: .none, posLabel: "",
                                      plural: nil, ipa: nil, praeteritum: nil, perfekt: nil,
                                      translation: "—", examples: [])
                    e.reverseQuery = term
                    e.errorMessage = failed ? self.translateErrorMessage : "Almanca karşılık bulunamadı."
                    completion(e)
                    return
                }
                let extras = alts.filter { $0.caseInsensitiveCompare(de) != .orderedSame }

                let finish: (WordEntry) -> Void = { built in
                    var e = built
                    e.reverseQuery = term
                    if e.germanAlternates == nil, !extras.isEmpty {
                        e.germanAlternates = Array(extras.prefix(4))
                    }
                    let back = e.translation
                    if !back.isEmpty, back != "—",
                       HistoryStore.normalize(back) != HistoryStore.normalize(term) {
                        var a = e.alternates ?? []
                        if !a.contains(where: { $0.caseInsensitiveCompare(back) == .orderedSame }) {
                            a.insert(back, at: 0)
                        }
                        e.alternates = Array(a.prefix(4))
                    }
                    e.translation = term
                    // Karşılık elimizde; hattın ara adımlarından kalan ağ uyarısı kartı kirletmesin.
                    e.errorMessage = nil
                    // İki anahtarla kaydet: Türkçe sorgu (tekrarında anında açılır)
                    // ve Almanca kelime (son aramalardan tıklanınca anında açılır).
                    HistoryStore.shared.record(term: cacheKey, entry: e)
                    HistoryStore.shared.record(term: self.cachePrefix + HistoryStore.normalize(de), entry: e)
                    completion(e)
                }

                if let p = PatternDictionary.lookup(de) { finish(p); return }
                if let hit = SampleDictionary.lookup(de) { finish(hit); return }
                if let cached = HistoryStore.shared.cached(self.cachePrefix + HistoryStore.normalize(de)) { finish(cached); return }

                // Çok kelimeli karşılık (sich freuen, zu Hause ...): Wiktionary'de
                // tek başlık yok; sade bir ifade kartı yeterli.
                if de.contains(" ") {
                    let e = WordEntry(lemma: de, kind: .phrase, gender: .none, posLabel: "ifade",
                                      plural: nil, ipa: nil, praeteritum: nil, perfekt: nil,
                                      translation: term, examples: [])
                    finish(e)
                    return
                }

                WiktionaryClient.fetch(de) { result in
                    DispatchQueue.main.async {
                        self.buildEntry(word: de, result: result, engine: engine) { entry in
                            if let entry {
                                finish(entry)
                            } else {
                                let e = WordEntry(lemma: de, kind: .other, gender: .none, posLabel: "",
                                                  plural: nil, ipa: nil, praeteritum: nil, perfekt: nil,
                                                  translation: term, examples: [])
                                finish(e)
                            }
                        }
                    }
                }
            }
        }
    }

    private func buildEntry(word: String, result: WiktionaryResult?, engine: TranslateEngineConfig,
                            completion: @escaping (WordEntry?) -> Void) {
        let hasWik = result?.isUseful == true
        let wikResult = hasWik ? result : nil
        let group = DispatchGroup()

        var wordTR: String?
        var alternates: [String] = []
        var english: String?
        var synonyms: [String] = []
        var tatoebaEx: [Example] = []
        var translationFailed = false
        let tl = targetLang
        let wiktDE = wikResult?.examplesDE ?? []
        var wiktExTR = [String?](repeating: nil, count: wiktDE.count)

        group.enter(); TranslateClient.word(word, to: tl, engine: engine) { m, a, f in
            wordTR = m; alternates = a; if f { translationFailed = true }; group.leave()
        }
        // Hedef dil Türkçe'yken İngilizce referans da çekilir; English modunda ana
        // çeviri zaten İngilizce olduğundan ikinci çağrı gereksizdir.
        if tl == "tr" {
            group.enter(); TranslateClient.simple(word, to: "en", engine: engine) { e, _ in english = e; group.leave()
            }
        }
        group.enter(); SynonymClient.synonyms(word) { synonyms = $0; group.leave() }

        if wiktDE.isEmpty {
            if tl == "tr" {   // Tatoeba örnekleri Türkçe çevirilidir
                group.enter(); TatoebaClient.examples(word) { tatoebaEx = $0; group.leave() }
            }
        } else {
            for (i, de) in wiktDE.enumerated() {
                group.enter(); TranslateClient.simple(de, to: tl, engine: engine) { tr, _ in wiktExTR[i] = tr; group.leave() }
            }
        }

        group.notify(queue: .main) {
            var examples: [Example] = []
            if wiktDE.isEmpty {
                examples = tatoebaEx
            } else {
                for (i, de) in wiktDE.enumerated() {
                    if let tr = wiktExTR[i], !tr.isEmpty { examples.append(Example(de: de, tr: tr)) }
                }
            }
            completion(self.makeEntry(word: word, result: wikResult, translation: wordTR ?? "—",
                                      alternates: alternates, english: english, synonyms: synonyms, examples: examples,
                                      translationFailed: translationFailed && wordTR == nil))
        }
    }

    // "Çeviri alınamadı" mesajı hedef dile göre.
    private var translateErrorMessage: String {
        targetLang == "tr"
            ? "Çeviri alınamadı — internet bağlantını kontrol et."
            : "Translation failed — check your internet connection."
    }

    // Uzun metni cümle sonlarından (~) eşit parçalara böler; hiçbir parça limiti aşmaz.
    // Cümle sınırı bulunamazsa son boşluktan, o da yoksa sert kesimden böler.
    static func splitForTranslation(_ text: String, limit: Int = 1200) -> [String] {
        if text.count <= limit { return [text] }
        var parts: [String] = []
        var rest = Substring(text)
        while rest.count > limit {
            let window = rest.prefix(limit)
            var cut = window.lastIndex(where: { ".!?…".contains($0) }).map { rest.index(after: $0) }
            if cut == nil || cut! <= rest.startIndex {
                cut = window.lastIndex(where: { $0 == " " || $0 == "\n" })
            }
            let at = cut ?? window.endIndex
            let piece = rest[..<at].trimmingCharacters(in: .whitespacesAndNewlines)
            if !piece.isEmpty { parts.append(piece) }
            rest = rest[at...].drop(while: { $0 == " " || $0 == "\n" })
        }
        if !rest.isEmpty { parts.append(String(rest)) }
        return parts
    }

    private func makeEntry(word: String, result: WiktionaryResult?, translation: String,
                           alternates: [String], english: String?, synonyms: [String], examples: [Example],
                           translationFailed: Bool) -> WordEntry {
        var kind: EntryKind = .other
        var gender: Gender = .none
        var posLabel = ""
        var plural: String?
        var ipa: String?
        var praeteritum: String?
        var perfekt: String?

        if let r = result {
            switch r.kind {
            case .noun:
                kind = .noun
                switch r.genus {
                case "m": gender = .der; posLabel = "isim · eril"
                case "f": gender = .die; posLabel = "isim · dişil"
                case "n": gender = .das; posLabel = "isim · nötr"
                default: gender = .none; posLabel = "isim"
                }
            case .verb: kind = .verb; posLabel = "fiil"
            case .adjective: kind = .adjective; posLabel = "sıfat"
            case .other: kind = .other; posLabel = r.posLabel ?? ""
            }
            if kind == .noun, let p = r.plural {
                let stripped = WiktionaryClient.stripMarkup(p)
                let cleaned = stripped.trimmingCharacters(in: CharacterSet(charactersIn: "—-–. "))
                if !cleaned.isEmpty, cleaned.rangeOfCharacter(from: .letters) != nil { plural = "die \(cleaned)" }
            }
            if let i = r.ipa { ipa = "/\(i)/" }
            if kind == .verb {
                praeteritum = r.praeteritum
                if let part = r.partizip {
                    let aux = (r.auxiliary ?? "haben").lowercased().hasPrefix("sein") ? "ist" : "hat"
                    perfekt = "\(aux) \(part)"
                }
            }
        }

        var entry = WordEntry(lemma: word, kind: kind, gender: gender, posLabel: posLabel,
                              plural: plural, ipa: ipa, praeteritum: praeteritum, perfekt: perfekt,
                              translation: translation, examples: examples,
                              alternates: alternates.isEmpty ? nil : alternates,
                              english: english,
                              synonyms: synonyms.isEmpty ? nil : synonyms)
        if translationFailed {
            entry.errorMessage = translateErrorMessage
        }
        return entry
    }
}
