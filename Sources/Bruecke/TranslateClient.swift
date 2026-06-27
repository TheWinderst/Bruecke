import Foundation

// Çeviri kaynağı soyutlaması.
//  • .google : Google'ın anahtarsız/halka açık çeviri ucu — en iyi Almanca→Türkçe
//              kalitesi ve "diğer anlamlar" alternatifleri. Varsayılan. (Resmî değildir;
//              Google ile bağlantılı değildir — README'deki nota bakınız.)
//  • .libre  : LibreTranslate — tamamen açık kaynak bir alternatif. Tek bir çeviri döner,
//              alternatif anlam vermez ve çalışan bir sunucu gerektirir.
enum TranslateEngineConfig {
    case google
    case libre(endpoint: String)
}

enum TranslateClient {
    private static let session: URLSession = {
        let c = URLSessionConfiguration.default
        c.timeoutIntervalForRequest = 10
        c.waitsForConnectivity = false
        return URLSession(configuration: c)
    }()

    // Ana çeviri + (varsa) alternatif anlamlar. failed=true → ağ/sunucu hatası (boş sonuçtan ayırt edilir).
    static func word(_ text: String, from sl: String = "de", to tl: String,
                     engine: TranslateEngineConfig,
                     completion: @escaping (_ main: String?, _ alternates: [String], _ failed: Bool) -> Void) {
        switch engine {
        case .google:
            googleWord(text, sl: sl, tl: tl, completion: completion)
        case .libre(let endpoint):
            libre(text, sl: sl, tl: tl, endpoint: endpoint) { main, failed in
                completion(main, [], failed)
            }
        }
    }

    // Tek yönlü düz çeviri (alternatifsiz) — İngilizce ve örnek cümleler için.
    static func simple(_ text: String, from sl: String = "de", to tl: String,
                       engine: TranslateEngineConfig,
                       completion: @escaping (_ result: String?, _ failed: Bool) -> Void) {
        switch engine {
        case .google:
            googleSimple(text, sl: sl, tl: tl, completion: completion)
        case .libre(let endpoint):
            libre(text, sl: sl, tl: tl, endpoint: endpoint, completion: completion)
        }
    }

    // MARK: - Google

    private static func googleWord(_ text: String, sl: String, tl: String,
                                   completion: @escaping (String?, [String], Bool) -> Void) {
        guard let url = googleURL(text, sl: sl, tl: tl, extra: "&dt=bd") else { completion(nil, [], true); return }
        session.dataTask(with: url) { data, response, error in
            if transportFailed(data, response, error) { completion(nil, [], true); return }
            var alts: [String] = []
            let main = joinedTranslation(from: data)
            if let data, let json = try? JSONSerialization.jsonObject(with: data) as? [Any],
               json.count > 1, let dict = json[1] as? [Any] {
                for grp in dict {
                    if let g = grp as? [Any], g.count > 1, let terms = g[1] as? [String] {
                        for term in terms where !alts.contains(term) { alts.append(term) }
                    }
                }
            }
            if let m = main { alts.removeAll { $0.caseInsensitiveCompare(m) == .orderedSame } }
            completion(main, Array(alts.prefix(4)), false)
        }.resume()
    }

    private static func googleSimple(_ text: String, sl: String, tl: String,
                                     completion: @escaping (String?, Bool) -> Void) {
        guard let url = googleURL(text, sl: sl, tl: tl, extra: "") else { completion(nil, true); return }
        session.dataTask(with: url) { data, response, error in
            if transportFailed(data, response, error) { completion(nil, true); return }
            completion(joinedTranslation(from: data), false)
        }.resume()
    }

    // Google yanıtının ana cümlesini çıkarır (iki yerde kopyalanmıştı — tek yere alındı).
    private static func joinedTranslation(from data: Data?) -> String? {
        guard let data, let json = try? JSONSerialization.jsonObject(with: data) as? [Any],
              let segments = json.first as? [Any] else { return nil }
        var parts: [String] = []
        for s in segments { if let a = s as? [Any], let t = a.first as? String { parts.append(t) } }
        let joined = parts.joined()
        return joined.isEmpty ? nil : joined
    }

    private static func googleURL(_ text: String, sl: String, tl: String, extra: String) -> URL? {
        guard let q = encode(text) else { return nil }
        return URL(string: "https://translate.googleapis.com/translate_a/single?client=gtx&sl=\(sl)&tl=\(tl)&dt=t\(extra)&q=\(q)")
    }

    // MARK: - LibreTranslate

    private static func libre(_ text: String, sl: String, tl: String, endpoint: String,
                              completion: @escaping (String?, Bool) -> Void) {
        let base = endpoint.trimmingCharacters(in: .whitespaces).hasSuffix("/")
            ? String(endpoint.dropLast()) : endpoint.trimmingCharacters(in: .whitespaces)
        guard let url = URL(string: base + "/translate") else { completion(nil, true); return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["q": text, "source": sl, "target": tl, "format": "text"]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        session.dataTask(with: req) { data, response, error in
            if transportFailed(data, response, error) { completion(nil, true); return }
            if let data, let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let t = obj["translatedText"] as? String, !t.isEmpty {
                completion(t, false)
            } else {
                completion(nil, true)
            }
        }.resume()
    }

    // MARK: - Ortak

    // Sorgu değeri için katı yüzde-kodlama (& ? + = gibi alt-ayraçları da kaçırır).
    static func encode(_ text: String) -> String? {
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        return text.addingPercentEncoding(withAllowedCharacters: allowed)
    }

    private static func transportFailed(_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Bool {
        if error != nil { return true }
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            alog("translate http \(http.statusCode) host=\(http.url?.host ?? "?")")
            return true
        }
        return data == nil
    }
}
