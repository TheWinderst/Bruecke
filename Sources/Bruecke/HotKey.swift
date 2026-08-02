import Carbon.HIToolbox
import AppKit

final class HotKey {
    private var hotKeyRef: EventHotKeyRef?
    private let action: () -> Void
    let myID: UInt32
    // Kayıt başarısızsa (başka bir uygulama kısayolu kapmıştır) menüde uyarı gösterilir.
    private(set) var registered = true

    private static var registry: [UInt32: HotKey] = [:]
    private static var nextID: UInt32 = 1

    // Bir tuş basılınca oluşan tek seferlik yakalama; kayıt bitince kendini söker.
    private static var captureMonitor: Any?

    // Uygulama genelinde TEK bir Carbon olay işleyici (her örnekte yenisini kurmak yerine).
    // İlk HotKey oluşturulduğunda bir kez kurulur ve uygulama ömrü boyunca yaşar.
    private static let installSharedHandler: Bool = {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: OSType(kEventHotKeyPressed))
        var ref: EventHandlerRef?
        InstallEventHandler(GetApplicationEventTarget(), { (_, eventRef, _) -> OSStatus in
            alog("hotkey event received")
            guard let eventRef else { return noErr }
            var hkID = EventHotKeyID()
            let status = GetEventParameter(
                eventRef,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hkID
            )
            if status == noErr, let instance = HotKey.registry[hkID.id] {
                DispatchQueue.main.async { instance.action() }
            }
            return noErr
        }, 1, &eventType, nil, &ref)
        return true
    }()

    init(keyCode: UInt32, modifiers: UInt32, action: @escaping () -> Void) {
        self.action = action
        self.myID = HotKey.nextID
        HotKey.nextID += 1
        HotKey.registry[myID] = self
        _ = HotKey.installSharedHandler   // ilk örnekte tek işleyiciyi kur
        register(keyCode: keyCode, modifiers: modifiers)
    }

    // Kısayolu yeni tuş bileşimiyle yeniden kaydeder (Ayarlar'dan değişince).
    func update(keyCode: UInt32, modifiers: UInt32) {
        if let ref = hotKeyRef { UnregisterEventHotKey(ref); hotKeyRef = nil }
        register(keyCode: keyCode, modifiers: modifiers)
    }

    private func register(keyCode: UInt32, modifiers: UInt32) {
        let signature: OSType = 0x42524B45 // "BRKE"
        let hotKeyID = EventHotKeyID(signature: signature, id: myID)
        let regStatus = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        registered = (regStatus == noErr)
        alog("HotKey register keyCode=\(keyCode) modifiers=\(modifiers) status=\(regStatus)")
    }

    // Bir sonraki tuş basımını yakala: Ayarlar'daki "Kaydet" düğmesi bunu çağırır,
    // kullanıcının bastığı bileşim (en az bir değiştirici ile) geri döner.
    // 15 sn içinde tuşa basılmaz ya da ESC'ye basılırsa sessizce biter.
    static func captureNextKeyPress(completion: @escaping (Int, Int) -> Void) {
        if let m = captureMonitor { NSEvent.removeMonitor(m); captureMonitor = nil }
        var done = false
        var timeout: DispatchWorkItem?

        let finish: (Int?, Int?) -> Void = { keyCode, mods in
            guard !done else { return }
            done = true
            timeout?.cancel()
            if let m = captureMonitor { NSEvent.removeMonitor(m); captureMonitor = nil }
            if let keyCode, let mods { completion(keyCode, mods) }
        }

        captureMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            // Yalnız değiştirici tuş basımı keyDown üretmez; ⌘R gibi sistem
            // bileşimleri uygulamaya gelmeden yutulur — kullanıcı başka bir tuş dener.
            let carbon = Self.carbonModifiers(from: event.modifierFlags)
            if event.keyCode == 53 { finish(nil, nil); return nil }   // ESC: vazgeç
            guard carbon != 0 else { return event }                   // çıplak harf: yazı olarak kalsın
            finish(Int(event.keyCode), carbon)
            return nil
        }
        let work = DispatchWorkItem { finish(nil, nil) }
        timeout = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 15, execute: work)
    }

    // Açık bir yakalamayı iptal eder (Ayarlar penceresi kapanınca monitör kalmasın).
    static func cancelCapture() {
        if let m = captureMonitor { NSEvent.removeMonitor(m); captureMonitor = nil }
    }

    // AppKit değiştirici bayraklarını Carbon (RegisterEventHotKey) bayraklarına çevirir.
    static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> Int {
        var m = 0
        if flags.contains(.command) { m |= Int(cmdKey) }
        if flags.contains(.shift) { m |= Int(shiftKey) }
        if flags.contains(.option) { m |= Int(optionKey) }
        if flags.contains(.control) { m |= Int(controlKey) }
        return m
    }

    // Tuş bileşimini "⌘⇧D" biçiminde gösterir (menü ve ayarlar etiketi).
    static func displayString(keyCode: Int, modifiers: Int) -> String {
        var s = ""
        if modifiers & Int(controlKey) != 0 { s += "⌃" }
        if modifiers & Int(optionKey) != 0 { s += "⌥" }
        if modifiers & Int(shiftKey) != 0 { s += "⇧" }
        if modifiers & Int(cmdKey) != 0 { s += "⌘" }
        return s + (keyNames[keyCode] ?? "tuş \(keyCode)")
    }

    private static let keyNames: [Int: String] = [
        0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X", 8: "C", 9: "V",
        11: "B", 12: "Q", 13: "W", 14: "E", 15: "R", 16: "Y", 17: "T",
        18: "1", 19: "2", 20: "3", 21: "4", 22: "6", 23: "5", 24: "=", 25: "9", 26: "7",
        27: "-", 28: "8", 29: "0", 30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P",
        37: "L", 38: "J", 39: "'", 40: "K", 41: ";", 42: "\\", 43: ",", 44: "/", 45: "N",
        46: "M", 47: ".", 50: "`",
        96: "F5", 97: "F7", 98: "F3", 99: "F8", 100: "F9", 101: "F6", 103: "F11",
        105: "F13", 107: "F14", 109: "F10", 111: "F12", 113: "F15",
        118: "F4", 120: "F2", 122: "F1", 123: "←", 124: "→", 125: "↓", 126: "↑"
    ]

    deinit {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        HotKey.registry[myID] = nil
    }
}
