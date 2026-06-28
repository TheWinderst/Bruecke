import Foundation

enum Gender: String, Codable {
    case der, die, das, none
}

enum EntryKind: String, Codable {
    case noun, verb, adjective, phrase, other
}

struct Example: Codable, Hashable {
    let de: String
    let tr: String
}

// Almanca dilbilgisi hâli (Kasus). Edat kalıplarında hangi "ek"in geleceğini belirler.
enum Kasus: String, Codable {
    case akkusativ, dativ

    var short: String { self == .akkusativ ? "+A" : "+D" }
    var name: String { self == .akkusativ ? "Akkusativ" : "Dativ" }
    // Türkçe konuşana kaba bir köprü: Akkusativ ≈ -i hâli, Dativ ≈ -e hâli.
    var trHint: String { self == .akkusativ ? "-i hâli" : "-e hâli" }
}

// Edat kalıbı: bir fiilin sabit edatı ve o edatın yönettiği hâl + hatırlatma ipucu.
// Örn. "sich beschweren über" → edat "über", hâl Akkusativ.
struct VerbPattern: Codable, Hashable {
    let verb: String          // "sich beschweren"
    let preposition: String   // "über"
    let kasus: Kasus          // .akkusativ
    let tip: String           // Türkçe ipucu
}

struct WordEntry: Codable, Hashable, Identifiable {
    let lemma: String
    var kind: EntryKind
    var gender: Gender
    var posLabel: String
    var plural: String?
    var ipa: String?
    var praeteritum: String?
    var perfekt: String?
    var translation: String
    var examples: [Example]
    var alternates: [String]? = nil
    var english: String? = nil
    var synonyms: [String]? = nil
    // Ağ hatası gibi durumlarda kullanıcıya gösterilecek mesaj (çekilemedi vb.).
    var errorMessage: String? = nil

    // Edat kalıbı (Verb mit Präposition) bilgisi; bu kelime bir kalıpsa dolu, değilse nil.
    var pattern: VerbPattern? = nil

    // Eş sesli/eş yazımlı kelimeler (der/die See, das/der Band) çakışmasın diye
    // kimliği yalnızca lemma değil, tür+cinsiyetle birlikte belirleriz.
    var id: String { "\(lemma)|\(kind.rawValue)|\(gender.rawValue)" }

    var displayHeadword: String {
        if kind == .noun, gender != .none { return "\(gender.rawValue) \(lemma)" }
        return lemma
    }
}

enum SampleDictionary {
    static func lookup(_ term: String) -> WordEntry? {
        entries[term.lowercased()]
    }

