import Foundation

@MainActor
final class SavedStore: ObservableObject {
    static let shared = SavedStore()

    @Published private(set) var entries: [WordEntry] = []
    private let key = "savedEntries"

    init() { load() }

    func isSaved(_ entry: WordEntry) -> Bool {
        entries.contains { $0.id == entry.id }
    }

    func toggle(_ entry: WordEntry) {
        if let idx = entries.firstIndex(where: { $0.id == entry.id }) {
            entries.remove(at: idx)
        } else {
            entries.insert(entry, at: 0)
        }
        save()
    }

    func remove(_ entry: WordEntry) {
        entries.removeAll { $0.id == entry.id }
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([WordEntry].self, from: data) else { return }
        entries = decoded
    }

    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
