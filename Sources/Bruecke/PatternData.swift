import Foundation

// Almanca edat kalıpları (Verben mit Präpositionen) bilgi tabanı.
//
// Amaç: kullanıcı "sich beschweren über", "beschweren über" ya da yalnızca
// "beschweren" seçtiğinde Brücke bunu bir kalıp olarak tanısın; edatı, edatın
// yönettiği hâli ("ek"), Türkçe/İngilizce anlamı, bir örnek cümle ve hâli
// hatırlatan kısa bir ipucu göstersin.
//
// Hâl kuralının kısa hatırlatıcısı (ipuçlarında kullanılır):
//  • mit · bei · zu · von · nach · aus · vor  → her zaman DATİV
//  • für · um · gegen · durch · ohne          → her zaman AKKUSATİV
//  • an · auf · in · über  (iki yönlü)        → kalıpta mecazi "yönelme/konu" → AKKUSATİV
//    (yer/durum bildirseydi Dativ olurdu: teilnehmen an +D, arbeiten an +D gibi
//     istisnalar fiile bağlıdır, ezber gerektirir.)

struct PatternRecord {
    let verb: String        // "sich beschweren" ya da "warten"
    let prep: String        // "über"
    let kasus: Kasus
    let tr: String          // "şikayet etmek"
    let en: String          // "complain about"
    let exDE: String
    let exTR: String
    let tip: String
}

enum PatternDictionary {

    // Seçilen metni eşleştirme için sadeleştirir: küçük harf, fazla boşluk/satır
    // temizliği, sondaki "+a / +d / (akkusativ)" gibi hâl işaretlerini atar.
    static func normalize(_ s: String) -> String {
        var t = s.lowercased()
        // hâl işaretlerini ve parantezleri kaldır
        for token in ["(+a)", "(+d)", "+akk", "+dat", "+a", "+d", "(akkusativ)", "(dativ)", "akk.", "dat."] {
            t = t.replacingOccurrences(of: token, with: " ")
        }
        // noktalama → boşluk
        t = String(t.map { ($0.isLetter || $0 == " ") ? $0 : " " })
        // çoklu boşlukları teke indir
        let parts = t.split(separator: " ").map(String.init)
        return parts.joined(separator: " ").trimmingCharacters(in: .whitespaces)
    }

    static func lookup(_ term: String) -> WordEntry? {
        let key = normalize(term)
        guard !key.isEmpty else { return nil }

        if let rec = map[key] { return entry(from: rec) }

        // "sich" başta ise atıp tekrar dene
        if key.hasPrefix("sich ") {
            let noSich = String(key.dropFirst(5))
            if let rec = map[noSich] { return entry(from: rec) }
        }
        // sondaki edatı atıp çekirdek fiille dene (ör. "warten auf" → "warten")
        let words = key.split(separator: " ").map(String.init)
        if words.count >= 2 {
            let dropLast = words.dropLast().joined(separator: " ")
            if let rec = map[dropLast] { return entry(from: rec) }
        }
        return nil
    }

    private static func entry(from r: PatternRecord) -> WordEntry {
        WordEntry(
            lemma: "\(r.verb) \(r.prep)",
            kind: .verb, gender: .none, posLabel: "edat kalıbı",
            plural: nil, ipa: nil, praeteritum: nil, perfekt: nil,
            translation: r.tr,
            examples: [Example(de: r.exDE, tr: r.exTR)],
            english: r.en,
            pattern: VerbPattern(verb: r.verb, preposition: r.prep, kasus: r.kasus, tip: r.tip)
        )
    }

    // Her kayıt için olası seçim biçimlerini anahtar yapar:
    // tam fiil, çekirdek fiil (sich'siz), fiil+edat, çekirdek+edat.
    private static let map: [String: PatternRecord] = {
        var m: [String: PatternRecord] = [:]
        for r in records {
            let core = r.verb.replacingOccurrences(of: "sich ", with: "")
            for form in [r.verb, core, "\(r.verb) \(r.prep)", "\(core) \(r.prep)"] {
                m[form.lowercased()] = r
            }
        }
        return m
    }()