    static let entries: [String: WordEntry] = [
        "apfel": WordEntry(lemma: "Apfel", kind: .noun, gender: .der, posLabel: "isim · eril",
            plural: "die Äpfel", ipa: "/ˈapfl̩/", praeteritum: nil, perfekt: nil, translation: "elma",
            examples: [
                Example(de: "Der Apfel ist rot.", tr: "Elma kırmızıdır."),
                Example(de: "Ich esse einen Apfel.", tr: "Bir elma yiyorum.")
            ]),
        "haus": WordEntry(lemma: "Haus", kind: .noun, gender: .das, posLabel: "isim · nötr",
            plural: "die Häuser", ipa: "/haʊ̯s/", praeteritum: nil, perfekt: nil, translation: "ev",
            examples: [
                Example(de: "Das Haus ist groß.", tr: "Ev büyük."),
                Example(de: "Wir kaufen ein Haus.", tr: "Bir ev satın alıyoruz.")
            ]),
        "katze": WordEntry(lemma: "Katze", kind: .noun, gender: .die, posLabel: "isim · dişil",
            plural: "die Katzen", ipa: "/ˈkatsə/", praeteritum: nil, perfekt: nil, translation: "kedi",
            examples: [
                Example(de: "Die Katze schläft.", tr: "Kedi uyuyor."),
                Example(de: "Ich habe eine Katze.", tr: "Bir kedim var.")
            ]),
        "buch": WordEntry(lemma: "Buch", kind: .noun, gender: .das, posLabel: "isim · nötr",
            plural: "die Bücher", ipa: "/buːx/", praeteritum: nil, perfekt: nil, translation: "kitap",
            examples: [
                Example(de: "Das Buch ist spannend.", tr: "Kitap heyecan verici."),
                Example(de: "Ich lese ein Buch.", tr: "Bir kitap okuyorum.")
            ]),
        "wasser": WordEntry(lemma: "Wasser", kind: .noun, gender: .das, posLabel: "isim · nötr",
            plural: "die Wässer", ipa: "/ˈvasɐ/", praeteritum: nil, perfekt: nil, translation: "su",
            examples: [
                Example(de: "Das Wasser ist kalt.", tr: "Su soğuk."),
                Example(de: "Ich trinke Wasser.", tr: "Su içiyorum.")
            ]),
        "freund": WordEntry(lemma: "Freund", kind: .noun, gender: .der, posLabel: "isim · eril",
            plural: "die Freunde", ipa: "/fʁɔɪ̯nt/", praeteritum: nil, perfekt: nil, translation: "arkadaş",
            examples: [
                Example(de: "Mein Freund ist nett.", tr: "Arkadaşım kibar."),
                Example(de: "Er ist mein bester Freund.", tr: "O benim en iyi arkadaşım.")
            ]),
        "tee": WordEntry(lemma: "Tee", kind: .noun, gender: .der, posLabel: "isim · eril",
            plural: "die Tees", ipa: "/teː/", praeteritum: nil, perfekt: nil, translation: "çay",
            examples: [
                Example(de: "Der Tee ist heiß.", tr: "Çay sıcak."),
                Example(de: "Ich trinke gern Tee.", tr: "Çay içmeyi severim.")
            ]),
        "schön": WordEntry(lemma: "schön", kind: .adjective, gender: .none, posLabel: "sıfat",
            plural: nil, ipa: "/ʃøːn/", praeteritum: nil, perfekt: nil, translation: "güzel",
            examples: [
                Example(de: "Das ist schön.", tr: "Bu güzel."),
                Example(de: "Sie hat schöne Augen.", tr: "Onun güzel gözleri var.")
            ]),
        "lernen": WordEntry(lemma: "lernen", kind: .verb, gender: .none, posLabel: "fiil",
            plural: nil, ipa: "/ˈlɛʁnən/", praeteritum: "lernte", perfekt: "hat gelernt", translation: "öğrenmek",
            examples: [
                Example(de: "Ich lerne Deutsch.", tr: "Almanca öğreniyorum."),
                Example(de: "Wir lernen zusammen.", tr: "Birlikte öğreniyoruz.")
            ]),
        "trinken": WordEntry(lemma: "trinken", kind: .verb, gender: .none, posLabel: "fiil",
            plural: nil, ipa: "/ˈtʁɪŋkn̩/", praeteritum: "trank", perfekt: "hat getrunken", translation: "içmek",
            examples: [
                Example(de: "Ich trinke Wasser.", tr: "Su içiyorum."),
                Example(de: "Sie trinkt Tee.", tr: "O çay içiyor.")
            ]),
        "gehen": WordEntry(lemma: "gehen", kind: .verb, gender: .none, posLabel: "fiil",
            plural: nil, ipa: "/ˈɡeːən/", praeteritum: "ging", perfekt: "ist gegangen", translation: "gitmek",
            examples: [
                Example(de: "Ich gehe nach Hause.", tr: "Eve gidiyorum."),
                Example(de: "Wir gehen ins Kino.", tr: "Sinemaya gidiyoruz.")
            ]),
        "machen": WordEntry(lemma: "machen", kind: .verb, gender: .none, posLabel: "fiil",
            plural: nil, ipa: "/ˈmaxn̩/", praeteritum: "machte", perfekt: "hat gemacht", translation: "yapmak",
            examples: [
                Example(de: "Was machst du?", tr: "Ne yapıyorsun?"),
                Example(de: "Ich mache Hausaufgaben.", tr: "Ödev yapıyorum.")
            ]),
        "wollen": WordEntry(lemma: "wollen", kind: .verb, gender: .none, posLabel: "fiil · modal",
            plural: nil, ipa: "/ˈvɔlən/", praeteritum: "wollte", perfekt: "hat gewollt", translation: "istemek",
            examples: [
                Example(de: "Ich will Tee trinken.", tr: "Çay içmek istiyorum."),
                Example(de: "Was willst du?", tr: "Ne istiyorsun?")
            ]),
        "versuchen": WordEntry(lemma: "versuchen", kind: .verb, gender: .none, posLabel: "fiil",
            plural: nil, ipa: "/fɛɐ̯ˈzuːxn̩/", praeteritum: "versuchte", perfekt: "hat versucht", translation: "denemek",
            examples: [
                Example(de: "Ich versuche zu schlafen.", tr: "Uyumaya çalışıyorum."),
                Example(de: "Versuch es noch mal!", tr: "Bir daha dene!")
            ])
    ]
}
