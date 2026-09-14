import AppKit

// ============================================================
// LEVEL
// ============================================================

let mapWidth = 50
let mapHeight = 40

func makeLevel() -> [[Character]] {
    var map = Array(
        repeating: Array(repeating: Character("."), count: mapWidth),
        count: mapHeight
    )

    // Outer walls.
    for x in 0..<mapWidth {
        map[0][x] = "1"
        map[mapHeight - 1][x] = "1"
    }

    for y in 0..<mapHeight {
        map[y][0] = "1"
        map[y][mapWidth - 1] = "1"
    }

    // --------------------------------------------------------
    // Interior walls
    // --------------------------------------------------------

    for x in 5...20 {
        if x != 11 && x != 12 {
            map[7][x] = "2"
        }
    }

    for x in 25...43 {
        if x != 34 {
            map[6][x] = "3"
        }
    }

    for y in 8...20 {
        if y != 14 {
            map[y][15] = "1"
        }
    }

    for y in 4...17 {
        if y != 10 {
            map[y][28] = "2"
        }
    }

    for x in 4...13 {
        if x != 8 {
            map[22][x] = "3"
        }
    }

    for x in 18...34 {
        if x != 25 && x != 26 {
            map[25][x] = "1"
        }
    }

    for x in 36...46 {
        if x != 41 {
            map[20][x] = "2"
        }
    }

    for y in 19...34 {
        if y != 27 {
            map[y][38] = "3"
        }
    }

    for y in 24...36 {
        if y != 31 {
            map[y][10] = "2"
        }
    }

    for x in 14...28 {
        if x != 20 {
            map[34][x] = "1"
        }
    }

    // Small room.
    for x in 31...43 {
        map[30][x] = "3"
    }

    for x in 31...43 {
        map[36][x] = "3"
    }

    for y in 30...36 {
        map[y][31] = "3"
        map[y][43] = "3"
    }

    // Doorways into room.
    map[30][36] = "."
    map[30][37] = "."
    map[36][39] = "."

    // Another little structure.
    for x in 18...23 {
        map[14][x] = "2"
        map[19][x] = "2"
    }

    for y in 14...19 {
        map[y][18] = "2"
        map[y][23] = "2"
    }

    map[19][20] = "."
    map[19][21] = "."

    return map
}

let level = makeLevel()


// ============================================================
// DATA TYPES
// ============================================================

struct Enemy {
    var x: Double
    var y: Double

    var red: CGFloat
    var green: CGFloat
    var blue: CGFloat

    var dying = false
    var deathAge = 0.0
}


struct WallImpact {
    var x: Double
    var y: Double
    var age = 0.0
}


struct RayHit {
    let distance: Double
    let wallType: Character
    let side: Int

    let x: Double
    let y: Double
}


// ============================================================
// GAME
// ============================================================

final class GameView: NSView {

    // --------------------------------------------------------
    // Player
    // --------------------------------------------------------

    var playerX = 3.5
    var playerY = 3.5

    var playerAngle = 0.0

    let fieldOfView = Double.pi / 3.0

    let moveSpeed = 3.2
    let turnSpeed = 2.2

    let playerRadius = 0.20
    let enemyRadius = 0.27


    // --------------------------------------------------------
    // Enemies
    // --------------------------------------------------------

    var enemies: [Enemy] = [
        Enemy(
            x: 12.5,
            y: 4.5,
            red: 0.9,
            green: 0.15,
            blue: 0.15
        ),

        Enemy(
            x: 21.5,
            y: 11.5,
            red: 0.75,
            green: 0.20,
            blue: 0.9
        ),

        Enemy(
            x: 34.5,
            y: 12.5,
            red: 0.9,
            green: 0.65,
            blue: 0.1
        ),

        Enemy(
            x: 7.5,
            y: 28.5,
            red: 0.15,
            green: 0.8,
            blue: 0.8
        ),

        Enemy(
            x: 41.5,
            y: 33.5,
            red: 0.9,
            green: 0.3,
            blue: 0.5
        )
    ]


    // --------------------------------------------------------
    // Effects
    // --------------------------------------------------------

    var wallImpacts: [WallImpact] = []

    var recoil = 0.0
    var muzzleFlashTimer = 0.0
    var hitMarkerTimer = 0.0


