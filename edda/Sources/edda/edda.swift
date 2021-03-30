import ShortcutRecorder

@_cdecl("mjDouble")
public func mjDouble(x: Int) -> Int {
    return x * 2
}

@_cdecl("mjRegisterKeybind")
public func mjRegisterKeybind(kb: UnsafePointer<CChar>) {
    let swift_kb = String(cString: kb)
    let shortcut = Shortcut(keyEquivalent: swift_kb) // "⌘A")
    let beepAction = ShortcutAction(shortcut: shortcut!, actionHandler: testKeyPress)
    GlobalShortcutMonitor.shared.addAction(beepAction, forKeyEvent: .down)
}

func testKeyPress(sca: ShortcutAction) -> Bool {
    NSSound.beep()
    return true
}
