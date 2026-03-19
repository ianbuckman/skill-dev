import AppKit
import Carbon.HIToolbox

@MainActor
final class HotkeyService {
    private var hotkeys: [UInt32: () -> Void] = [:]
    private var nextID: UInt32 = 1
    private var hotKeyRefs: [UInt32: EventHotKeyRef] = [:]
    private var eventHandler: EventHandlerRef?

    static let shared = HotkeyService()

    private init() {
        installEventHandler()
    }

    private func installEventHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, _) -> OSStatus in
                var hotKeyID = EventHotKeyID()
                GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                Task { @MainActor in
                    HotkeyService.shared.handleHotkey(id: hotKeyID.id)
                }
                return noErr
            },
            1,
            &eventType,
            nil,
            &eventHandler
        )
        if status != noErr {
            print("Failed to install hotkey event handler: \(status)")
        }
    }

    private func handleHotkey(id: UInt32) {
        hotkeys[id]?()
    }

    @discardableResult
    func register(keyCode: UInt32, modifiers: UInt32, handler: @escaping @MainActor () -> Void) -> UInt32 {
        let id = nextID
        nextID += 1

        let hotKeyID = EventHotKeyID(signature: OSType(0x534E4150), id: id) // "SNAP"
        var hotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if status == noErr, let ref = hotKeyRef {
            hotKeyRefs[id] = ref
            hotkeys[id] = handler
        } else {
            print("Failed to register hotkey: \(status)")
        }

        return id
    }

    func unregister(id: UInt32) {
        if let ref = hotKeyRefs[id] {
            UnregisterEventHotKey(ref)
            hotKeyRefs.removeValue(forKey: id)
            hotkeys.removeValue(forKey: id)
        }
    }

    func unregisterAll() {
        for (_, ref) in hotKeyRefs {
            UnregisterEventHotKey(ref)
        }
        hotKeyRefs.removeAll()
        hotkeys.removeAll()
    }
}

// Carbon modifier key masks
enum CarbonModifier {
    static let command: UInt32 = UInt32(cmdKey)
    static let shift: UInt32 = UInt32(shiftKey)
    static let option: UInt32 = UInt32(optionKey)
    static let control: UInt32 = UInt32(controlKey)
}

// Carbon key codes for common keys
enum CarbonKeyCode {
    static let key0: UInt32 = 0x1D
    static let key1: UInt32 = 0x12
    static let key2: UInt32 = 0x13
    static let key3: UInt32 = 0x14
    static let key4: UInt32 = 0x15
    static let key5: UInt32 = 0x17
    static let key6: UInt32 = 0x16
    static let key7: UInt32 = 0x1A
    static let key8: UInt32 = 0x1C
    static let key9: UInt32 = 0x19
    static let keyT: UInt32 = 0x11
    static let keyF: UInt32 = 0x03
}
