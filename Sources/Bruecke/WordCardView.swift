import SwiftUI
import AVFoundation
import AppKit

struct WordCardView: View {
    let entry: WordEntry
    let speaker: Speaker

    @StateObject private var coach = PronunciationCoach()
    @ObservedObject private var saved = SavedStore.shared
    @ObservedObject private var settings = AppSettings.shared
    @State private var copied = false

    private let cBlue = Color(red: 10/255, green: 132/255, blue: 1)
    private let cPink = Color(red: 255/255, green: 55/255, blue: 95/255)
    private let cGreen = Color(red: 40/255, green: 200/255, blue: 100/255)
    private let cPurple = Color(red: 150/255, green: 95/255, blue: 230/255)
    private let cTeal = Color(red: 40/255, green: 170/255, blue: 190/255)

    var body: some View {
        Group {
            if coach.isActive {
                // Üst üste bindirme YOK: pratik ekranı kartın yerine geçer ve kartın
                // kendi cam yüzeyini kullanır → arkadan kelime sızmaz, her iki modda temiz.
                PracticeView(coach: coach, target: entry.lemma, accent: cBlue)
                    .transition(.opacity)
            } else {
                content
                    .transition(.opacity)
            }
        }
        .frame(width: 380, alignment: .leading)
        .modifier(GlassCardBG())
        .animation(.easeInOut(duration: 0.22), value: coach.isActive)
        // Kart kapatılırsa (popover dışına tıklama vb.) ses motoru/tanıma görevi sızmasın.
        .onDisappear { coach.reset() }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            if entry.kind != .phrase, !metaLine.isEmpty {
                Text(metaLine).font(.system(size: 13)).foregroundStyle(.secondary).padding(.top, 6)
            }

            if entry.kind == .verb { verbForms.padding(.top, 12) }

            translationBox.padding(.top, 14)

            if let p = entry.pattern { patternBox(p).padding(.top, 12) }

            if settings.showEnglish, let en = entry.english, !en.isEmpty {
                detailLine("İngilizce", en)
            }
            if settings.showAlternates, let alts = entry.alternates, !alts.isEmpty {
                detailLine("Diğer anlamlar", alts.joined(separator: " · "))
            }
            if settings.showSynonyms, let syn = entry.synonyms, !syn.isEmpty {
                detailLine("Eş anlamlı (DE)", syn.joined(separator: " · "))
            }

            if !entry.examples.isEmpty {
                Text("Örnek cümleler").font(.system(size: 12)).foregroundStyle(.secondary).padding(.top, 16)
                VStack(spacing: 8) {
                    ForEach(entry.examples, id: \.self) { exampleRow($0) }
                }
                .padding(.top, 8)
            }

            footer.padding(.top, 16)
        }
        .padding(18)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            if let tag {
                Text(tag.text)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(tag.color)
                    .padding(.horizontal, 9).padding(.vertical, 3)
                    .background(tag.color.opacity(0.18), in: RoundedRectangle(cornerRadius: 6))
            }
            headwordText
                .font(.system(size: headwordSize, weight: .semibold))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            speakerButton
        }
    }

    private var speakerButton: some View {
        Menu {
            ForEach(speaker.germanVoices(), id: \.identifier) { v in
                Button(v.name) { speaker.speak(entry.displayHeadword, voiceIdentifier: v.identifier) }
            }
            if !speaker.germanVoices().isEmpty { Divider() }
            Button("Yavaş oku") { speaker.speakSlow(entry.displayHeadword) }
            Button("Hece hece") { speaker.speakSyllables(entry.displayHeadword) }
        } label: {
            Image(systemName: "speaker.wave.2").font(.system(size: 16)).foregroundStyle(.secondary)
        } primaryAction: {
            speaker.speak(entry.displayHeadword)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
    }

    private var verbForms: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Fiil çekimi").font(.system(size: 11)).foregroundStyle(.tertiary)
            HStack(alignment: .top, spacing: 6) {
                labeledChip(entry.lemma, "mastar")
                if let p = entry.praeteritum { chipArrow; labeledChip(p, "Präteritum") }
                if let pf = entry.perfekt { chipArrow; labeledChip(pf, "Perfekt") }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func labeledChip(_ text: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(text)
                .font(.system(size: 13, weight: .medium)).foregroundStyle(.primary)
                .padding(.horizontal, 9).padding(.vertical, 4)
                .background(.quaternary, in: Capsule())
            Text(label).font(.system(size: 10)).foregroundStyle(.tertiary)
        }
    }

    private var chipArrow: some View {
        VStack(spacing: 4) {
            Image(systemName: "arrow.right").font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.tertiary).frame(height: 25)
            Text(" ").font(.system(size: 10)).opacity(0)
        }
    }

    private var translationBox: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Türkçe").font(.system(size: 12)).foregroundStyle(.secondary)
            Text(entry.translation)
                .font(.system(size: 22, weight: .semibold)).foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
            if let err = entry.errorMessage {
                Label(err, systemImage: "wifi.exclamationmark")
                    .font(.system(size: 12)).foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
    }

    // Edat kalıbı kutusu: solda belirgin dolu hâl rozeti (+A / +D), yanında
    // "edat + hâl" ve Türkçe karşılığı, altında ince ayraçla ipucu.
    // Akkusativ mavi, Dativ pembe ile renklenir.
    private func patternBox(_ p: VerbPattern) -> some View {
        let c = p.kasus == .akkusativ ? cBlue : cPink
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Text(p.kasus.short)
                    .font(.system(size: 17, weight: .bold)).foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(c, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    (Text(p.preposition).foregroundStyle(c).fontWeight(.semibold)
                        + Text("  +  ").foregroundStyle(.tertiary)
                        + Text(p.kasus.name).foregroundStyle(.primary).fontWeight(.medium))
                        .font(.system(size: 16))
                    Text("Türkçede ≈ \(p.kasus.trHint)")
                        .font(.system(size: 11.5)).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }

            Rectangle().fill(c.opacity(0.16)).frame(height: 1).padding(.vertical, 11)

            HStack(alignment: .top, spacing: 7) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 11)).foregroundStyle(c).padding(.top, 1)
                Text(p.tip).font(.system(size: 12.5)).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(c.opacity(0.07), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(c.opacity(0.22), lineWidth: 0.8))
    }

    private func detailLine(_ label: String, _ value: String) -> some View {
        (Text(label + " · ").foregroundStyle(.tertiary) + Text(value).foregroundStyle(.secondary))
            .font(.system(size: 12))
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 6)
    }

    private func exampleRow(_ example: Example) -> some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                Text(example.de).font(.system(size: 15.5, design: .serif)).foregroundStyle(.primary)
                Text(example.tr).font(.system(size: 13)).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Button { speaker.speak(example.de) } label: {
                Image(systemName: "speaker.wave.2").font(.system(size: 13)).foregroundStyle(.secondary)
            }
            .buttonStyle(.plain).help("Cümleyi seslendir")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 9))
    }

    private var footer: some View {
        HStack(spacing: 12) {
            // Belirgin, opak birincil düğme (cam stili her iki modda da silik kalıyordu).
            Button { coach.start(target: entry.lemma) } label: {
                Label("Telaffuzu dene", systemImage: "mic")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16).padding(.vertical, 9)
                    .background(cBlue, in: Capsule())
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .help("Telaffuzunu söyleyip puan al")

            Spacer(minLength: 0)

            Button(action: copyTranslation) {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 15)).foregroundStyle(copied ? Color.green : Color.secondary)
                    .frame(width: 34, height: 34).contentShape(Rectangle())
            }
            .buttonStyle(.plain).help("Çeviriyi kopyala")

            Button { saved.toggle(entry) } label: {
                Image(systemName: saved.isSaved(entry) ? "star.fill" : "star")
                    .font(.system(size: 15)).foregroundStyle(saved.isSaved(entry) ? Color.yellow : Color.secondary)
                    .frame(width: 34, height: 34).contentShape(Rectangle())
            }
            .buttonStyle(.plain).help(saved.isSaved(entry) ? "Kaydedildi — kaldır" : "Kaydet")
        }
    }

    private func copyTranslation() {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(entry.translation, forType: .string)
        copied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { copied = false }
    }

    private var headwordSize: CGFloat {
        if entry.pattern != nil { return 22 }
        return entry.kind == .phrase ? 18 : 29
    }

    // Edat kalıbında, başlığın sonundaki edatı kendi (hâl) renginde vurgular:
    // "sich beschweren über" → "über" mavi (Akkusativ) ya da pembe (Dativ).
    private var headwordText: Text {
        guard let p = entry.pattern, entry.lemma.hasSuffix(" \(p.preposition)") else {
            return Text(entry.lemma).foregroundStyle(.primary)
        }
        let c = p.kasus == .akkusativ ? cBlue : cPink
        let stem = String(entry.lemma.dropLast(p.preposition.count))
        return Text(stem).foregroundStyle(.primary) + Text(p.preposition).foregroundStyle(c).fontWeight(.bold)
    }

    private var tag: (text: String, color: Color)? {
        switch entry.kind {
        case .noun:
            if entry.gender == .none { return ("isim", cBlue) }
            return (entry.gender.rawValue, genderColor)
        case .verb: return ("fiil", cPurple)
        case .adjective: return ("sıfat", cTeal)
        case .phrase: return ("cümle", .secondary)
        case .other: return entry.posLabel.isEmpty ? nil : (entry.posLabel, .secondary)
        }
    }

    private var genderColor: Color {
        switch entry.gender {
        case .der: return cBlue
        case .die: return cPink
        case .das: return cGreen
        case .none: return cBlue
        }
    }

    private var metaLine: String {
        var parts: [String] = []
        if !entry.posLabel.isEmpty { parts.append(entry.posLabel) }
        if entry.kind == .noun, let plural = entry.plural { parts.append("çoğul: \(plural)") }
        return parts.joined(separator: " · ")
    }
}

