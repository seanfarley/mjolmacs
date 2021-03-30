import ShortcutRecorder

@_cdecl("mjDouble")
public func mjDouble(x: Int) -> Int {
    return x * 2
}

@_cdecl("mjRegisterKeybind")
public func mjRegisterKeybind() {
    let shortcut = Shortcut(keyEquivalent: "⌘A")
    let beepAction = ShortcutAction(shortcut: shortcut!, actionHandler: testKeyPress)
    GlobalShortcutMonitor.shared.addAction(beepAction, forKeyEvent: .down)
}

func testKeyPress(sca: ShortcutAction) -> Bool {
    NSSound.beep()
    return true
}
