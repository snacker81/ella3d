import AppKit

// ============================================================
// MAP
//
// . = empty
// 1 = blue wall
// 2 = green wall
// 3 = orange wall
// ============================================================

let level: [[Character]] = [
    Array("111111111111"),
    Array("1..........1"),
    Array("1..22......1"),
    Array("1..........1"),
    Array("1.....333..1"),
    Array("1..........1"),
    Array("1..2.......1"),
    Array("1..2...11..1"),
    Array("1..........1"),
    Array("111111111111")
]

let mapHeight = level.count
let mapWidth = level[0].count


// ============================================================
// ENEMIES
// ============================================================

struct Enemy {
    var x: Double
    var y: Double

    var red: CGFloat
    var green: CGFloat
    var blue: CGFloat
}

let enemies: [Enemy] = [
    Enemy(
        x: 6.5,
        y: 1.5,
        red: 0.9,
        green: 0.15,
        blue: 0.15
    ),

    Enemy(
        x: 8.5,
        y: 5.5,
        red: 0.7,
        green: 0.2,
        blue: 0.9
    ),

    Enemy(
        x: 4.5,
        y: 8.5,
        red: 0.9,
        green: 0.7,
        blue: 0.1
    )
]


// ============================================================
// GAME VIEW
// ============================================================

final class GameView: NSView {

    // --------------------------------------------------------
    // Player
    // --------------------------------------------------------

    var playerX = 2.5
    var playerY = 1.5
    var playerAngle = 0.0

    let fieldOfView = Double.pi / 3.0

    let moveSpeed = 2.5
    let turnSpeed = 2.0

    let playerRadius = 0.20
    let enemyRadius = 0.25


    // --------------------------------------------------------
    // Input / loop
    // --------------------------------------------------------

    var pressedKeys = Set<UInt16>()

    var timer: Timer?

    var lastTime =
        ProcessInfo.processInfo.systemUptime


    override var acceptsFirstResponder: Bool {
        true
    }


    override func keyDown(with event: NSEvent) {

        pressedKeys.insert(event.keyCode)

        // ESC
        if event.keyCode == 53 {
            NSApplication.shared.terminate(nil)
        }
    }


