import Foundation

@MainActor
final class DictionaryService {

    // Hangi çeviri motoru kullanılacak (kullanıcı ayarından).
    private var engine: TranslateEngineConfig {
        switch AppSettings.shared.translationEngine {
        case .google: return .google
        case .libre:  return .libre(endpoint: AppSettings.shared.libreEndpoint)
        }
    }

    func lookup(_ raw: String, completion: @escaping (WordEntry?) -> Void) {
        let term = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { completion(nil); return }

        // Önce edat kalıbı mı diye bak (sich beschweren über, warten auf ...).
        // Kullanıcı tam kalıbı, sadece fiili ya da fiil+edatı seçmiş olabilir.
        if let p = PatternDictionary.lookup(term) {
            HistoryStore.shared.record(term: term, entry: p)
            completion(p)
            return
        }

        if let hit = SampleDictionary.lookup(term) {
            HistoryStore.shared.record(term: term, entry: hit)
            completion(hit)
            return
        }

        // Daha önce bakıldıysa ağa hiç çıkma: anında ve çevrimdışı da çalışır.
        if let cached = HistoryStore.shared.cached(term) {
            HistoryStore.shared.record(term: term, entry: cached)   // geçmişte öne taşı
            completion(cached)
            return
        }

        let engine = self.engine

        if term.contains(" ") {
            let group = DispatchGroup()
            var main: String?
            var english: String?
            var failed = false
            group.enter(); TranslateClient.word(term, to: "tr", engine: engine) { m, _, f in main = m; if f { failed = true }; group.leave() }
            group.enter(); TranslateClient.simple(term, to: "en", engine: engine) { e, _ in english = e; group.leave() }
            group.notify(queue: .main) {
                var e = self.makeEntry(word: term, result: nil, translation: main ?? "—",
                                       alternates: [], english: english, synonyms: [], examples: [],
                                       translationFailed: failed && main == nil)
                e.kind = .phrase
                e.posLabel = "cümle"
                HistoryStore.shared.record(term: term, entry: e)
                completion(e)
            }
            return
        }

        let word = term.trimmingCharacters(in: CharacterSet.letters.inverted)
        guard !word.isEmpty else { completion(nil); return }

        if let cached = HistoryStore.shared.cached(word) {
            HistoryStore.shared.record(term: word, entry: cached)
            completion(cached)
            return
        }

        WiktionaryClient.fetch(word) { result in
            DispatchQueue.main.async {
                self.buildEntry(word: word, result: result, engine: engine) { entry in
                    if let entry { HistoryStore.shared.record(term: word, entry: entry) }
                    completion(entry)
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
        let wiktDE = wikResult?.examplesDE ?? []
        var wiktExTR = [String?](repeating: nil, count: wiktDE.count)

        group.enter(); TranslateClient.word(word, to: "tr", engine: engine) { m, a, f in
            wordTR = m; alternates = a; if f { translationFailed = true }; group.leave()
        }
        group.enter(); TranslateClient.simple(word, to: "en", engine: engine) { e, _ in english = e; group.leave() }
        group.enter(); SynonymClient.synonyms(word) { synonyms = $0; group.leave() }

        if wiktDE.isEmpty {
            group.enter(); TatoebaClient.examples(word) { tatoebaEx = $0; group.leave() }
        } else {
            for (i, de) in wiktDE.enumerated() {
                group.enter(); TranslateClient.simple(de, to: "tr", engine: engine) { tr, _ in wiktExTR[i] = tr; group.leave() }
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
            entry.errorMessage = "Çeviri alınamadı — internet bağlantını kontrol et."
        }
        return entry
    }
}