    // --------------------------------------------------------
    // Head bob
    // --------------------------------------------------------

    var bobPhase = 0.0
    var bobStrength = 0.0

    var cameraBob: CGFloat = 0
    var gunBobX: CGFloat = 0


    // --------------------------------------------------------
    // Input
    // --------------------------------------------------------

    var pressedKeys = Set<UInt16>()


    // --------------------------------------------------------
    // Loop
    // --------------------------------------------------------

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

        // SPACE
        if event.keyCode == 49 && !event.isARepeat {
            shoot()
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
        // Turning
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
        // Walking
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


        var actuallyMoved = false


        if movement != 0 {

            let dx =
                cos(playerAngle) * movement

            let dy =
                sin(playerAngle) * movement


            let newX =
                playerX + dx

            if canStand(
                x: newX,
                y: playerY
            ) {
                playerX = newX
                actuallyMoved = true
            }


            let newY =
                playerY + dy

            if canStand(
                x: playerX,
                y: newY
            ) {
                playerY = newY
                actuallyMoved = true
            }
        }


        // ====================================================
        // HEAD BOB
        // ====================================================

        if actuallyMoved {

            bobStrength =
                min(1.0, bobStrength + dt * 7.0)

            bobPhase += dt * 11.0

        } else {

            bobStrength =
                max(0.0, bobStrength - dt * 6.0)
        }


        cameraBob =
            CGFloat(
                sin(bobPhase)
                * 5.5
                * bobStrength
            )


        gunBobX =
            CGFloat(
                cos(bobPhase * 0.5)
                * 7.0
                * bobStrength
            )


        // ====================================================
        // GUN EFFECTS
        // ====================================================

        recoil =
            max(
                0,
                recoil - dt * 5.5
            )

        muzzleFlashTimer =
            max(
                0,
                muzzleFlashTimer - dt
            )

        hitMarkerTimer =
            max(
                0,
                hitMarkerTimer - dt
            )


        // ====================================================
        // WALL IMPACTS
        // ====================================================

        for i in wallImpacts.indices {
            wallImpacts[i].age += dt
        }

        wallImpacts.removeAll {
            $0.age > 3.0
        }


        // ====================================================
        // ENEMY DEATHS
        // ====================================================

        var respawnCount = 0

        for i in enemies.indices.reversed() {

            if enemies[i].dying {

                enemies[i].deathAge += dt

                if enemies[i].deathAge > 0.48 {

                    enemies.remove(at: i)
                    respawnCount += 1
                }
            }
        }


        for _ in 0..<respawnCount {
            spawnEnemy()
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


            let minimumDistance =
                playerRadius + enemyRadius


            if dx * dx + dy * dy <
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


        if wallAt(
            x: x - r,
            y: y - r
        ) != nil {
            return false
        }

        if wallAt(
            x: x + r,
            y: y - r
        ) != nil {
            return false
        }

        if wallAt(
            x: x - r,
            y: y + r
        ) != nil {
            return false
        }

        if wallAt(
            x: x + r,
            y: y + r
        ) != nil {
            return false
        }


        if collidesWithEnemy(
            x: x,
            y: y
        ) {
            return false
        }


        return true
    }


    // ========================================================
    // RAYCAST
    // ========================================================

    func castRay(
        angle: Double
    ) -> RayHit {

        let rayDirX =
            cos(angle)

        let rayDirY =
            sin(angle)


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


        var side = 0

        var wallType: Character = "1"


        while true {

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

                break
            }


            let tile =
                level[mapY][mapX]


            if tile != "." {

                wallType = tile
                break
            }
        }


        let distance: Double

        if side == 0 {

            distance =
                sideDistX - deltaDistX

        } else {

            distance =
                sideDistY - deltaDistY
        }


        let hitX =
            playerX + rayDirX * distance

        let hitY =
            playerY + rayDirY * distance


        return RayHit(
            distance: distance,
            wallType: wallType,
            side: side,
            x: hitX,
            y: hitY
        )
    }


    // ========================================================
    // SHOOTING
    // ========================================================

