import SwiftUI

// Kayıtlı kelimelerden çevir-kapat tekrar kartları. Kart önce Almanca yüzü
// gösterir; tıklayınca (ya da boşluk tuşuyla) dönüp Türkçesini açar.
// "Bildim" kartı turdan çıkarır, "Tekrar" tura geri koyar — hepsi bilinince
// özet ekranı gelir. Amaç: pasif sözlüğü gerçek bir öğrenme döngüsüne çevirmek.
struct FlashcardView: View {
    let entries: [WordEntry]
    let speaker: Speaker
    let onDone: () -> Void

    @State private var deck: [WordEntry] = []
    @State private var flipped = false
    @State private var knownCount = 0
    @State private var againCount = 0

    private var total: Int { knownCount + deck.count }
    private let cGreen = Color(red: 40/255, green: 200/255, blue: 100/255)
    private let cOrange = Color(red: 235/255, green: 160/255, blue: 30/255)

    var body: some View {
        Group {
            if entries.isEmpty {
                emptyBody
            } else if let current = deck.first {
                practiceBody(current)
            } else {
                summaryBody
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear(perform: startRound)
    }

    private func startRound() {
        deck = entries.shuffled()
        flipped = false
        knownCount = 0
        againCount = 0
    }

    // MARK: - Çalışma ekranı

    private func practiceBody(_ current: WordEntry) -> some View {
        VStack(spacing: 14) {
            HStack {
                Text("\(knownCount) / \(total)")
                    .font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
                    .monospacedDigit()
                Spacer()
                if againCount > 0 {
                    Text("tekrar: \(againCount)")
                        .font(.system(size: 11)).foregroundStyle(cOrange)
                }
            }

            ProgressView(value: Double(knownCount), total: Double(max(total, 1)))
                .progressViewStyle(.linear)
                .tint(cGreen)

            Spacer(minLength: 4)

            card(current)

            Spacer(minLength: 4)

            if flipped {
                HStack(spacing: 10) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { markAgain() }
                    } label: {
                        Label("Tekrar", systemImage: "arrow.counterclockwise")
                            .font(.system(size: 13, weight: .semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .controlSize(.large)
                    .modifier(GlassBtn())
                    .tint(cOrange)

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { markKnown() }
                    } label: {
                        Label("Bildim", systemImage: "checkmark")
                            .font(.system(size: 13, weight: .semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .controlSize(.large)
                    .modifier(GlassProminentBtn())
                    .tint(cGreen)
                    .keyboardShortcut(.return, modifiers: [])
                }
            } else {
                Button {
                    flip()
                } label: {
                    Text("Kartı çevir")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.large)
                .modifier(GlassBtn())
                .keyboardShortcut(.return, modifiers: [])
            }
        }
        .padding(16)
    }

    private func card(_ entry: WordEntry) -> some View {
        ZStack {
            cardFace(front: true, entry: entry)
                .opacity(flipped ? 0 : 1)
                .rotation3DEffect(.degrees(flipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            cardFace(front: false, entry: entry)
                .opacity(flipped ? 1 : 0)
                .rotation3DEffect(.degrees(flipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 210)
        .contentShape(RoundedRectangle(cornerRadius: 18))
        .onTapGesture { if !flipped { flip() } }
        .animation(.spring(duration: 0.4, bounce: 0.25), value: flipped)
    }

    private func cardFace(front: Bool, entry: WordEntry) -> some View {
        VStack(spacing: 10) {
            if front {
                if let t = tag(entry) {
                    Text(t.text)
                        .font(.system(size: 11, weight: .semibold)).foregroundStyle(t.color)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(t.color.opacity(0.16), in: RoundedRectangle(cornerRadius: 6))
                }
                Text(entry.displayHeadword)
                    .font(.system(size: 26, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.6)
                Button {
                    speaker.speak(entry.displayHeadword)
                } label: {
                    Image(systemName: "speaker.wave.2")
                        .font(.system(size: 14)).foregroundStyle(.secondary)
                        .frame(width: 30, height: 30).contentShape(Circle())
                }
                .buttonStyle(.plain).help("Seslendir")
                Text("çevirmek için tıkla")
                    .font(.system(size: 11)).foregroundStyle(.tertiary)
            } else {
                Text(entry.translation)
                    .font(.system(size: 24, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.6)
                if entry.kind == .verb, let p = entry.praeteritum {
                    Text("\(entry.lemma) → \(p)\(entry.perfekt.map { " → \($0)" } ?? "")")
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                } else if let plural = entry.plural {
                    Text("çoğul: \(plural)")
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                }
                if let ex = entry.examples.first {
                    VStack(spacing: 2) {
                        Text(ex.de).font(.system(size: 12.5, design: .serif))
                        Text(ex.tr).font(.system(size: 11)).foregroundStyle(.secondary)
                    }
                    .multilineTextAlignment(.center)
                    .padding(.top, 2)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.quaternary.opacity(0.6), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private func flip() {
        flipped = true
    }

    private func markKnown() {
        guard !deck.isEmpty else { return }
        deck.removeFirst()
        knownCount += 1
        flipped = false
    }

    private func markAgain() {
        guard !deck.isEmpty else { return }
        let card = deck.removeFirst()
        deck.append(card)
        againCount += 1
        flipped = false
    }

    // MARK: - Boş durum (menüden tekrar açıldı ama kayıtlı kelime yok)

    private var emptyBody: some View {
        VStack(spacing: 10) {
            Image(systemName: "rectangle.on.rectangle.angled")
                .font(.system(size: 32)).foregroundStyle(.tertiary)
            Text("Tekrar için kayıtlı kelime gerek").font(.system(size: 14, weight: .medium))
            Text("Bir kelime kartında ⭐ simgesine basarak kelime biriktir, sonra buradan çalış.")
                .font(.system(size: 12)).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(28)
    }

    // MARK: - Özet ekranı

    private var summaryBody: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 40)).foregroundStyle(cGreen)
            Text("Tur bitti!").font(.system(size: 17, weight: .semibold))
            Text(againCount == 0
                 ? "\(knownCount) kelimenin hepsini ilk seferde bildin."
                 : "\(knownCount) kelime · \(againCount) kez tekrar gerekti.")
                .font(.system(size: 12.5)).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 10) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { startRound() }
                } label: {
                    Label("Yeni tur", systemImage: "arrow.clockwise")
                }
                .controlSize(.large)
                .modifier(GlassProminentBtn())
                .tint(.blue)

                Button("Listeye dön", action: onDone)
                    .controlSize(.large)
                    .modifier(GlassBtn())
            }
            .padding(.top, 6)
        }
        .padding(24)
    }

    private func tag(_ entry: WordEntry) -> (text: String, color: Color)? {
        let cBlue = Color(red: 10/255, green: 132/255, blue: 1)
        let cPink = Color(red: 255/255, green: 55/255, blue: 95/255)
        let cGreenTag = Color(red: 40/255, green: 200/255, blue: 100/255)
        let cPurple = Color(red: 150/255, green: 95/255, blue: 230/255)
        let cTeal = Color(red: 40/255, green: 170/255, blue: 190/255)
        switch entry.kind {
        case .noun:
            // Artikel zaten başlıkta ("der Apfel") — rozet türü söyler, rengi artikelden alır.
            switch entry.gender {
            case .der: return ("isim", cBlue)
            case .die: return ("isim", cPink)
            case .das: return ("isim", cGreenTag)
            case .none: return ("isim", cBlue)
            }
        case .verb: return ("fiil", cPurple)
        case .adjective: return ("sıfat", cTeal)
        case .phrase: return ("cümle", .secondary)
        case .other: return entry.posLabel.isEmpty ? nil : (entry.posLabel, .secondary)
        }
    }
}
