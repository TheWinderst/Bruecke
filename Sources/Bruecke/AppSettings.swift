import Foundation
import Carbon.HIToolbox

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

// Almancadan hangi dile çevrileceği. Türkçe, uygulamanın ana dilidir: TR→DE ters
// arama ve bütün yerleşik içerik (örnek kelimeler, edat kalıpları) Türkçedir.
// English seçilirse DE→EN çift diliyle çalışılır.
enum TranslationLanguage: String, CaseIterable, Identifiable {
    case turkish, english
    var id: String { rawValue }
    var code: String { self == .turkish ? "tr" : "en" }
    var label: String { self == .turkish ? "Türkçe" : "English" }
}

@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var showEnglish: Bool { didSet { UserDefaults.standard.set(showEnglish, forKey: "showEnglish") } }
    @Published var showAlternates: Bool { didSet { UserDefaults.standard.set(showAlternates, forKey: "showAlternates") } }
    @Published var showSynonyms: Bool { didSet { UserDefaults.standard.set(showSynonyms, forKey: "showSynonyms") } }

    // Arama geçmişi + çevrimdışı önbellek (kapatılınca depo da boşaltılır).
    @Published var keepHistory: Bool {
        didSet {
            UserDefaults.standard.set(keepHistory, forKey: "keepHistory")
            if !keepHistory { HistoryStore.shared.clear() }
        }
    }

    // Yazıp çevirme kutusunun yönü: false = Almanca→Türkçe (varsayılan),
    // true = Türkçe→Almanca. Kutudaki düğmeden değişir, sonraki açılışta hatırlanır.
    @Published var searchReversed: Bool {
        didSet { UserDefaults.standard.set(searchReversed, forKey: "searchReversed") }
    }

    @Published var translationEngine: TranslationEngine {
        didSet { UserDefaults.standard.set(translationEngine.rawValue, forKey: "translationEngine") }
    }
    // LibreTranslate sunucu adresi (kullanıcı kendi sunucusunu girebilir).
    @Published var libreEndpoint: String {
        didSet { UserDefaults.standard.set(libreEndpoint, forKey: "libreEndpoint") }
    }
    // Çeviri dili: Almanca → Türkçe (varsayılan) ya da English.
    @Published var translationLanguage: TranslationLanguage {
        didSet { UserDefaults.standard.set(translationLanguage.rawValue, forKey: "translationLanguage") }
    }

    // Kısayol: sanal tuş kodu + Carbon değiştirici bayrakları (⌘⇧D varsayılan).
    @Published var hotKeyKeyCode: Int {
        didSet { UserDefaults.standard.set(hotKeyKeyCode, forKey: "hotKeyKeyCode") }
    }
    @Published var hotKeyModifiers: Int {
        didSet { UserDefaults.standard.set(hotKeyModifiers, forKey: "hotKeyModifiers") }
    }

    init() {
        let d = UserDefaults.standard
        func b(_ key: String) -> Bool { d.object(forKey: key) == nil ? true : d.bool(forKey: key) }
        showEnglish = b("showEnglish")
        showAlternates = b("showAlternates")
        showSynonyms = b("showSynonyms")
        keepHistory = b("keepHistory")
        searchReversed = d.bool(forKey: "searchReversed")
        translationEngine = TranslationEngine(rawValue: d.string(forKey: "translationEngine") ?? "") ?? .google
        libreEndpoint = d.string(forKey: "libreEndpoint") ?? "https://libretranslate.com"
        translationLanguage = TranslationLanguage(rawValue: d.string(forKey: "translationLanguage") ?? "") ?? .turkish
        hotKeyKeyCode = d.object(forKey: "hotKeyKeyCode") == nil ? 2 : d.integer(forKey: "hotKeyKeyCode")
        hotKeyModifiers = d.object(forKey: "hotKeyModifiers") == nil
            ? Int(cmdKey | shiftKey) : d.integer(forKey: "hotKeyModifiers")
    }
}