    override func keyUp(with event: NSEvent) {
        pressedKeys.remove(event.keyCode)
    }


    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
    }


    // ========================================================
    // GAME LOOP
    // ========================================================

    override func viewDidMoveToWindow() {

        super.viewDidMoveToWindow()

        guard timer == nil else {
            return
        }

        lastTime =
            ProcessInfo.processInfo.systemUptime

        timer = Timer.scheduledTimer(
            withTimeInterval: 1.0 / 60.0,
            repeats: true
        ) { [weak self] _ in

            self?.update()
        }
    }


    deinit {
        timer?.invalidate()
    }


    func update() {

        let now =
            ProcessInfo.processInfo.systemUptime

        let dt =
            min(now - lastTime, 0.05)

        lastTime = now


        // ----------------------------------------------------
        // Turn
        //
        // A / Left
        // D / Right
        // ----------------------------------------------------

        if pressedKeys.contains(0) ||
           pressedKeys.contains(123) {

            playerAngle -= turnSpeed * dt
        }

        if pressedKeys.contains(2) ||
           pressedKeys.contains(124) {

            playerAngle += turnSpeed * dt
        }


        // ----------------------------------------------------
        // Forward / backward
        //
        // W / Up
        // S / Down
        // ----------------------------------------------------

        var movement = 0.0

        if pressedKeys.contains(13) ||
           pressedKeys.contains(126) {

            movement += moveSpeed * dt
        }

        if pressedKeys.contains(1) ||
           pressedKeys.contains(125) {

            movement -= moveSpeed * dt
        }


        if movement != 0 {

            let dx =
                cos(playerAngle) * movement

            let dy =
                sin(playerAngle) * movement


            // X and Y separately gives us wall sliding.

            let newX =
                playerX + dx

            if canStand(
                x: newX,
                y: playerY
            ) {
                playerX = newX
            }


            let newY =
                playerY + dy

            if canStand(
                x: playerX,
                y: newY
            ) {
                playerY = newY
            }
        }


        needsDisplay = true
    }


    // ========================================================
    // COLLISION
    // ========================================================

    func wallAt(
        x: Double,
        y: Double
    ) -> Character? {

        let mx =
            Int(floor(x))

        let my =
            Int(floor(y))


        if mx < 0 ||
           my < 0 ||
           mx >= mapWidth ||
           my >= mapHeight {

            return "1"
        }


        let tile =
            level[my][mx]

        if tile == "." {
            return nil
        }

        return tile
    }


    func collidesWithEnemy(
        x: Double,
        y: Double
    ) -> Bool {

        for enemy in enemies {

            let dx =
                enemy.x - x

            let dy =
                enemy.y - y

            let distanceSquared =
                dx * dx + dy * dy

            let minimumDistance =
                playerRadius + enemyRadius

            if distanceSquared <
                minimumDistance * minimumDistance {

                return true
            }
        }

        return false
    }


    func canStand(
        x: Double,
        y: Double
    ) -> Bool {

        let r =
            playerRadius


        if wallAt(x: x - r, y: y - r) != nil {
            return false
        }

        if wallAt(x: x + r, y: y - r) != nil {
            return false
        }

        if wallAt(x: x - r, y: y + r) != nil {
            return false
        }

        if wallAt(x: x + r, y: y + r) != nil {
            return false
        }


        if collidesWithEnemy(x: x, y: y) {
            return false
        }


        return true
    }


    // ========================================================
    // COLOR
    // ========================================================

    func wallColor(
        type: Character,
        brightness: CGFloat
    ) -> NSColor {

        let b =
            max(0.0, min(1.0, brightness))


        switch type {

        // Blue
        case "1":

            return NSColor(
                calibratedRed: 0.20 * b,
                green: 0.45 * b,
                blue: 1.00 * b,
                alpha: 1
            )


        // Green
        case "2":

            return NSColor(
                calibratedRed: 0.15 * b,
                green: 0.90 * b,
                blue: 0.35 * b,
                alpha: 1
            )


        // Orange
        case "3":

            return NSColor(
                calibratedRed: 1.00 * b,
                green: 0.45 * b,
                blue: 0.12 * b,
                alpha: 1
            )


        default:

            return NSColor(
                calibratedWhite: b,
                alpha: 1
            )
        }
    }


    // ========================================================
    // DRAW
    // ========================================================

    override func draw(_ dirtyRect: NSRect) {

        let screenWidth =
            bounds.width

        let screenHeight =
            bounds.height


        // ----------------------------------------------------
        // Ceiling
        // ----------------------------------------------------

        NSColor(
            calibratedRed: 0.07,
            green: 0.08,
            blue: 0.11,
            alpha: 1
        ).setFill()

        NSRect(
            x: 0,
            y: screenHeight / 2,
            width: screenWidth,
            height: screenHeight / 2
        ).fill()


        // ----------------------------------------------------
        // Floor
        // ----------------------------------------------------

        NSColor(
            calibratedRed: 0.16,
            green: 0.15,
            blue: 0.14,
            alpha: 1
        ).setFill()

        NSRect(
            x: 0,
            y: 0,
            width: screenWidth,
            height: screenHeight / 2
        ).fill()


        // ----------------------------------------------------
        // Raycasting setup
        // ----------------------------------------------------

        let rayCount =
            max(160, Int(screenWidth / 2))

        let sliceWidth =
            screenWidth / CGFloat(rayCount)


        let projectionPlane =
            (screenWidth / 2) /
            CGFloat(tan(fieldOfView / 2))


        // One distance per ray.
        //
        // This is our tiny Z-buffer.
        // We use it later to hide enemies behind walls.

        var zBuffer = [Double](
            repeating: 1e30,
            count: rayCount
        )


        // ====================================================
        // WALL RAYS
        // ====================================================

        for ray in 0..<rayCount {

            let amount =
                Double(ray) /
                Double(rayCount - 1)


            let rayAngle =
                playerAngle
                - fieldOfView / 2
                + amount * fieldOfView


            let rayDirX =
                cos(rayAngle)

            let rayDirY =
                sin(rayAngle)


            var mapX =
                Int(floor(playerX))

            var mapY =
                Int(floor(playerY))


            let deltaDistX =
                abs(rayDirX) < 0.000001
                ? 1e30
                : abs(1.0 / rayDirX)


            let deltaDistY =
                abs(rayDirY) < 0.000001
                ? 1e30
                : abs(1.0 / rayDirY)


            var stepX: Int
            var stepY: Int

            var sideDistX: Double
            var sideDistY: Double


            // ------------------------------------------------
            // X stepping
            // ------------------------------------------------

            if rayDirX < 0 {

                stepX = -1

                sideDistX =
                    (playerX - Double(mapX))
                    * deltaDistX

            } else {

                stepX = 1

                sideDistX =
                    (Double(mapX + 1) - playerX)
                    * deltaDistX
            }


            // ------------------------------------------------
            // Y stepping
            // ------------------------------------------------

            if rayDirY < 0 {

                stepY = -1

                sideDistY =
                    (playerY - Double(mapY))
                    * deltaDistY

            } else {

                stepY = 1

                sideDistY =
                    (Double(mapY + 1) - playerY)
                    * deltaDistY
            }


            // ------------------------------------------------
            // DDA
            // ------------------------------------------------

            var hit = false

            var side = 0

            var wallType: Character = "1"


            while !hit {

                if sideDistX < sideDistY {

                    sideDistX += deltaDistX
                    mapX += stepX

                    side = 0

                } else {

                    sideDistY += deltaDistY
                    mapY += stepY

                    side = 1
                }


                if mapX < 0 ||
                   mapY < 0 ||
                   mapX >= mapWidth ||
                   mapY >= mapHeight {

                    hit = true
                    wallType = "1"

                    break
                }


                let tile =
                    level[mapY][mapX]

                if tile != "." {

                    hit = true
                    wallType = tile
                }
            }


            // ------------------------------------------------
            // Distance
            // ------------------------------------------------

            let rawDistance: Double

            if side == 0 {

                rawDistance =
                    sideDistX - deltaDistX

            } else {

                rawDistance =
                    sideDistY - deltaDistY
            }


            // Fish-eye correction.
            //
            // The result is distance perpendicular
            // to the camera plane.

            let correctedDistance =
                max(
                    rawDistance *
                    cos(rayAngle - playerAngle),
                    0.001
                )


            zBuffer[ray] =
                correctedDistance


            // ------------------------------------------------
            // Project wall
            // ------------------------------------------------

            let wallHeight =
                projectionPlane /
                CGFloat(correctedDistance)


            let wallY =
                (screenHeight - wallHeight) / 2


            // ------------------------------------------------
            // Shading
            // ------------------------------------------------

            var brightness =
                CGFloat(
                    1.0 /
                    (1.0 + correctedDistance * 0.12)
                )


            brightness =
                max(0.20, brightness)


            // One wall orientation is darker.
            // This makes corners much easier to see.

            if side == 1 {
                brightness *= 0.72
            }


            wallColor(
                type: wallType,
                brightness: brightness
            ).setFill()


            NSRect(
                x: CGFloat(ray) * sliceWidth,
                y: wallY,
                width: sliceWidth + 1,
                height: wallHeight
            ).fill()
        }


        // ====================================================
        // SPRITES / ENEMIES
        // ====================================================

        drawEnemies(
            screenWidth: screenWidth,
            screenHeight: screenHeight,
            projectionPlane: projectionPlane,
            rayCount: rayCount,
            zBuffer: zBuffer
        )


        // ----------------------------------------------------
        // Crosshair
        // ----------------------------------------------------

        NSColor.white.withAlphaComponent(0.6).setStroke()

        let crosshair =
            NSBezierPath()

        crosshair.move(
            to: NSPoint(
                x: screenWidth / 2 - 5,
                y: screenHeight / 2
            )
        )

        crosshair.line(
            to: NSPoint(
                x: screenWidth / 2 + 5,
                y: screenHeight / 2
            )
        )

        crosshair.move(
            to: NSPoint(
                x: screenWidth / 2,
                y: screenHeight / 2 - 5
            )
        )

        crosshair.line(
            to: NSPoint(
                x: screenWidth / 2,
                y: screenHeight / 2 + 5
            )
        )

        crosshair.stroke()


        drawMinimap()
    }


    // ========================================================
    // SPRITE RENDERER
    // ========================================================

    func drawEnemies(
        screenWidth: CGFloat,
        screenHeight: CGFloat,
        projectionPlane: CGFloat,
        rayCount: Int,
        zBuffer: [Double]
    ) {

        // Draw far enemies first.
        //
        // This matters when two sprites overlap.

        let sortedEnemies =
            enemies.sorted {

                let dx1 =
                    $0.x - playerX

                let dy1 =
                    $0.y - playerY


                let dx2 =
                    $1.x - playerX

                let dy2 =
                    $1.y - playerY


                return
                    dx1 * dx1 + dy1 * dy1
                    >
                    dx2 * dx2 + dy2 * dy2
            }


        for enemy in sortedEnemies {

            let dx =
                enemy.x - playerX

            let dy =
                enemy.y - playerY


            let distance =
                sqrt(dx * dx + dy * dy)


            let enemyAngle =
                atan2(dy, dx)


            var relativeAngle =
                enemyAngle - playerAngle


            // Keep angle between -π and +π.

            while relativeAngle > Double.pi {
                relativeAngle -= Double.pi * 2
            }

	   while relativeAngle < -Double.pi {
    		relativeAngle += Double.pi * 2
	   }

            // Ignore things behind us.

            if abs(relativeAngle) >
                fieldOfView / 2 + 0.4 {

                continue
            }


            // Perpendicular depth.
            //
            // This is directly comparable with the
            // wall Z-buffer.

            let depth =
                distance * cos(relativeAngle)


            if depth <= 0.05 {
                continue
            }


            // ------------------------------------------------
            // Project sprite position
            // ------------------------------------------------

            let screenX =
                screenWidth / 2
                + CGFloat(tan(relativeAngle))
                * projectionPlane


            let spriteHeight =
                projectionPlane /
                CGFloat(depth)
                * 0.90


            let spriteWidth =
                spriteHeight * 0.55


            let left =
                screenX - spriteWidth / 2

            let right =
                screenX + spriteWidth / 2


            // Center enemy vertically around horizon.

            let centerY =
                screenHeight / 2


            // ------------------------------------------------
            // Distance darkening
            // ------------------------------------------------

            let shade =
                max(
                    CGFloat(0.30),
                    CGFloat(
                        1.0 /
                        (1.0 + depth * 0.10)
                    )
                )


            let bodyColor =
                NSColor(
                    calibratedRed:
                        enemy.red * shade,

                    green:
                        enemy.green * shade,

                    blue:
                        enemy.blue * shade,

                    alpha: 1
                )


            let headColor =
                NSColor(
                    calibratedRed:
                        min(1, enemy.red * shade * 1.15),

                    green:
                        min(1, enemy.green * shade * 1.15),

                    blue:
                        min(1, enemy.blue * shade * 1.15),

                    alpha: 1
                )


            // ------------------------------------------------
            // Draw sprite one vertical strip at a time.
            //
            // This allows each part to be tested against
            // the wall Z-buffer.
            // ------------------------------------------------

            let startX =
                max(0, Int(floor(left)))

            let endX =
                min(
                    Int(screenWidth) - 1,
                    Int(ceil(right))
                )


            if startX > endX {
                continue
            }


            for pixelX in startX...endX {

                // Which wall ray corresponds to this pixel?

                var rayIndex =
                    Int(
                        Double(pixelX) /
                        Double(screenWidth)
                        * Double(rayCount)
                    )


                rayIndex =
                    max(
                        0,
                        min(rayCount - 1, rayIndex)
                    )


                // Wall in front of enemy?
                //
                // Don't draw this sprite strip.

                if depth >= zBuffer[rayIndex] {
                    continue
                }


                // Horizontal position through sprite:
                //
                // -1 = far left
                //  0 = center
                // +1 = far right

                let normalizedX =
                    (
                        CGFloat(pixelX)
                        - screenX
                    )
                    /
                    (spriteWidth / 2)


                let absoluteX =
                    abs(normalizedX)


                // --------------------------------------------
                // Body
                // --------------------------------------------

                if absoluteX < 0.80 {

                    bodyColor.setFill()


                    let bodyBottom =
                        centerY
                        - spriteHeight * 0.40


                    let bodyTop =
                        centerY
                        + spriteHeight * 0.14


                    NSRect(
                        x: CGFloat(pixelX),
                        y: bodyBottom,
                        width: 1.5,
                        height:
                            bodyTop - bodyBottom
                    ).fill()
                }


                // --------------------------------------------
                // Head
                // --------------------------------------------

                if absoluteX < 0.50 {

                    headColor.setFill()


                    let headBottom =
                        centerY
                        + spriteHeight * 0.10


                    let headTop =
                        centerY
                        + spriteHeight * 0.40


                    NSRect(
                        x: CGFloat(pixelX),
                        y: headBottom,
                        width: 1.5,
                        height:
                            headTop - headBottom
                    ).fill()
                }


                // --------------------------------------------
                // Legs
                // --------------------------------------------

                if absoluteX > 0.15 &&
                   absoluteX < 0.65 {

                    bodyColor.setFill()


                    let legBottom =
                        centerY
                        - spriteHeight * 0.50


                    let legTop =
                        centerY
                        - spriteHeight * 0.30


                    NSRect(
                        x: CGFloat(pixelX),
                        y: legBottom,
                        width: 1.5,
                        height:
                            legTop - legBottom
                    ).fill()
                }


                // --------------------------------------------
                // Eyes
                // --------------------------------------------

                if (
                    normalizedX > -0.32 &&
                    normalizedX < -0.16
                ) ||
                (
                    normalizedX > 0.16 &&
                    normalizedX < 0.32
                ) {

                    NSColor.black.setFill()


                    NSRect(
                        x: CGFloat(pixelX),
                        y:
                            centerY
                            + spriteHeight * 0.29,
                        width: 1.5,
                        height:
                            max(
                                1,
                                spriteHeight * 0.035
                            )
                    ).fill()
                }
            }
        }
    }


    // ========================================================
    // MINIMAP
    // ========================================================

    func drawMinimap() {

        let scale: CGFloat = 12
        let padding: CGFloat = 12

        let screenHeight =
            bounds.height


        // ----------------------------------------------------
        // Map cells
        // ----------------------------------------------------

        for y in 0..<mapHeight {

            for x in 0..<mapWidth {

                let tile =
                    level[y][x]


                let rect =
                    NSRect(
                        x:
                            padding
                            + CGFloat(x) * scale,

                        y:
                            screenHeight
                            - padding
                            - CGFloat(y + 1) * scale,

                        width: scale,
                        height: scale
                    )


                switch tile {

                case "1":

                    NSColor(
                        calibratedRed: 0.20,
                        green: 0.45,
                        blue: 1.00,
                        alpha: 0.9
                    ).setFill()


                case "2":

                    NSColor(
                        calibratedRed: 0.15,
                        green: 0.90,
                        blue: 0.35,
                        alpha: 0.9
                    ).setFill()


                case "3":

                    NSColor(
                        calibratedRed: 1.00,
                        green: 0.45,
                        blue: 0.12,
                        alpha: 0.9
                    ).setFill()


                default:

                    NSColor(
                        calibratedWhite: 0.05,
                        alpha: 0.75
                    ).setFill()
                }


                rect.fill()
            }
        }


        // ----------------------------------------------------
        // Enemies
        // ----------------------------------------------------

        for enemy in enemies {

            let ex =
                padding
                + CGFloat(enemy.x) * scale


            let ey =
                screenHeight
                - padding
                - CGFloat(enemy.y) * scale


            NSColor(
                calibratedRed: enemy.red,
                green: enemy.green,
                blue: enemy.blue,
                alpha: 1
            ).setFill()


            NSBezierPath(
                ovalIn: NSRect(
                    x: ex - 3,
                    y: ey - 3,
                    width: 6,
                    height: 6
                )
            ).fill()
        }


        // ----------------------------------------------------
        // Player
        // ----------------------------------------------------

        let px =
            padding
            + CGFloat(playerX) * scale


        let py =
            screenHeight
            - padding
            - CGFloat(playerY) * scale


        NSColor.white.setFill()


        NSBezierPath(
            ovalIn: NSRect(
                x: px - 3,
                y: py - 3,
                width: 6,
                height: 6
            )
        ).fill()


        // ----------------------------------------------------
        // Facing direction
        // ----------------------------------------------------

        let directionLength: CGFloat = 15


        let direction =
            NSBezierPath()


        direction.move(
            to: NSPoint(
                x: px,
                y: py
            )
        )


        direction.line(
            to: NSPoint(
                x:
                    px
                    + CGFloat(cos(playerAngle))
                    * directionLength,

                y:
                    py
                    - CGFloat(sin(playerAngle))
                    * directionLength
            )
        )


        NSColor.white.setStroke()

        direction.lineWidth = 2

        direction.stroke()
    }
}


// ============================================================
// APPLICATION
// ============================================================

final class AppDelegate:
    NSObject,
    NSApplicationDelegate {

    func applicationShouldTerminateAfterLastWindowClosed(
        _ sender: NSApplication
    ) -> Bool {

        true
    }
}


let app =
    NSApplication.shared


app.setActivationPolicy(.regular)


let delegate =
    AppDelegate()


app.delegate =
    delegate


let window =
    NSWindow(
        contentRect: NSRect(
            x: 0,
            y: 0,
            width: 800,
            height: 600
        ),

        styleMask: [
            .titled,
            .closable,
            .miniaturizable,
            .resizable
        ],

        backing: .buffered,

        defer: false
    )


window.title =
    "Tiny Swift Raycaster"


window.center()


let gameView =
    GameView(
        frame: window.contentView!.bounds
    )


gameView.autoresizingMask = [
    .width,
    .height
]


window.contentView =
    gameView


window.makeKeyAndOrderFront(nil)

window.makeFirstResponder(gameView)

app.activate(ignoringOtherApps: true)

app.run()
