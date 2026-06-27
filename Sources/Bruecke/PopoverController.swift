import AppKit
import SwiftUI

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
