import AppKit

final class GameView: NSView {
    var playerX: CGFloat = 100

    override var acceptsFirstResponder: Bool {
        true
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.setFill()
        bounds.fill()

        NSColor.white.setFill()
        NSRect(
            x: playerX,
            y: 50,
            width: 40,
            height: 40
        ).fill()
    }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 123: // left arrow
            playerX -= 10

        case 124: // right arrow
            playerX += 10

        default:
            break
        }

        needsDisplay = true
    }
}

let app = NSApplication.shared

// Make this behave like a normal macOS application.
app.setActivationPolicy(.regular)

let window = NSWindow(
    contentRect: NSRect(
        x: 0,
        y: 0,
        width: 640,
        height: 480
    ),
    styleMask: [
        .titled,
        .closable,
        .resizable
    ],
    backing: .buffered,
    defer: false
)

window.title = "Tiny Game"
window.center()

let gameView = GameView(
    frame: NSRect(
        x: 0,
        y: 0,
        width: 640,
        height: 480
    )
)

window.contentView = gameView

window.makeKeyAndOrderFront(nil)

// Important: send keyboard events to the game view.
window.makeFirstResponder(gameView)

// Important when launching from Terminal.
app.activate(ignoringOtherApps: true)

app.run()
