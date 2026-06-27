import AppKit

enum SelectionReader {

    // Ana iş parçacığında çağrılır (kısayol/servis). Panonun tamamını yedekler, sentetik ⌘C ile
    // seçimi okur, sonra panoyu eski haline getirir. Metin cihazdan yalnızca çeviri/sözlük
    // sunucularına gider (README'deki Gizlilik notuna bakınız).
    static func readSelectedText(completion: @escaping (String?) -> Void) {
        let pasteboard = NSPasteboard.general
        let saved = snapshotItems(pasteboard)       // tüm türleriyle yedek (resim/dosya/RTF kaybolmasın)
        let oldChangeCount = pasteboard.changeCount

        DispatchQueue.global(qos: .userInitiated).async {
            postCommandC()
            // Sabit 150ms yerine: pano değişene kadar yokla (yavaş uygulamalarda seçim kaçmasın).
            var changed = false
            let deadline = Date().addingTimeInterval(0.45)
            while Date() < deadline {
                if pasteboard.changeCount != oldChangeCount { changed = true; break }
                usleep(15_000)
            }

            DispatchQueue.main.async {
                var result: String?
                if changed {
                    result = pasteboard.string(forType: .string)?
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                }
                pasteboard.clearContents()
                if !saved.isEmpty { pasteboard.writeObjects(saved) }
                alog("selection read: changed=\(changed) len=\(result?.count ?? -1)")
                completion(result)
            }
        }
    }

    private static func snapshotItems(_ pb: NSPasteboard) -> [NSPasteboardItem] {
        pb.pasteboardItems?.compactMap { item in
            let copy = NSPasteboardItem()
            for type in item.types {
                if let data = item.data(forType: type) { copy.setData(data, forType: type) }
            }
            return copy.types.isEmpty ? nil : copy
        } ?? []
    }

    private static func postCommandC() {
        let source = CGEventSource(stateID: .combinedSessionState)
        let keyC: CGKeyCode = 8
        let down = CGEvent(keyboardEventSource: source, virtualKey: keyC, keyDown: true)
        down?.flags = .maskCommand
        let up = CGEvent(keyboardEventSource: source, virtualKey: keyC, keyDown: false)
        up?.flags = .maskCommand
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }
}