    func shoot() {

        recoil = 1.0

        muzzleFlashTimer = 0.075


        let rayX =
            cos(playerAngle)

        let rayY =
            sin(playerAngle)


        // Nearest wall straight ahead.
        let wallHit =
            castRay(angle: playerAngle)


        var closestEnemyIndex: Int?
        var closestEnemyDistance =
            Double.infinity


        // ----------------------------------------------------
        // Ray vs enemy circles
        // ----------------------------------------------------

        for i in enemies.indices {

            if enemies[i].dying {
                continue
            }


            let dx =
                enemies[i].x - playerX

            let dy =
                enemies[i].y - playerY


            // Distance along firing ray.
            let projection =
                dx * rayX + dy * rayY


            if projection <= 0 {
                continue
            }


            // Squared perpendicular distance
            // from ray to enemy center.
            let centerDistanceSquared =
                dx * dx + dy * dy


            let perpendicularSquared =
                centerDistanceSquared
                - projection * projection


            let radiusSquared =
                enemyRadius * enemyRadius


            if perpendicularSquared >
                radiusSquared {

                continue
            }


            // Entry point into enemy circle.
            let inside =
                sqrt(
                    max(
                        0,
                        radiusSquared
                        - perpendicularSquared
                    )
                )


            let hitDistance =
                projection - inside


            // Enemy must be closer than wall.
            if hitDistance < wallHit.distance &&
               hitDistance < closestEnemyDistance {

                closestEnemyDistance =
                    hitDistance

                closestEnemyIndex = i
            }
        }


        // ----------------------------------------------------
        // Enemy hit
        // ----------------------------------------------------

        if let index = closestEnemyIndex {

            enemies[index].dying = true
            enemies[index].deathAge = 0

            hitMarkerTimer = 0.18

            return
        }


        // ----------------------------------------------------
        // Wall hit
        // ----------------------------------------------------

        wallImpacts.append(
            WallImpact(
                x: wallHit.x,
                y: wallHit.y
            )
        )
    }


    // ========================================================
    // RESPAWN
    // ========================================================

    func spawnEnemy() {

        for _ in 0..<500 {

            let tileX =
                Int.random(
                    in: 2..<(mapWidth - 2)
                )

            let tileY =
                Int.random(
                    in: 2..<(mapHeight - 2)
                )


            let x =
                Double(tileX) + 0.5

            let y =
                Double(tileY) + 0.5


            if wallAt(x: x, y: y) != nil {
                continue
            }


            // Don't spawn right beside player.
            let dx =
                x - playerX

            let dy =
                y - playerY


            if dx * dx + dy * dy < 25 {
                continue
            }


            var tooClose =
                false


            for enemy in enemies {

                let ex =
                    x - enemy.x

                let ey =
                    y - enemy.y


                if ex * ex + ey * ey < 2.0 {
                    tooClose = true
                    break
                }
            }


            if tooClose {
                continue
            }


            let colors: [
                (
                    CGFloat,
                    CGFloat,
                    CGFloat
                )
            ] = [

                (0.95, 0.18, 0.18),
                (0.72, 0.22, 0.95),
                (0.95, 0.65, 0.12),
                (0.15, 0.85, 0.75),
                (0.95, 0.25, 0.55)
            ]


            let color =
                colors.randomElement()!


            enemies.append(
                Enemy(
                    x: x,
                    y: y,
                    red: color.0,
                    green: color.1,
                    blue: color.2
                )
            )


            return
        }
    }


    // ========================================================
    // WALL COLOR
    // ========================================================

