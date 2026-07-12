import SwiftUI
import AppKit
import UniformTypeIdentifiers

// Kelimelerim penceresinin hangi yüzü açık: liste mi, tekrar (flashcard) mı.
// Menüden "Kelime tekrarı…" seçilince pencere doğrudan tekrar modunda açılsın
// diye durum paylaşılan bir nesnede tutulur.
enum SavedViewMode {
    case list, review
}

@MainActor
final class SavedViewState: ObservableObject {
    static let shared = SavedViewState()
    @Published var mode: SavedViewMode = .list
}

struct SavedWordsView: View {
    let speaker: Speaker
    var onSelect: (WordEntry) -> Void

    @ObservedObject var store = SavedStore.shared
    @ObservedObject private var state = SavedViewState.shared

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            switch state.mode {
            case .list:
                listContent
            case .review:
                FlashcardView(entries: store.entries, speaker: speaker) {
                    state.mode = .list
                }
            }
        }
        .frame(minWidth: 360, minHeight: 420)
        .animation(.easeInOut(duration: 0.18), value: state.mode == .review)
    }

    private var header: some View {
        HStack(spacing: 10) {
            if state.mode == .review {
                Button {
                    state.mode = .list
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary)
                        .frame(width: 26, height: 26)
                        .background(.quaternary, in: Circle())
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Listeye dön")
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(state.mode == .review ? "Kelime tekrarı" : "Kayıtlı kelimeler")
                    .font(.system(size: 14, weight: .semibold))
                Text("\(store.entries.count) kelime")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)

            if state.mode == .list {
                Button(action: exportCSV) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 13))
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("CSV olarak dışa aktar (Anki'ye uygun)")
                .disabled(store.entries.isEmpty)

                Button {
                    state.mode = .review
                } label: {
                    Label("Tekrar et", systemImage: "rectangle.on.rectangle.angled")
                        .font(.system(size: 12, weight: .semibold))
                }
                .controlSize(.regular)
                .modifier(GlassProminentBtn())
                .tint(.blue)
                .disabled(store.entries.count < 2)
                .help(store.entries.count < 2 ? "Tekrar için en az 2 kayıtlı kelime gerekir" : "Kartlarla tekrar çalış")
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
    }

    @ViewBuilder
    private var listContent: some View {
        if store.entries.isEmpty {
            VStack(spacing: 10) {
                Image(systemName: "star").font(.system(size: 34)).foregroundStyle(.tertiary)
                Text("Henüz kayıtlı kelime yok").font(.system(size: 15, weight: .medium))
                Text("Bir kelime kartında ⭐ simgesine basarak kaydet.")
                    .font(.system(size: 12)).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(30)
        } else {
            List {
                ForEach(store.entries) { entry in
                    Button { onSelect(entry) } label: {
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.displayHeadword).font(.system(size: 14, weight: .medium))
                                Text(entry.translation).font(.system(size: 12)).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.system(size: 11)).foregroundStyle(.tertiary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Seslendir") { speaker.speak(entry.displayHeadword) }
                        Button("Sil", role: .destructive) { store.remove(entry) }
                    }
                }
                .onDelete { offsets in
                    offsets.map { store.entries[$0] }.forEach { store.remove($0) }
                }
            }
        }
    }

    // Kayıtlı kelimeleri CSV'ye yazar. Sütunlar Anki içe aktarmasıyla uyumlu:
    // ilk iki sütun ön/arka yüz olur, gerisi ek alan.
    private func exportCSV() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "bruecke-kelimeler.csv"
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.title = "Kelimeleri dışa aktar"
        NSApp.activate(ignoringOtherApps: true)
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            let entries = SavedStore.shared.entries
            var lines = ["Almanca,Türkçe,Tür,Çoğul,Örnek (DE),Örnek (TR)"]
            for e in entries {
                let ex = e.examples.first
                lines.append([
                    e.displayHeadword, e.translation, e.posLabel,
                    e.plural ?? "", ex?.de ?? "", ex?.tr ?? ""
                ].map(csvField).joined(separator: ","))
            }
            try? lines.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
        }
    }

    private func csvField(_ s: String) -> String {
        if s.contains(",") || s.contains("\"") || s.contains("\n") {
            return "\"" + s.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return s
    }
}
