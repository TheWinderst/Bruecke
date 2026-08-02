import SwiftUI
import AppKit

struct SettingsView: View {
    @ObservedObject var settings = AppSettings.shared
    @ObservedObject private var history = HistoryStore.shared

    // Kısayol kaydı: kullanıcı "Kaydet"e basınca bir sonraki tuş bileşimi yakalanır.
    @State private var capturing = false
    // Aynı anda tek kayıt isteği: pencere kapanıp yeniden açılınca eski callback sızmasın.
    @State private var captureGeneration = 0

    var body: some View {
        Form {
            Section("Kart içeriği") {
                Toggle("İngilizce çeviriyi göster", isOn: $settings.showEnglish)
                Toggle("Diğer (Türkçe) anlamları göster", isOn: $settings.showAlternates)
                Toggle("Almanca eş anlamlıları göster", isOn: $settings.showSynonyms)
            }
            Section("Geçmiş ve önbellek") {
                Toggle("Arama geçmişini tut", isOn: $settings.keepHistory)
                Text("Bakılan kelimeler bu Mac'te saklanır: ikinci bakış anında açılır ve internetsiz de çalışır; arama kutusunda son aramalar görünür.")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
                if !history.items.isEmpty {
                    HStack {
                        Text("\(history.items.count) kelime bellekte")
                            .font(.system(size: 12)).foregroundStyle(.secondary)
                        Spacer()
                        Button("Geçmişi temizle", role: .destructive) { history.clear() }
                            .controlSize(.small)
                    }
                }
            }
            Section("Çeviri") {
                Picker("Çeviri dili", selection: $settings.translationLanguage) {
                    ForEach(TranslationLanguage.allCases) { l in
                        Text(l.label).tag(l)
                    }
                }
                if settings.translationLanguage == .english {
                    Text("Kartlar Almancadan İngilizceye çevrilir. Türkçeden Almancaya ters arama ve yerleşik edat kalıpları Türkçe modundadır.")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                }
                Picker("Çeviri motoru", selection: $settings.translationEngine) {
                    ForEach(TranslationEngine.allCases) { e in
                        Text(e.label).tag(e)
                    }
                }
                if settings.translationEngine == .libre {
                    TextField("LibreTranslate adresi", text: $settings.libreEndpoint)
                        .textFieldStyle(.roundedBorder)
                    Text("LibreTranslate açık kaynaktır; bazı sunucular API anahtarı ister. Kendi sunucunu da girebilirsin.")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                }
            }
            Section("Kısayol") {
                HStack {
                    Text("Çeviri kısayolu")
                    Spacer()
                    if capturing {
                        Text("yeni kısayola bas…")
                            .font(.system(size: 12)).foregroundStyle(.secondary)
                        Button("Vazgeç") { cancelCapture() }
                            .controlSize(.small)
                    } else {
                        Text(currentHotKeyLabel)
                            .font(.system(size: 13, weight: .semibold))
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
                        Button("Değiştir…") { startCapture() }
                            .controlSize(.small)
                    }
                }
                Text("Bazı uygulamalar ⌘⇧D'yi kendi kullanır; çakışırsa buradan değiştir. En az bir değiştirici tuş (⌘, ⇧, ⌥, ⌃) ile bir tuşa bas.")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
            }
            Section("Bilgi") {
                LabeledContent("Sürüm", value: "Brücke 1.5")
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 560)
        .onDisappear { cancelCapture() }
    }

    private var currentHotKeyLabel: String {
        HotKey.displayString(keyCode: settings.hotKeyKeyCode, modifiers: settings.hotKeyModifiers)
    }

    private func startCapture() {
        capturing = true
        captureGeneration += 1
        let gen = captureGeneration
        HotKey.captureNextKeyPress { keyCode, mods in
            DispatchQueue.main.async {
                guard gen == captureGeneration else { return }
                capturing = false
                settings.hotKeyKeyCode = keyCode
                settings.hotKeyModifiers = mods
                // Yeni bileşimi hemen etkinleştir ve menüdeki etiketi tazele.
                (NSApp.delegate as? AppDelegate)?.applyHotKeyChange()
            }
        }
    }

    private func cancelCapture() {
        guard capturing else { return }
        captureGeneration += 1   // bekleyen yakalama callback'ini geçersiz kıl
        capturing = false
        // Yakalamayı gerçekten durdur: boş bir tamamlama ile monitörü söktür.
        HotKey.cancelCapture()
    }
}
