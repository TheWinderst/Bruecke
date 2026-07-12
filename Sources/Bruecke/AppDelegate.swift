import AppKit
import SwiftUI
import ApplicationServices
import Carbon.HIToolbox

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var hotKey: HotKey?
    private var savedWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private let speaker = Speaker()
    private let dictionary = DictionaryService()
    private lazy var popover = PopoverController(speaker: speaker)

    // Yalnızca en yeni aramanın kartı boyaması için artan kuşak sayacı (hızlı ardışık aramalar yarışmasın).
    private var lookupGeneration = 0

    func applicationDidFinishLaunching(_ notification: Notification) {
        alogReset()
        alog("launched. accessibility trusted=\(AXIsProcessTrusted())")

        setUpStatusItem()
        hotKey = HotKey(keyCode: 2, modifiers: UInt32(cmdKey | shiftKey)) { [weak self] in
            self?.triggerLookup()
        }
        // Kullanıcı bekleme kartını ESC/dış tıklama ile kapatırsa bekleyen arama
        // iptal olsun — sonradan sonuç kartı kendiliğinden fırlamasın.
        popover.onUserDismiss = { [weak self] in
            self?.lookupGeneration += 1
        }
        NSApp.servicesProvider = self
        promptForAccessibilityIfNeeded()
    }

    private func setUpStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "character.book.closed", accessibilityDescription: "Brücke")
            button.title = button.image == nil ? "BR" : ""
        }

        let menu = NSMenu()
        menu.addItem(withTitle: "Seçili kelimeyi çevir  (⌘⇧D)", action: #selector(triggerLookup), keyEquivalent: "")
        menu.addItem(withTitle: "Kelime yaz ve çevir…", action: #selector(openSearch), keyEquivalent: "")
        menu.addItem(withTitle: "Kaydedilen kelimeler…", action: #selector(showSaved), keyEquivalent: "")
        menu.addItem(withTitle: "Kelime tekrarı…", action: #selector(showReview), keyEquivalent: "")
        menu.addItem(withTitle: "Ayarlar…", action: #selector(showSettings), keyEquivalent: ",")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Örnek kart: der Apfel", action: #selector(showSample), keyEquivalent: "")
        menu.addItem(withTitle: "Brücke hakkında", action: #selector(showAbout), keyEquivalent: "")
        menu.addItem(withTitle: "Çıkış", action: #selector(quit), keyEquivalent: "q")
        for item in menu.items { item.target = self }
        statusItem.menu = menu
    }

    @objc private func triggerLookup() {
        lookupGeneration += 1
        let gen = lookupGeneration
        SelectionReader.readSelectedText { [weak self] text in
            guard let self, gen == self.lookupGeneration else { return }
            let clean = (text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if clean.isEmpty {
                // Seçim yoksa boş "önce kelime seç" kartı yerine doğrudan yazma
                // kutusunu aç — kullanıcı kendi kelimesini yazıp çevirebilsin.
                self.presentSearch()
                return
            }
            self.lookupAndShow(clean, gen: gen, at: NSEvent.mouseLocation)
        }
    }

    @objc private func openSearch() {
        presentSearch()
    }

    // Yazıp çevirme kutusunu imlecin olduğu yerde açar (menü çubuğundan çağrılınca
    // sağ üstte belirir). Enter'a basınca kelimeyi arayıp kartı gösterir.
    private func presentSearch() {
        popover.showSearch(at: NSEvent.mouseLocation) { [weak self] term, direction in
            guard let self else { return }
            self.lookupGeneration += 1
            // Çapa vermiyoruz: sonuç kartı arama kutusunun olduğu noktada açılır.
            self.lookupAndShow(term, direction: direction, gen: self.lookupGeneration, at: nil)
        }
    }

    @objc func translateService(_ pboard: NSPasteboard, userData: String?, error: AutoreleasingUnsafeMutablePointer<NSString>?) {
        let clean = (pboard.string(forType: .string) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        lookupGeneration += 1
        lookupAndShow(clean, gen: lookupGeneration, at: NSEvent.mouseLocation)
    }

    private func lookupAndShow(_ term: String, direction: LookupDirection = .auto, gen: Int, at anchor: NSPoint?) {
        // Sonuç anında (önbellek/örnek sözlük) gelirse yükleme kartını hiç
        // göstermeyiz — kart bir karelik parlayıp sönmesin. Yükleme kartı
        // gösterildiyse sonuç kartı aynı noktada onun yerini alır.
        var completed = false
        var showedLoading = false
        dictionary.lookup(term, direction: direction) { [weak self] entry in
            guard let self else { return }
            completed = true
            guard gen == self.lookupGeneration else { return }
            self.present(entry ?? self.cannotTranslateEntry, at: showedLoading ? nil : anchor)
        }
        if !completed {
            showedLoading = true
            popover.showLoading(term: term, at: anchor)
        }
    }

    @objc private func showSample() {
        guard let entry = SampleDictionary.lookup("apfel") else { return }
        present(entry, at: NSEvent.mouseLocation)
    }

    @objc private func showSaved() {
        presentSavedWindow(mode: .list)
    }

    @objc private func showReview() {
        presentSavedWindow(mode: .review)
    }

    private func presentSavedWindow(mode: SavedViewMode) {
        if savedWindow == nil {
            let view = SavedWordsView(speaker: speaker,
                                      onSelect: { [weak self] entry in self?.present(entry, at: NSEvent.mouseLocation) })
            let window = NSWindow(contentViewController: NSHostingController(rootView: view))
            window.title = "Kelimelerim"
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.setContentSize(NSSize(width: 380, height: 480))
            window.isReleasedWhenClosed = false
            window.center()
            savedWindow = window
        }
        SavedViewState.shared.mode = mode
        bringToFront(savedWindow)
    }

    @objc private func showSettings() {
        if settingsWindow == nil {
            let window = NSWindow(contentViewController: NSHostingController(rootView: SettingsView()))
            window.title = "Brücke Ayarları"
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            window.center()
            settingsWindow = window
        }
        bringToFront(settingsWindow)
    }

    private func bringToFront(_ window: NSWindow?) {
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    private var cannotTranslateEntry: WordEntry {
        WordEntry(
            lemma: "Çeviremedim",
            kind: .other, gender: .none, posLabel: "",
            plural: nil, ipa: nil, praeteritum: nil, perfekt: nil,
            translation: "Bir Almanca kelime seçip ⌘⇧D'ye bas. (Bağlantı yoksa onu da kontrol et.)",
            examples: []
        )
    }

    private func present(_ entry: WordEntry, at anchor: NSPoint?) {
        popover.show(entry: entry, at: anchor)
    }

    @objc private func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "Brücke"
        alert.informativeText = """
        Almanca–Türkçe sözlük. Bir kelime seç ve ⌘⇧D'ye bas.

        Kaynaklar: Wiktionary (CC BY-SA), Tatoeba (CC BY), OpenThesaurus (CC BY-SA), \
        çeviri Google (resmî olmayan) / LibreTranslate.

        © 2026 thewinderst · GPL-3.0 Lisansı
        """
        alert.runModal()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func promptForAccessibilityIfNeeded() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        _ = AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
    }
}
