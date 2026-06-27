import Carbon.HIToolbox

final class HotKey {
    private var hotKeyRef: EventHotKeyRef?
    private let action: () -> Void
    private let myID: UInt32

    private static var registry: [UInt32: HotKey] = [:]
    private static var nextID: UInt32 = 1

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

        let signature: OSType = 0x42524B45 // "BRKE"
        let hotKeyID = EventHotKeyID(signature: signature, id: myID)
        let regStatus = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        alog("HotKey init keyCode=\(keyCode) modifiers=\(modifiers) register=\(regStatus)")
    }

    deinit {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        HotKey.registry[myID] = nil
    }
}
