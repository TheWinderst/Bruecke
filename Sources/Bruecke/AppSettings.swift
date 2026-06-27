import Foundation

enum TranslationEngine: String, CaseIterable, Identifiable {
    case google      // Google'ın ücretsiz/halka açık ucu (en iyi kalite, varsayılan)
    case libre       // LibreTranslate — tamamen açık kaynak alternatif
    var id: String { rawValue }
    var label: String {
        switch self {
        case .google: return "Google (önerilen)"
        case .libre:  return "LibreTranslate (açık kaynak)"
        }
    }
}

@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var showEnglish: Bool { didSet { UserDefaults.standard.set(showEnglish, forKey: "showEnglish") } }
    @Published var showAlternates: Bool { didSet { UserDefaults.standard.set(showAlternates, forKey: "showAlternates") } }
    @Published var showSynonyms: Bool { didSet { UserDefaults.standard.set(showSynonyms, forKey: "showSynonyms") } }

    @Published var translationEngine: TranslationEngine {
        didSet { UserDefaults.standard.set(translationEngine.rawValue, forKey: "translationEngine") }
    }
    // LibreTranslate sunucu adresi (kullanıcı kendi sunucusunu girebilir).
    @Published var libreEndpoint: String {
        didSet { UserDefaults.standard.set(libreEndpoint, forKey: "libreEndpoint") }
    }

    init() {
        let d = UserDefaults.standard
        func b(_ key: String) -> Bool { d.object(forKey: key) == nil ? true : d.bool(forKey: key) }
        showEnglish = b("showEnglish")
        showAlternates = b("showAlternates")
        showSynonyms = b("showSynonyms")
        translationEngine = TranslationEngine(rawValue: d.string(forKey: "translationEngine") ?? "") ?? .google
        libreEndpoint = d.string(forKey: "libreEndpoint") ?? "https://libretranslate.com"
    }
}
