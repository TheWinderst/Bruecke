import SwiftUI
import AppKit

// Kelime seçmeden, doğrudan yazıp çevirmek için küçük arama kutusu.
// Menü çubuğundan ("Kelime yaz ve çevir…") ya da hiçbir şey seçili değilken
// ⌘⇧D'ye basınca açılır. Kartla aynı cam yüzeyi ve native tipografiyi kullanır.
struct DictionarySearchView: View {
    let onSubmit: (String, LookupDirection) -> Void

    @State private var text = ""
    @State private var loading = false
    // Arama yönü; son seçim hatırlanır. Yazıda Türkçe/Almanca harf ipucu varsa
    // DictionaryService yönü kendisi düzeltir, düğme yanlış kalsa bile sonuç doğrudur.
    @State private var reversed = AppSettings.shared.searchReversed
    @FocusState private var focused: Bool

    // Panel boyutu açılışta bir kez ölçülür; liste o yüzden açılış anındaki
    // geçmişle sabitlenir (panel ömrü boyunca değişmez, yerleşim kaymaz).
    private let recents: [WordEntry] = AppSettings.shared.keepHistory
        ? HistoryStore.shared.recent(5) : []

    private let cBlue = Color(red: 10/255, green: 132/255, blue: 1)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 9) {
                Image(systemName: "character.book.closed")
                    .font(.system(size: 15, weight: .semibold)).foregroundStyle(cBlue)
                Text("Kelime çevir").font(.system(size: 15, weight: .semibold)).foregroundStyle(.primary)
                Spacer(minLength: 0)
                Picker("Yön", selection: $reversed) {
                    Text("DE → TR").tag(false)
                    Text("TR → DE").tag(true)
                }
                .pickerStyle(.segmented)
                .controlSize(.small)
                .fixedSize()
                .labelsHidden()
                .disabled(loading)
                .onChange(of: reversed) { _, v in AppSettings.shared.searchReversed = v }
            }

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").font(.system(size: 14)).foregroundStyle(.secondary)
                TextField(reversed ? "Türkçe kelime…" : "Almanca kelime ya da cümle…", text: $text)
                    .textFieldStyle(.plain)
                    .font(.system(size: 17))
                    .focused($focused)
                    .disabled(loading)
                    .onSubmit(submit)
                if loading {
                    ProgressView().controlSize(.small)
                } else if !text.isEmpty {
                    Button { text = "" } label: {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 14)).foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain).help("Temizle")
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))

            if !recents.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Son aramalar").font(.system(size: 11)).foregroundStyle(.tertiary)
                        .padding(.top, 2)
                    ForEach(recents, id: \.id) { entry in
                        Button {
                            guard !loading else { return }
                            loading = true
                            // Geçmişteki kelime her zaman Almanca lemma ile durur.
                            onSubmit(entry.lemma, .deToTr)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 11)).foregroundStyle(.tertiary)
                                Text(entry.displayHeadword)
                                    .font(.system(size: 13, weight: .medium)).foregroundStyle(.primary)
                                    .lineLimit(1)
                                Text(entry.translation)
                                    .font(.system(size: 12)).foregroundStyle(.secondary)
                                    .lineLimit(1)
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 8).padding(.vertical, 5)
                            .contentShape(RoundedRectangle(cornerRadius: 7))
                        }
                        .buttonStyle(RecentRowStyle())
                    }
                }
            }

            HStack(spacing: 8) {
                Text("Enter ile çevir · Esc ile kapat").font(.system(size: 11)).foregroundStyle(.tertiary)
                Spacer(minLength: 0)
                Button(action: submit) {
                    Text(loading ? "Çeviriliyor…" : "Çevir")
                        .font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background(canSubmit ? cBlue : Color.secondary.opacity(0.4), in: Capsule())
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain).disabled(!canSubmit)
            }
        }
        .padding(16)
        .frame(width: 340, alignment: .leading)
        .modifier(GlassCardBG())
        // Panel anahtar olduğunda alanı otomatik odakla (asyncAfter: hosting yerleşsin).
        .onAppear { DispatchQueue.main.async { focused = true } }
    }

    private var canSubmit: Bool {
        !loading && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func submit() {
        let term = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty, !loading else { return }
        loading = true          // sonuç kartı gelene kadar dönen gösterge
        onSubmit(term, reversed ? .trToDe : .deToTr)
    }
}

// Son arama satırı: üzerine gelince hafifçe belirginleşir.
private struct RecentRowStyle: ButtonStyle {
    @State private var hovering = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(Color.primary.opacity(configuration.isPressed ? 0.12 : (hovering ? 0.06 : 0)))
            )
            .onHover { hovering = $0 }
    }
}

// Kısayola basılır basılmaz beliren küçük "çevriliyor" kartı.
// Sonuç gelince aynı noktada asıl kartla değiştirilir.
struct LoadingCardView: View {
    let term: String

    var body: some View {
        HStack(spacing: 12) {
            ProgressView().controlSize(.small)
            VStack(alignment: .leading, spacing: 2) {
                Text(term)
                    .font(.system(size: 16, weight: .semibold)).foregroundStyle(.primary)
                    .lineLimit(1)
                Text("Çevriliyor…")
                    .font(.system(size: 12)).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .frame(width: 260, alignment: .leading)
        .modifier(GlassCardBG())
    }
}