// MARK: - Liquid Glass wrappers (native macOS 26, with fallback)

struct GlassCardBG: ViewModifier {
    @ViewBuilder func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        } else {
            content.background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
    }
}

struct GlassProminentBtn: ViewModifier {
    @ViewBuilder func body(content: Content) -> some View {
        if #available(macOS 26.0, *) { content.buttonStyle(.glassProminent) }
        else { content.buttonStyle(.borderedProminent) }
    }
}

struct GlassBtn: ViewModifier {
    @ViewBuilder func body(content: Content) -> some View {
        if #available(macOS 26.0, *) { content.buttonStyle(.glass) }
        else { content.buttonStyle(.bordered) }
    }
}

// MARK: - Pronunciation practice (native, opaque, centered)

struct PracticeView: View {
    @ObservedObject var coach: PronunciationCoach
    let target: String
    let accent: Color

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { coach.reset() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 30, height: 30)
                        .background(.quaternary, in: Circle())
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Geri")
                Spacer()
            }

            Spacer(minLength: 8)

            switch coach.phase {
            case .listening:
                ListeningContent(level: coach.level, target: target, accent: accent)
            case .result(let score, let heard):
                ResultContent(coach: coach, target: target, score: score, heard: heard)
            case .idle:
                EmptyView()
            }

            Spacer(minLength: 8)
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ListeningContent: View {
    var level: CGFloat
    let target: String
    let accent: Color
    @State private var pulse = false
    @State private var progress: CGFloat = 1

    var body: some View {
        VStack(spacing: 16) {
            SiriWave(level: level, color: accent).frame(height: 52).padding(.horizontal, 26)

            HStack(spacing: 7) {
                Circle().fill(.red).frame(width: 8, height: 8).opacity(pulse ? 0.35 : 1)
                Text("Şimdi söyle").font(.system(size: 13, weight: .medium)).foregroundStyle(.primary)
            }
            Text(target).font(.system(size: 23, weight: .semibold)).foregroundStyle(.primary)

            // 4 saniyelik dinleme penceresini gösteren ince çubuk.
            Capsule().fill(.quaternary)
                .frame(width: 120, height: 4)
                .overlay(alignment: .leading) {
                    Capsule().fill(accent.opacity(0.8)).frame(width: 120 * progress, height: 4)
                }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) { pulse = true }
            withAnimation(.linear(duration: 4.0)) { progress = 0 }
        }
    }
}

