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
            // 1) Panonun değişmesini bekle (uygulama ⌘C'yi işleyene kadar).
            var changed = false
            let changeDeadline = Date().addingTimeInterval(0.45)
            while Date() < changeDeadline {
                if pasteboard.changeCount != oldChangeCount { changed = true; break }
                usleep(15_000)
            }

            // 2) KRİTİK: Bazı uygulamalar (özellikle web sayfaları) ⌘C'de önce panoyu
            //    BOŞALTIP metni bir an SONRA yazar. changeCount değişir değişmez okursak
            //    metin henüz gelmemiş olur ve nil döner (log'da changed=true len=-1 →
            //    "önce kelime seç" kartı yanlışlıkla çıkar). Metin belirene kadar kısa
            //    bir süre daha yokla.
            var result: String?
            if changed {
                let textDeadline = Date().addingTimeInterval(0.30)
                repeat {
                    if let s = pasteboard.string(forType: .string)?
                        .trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
                        result = s
                        break
                    }
                    usleep(15_000)
                } while Date() < textDeadline
            }

            DispatchQueue.main.async {
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
