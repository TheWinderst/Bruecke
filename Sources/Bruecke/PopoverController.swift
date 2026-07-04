import AppKit
import SwiftUI

// Borderless panel'ler varsayılan olarak anahtar (key) olamaz → metin alanı odak
// alamaz. Arama kutusuna yazabilmek için bunu geçersiz kılıyoruz.
final class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

@MainActor
final class PopoverController {
    private var panel: NSPanel?
    private var clickMonitor: Any?
    private var escMonitor: Any?
    private var escGlobalMonitor: Any?
    private let speaker: Speaker

    init(speaker: Speaker) {
        self.speaker = speaker
    }

    func show(entry: WordEntry, at screenPoint: NSPoint) {
        close()

        let root = WordCardView(entry: entry, speaker: speaker)
        let hosting = NSHostingView(rootView: root)
        hosting.layout()
        var size = hosting.fittingSize

        // Çok uzun kartlar ekranın dışına taşmasın: yüksekliği görünür alana sığacak şekilde sınırla.
        if let screen = NSScreen.main {
            let maxH = screen.visibleFrame.height - 16
            if size.height > maxH {
                size.height = maxH
                hosting.setFrameSize(size)
            }
        }

        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.becomesKeyOnlyIfNeeded = true
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.contentView = hosting

        panel.setFrameOrigin(clamp(NSPoint(x: screenPoint.x, y: screenPoint.y - size.height), size: size))
        panel.orderFrontRegardless()
        self.panel = panel

        installDismissMonitors()
    }

    // Kelime seçmeden doğrudan yazıp çevirmek için klavye alan arama kutusu.
    // Kullanıcı Enter'a basınca onSubmit çağrılır; sonuç kartı gösterilince
    // (present → show) bu panel otomatik kapanır (show önce close() çağırır).
    func showSearch(at screenPoint: NSPoint, onSubmit: @escaping (String) -> Void) {
        close()

        let root = DictionarySearchView(onSubmit: onSubmit)
        let hosting = NSHostingView(rootView: root)
        hosting.layout()
        let size = hosting.fittingSize

        let panel = KeyablePanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true

        // Kenarlık temizliği: pencere anahtar/aktif olunca hosting katmanı köşelerde
        // opak bir dikdörtgen çizip cam kartın yuvarlak köşelerinin dışını siyah
        // bırakıyordu. Katmanı şeffaflaştırıp aynı 24px yuvarlağa kırpıyoruz; böylece
        // pencere gölgesi de yuvarlak biçime uyuyor (invalidateShadow ile tazelenir).
        hosting.wantsLayer = true
        hosting.layer?.backgroundColor = NSColor.clear.cgColor
        hosting.layer?.cornerRadius = 24
        hosting.layer?.cornerCurve = .continuous
        hosting.layer?.masksToBounds = true
        panel.contentView = hosting

        panel.setFrameOrigin(clamp(NSPoint(x: screenPoint.x, y: screenPoint.y - size.height), size: size))
        NSApp.activate(ignoringOtherApps: true)   // menü çubuğu uygulaması → alan odak alabilsin
        panel.makeKeyAndOrderFront(nil)
        panel.invalidateShadow()
        self.panel = panel

        installDismissMonitors()
    }

    // Dışarı tıklama ve ESC ile kapatma izleyicileri (hem kart hem arama kutusu için).
    private func installDismissMonitors() {
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.close()
        }
        // ESC ile kapatma: panel anahtar olmayabileceği için hem yerel hem genel izleyici koy.
        escMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            if event.keyCode == 53 { self?.close(); return nil }
            return event
        }
        escGlobalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            if event.keyCode == 53 { self?.close() }
        }
    }

    private func clamp(_ origin: NSPoint, size: NSSize) -> NSPoint {
        guard let screen = NSScreen.main else { return origin }
        let visible = screen.visibleFrame
        var p = origin
        p.x = min(max(p.x, visible.minX + 8), visible.maxX - size.width - 8)
        p.y = min(max(p.y, visible.minY + 8), visible.maxY - size.height - 8)
        return p
    }

    func close() {
        panel?.orderOut(nil)
        panel = nil
        if let m = clickMonitor { NSEvent.removeMonitor(m); clickMonitor = nil }
        if let m = escMonitor { NSEvent.removeMonitor(m); escMonitor = nil }
        if let m = escGlobalMonitor { NSEvent.removeMonitor(m); escGlobalMonitor = nil }
    }
}
