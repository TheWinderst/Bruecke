import SwiftUI
import AppKit

// Kelime seçmeden, doğrudan yazıp çevirmek için küçük arama kutusu.
// Menü çubuğundan ("Kelime yaz ve çevir…") ya da hiçbir şey seçili değilken
// ⌘⇧D'ye basınca açılır. Kartla aynı cam yüzeyi ve native tipografiyi kullanır.
struct DictionarySearchView: View {
    let onSubmit: (String) -> Void

    @State private var text = ""
    @State private var loading = false
    @FocusState private var focused: Bool

    private let cBlue = Color(red: 10/255, green: 132/255, blue: 1)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 9) {
                Image(systemName: "character.book.closed")
                    .font(.system(size: 15, weight: .semibold)).foregroundStyle(cBlue)
                Text("Kelime çevir").font(.system(size: 15, weight: .semibold)).foregroundStyle(.primary)
                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").font(.system(size: 14)).foregroundStyle(.secondary)
                TextField("Almanca kelime ya da cümle…", text: $text)
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
        onSubmit(term)
    }
}
