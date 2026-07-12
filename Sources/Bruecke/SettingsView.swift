import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = AppSettings.shared
    @ObservedObject private var history = HistoryStore.shared

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
            Section("Çeviri motoru") {
                Picker("Motor", selection: $settings.translationEngine) {
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
            Section("Bilgi") {
                LabeledContent("Çeviri kısayolu", value: "⌘⇧D")
                LabeledContent("Sürüm", value: "Brücke 1.3")
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 500)
    }
}
