import Foundation

enum TatoebaClient {
    private static let session: URLSession = {
        let c = URLSessionConfiguration.default
        c.timeoutIntervalForRequest = 10
        return URLSession(configuration: c)
    }()

    static func examples(_ word: String, completion: @escaping ([Example]) -> Void) {
        guard let q = TranslateClient.encode(word),
              let url = URL(string: "https://tatoeba.org/en/api_v0/search?from=deu&to=tur&query=\(q)&sort=relevance") else {
            completion([]); return
        }
        session.dataTask(with: url) { data, _, _ in
            var out: [Example] = []
            if let data,
               let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let results = obj["results"] as? [[String: Any]] {
                for r in results {
                    guard let de = r["text"] as? String, de.count <= 95 else { continue }
                    var tr: String?
                    if let groups = r["translations"] as? [[[String: Any]]] {
                        search: for grp in groups {
                            for t in grp {
                                if (t["lang"] as? String) == "tur", let txt = t["text"] as? String, !txt.isEmpty {
                                    tr = txt; break search
                                }
                            }
                        }
                    }
                    if let tr {
                        out.append(Example(de: de, tr: tr))
                        if out.count >= 2 { break }
                    }
                }
            }
            completion(out)
        }.resume()
    }
}