    func wallColor(
        type: Character,
        brightness: CGFloat
    ) -> NSColor {

        let b =
            max(
                0,
                min(1, brightness)
            )


        switch type {

        case "1":

            return NSColor(
                calibratedRed: 0.20 * b,
                green: 0.45 * b,
                blue: 1.00 * b,
                alpha: 1
            )


        case "2":

            return NSColor(
                calibratedRed: 0.15 * b,
                green: 0.90 * b,
                blue: 0.35 * b,
                alpha: 1
            )


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

    override func draw(
        _ dirtyRect: NSRect
    ) {

        let screenWidth =
            bounds.width

        let screenHeight =
            bounds.height


        let horizon =
            screenHeight / 2
            + cameraBob


        // ====================================================
        // CEILING
        // ====================================================

        NSColor(
            calibratedRed: 0.06,
            green: 0.07,
            blue: 0.10,
            alpha: 1
        ).setFill()


        NSRect(
            x: 0,
            y: horizon,
            width: screenWidth,
            height: screenHeight - horizon
        ).fill()


        // ====================================================
        // FLOOR
        // ====================================================

        NSColor(
            calibratedRed: 0.17,
            green: 0.15,
            blue: 0.13,
            alpha: 1
        ).setFill()


        NSRect(
            x: 0,
            y: 0,
            width: screenWidth,
            height: horizon
        ).fill()


        // ====================================================
        // WALLS
        // ====================================================

        let rayCount =
            max(
                240,
                Int(screenWidth / 2)
            )


        let sliceWidth =
            screenWidth
            / CGFloat(rayCount)


        let projectionPlane =
            (screenWidth / 2)
            /
            CGFloat(
                tan(fieldOfView / 2)
            )


        var zBuffer =
            [Double](
                repeating: 1e30,
                count: rayCount
            )


        for ray in 0..<rayCount {

            let amount =
                Double(ray)
                /
                Double(rayCount - 1)


            let rayAngle =
                playerAngle
                - fieldOfView / 2
                + amount * fieldOfView


            let hit =
                castRay(
                    angle: rayAngle
                )


            let correctedDistance =
                max(
                    hit.distance
                    *
                    cos(
                        rayAngle
                        - playerAngle
                    ),

                    0.001
                )


            zBuffer[ray] =
                correctedDistance


            let wallHeight =
                projectionPlane
                /
                CGFloat(
                    correctedDistance
                )


            let wallY =
                horizon
                - wallHeight / 2


            var brightness =
                CGFloat(
                    1.0
                    /
                    (
                        1.0
                        +
                        correctedDistance
                        * 0.10
                    )
                )


            brightness =
                max(
                    0.17,
                    brightness
                )


            if hit.side == 1 {
                brightness *= 0.70
            }


            wallColor(
                type: hit.wallType,
                brightness: brightness
            ).setFill()


            NSRect(
                x:
                    CGFloat(ray)
                    * sliceWidth,

                y:
                    wallY,

                width:
                    sliceWidth + 1,

                height:
                    wallHeight
            ).fill()
        }


        // ====================================================
        // ENEMIES
        // ====================================================

        drawEnemies(
            screenWidth: screenWidth,
            screenHeight: screenHeight,
            horizon: horizon,
            projectionPlane: projectionPlane,
            rayCount: rayCount,
            zBuffer: zBuffer
        )


        // ====================================================
        // WALL IMPACTS
        // ====================================================

        drawWallImpacts(
            screenWidth: screenWidth,
            horizon: horizon,
            projectionPlane: projectionPlane,
            rayCount: rayCount,
            zBuffer: zBuffer
        )


        // ====================================================
        // CROSSHAIR
        // ====================================================

        drawCrosshair(
            screenWidth: screenWidth,
            screenHeight: screenHeight
        )


        // ====================================================
        // GUN
        // ====================================================

        drawGun(
            screenWidth: screenWidth
        )


        // ====================================================
        // MINIMAP
        // ====================================================

        drawMinimap()
    }


    // ========================================================
    // ENEMIES
    // ========================================================

    func drawEnemies(
        screenWidth: CGFloat,
        screenHeight: CGFloat,
        horizon: CGFloat,
        projectionPlane: CGFloat,
        rayCount: Int,
        zBuffer: [Double]
    ) {

        let sorted =
            enemies.sorted {

                let ax =
                    $0.x - playerX

                let ay =
                    $0.y - playerY


                let bx =
                    $1.x - playerX

                let by =
                    $1.y - playerY


                return
                    ax * ax + ay * ay
                    >
                    bx * bx + by * by
            }


        for enemy in sorted {

            let dx =
                enemy.x - playerX

            let dy =
                enemy.y - playerY


            let distance =
                sqrt(
                    dx * dx + dy * dy
                )


            var angle =
                atan2(dy, dx)
                - playerAngle


            while angle > Double.pi {
                angle -= Double.pi * 2
            }

            while angle < -Double.pi {
                angle += Double.pi * 2
            }


            if abs(angle) >
                fieldOfView / 2 + 0.3 {

                continue
            }


            let depth =
                distance
                * cos(angle)


            if depth <= 0.05 {
                continue
            }


            let screenX =
                screenWidth / 2
                +
                CGFloat(
                    tan(angle)
                )
                * projectionPlane


            let spriteHeight =
                projectionPlane
                /
                CGFloat(depth)
                * 0.95


            let spriteWidth =
                spriteHeight * 0.58


            let left =
                screenX
                - spriteWidth / 2


            let right =
                screenX
                + spriteWidth / 2


            let startX =
                max(
                    0,
                    Int(floor(left))
                )


            let endX =
                min(
                    Int(screenWidth) - 1,
                    Int(ceil(right))
                )


            if startX > endX {
                continue
            }


            // ------------------------------------------------
            // Death blink
            // ------------------------------------------------

            let flashWhite =
                enemy.dying
                &&
                Int(
                    enemy.deathAge * 28
                ) % 2 == 0


            let shade =
                max(
                    CGFloat(0.28),
                    CGFloat(
                        1.0
                        /
                        (
                            1.0
                            +
                            depth * 0.08
                        )
                    )
                )


            let bodyColor: NSColor


            if flashWhite {

                bodyColor =
                    NSColor.white

            } else {

                bodyColor =
                    NSColor(
                        calibratedRed:
                            enemy.red * shade,

                        green:
                            enemy.green * shade,

                        blue:
                            enemy.blue * shade,

                        alpha: 1
                    )
            }


            for pixelX in startX...endX {

                var rayIndex =
                    Int(
                        Double(pixelX)
                        /
                        Double(screenWidth)
                        *
                        Double(rayCount)
                    )


                rayIndex =
                    max(
                        0,
                        min(
                            rayCount - 1,
                            rayIndex
                        )
                    )


                if depth >=
                    zBuffer[rayIndex] {

                    continue
                }


                let normalizedX =
                    (
                        CGFloat(pixelX)
                        - screenX
                    )
                    /
                    (spriteWidth / 2)


                let ax =
                    abs(normalizedX)


                // Body
                if ax < 0.78 {

                    bodyColor.setFill()


                    NSRect(
                        x: CGFloat(pixelX),
                        y:
                            horizon
                            - spriteHeight * 0.40,

                        width: 1.5,

                        height:
                            spriteHeight * 0.53
                    ).fill()
                }


                // Head
                if ax < 0.48 {

                    bodyColor.setFill()


                    NSRect(
                        x: CGFloat(pixelX),
                        y:
                            horizon
                            + spriteHeight * 0.10,

                        width: 1.5,

                        height:
                            spriteHeight * 0.28
                    ).fill()
                }


                // Legs
                if ax > 0.15 &&
                   ax < 0.62 {

                    bodyColor.setFill()


                    NSRect(
                        x: CGFloat(pixelX),
                        y:
                            horizon
                            - spriteHeight * 0.50,

                        width: 1.5,

                        height:
                            spriteHeight * 0.14
                    ).fill()
                }


                // Eyes
                if !flashWhite {

                    if (
                        normalizedX > -0.32
                        &&
                        normalizedX < -0.16
                    )
                    ||
                    (
                        normalizedX > 0.16
                        &&
                        normalizedX < 0.32
                    ) {

                        NSColor.black.setFill()


                        NSRect(
                            x:
                                CGFloat(pixelX),

                            y:
                                horizon
                                +
                                spriteHeight
                                * 0.28,

                            width: 1.5,

                            height:
                                max(
                                    1,
                                    spriteHeight
                                    * 0.035
                                )
                        ).fill()
                    }
                }
            }
        }
    }


    // ========================================================
    // WALL IMPACT MARKS
    // ========================================================

    func drawWallImpacts(
        screenWidth: CGFloat,
        horizon: CGFloat,
        projectionPlane: CGFloat,
        rayCount: Int,
        zBuffer: [Double]
    ) {

        for impact in wallImpacts {

            let dx =
                impact.x - playerX

            let dy =
                impact.y - playerY


            let distance =
                sqrt(
                    dx * dx + dy * dy
                )


            var angle =
                atan2(dy, dx)
                - playerAngle


            while angle > Double.pi {
                angle -= Double.pi * 2
            }

            while angle < -Double.pi {
                angle += Double.pi * 2
            }


            if abs(angle) >
                fieldOfView / 2 {

                continue
            }


            let depth =
                distance
                * cos(angle)


            if depth <= 0 {
                continue
            }


            let screenX =
                screenWidth / 2
                +
                CGFloat(
                    tan(angle)
                )
                * projectionPlane


            var rayIndex =
                Int(
                    Double(screenX)
                    /
                    Double(screenWidth)
                    *
                    Double(rayCount)
                )


            rayIndex =
                max(
                    0,
                    min(
                        rayCount - 1,
                        rayIndex
                    )
                )


            // Since the mark lies ON the wall,
            // allow a small tolerance.
            if depth >
                zBuffer[rayIndex] + 0.18 {

                continue
            }


            let fade =
                max(
                    CGFloat(0),
                    CGFloat(
                        1.0
                        - impact.age / 3.0
                    )
                )


            let size =
                max(
                    CGFloat(2),
                    CGFloat(
                        8.0 / depth
                    )
                )


            NSColor(
                calibratedRed: 1.0,
                green: 0.75,
                blue: 0.15,
                alpha: fade
            ).setFill()


            NSBezierPath(
                ovalIn: NSRect(
                    x:
                        screenX
                        - size / 2,

                    y:
                        horizon
                        - size / 2,

                    width: size,
                    height: size
                )
            ).fill()
        }
    }


    // ========================================================
    // CROSSHAIR
    // ========================================================

    func drawCrosshair(
        screenWidth: CGFloat,
        screenHeight: CGFloat
    ) {

        let centerX =
            screenWidth / 2

        let centerY =
            screenHeight / 2


        if hitMarkerTimer > 0 {

            NSColor.white.setStroke()

            let hit =
                NSBezierPath()

            hit.lineWidth = 2


            hit.move(
                to: NSPoint(
                    x: centerX - 8,
                    y: centerY - 8
                )
            )

            hit.line(
                to: NSPoint(
                    x: centerX - 3,
                    y: centerY - 3
                )
            )


            hit.move(
                to: NSPoint(
                    x: centerX + 8,
                    y: centerY - 8
                )
            )

            hit.line(
                to: NSPoint(
                    x: centerX + 3,
                    y: centerY - 3
                )
            )


            hit.move(
                to: NSPoint(
                    x: centerX - 8,
                    y: centerY + 8
                )
            )

            hit.line(
                to: NSPoint(
                    x: centerX - 3,
                    y: centerY + 3
                )
            )


            hit.move(
                to: NSPoint(
                    x: centerX + 8,
                    y: centerY + 8
                )
            )

            hit.line(
                to: NSPoint(
                    x: centerX + 3,
                    y: centerY + 3
                )
            )


            hit.stroke()

        } else {

            NSColor.white
                .withAlphaComponent(0.5)
                .setStroke()


            let crosshair =
                NSBezierPath()

            crosshair.lineWidth = 1


            crosshair.move(
                to: NSPoint(
                    x: centerX - 4,
                    y: centerY
                )
            )

            crosshair.line(
                to: NSPoint(
                    x: centerX + 4,
                    y: centerY
                )
            )


            crosshair.move(
                to: NSPoint(
                    x: centerX,
                    y: centerY - 4
                )
            )

            crosshair.line(
                to: NSPoint(
                    x: centerX,
                    y: centerY + 4
                )
            )


            crosshair.stroke()
        }
    }


    // ========================================================
    // GUN
    // ========================================================

    func drawGun(
        screenWidth: CGFloat
    ) {

        let recoilY =
            CGFloat(recoil) * 18


        let x =
            screenWidth / 2
            + gunBobX


        let y =
            CGFloat(14)
            + recoilY


        // Hand.
        NSColor(
            calibratedRed: 0.58,
            green: 0.40,
            blue: 0.28,
            alpha: 1
        ).setFill()


        NSBezierPath(
            roundedRect: NSRect(
                x: x - 18,
                y: y,
                width: 36,
                height: 60
            ),
            xRadius: 8,
            yRadius: 8
        ).fill()


        // Gun body.
        NSColor(
            calibratedWhite: 0.18,
            alpha: 1
        ).setFill()


        NSBezierPath(
            roundedRect: NSRect(
                x: x - 31,
                y: y + 45,
                width: 62,
                height: 37
            ),
            xRadius: 5,
            yRadius: 5
        ).fill()


        // Barrel.
        NSColor(
            calibratedWhite: 0.08,
            alpha: 1
        ).setFill()


        NSRect(
            x: x - 12,
            y: y + 78,
            width: 24,
            height: 40
        ).fill()


        // Barrel opening.
        NSColor.black.setFill()


        NSBezierPath(
            ovalIn: NSRect(
                x: x - 8,
                y: y + 108,
                width: 16,
                height: 10
            )
        ).fill()


        // ----------------------------------------------------
        // Muzzle flash
        // ----------------------------------------------------

        if muzzleFlashTimer > 0 {

            NSColor(
                calibratedRed: 1.0,
                green: 0.75,
                blue: 0.15,
                alpha: 0.95
            ).setFill()


            let flash =
                NSBezierPath()


            flash.move(
                to: NSPoint(
                    x: x,
                    y: y + 120
                )
            )


            flash.line(
                to: NSPoint(
                    x: x - 16,
                    y: y + 148
                )
            )


            flash.line(
                to: NSPoint(
                    x: x,
                    y: y + 140
                )
            )


            flash.line(
                to: NSPoint(
                    x: x + 16,
                    y: y + 148
                )
            )


            flash.close()

            flash.fill()
        }
    }


    // ========================================================
    // MINIMAP
    // ========================================================

    func drawMinimap() {

        // Bigger map means smaller cells.
        let scale: CGFloat = 4
        let padding: CGFloat = 10

        let screenHeight =
            bounds.height


        // Background.
        NSColor.black
            .withAlphaComponent(0.55)
            .setFill()


        NSRect(
            x: padding - 4,
            y:
                screenHeight
                - padding
                - CGFloat(mapHeight)
                * scale
                - 4,

            width:
                CGFloat(mapWidth)
                * scale + 8,

            height:
                CGFloat(mapHeight)
                * scale + 8
        ).fill()


        for y in 0..<mapHeight {

            for x in 0..<mapWidth {

                let tile =
                    level[y][x]


                if tile == "." {
                    continue
                }


                switch tile {

                case "1":

                    NSColor(
                        calibratedRed: 0.2,
                        green: 0.45,
                        blue: 1.0,
                        alpha: 0.85
                    ).setFill()


                case "2":

                    NSColor(
                        calibratedRed: 0.15,
                        green: 0.9,
                        blue: 0.35,
                        alpha: 0.85
                    ).setFill()


                case "3":

                    NSColor(
                        calibratedRed: 1.0,
                        green: 0.45,
                        blue: 0.12,
                        alpha: 0.85
                    ).setFill()


                default:

                    NSColor.white.setFill()
                }


                NSRect(
                    x:
                        padding
                        + CGFloat(x)
                        * scale,

                    y:
                        screenHeight
                        - padding
                        - CGFloat(y + 1)
                        * scale,

                    width: scale,
                    height: scale
                ).fill()
            }
        }


        // Enemies.
        for enemy in enemies {

            NSColor.systemRed.setFill()


            let ex =
                padding
                +
                CGFloat(enemy.x)
                * scale


            let ey =
                screenHeight
                - padding
                -
                CGFloat(enemy.y)
                * scale


            NSBezierPath(
                ovalIn: NSRect(
                    x: ex - 2,
                    y: ey - 2,
                    width: 4,
                    height: 4
                )
            ).fill()
        }


        // Player.
        let px =
            padding
            +
            CGFloat(playerX)
            * scale


        let py =
            screenHeight
            - padding
            -
            CGFloat(playerY)
            * scale


        NSColor.white.setFill()


        NSBezierPath(
            ovalIn: NSRect(
                x: px - 2.5,
                y: py - 2.5,
                width: 5,
                height: 5
            )
        ).fill()


        // Facing direction.
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
                    +
                    CGFloat(
                        cos(playerAngle)
                    )
                    * 10,

                y:
                    py
                    -
                    CGFloat(
                        sin(playerAngle)
                    )
                    * 10
            )
        )


        NSColor.white.setStroke()

        direction.lineWidth = 1

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
            width: 1000,
            height: 700
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

app.activate(
    ignoringOtherApps: true
)

app.run()
