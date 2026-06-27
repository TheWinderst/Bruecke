import Foundation

enum SynonymClient {
    private static let session: URLSession = {
        let c = URLSessionConfiguration.default
        c.timeoutIntervalForRequest = 10
        return URLSession(configuration: c)
    }()

    static func synonyms(_ word: String, completion: @escaping ([String]) -> Void) {
        guard let q = TranslateClient.encode(word),
              let url = URL(string: "https://www.openthesaurus.de/synonyme/search?q=\(q)&format=application/json") else {
            completion([]); return
        }
        session.dataTask(with: url) { data, _, _ in
            var out: [String] = []
            if let data,
               let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let synsets = obj["synsets"] as? [[String: Any]] {
                for synset in synsets {
                    if let terms = synset["terms"] as? [[String: Any]] {
                        for t in terms {
                            guard let raw = t["term"] as? String else { continue }
                            let term = raw.trimmingCharacters(in: .whitespaces)
                            if term.lowercased() != word.lowercased(),
                               !term.contains("..."), term.count <= 22, !out.contains(term) {
                                out.append(term)
                            }
                        }
                    }
                    if out.count >= 4 { break }
                }
            }
            completion(Array(out.prefix(4)))
        }.resume()
    }
}