struct SiriWave: View {
    var level: CGFloat
    var color: Color

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let mid = size.height / 2
                // Sessizken bile nazik bir taban dalgalanması olsun — "dinliyorum" hissi.
                let base = size.height * 0.13
                let amp = max(base, level * size.height * 0.42)
                let layers: [(freq: Double, speed: Double, op: Double, lw: Double)] = [
                    (1.4, 1.9, 0.95, 2.6), (2.2, -1.4, 0.55, 2.0), (3.0, 1.1, 0.3, 1.5)
                ]
                for layer in layers {
                    var path = Path()
                    var x: CGFloat = 0
                    while x <= size.width {
                        let rel = Double(x / size.width)
                        let env = sin(rel * .pi)
                        let y = mid + CGFloat(sin(rel * .pi * 2 * layer.freq + t * layer.speed) * env) * amp
                        if x == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
                        x += 2
                    }
                    ctx.stroke(path, with: .color(color.opacity(layer.op)), lineWidth: layer.lw)
                }
            }
        }
    }
}

struct ResultContent: View {
    @ObservedObject var coach: PronunciationCoach
    let target: String
    let score: Int
    let heard: String
    @State private var progress: CGFloat = 0

    private var color: Color {
        if score >= 60 { return Color(red: 40/255, green: 200/255, blue: 100/255) }
        if score >= 40 { return Color(red: 235/255, green: 160/255, blue: 30/255) }
        return Color(red: 235/255, green: 80/255, blue: 80/255)
    }
    private var message: String {
        if score >= 80 { return "Harika!" }
        if score >= 60 { return "İyi gidiyor!" }
        if score >= 40 { return "Fena değil, bir daha?" }
        return "Tekrar deneyelim"
    }

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle().stroke(color.opacity(0.16), lineWidth: 7).frame(width: 66, height: 66)
                Circle().trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .frame(width: 66, height: 66).rotationEffect(.degrees(-90))
                Text("%\(score)").font(.system(size: 18, weight: .bold)).foregroundStyle(color)
            }
            Text(message).font(.system(size: 15, weight: .medium)).foregroundStyle(.primary)
            if heard != "—" && !heard.isEmpty {
                Text("“\(heard)”").font(.system(size: 12)).foregroundStyle(.secondary)
                    .lineLimit(3).multilineTextAlignment(.center).padding(.horizontal, 14)
            }
            HStack(spacing: 10) {
                Button { coach.start(target: target) } label: { Label("Tekrar", systemImage: "mic") }
                    .modifier(GlassProminentBtn()).tint(.blue)
                Button { coach.reset() } label: { Text("Bitti") }
                    .modifier(GlassBtn())
            }
            .controlSize(.large)
        }
        .onAppear { withAnimation(.easeOut(duration: 0.6)) { progress = CGFloat(score) / 100 } }
    }
}