    // MARK: - Kalıplar (yaygın A1–B2 seti)

    static let records: [PatternRecord] = [
        // an + Akkusativ (yönelme/konu)
        PatternRecord(verb: "denken", prep: "an", kasus: .akkusativ,
            tr: "düşünmek (birini/bir şeyi)", en: "think of/about",
            exDE: "Ich denke oft an dich.", exTR: "Seni sık sık düşünüyorum.",
            tip: "an burada 'yönelme' anlatır → Akkusativ. Aklında tut: an dich, an ihn."),
        PatternRecord(verb: "sich erinnern", prep: "an", kasus: .akkusativ,
            tr: "hatırlamak", en: "remember",
            exDE: "Erinnerst du dich an den Sommer?", exTR: "O yazı hatırlıyor musun?",
            tip: "an + Akkusativ. Hatıra sana doğru 'gelir' → yönelme → -i hâli mantığı."),
        PatternRecord(verb: "sich gewöhnen", prep: "an", kasus: .akkusativ,
            tr: "alışmak", en: "get used to",
            exDE: "Ich gewöhne mich an das Wetter.", exTR: "Havaya alışıyorum.",
            tip: "an + Akkusativ. Bir şeye doğru 'alışma' → yönelme."),
        PatternRecord(verb: "glauben", prep: "an", kasus: .akkusativ,
            tr: "inanmak", en: "believe in",
            exDE: "Sie glaubt an sich selbst.", exTR: "Kendine inanıyor.",
            tip: "glauben an hep Akkusativ. (Dikkat: 'arbeiten an' ise Dativ ister.)"),

        // an + Dativ (katılım/üzerinde olma) — istisna grubu
        PatternRecord(verb: "teilnehmen", prep: "an", kasus: .dativ,
            tr: "katılmak", en: "take part in",
            exDE: "Wir nehmen an dem Kurs teil.", exTR: "Kursa katılıyoruz.",
            tip: "Burada an istisnaen Dativ ister. 'teilnehmen an + Dativ' diye ezberle."),
        PatternRecord(verb: "arbeiten", prep: "an", kasus: .dativ,
            tr: "üzerinde çalışmak", en: "work on",
            exDE: "Er arbeitet an einem Roman.", exTR: "Bir roman üzerinde çalışıyor.",
            tip: "arbeiten an + Dativ. 'Bir şeyin üstünde durmak' → yer gibi → Dativ."),
        PatternRecord(verb: "leiden", prep: "an", kasus: .dativ,
            tr: "(hastalık) çekmek", en: "suffer from (illness)",
            exDE: "Sie leidet an einer Allergie.", exTR: "Bir alerjisi var (ondan muzdarip).",
            tip: "Hastalık için: leiden an + Dativ. (Durum/koşul için: leiden unter + Dativ.)"),

        // auf + Akkusativ
        PatternRecord(verb: "warten", prep: "auf", kasus: .akkusativ,
            tr: "beklemek", en: "wait for",
            exDE: "Ich warte auf den Bus.", exTR: "Otobüsü bekliyorum.",
            tip: "warten auf + Akkusativ. 'Worauf wartest du?' → auf hep -i hâli alır."),
        PatternRecord(verb: "sich freuen", prep: "auf", kasus: .akkusativ,
            tr: "(gelecek bir şeyi) iple çekmek", en: "look forward to",
            exDE: "Ich freue mich auf das Wochenende.", exTR: "Hafta sonunu iple çekiyorum.",
            tip: "GELECEK için auf + Akkusativ. (Olmuş/şu anki şey için über + Akkusativ.)"),
        PatternRecord(verb: "sich konzentrieren", prep: "auf", kasus: .akkusativ,
            tr: "odaklanmak", en: "concentrate on",
            exDE: "Konzentrier dich auf die Arbeit!", exTR: "İşe odaklan!",
            tip: "auf + Akkusativ. Dikkatini bir şeye 'doğru' yöneltirsin → yönelme."),
        PatternRecord(verb: "achten", prep: "auf", kasus: .akkusativ,
            tr: "dikkat etmek", en: "pay attention to",
            exDE: "Achte auf die Verben!", exTR: "Fiillere dikkat et!",
            tip: "achten auf + Akkusativ. aufpassen auf da aynı: ikisi de -i hâli."),
        PatternRecord(verb: "hoffen", prep: "auf", kasus: .akkusativ,
            tr: "ummak", en: "hope for",
            exDE: "Wir hoffen auf gutes Wetter.", exTR: "İyi hava umuyoruz.",
            tip: "hoffen auf + Akkusativ. auf bu kalıpta her zaman -i hâli."),
        PatternRecord(verb: "sich vorbereiten", prep: "auf", kasus: .akkusativ,
            tr: "hazırlanmak", en: "prepare for",
            exDE: "Sie bereitet sich auf die Prüfung vor.", exTR: "Sınava hazırlanıyor.",
            tip: "auf + Akkusativ. Bir hedefe 'doğru' hazırlık → yönelme."),
        PatternRecord(verb: "verzichten", prep: "auf", kasus: .akkusativ,
            tr: "vazgeçmek", en: "do without / give up",
            exDE: "Ich verzichte auf Zucker.", exTR: "Şekerden vazgeçiyorum.",
            tip: "verzichten auf + Akkusativ. Anlam '-den vazgeçmek' olsa da Almanca auf + -i hâli ister."),
        PatternRecord(verb: "antworten", prep: "auf", kasus: .akkusativ,
            tr: "cevap vermek (bir şeye)", en: "answer (something)",
            exDE: "Er antwortet auf die Frage.", exTR: "Soruyu cevaplıyor.",
            tip: "Soruya cevap: auf + Akkusativ. (Kişiye cevap: antworten + Dativ.)"),
        PatternRecord(verb: "reagieren", prep: "auf", kasus: .akkusativ,
            tr: "tepki vermek", en: "react to",
            exDE: "Wie reagierst du auf Kritik?", exTR: "Eleştiriye nasıl tepki veriyorsun?",
            tip: "reagieren auf + Akkusativ. auf bu kalıpta -i hâli."),

        // über + Akkusativ (konu)
        PatternRecord(verb: "sich beschweren", prep: "über", kasus: .akkusativ,
            tr: "şikayet etmek", en: "complain about",
            exDE: "Er beschwert sich über den Lärm.", exTR: "Gürültüden şikayet ediyor.",
            tip: "über bir KONU bildirir → Akkusativ. 'Worüber?' → über + -i hâli."),
        PatternRecord(verb: "sich ärgern", prep: "über", kasus: .akkusativ,
            tr: "kızmak, sinirlenmek", en: "be annoyed about",
            exDE: "Ich ärgere mich über den Fehler.", exTR: "Bu hataya sinirleniyorum.",
            tip: "über + Akkusativ. Kızdığın 'konu' → -i hâli."),
        PatternRecord(verb: "sich freuen", prep: "über", kasus: .akkusativ,
            tr: "(olmuş bir şeye) sevinmek", en: "be happy about",
            exDE: "Sie freut sich über das Geschenk.", exTR: "Hediyeye sevindi.",
            tip: "OLMUŞ/eldeki şey için über + Akkusativ. (Gelecek için auf + Akkusativ.)"),
        PatternRecord(verb: "sprechen", prep: "über", kasus: .akkusativ,
            tr: "konuşmak (hakkında)", en: "talk about",
            exDE: "Wir sprechen über Politik.", exTR: "Siyaset hakkında konuşuyoruz.",
            tip: "Konu = über + Akkusativ. (Kişiyle konuşmak: sprechen mit + Dativ.)"),
        PatternRecord(verb: "nachdenken", prep: "über", kasus: .akkusativ,
            tr: "üzerine düşünmek, kafa yormak", en: "think over / ponder",
            exDE: "Ich denke über dein Angebot nach.", exTR: "Teklifin üzerine düşünüyorum.",
            tip: "über + Akkusativ. Üzerinde kafa yorduğun 'konu' → -i hâli."),
        PatternRecord(verb: "sich informieren", prep: "über", kasus: .akkusativ,
            tr: "bilgi edinmek", en: "get information about",
            exDE: "Informier dich über die Regeln.", exTR: "Kurallar hakkında bilgi al.",
            tip: "über + Akkusativ. Bilgi aldığın 'konu' → -i hâli."),
        PatternRecord(verb: "lachen", prep: "über", kasus: .akkusativ,
            tr: "gülmek (bir şeye)", en: "laugh about",
            exDE: "Sie lachen über den Witz.", exTR: "Şakaya gülüyorlar.",
            tip: "über + Akkusativ. Güldüğün 'konu' → -i hâli."),

        // für + Akkusativ (für daima Akkusativ)
        PatternRecord(verb: "sich interessieren", prep: "für", kasus: .akkusativ,
            tr: "ilgilenmek", en: "be interested in",
            exDE: "Ich interessiere mich für Musik.", exTR: "Müzikle ilgileniyorum.",
            tip: "für edatı HER ZAMAN Akkusativ. Kalıbı için ek düşünmene gerek yok."),
        PatternRecord(verb: "danken", prep: "für", kasus: .akkusativ,
            tr: "teşekkür etmek (bir şey için)", en: "thank for",
            exDE: "Danke für deine Hilfe!", exTR: "Yardımın için teşekkürler!",
            tip: "für → Akkusativ (hep). Kişiye olan kısım Dativ'dir: danke dir für ..."),
        PatternRecord(verb: "sich entschuldigen", prep: "für", kasus: .akkusativ,
            tr: "özür dilemek (bir şey için)", en: "apologize for",
            exDE: "Ich entschuldige mich für die Verspätung.", exTR: "Geç kaldığım için özür dilerim.",
            tip: "für → Akkusativ. (Kişiden özür: sich entschuldigen bei + Dativ.)"),
        PatternRecord(verb: "sich bedanken", prep: "für", kasus: .akkusativ,
            tr: "teşekkür etmek", en: "give thanks for",
            exDE: "Wir bedanken uns für die Einladung.", exTR: "Davet için teşekkür ederiz.",
            tip: "für → Akkusativ (hep)."),

        // um + Akkusativ (um daima Akkusativ)
        PatternRecord(verb: "bitten", prep: "um", kasus: .akkusativ,
            tr: "rica etmek", en: "ask for / request",
            exDE: "Er bittet um Hilfe.", exTR: "Yardım rica ediyor.",
            tip: "um edatı HER ZAMAN Akkusativ."),
        PatternRecord(verb: "sich kümmern", prep: "um", kasus: .akkusativ,
            tr: "ilgilenmek, bakmak", en: "take care of",
            exDE: "Sie kümmert sich um die Kinder.", exTR: "Çocuklara bakıyor.",
            tip: "um → Akkusativ (hep)."),
        PatternRecord(verb: "sich bewerben", prep: "um", kasus: .akkusativ,
            tr: "başvurmak", en: "apply for",
            exDE: "Ich bewerbe mich um die Stelle.", exTR: "İş için başvuruyorum.",
            tip: "um → Akkusativ. (Nereye başvuru: sich bewerben bei + Dativ.)"),

        // in + Akkusativ
        PatternRecord(verb: "sich verlieben", prep: "in", kasus: .akkusativ,
            tr: "âşık olmak", en: "fall in love with",
            exDE: "Er hat sich in sie verliebt.", exTR: "Ona âşık oldu.",
            tip: "Burada in 'içine doğru' hareket → Akkusativ. sich verlieben in + -i hâli."),

        // mit + Dativ (mit daima Dativ)
        PatternRecord(verb: "sprechen", prep: "mit", kasus: .dativ,
            tr: "konuşmak (biriyle)", en: "speak with",
            exDE: "Ich spreche mit dem Lehrer.", exTR: "Öğretmenle konuşuyorum.",
            tip: "mit edatı HER ZAMAN Dativ. Kişiyle birliktelik → -e/-le hâli."),
        PatternRecord(verb: "anfangen", prep: "mit", kasus: .dativ,
            tr: "başlamak", en: "start with",
            exDE: "Wir fangen mit der Übung an.", exTR: "Alıştırmayla başlıyoruz.",
            tip: "mit → Dativ (hep). beginnen mit ve aufhören mit de aynı."),
        PatternRecord(verb: "aufhören", prep: "mit", kasus: .dativ,
            tr: "bırakmak, son vermek", en: "stop (doing)",
            exDE: "Hör mit dem Rauchen auf!", exTR: "Sigarayı bırak!",
            tip: "mit → Dativ (hep)."),
        PatternRecord(verb: "sich beschäftigen", prep: "mit", kasus: .dativ,
            tr: "uğraşmak, meşgul olmak", en: "occupy oneself with",
            exDE: "Sie beschäftigt sich mit Kunst.", exTR: "Sanatla uğraşıyor.",
            tip: "mit → Dativ (hep)."),
        PatternRecord(verb: "rechnen", prep: "mit", kasus: .dativ,
            tr: "hesaba katmak, beklemek", en: "count on / reckon with",
            exDE: "Ich rechne mit deiner Hilfe.", exTR: "Yardımına güveniyorum (hesaba katıyorum).",
            tip: "mit → Dativ (hep)."),
        PatternRecord(verb: "telefonieren", prep: "mit", kasus: .dativ,
            tr: "telefonla konuşmak", en: "talk on the phone with",
            exDE: "Er telefoniert mit seiner Mutter.", exTR: "Annesiyle telefonda konuşuyor.",
            tip: "mit → Dativ (hep)."),

        // bei + Dativ
        PatternRecord(verb: "helfen", prep: "bei", kasus: .dativ,
            tr: "yardım etmek (bir konuda)", en: "help with",
            exDE: "Kannst du mir bei der Arbeit helfen?", exTR: "İşte bana yardım eder misin?",
            tip: "bei edatı HER ZAMAN Dativ. (Kime yardım kısmı da Dativ: hilf mir.)"),
        PatternRecord(verb: "sich entschuldigen", prep: "bei", kasus: .dativ,
            tr: "özür dilemek (birinden)", en: "apologize to",
            exDE: "Entschuldige dich bei ihr!", exTR: "Ondan özür dile!",
            tip: "bei → Dativ. (Bir şey için özür: ... für + Akkusativ.)"),

        // zu + Dativ (zu daima Dativ)
        PatternRecord(verb: "gehören", prep: "zu", kasus: .dativ,
            tr: "ait olmak", en: "belong to",
            exDE: "Das gehört zu meiner Arbeit.", exTR: "Bu, işimin bir parçası.",
            tip: "zu edatı HER ZAMAN Dativ."),
        PatternRecord(verb: "passen", prep: "zu", kasus: .dativ,
            tr: "yakışmak, uymak", en: "match / suit",
            exDE: "Die Jacke passt zu der Hose.", exTR: "Ceket pantolona yakışıyor.",
            tip: "zu → Dativ (hep)."),
        PatternRecord(verb: "einladen", prep: "zu", kasus: .dativ,
            tr: "davet etmek", en: "invite to",
            exDE: "Ich lade dich zu meiner Party ein.", exTR: "Seni partime davet ediyorum.",
            tip: "zu → Dativ (hep)."),
        PatternRecord(verb: "gratulieren", prep: "zu", kasus: .dativ,
            tr: "kutlamak, tebrik etmek", en: "congratulate on",
            exDE: "Ich gratuliere dir zum Geburtstag.", exTR: "Doğum gününü kutlarım.",
            tip: "zu → Dativ (hep). zu dem → zum kısalmasına dikkat."),

        // von + Dativ (von daima Dativ)
        PatternRecord(verb: "träumen", prep: "von", kasus: .dativ,
            tr: "hayalini kurmak, rüyasını görmek", en: "dream of",
            exDE: "Sie träumt von einer Reise.", exTR: "Bir seyahatin hayalini kuruyor.",
            tip: "von edatı HER ZAMAN Dativ."),
        PatternRecord(verb: "erzählen", prep: "von", kasus: .dativ,
            tr: "anlatmak (-den bahsederek)", en: "tell about",
            exDE: "Erzähl mir von deinem Tag!", exTR: "Bana gününü anlat!",
            tip: "von → Dativ (hep). (Konu vurgusu için: erzählen über + Akkusativ.)"),
        PatternRecord(verb: "abhängen", prep: "von", kasus: .dativ,
            tr: "bağlı olmak", en: "depend on",
            exDE: "Das hängt vom Wetter ab.", exTR: "Bu, havaya bağlı.",
            tip: "von → Dativ (hep). von dem → vom kısalır."),
        PatternRecord(verb: "halten", prep: "von", kasus: .dativ,
            tr: "(bir şey) hakkında ne düşünmek", en: "think of (opinion)",
            exDE: "Was hältst du von dem Plan?", exTR: "Bu plan hakkında ne düşünüyorsun?",
            tip: "von → Dativ (hep). 'Fikrin ne?' anlamında kalıp."),

        // nach + Dativ (nach daima Dativ)
        PatternRecord(verb: "fragen", prep: "nach", kasus: .dativ,
            tr: "sormak (-i sormak)", en: "ask about/for",
            exDE: "Er fragt nach dem Weg.", exTR: "Yolu soruyor.",
            tip: "nach edatı HER ZAMAN Dativ."),
        PatternRecord(verb: "suchen", prep: "nach", kasus: .dativ,
            tr: "aramak", en: "search for",
            exDE: "Ich suche nach meinem Schlüssel.", exTR: "Anahtarımı arıyorum.",
            tip: "nach → Dativ (hep)."),
        PatternRecord(verb: "sich sehnen", prep: "nach", kasus: .dativ,
            tr: "özlemek, hasret çekmek", en: "long for",
            exDE: "Ich sehne mich nach dem Sommer.", exTR: "Yazı özlüyorum.",
            tip: "nach → Dativ (hep)."),

        // vor + Dativ (korku/koruma grubunda Dativ)
        PatternRecord(verb: "Angst haben", prep: "vor", kasus: .dativ,
            tr: "korkmak", en: "be afraid of",
            exDE: "Sie hat Angst vor dem Hund.", exTR: "Köpekten korkuyor.",
            tip: "Korku kalıbında vor + Dativ. sich fürchten vor da aynı."),
        PatternRecord(verb: "sich fürchten", prep: "vor", kasus: .dativ,
            tr: "korkmak", en: "be scared of",
            exDE: "Er fürchtet sich vor der Dunkelheit.", exTR: "Karanlıktan korkuyor.",
            tip: "vor + Dativ. Korku/uyarı/koruma grubu Dativ alır (warnen/schützen vor)."),
        PatternRecord(verb: "warnen", prep: "vor", kasus: .dativ,
            tr: "uyarmak", en: "warn about",
            exDE: "Die Polizei warnt vor dem Sturm.", exTR: "Polis fırtınaya karşı uyarıyor.",
            tip: "vor + Dativ. Korku/tehlike grubuyla aynı mantık."),

        // aus + Dativ
        PatternRecord(verb: "bestehen", prep: "aus", kasus: .dativ,
            tr: "-den oluşmak", en: "consist of",
            exDE: "Das Team besteht aus fünf Leuten.", exTR: "Takım beş kişiden oluşuyor.",
            tip: "aus edatı HER ZAMAN Dativ.")
    ]
}
