import Foundation

struct WiktionaryResult {
    enum Kind { case noun, verb, adjective, other }
    var kind: Kind = .other
    var posLabel: String?
    var genus: String?
    var plural: String?
    var ipa: String?
    var praeteritum: String?
    var partizip: String?
    var auxiliary: String?
    var examplesDE: [String] = []
    var baseLemma: String?

    var isUseful: Bool {
        kind != .other || ipa != nil || !examplesDE.isEmpty || (posLabel?.isEmpty == false)
    }
}

enum WiktionaryClient {
    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.waitsForConnectivity = false
        return URLSession(configuration: config)
    }()

    static func fetch(_ word: String, completion: @escaping (WiktionaryResult?) -> Void) {
        loadResolved(word) { result in
            if let result, result.isUseful { completion(result); return }
            let alt = toggledFirst(word)
            guard alt != word else { completion(result); return }
            loadResolved(alt) { altResult in
                if let altResult, altResult.isUseful { completion(altResult) }
                else { completion(altResult ?? result) }
            }
        }
    }

    private static func loadResolved(_ word: String, hop: Int = 0, completion: @escaping (WiktionaryResult?) -> Void) {
        load(word) { result in
            if hop < 2, let base = result?.baseLemma, !base.isEmpty, base != word {
                loadResolved(base, hop: hop + 1) { baseResult in
                    if let baseResult, baseResult.isUseful { completion(baseResult) }
                    else { completion(result) }
                }
                return
            }
            completion(result)
        }
    }

    private static func toggledFirst(_ s: String) -> String {
        guard let f = s.first else { return s }
        if f.isLowercase { return f.uppercased() + s.dropFirst() }
        return f.lowercased() + s.dropFirst()
    }

    private static func load(_ page: String, completion: @escaping (WiktionaryResult?) -> Void) {
        // Sayfa adı bir sorgu parametresine girdiği için katı (sorgu-güvenli) kodlama kullan.
        let enc = TranslateClient.encode(page) ?? page
        guard let url = URL(string: "https://de.wiktionary.org/w/api.php?action=parse&page=\(enc)&prop=wikitext&format=json&formatversion=2") else {
            completion(nil); return
        }
        session.dataTask(with: url) { data, _, _ in
            guard let data,
                  let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let parse = obj["parse"] as? [String: Any],
                  let wikitext = parse["wikitext"] as? String else {
                completion(nil); return
            }
            completion(parseGerman(wikitext))
        }.resume()
    }

    private static func parseGerman(_ full: String) -> WiktionaryResult {
        let wt = germanSection(full)
        var r = WiktionaryResult()

        if var base = m1(#"\{\{Grundformverweis[^|}]*\|([^}|]+)\}\}"#, wt) {
            if let eq = base.firstIndex(of: "=") { base = String(base[base.index(after: eq)...]) }
            r.baseLemma = base.trimmingCharacters(in: .whitespaces)
        }

        let raw = m1(#"\{\{Wortart\|([^|}]+)\|Deutsch\}\}"#, wt)?.lowercased() ?? ""
        switch raw {
        case "substantiv": r.kind = .noun
        case "verb": r.kind = .verb
        case "adjektiv": r.kind = .adjective; r.posLabel = "sıfat"
        case "adverb": r.posLabel = "zarf"
        case "präposition": r.posLabel = "edat"
        case "konjunktion", "subjunktion": r.posLabel = "bağlaç"
        case "artikel": r.posLabel = "artikel"
        case "numerale", "numeral": r.posLabel = "sayı"
        case "interjektion": r.posLabel = "ünlem"
        default:
            if raw.contains("pronomen") { r.posLabel = "zamir" }
            else if raw.contains("partikel") { r.posLabel = "edat" }
        }

        if r.kind == .noun {
            r.genus = m1(#"\|\s*Genus[^=\n]*=\s*([mfn])"#, wt)
            r.plural = m1(#"\|\s*Nominativ Plural[^=\n]*=\s*([^\n|}]+)"#, wt)
        }
        r.ipa = m1(#"\{\{Lautschrift\|([^}]+)\}\}"#, wt)
        if r.kind == .verb {
            r.praeteritum = m1(#"\|\s*Präteritum_ich\s*=\s*([^\n|}]+)"#, wt)
            r.partizip = m1(#"\|\s*Partizip II\s*=\s*([^\n|}]+)"#, wt)
            r.auxiliary = m1(#"\|\s*Hilfsverb\s*=\s*([^\n|}]+)"#, wt)
        }
        r.examplesDE = examples(wt)
        return r
    }

    private static func germanSection(_ wt: String) -> String {
        guard let r = wt.range(of: "{{Sprache|Deutsch}}") else { return wt }
        let after = wt[r.upperBound...]
        if let next = after.range(of: "\n== ") { return String(after[..<next.lowerBound]) }
        return String(after)
    }

    private static func m1(_ pattern: String, _ text: String) -> String? {
        guard let re = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = re.firstMatch(in: text, range: range), match.numberOfRanges > 1,
              let rr = Range(match.range(at: 1), in: text) else { return nil }
        let s = String(text[rr]).trimmingCharacters(in: .whitespaces)
        return s.isEmpty ? nil : s
    }

    private static func examples(_ wt: String) -> [String] {
        let lines = wt.components(separatedBy: "\n")
        guard let idx = lines.firstIndex(where: { $0.contains("{{Beispiele}}") }) else { return [] }
        var out: [String] = []
        var i = idx + 1
        while i < lines.count && out.count < 2 {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            if line.hasPrefix(":[") {
                let c = clean(line)
                if c.count >= 8 && c.count <= 85 { out.append(c) }
            } else if line.hasPrefix("{{") {
                break
            }
            i += 1
        }
        return out
    }

    private static func clean(_ s: String) -> String {
        var t = s
        t = t.replacingOccurrences(of: #"^:\[[0-9a-z, ]+\]\s*"#, with: "", options: .regularExpression)
        t = stripMarkup(t)
        for q in ["\u{201E}", "\u{201C}", "\u{201D}", "\u{201A}", "\u{2018}", "\u{2019}", "\u{00AB}", "\u{00BB}"] {
            t = t.replacingOccurrences(of: q, with: "")
        }
        return t.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // Wiki işaretlemesini ([[..]], {{..}}, '', <..>) çıkarır. Çoğul/örnek temizliğinde paylaşılır.
    static func stripMarkup(_ s: String) -> String {
        var t = s
        t = t.replacingOccurrences(of: #"\[\[[^\]|]*\|([^\]]*)\]\]"#, with: "$1", options: .regularExpression)
        t = t.replacingOccurrences(of: #"\[\[([^\]]*)\]\]"#, with: "$1", options: .regularExpression)
        t = t.replacingOccurrences(of: "''", with: "")
        t = t.replacingOccurrences(of: #"\{\{[^}]*\}\}"#, with: "", options: .regularExpression)
        t = t.replacingOccurrences(of: #"<[^>]+>"#, with: "", options: .regularExpression)
        return t.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
