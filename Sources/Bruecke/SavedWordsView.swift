import SwiftUI

struct SavedWordsView: View {
    @ObservedObject var store = SavedStore.shared
    var onSelect: (WordEntry) -> Void

    var body: some View {
        Group {
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
                            Button("Sil", role: .destructive) { store.remove(entry) }
                        }
                    }
                    .onDelete { offsets in
                        offsets.map { store.entries[$0] }.forEach { store.remove($0) }
                    }
                }
            }
        }
        .frame(minWidth: 320, minHeight: 360)
    }
}
