import Foundation

// Arama geçmişi + çevrimdışı önbellek — tek depo, iki iş:
// 1) "Son aramalar" listesi (arama kutusunda tıklanabilir).
// 2) Daha önce bakılan kelime tekrar sorulunca ağa çıkmadan anında açılır;
//    internet yokken de çalışır.
// Ayarlardan "geçmişi tut" kapatılırsa ikisi birden durur ve depo boşaltılır.

struct HistoryItem: Codable {
    let key: String        // normalize edilmiş arama anahtarı (küçük harf)
    let entry: WordEntry
    let date: Date
}

@MainActor
final class HistoryStore: ObservableObject {
    static let shared = HistoryStore()

    @Published private(set) var items: [HistoryItem] = []   // en yeni başta
    private let storageKey = "lookupHistory"
    private let capacity = 200

    init() { load() }

    static func normalize(_ term: String) -> String {
        term.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    // Önbellekten getir (geçmiş kapalıysa hiç bakma).
    func cached(_ term: String) -> WordEntry? {
        guard AppSettings.shared.keepHistory else { return nil }
        let key = Self.normalize(term)
        return items.first { $0.key == key }?.entry
    }

    // Başarılı bir aramayı kaydet; aynı kelime tekrar aranırsa öne taşınır.
    func record(term: String, entry: WordEntry) {
        guard AppSettings.shared.keepHistory else { return }
        // Hatalı/boş sonuçları saklama — önbellek bozuk veri sunmasın.
        guard entry.errorMessage == nil, entry.translation != "—", !entry.translation.isEmpty else { return }
        let key = Self.normalize(term)
        guard !key.isEmpty else { return }
        items.removeAll { $0.key == key }
        items.insert(HistoryItem(key: key, entry: entry, date: Date()), at: 0)
        if items.count > capacity { items.removeLast(items.count - capacity) }
        save()
    }

    func recent(_ limit: Int) -> [WordEntry] {
        // Aynı kart iki anahtarla saklanmış olabilir (Türkçe sorgu + Almanca
        // kelime); listede bir kez görünsün.
        var seen = Set<String>()
        var out: [WordEntry] = []
        for item in items {
            guard seen.insert(item.entry.id).inserted else { continue }
            out.append(item.entry)
            if out.count == limit { break }
        }
        return out
    }

    func clear() {
        items = []
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([HistoryItem].self, from: data) else { return }
        items = decoded
    }

    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
