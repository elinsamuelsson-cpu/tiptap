import SpriteKit

class RabbitNode: SKNode {

    // MARK: - State

    enum State {
        case hidden, earsGrowing, earsIdle, rising, dancing, rolling, rollIdle, pinballing
    }

    private(set) var state: State = .hidden

    // Textures
    private var earsTexture: SKTexture!
    private var rise1Texture: SKTexture!
    private var rise2Texture: SKTexture!
    private var danceFrames: [SKTexture] = []
    private var rollFrames: [SKTexture] = []

    // Nodes
    private var currentSprite: SKSpriteNode?
    private var earsCropNode: SKCropNode?
    private var ballTrailEmitter: BallTrailEmitter?
    private var lastSpritePosition: CGPoint = .zero

    // Callbacks
    var onEarsComplete: (() -> Void)?
    var onDanceStarted: (() -> Void)?
    var onRollComplete: (() -> Void)?
    var onPinballComplete: (() -> Void)?

    // MARK: - Positions

    private let earsPosition = CGPoint(x: 745, y: 738)
    private let earsSize = CGSize(width: 448, height: 502)

    private let dancePosition = CGPoint(x: 815, y: 1307)
    private let danceSize = CGSize(width: 691, height: 1070)

    // Ears settle position (where they rest after grow)
    private let earsSettleY: CGFloat = 4

    // MARK: - Init

    override init() {
        super.init()
        let allEars = SpriteLoader.loadFrames(baseName: "rabbit_ears_grow", count: 3)
        earsTexture = allEars[2]
        let riseFrames = SpriteLoader.loadFrames(baseName: "rabbit_rise", count: 2)
        rise2Texture = riseFrames[1]
        danceFrames = SpriteLoader.loadFrames(baseName: "rabbit_dance", count: 5)
        rollFrames = SpriteLoader.loadFrames(baseName: "rabbit_roll", count: 6)
        rise1Texture = rollFrames[5]
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Ears Grow (mask reveal with spring bounce)

    func startEarsGrow() {
        guard state == .hidden else { return }
        state = .earsGrowing
        currentSprite?.removeFromParent()
        earsCropNode?.removeFromParent()

        let crop = SKCropNode()
        crop.position = earsPosition
        crop.zPosition = 15
        addChild(crop)
        earsCropNode = crop

        let mask = SKSpriteNode(color: .white, size: earsSize)
        crop.maskNode = mask

        let sprite = SKSpriteNode(texture: earsTexture, size: earsSize)
        sprite.name = "rabbitEars"
        sprite.position = CGPoint(x: 0, y: -earsSize.height)
        crop.addChild(sprite)
        currentSprite = sprite

        let rise = SKAction.moveTo(y: earsSettleY + 5, duration: 0.5)
        rise.timingMode = .easeOut
        let back = SKAction.moveTo(y: earsSettleY - 5, duration: 0.15)
        back.timingMode = .easeInEaseOut
        let bounce = SKAction.moveTo(y: earsSettleY + 2, duration: 0.1)
        bounce.timingMode = .easeInEaseOut
        let settle = SKAction.moveTo(y: earsSettleY, duration: 0.08)
        settle.timingMode = .easeInEaseOut

        let done = SKAction.run { [weak self] in
            self?.state = .earsIdle
            self?.startEarsBreathing()
            self?.onEarsComplete?()
        }

        sprite.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.3),
            rise, back, bounce, settle,
            done
        ]), withKey: "earsGrow")
    }

    // MARK: - Ears Breathing

    private func startEarsBreathing() {
        guard let crop = earsCropNode else { return }

        let quickUp = SKAction.scale(to: 1.02, duration: 0.12)
        quickUp.timingMode = .easeOut
        let quickDown = SKAction.scale(to: 0.9925, duration: 0.1)
        quickDown.timingMode = .easeIn
        let settle = SKAction.scale(to: 1.0, duration: 0.15)
        settle.timingMode = .easeInEaseOut
        let quickPulse = SKAction.sequence([quickUp, quickDown, settle])

        let scaleUp = SKAction.scale(to: 1.035, duration: 1.8)
        scaleUp.timingMode = .easeInEaseOut
        let scaleDown = SKAction.scale(to: 1.0, duration: 1.8)
        scaleDown.timingMode = .easeInEaseOut
        let breathe = SKAction.repeatForever(SKAction.sequence([scaleUp, scaleDown]))

        crop.run(SKAction.sequence([quickPulse, breathe]), withKey: "idle")
    }

    // MARK: - Rise Sequence (Tap 2: ears down, ball rises via mask, fades to rise1→rise2→dance)

    func startRiseSequence() {
        guard state == .earsIdle, let earSprite = currentSprite else { return }
        state = .rising

        // Stop breathing
        earsCropNode?.removeAction(forKey: "idle")
        earsCropNode?.setScale(1.0)

        // -- Step 1: Ears slide back down (reverse of grow) --
        let slideDown = SKAction.moveTo(y: -earsSize.height, duration: 0.35)
        slideDown.timingMode = .easeInEaseOut

        let cleanupEars = SKAction.run { [weak self] in
            guard let self else { return }
            self.earsCropNode?.removeFromParent()
            self.earsCropNode = nil
            self.currentSprite = nil

            // -- Step 2: Ball rises from hat via mask --
            self.startBallRise()
        }

        earSprite.run(SKAction.sequence([
            slideDown,
            cleanupEars
        ]), withKey: "earsDown")
    }

    // MARK: - Rise (rise_01 grows out of hat via mask, fades to rise_02, then dance)

    private func startBallRise() {
        // Crop node at dance position for mask
        let crop = SKCropNode()
        crop.position = dancePosition
        crop.zPosition = 15
        addChild(crop)

        // Tall mask from hat top to well above
        let maskBottom: CGFloat = 487 - dancePosition.y
        let maskTop: CGFloat = 2100 - dancePosition.y
        let maskHeight = maskTop - maskBottom
        let maskCenterY = (maskBottom + maskTop) / 2
        let mask = SKSpriteNode(color: .white, size: CGSize(width: 1200, height: maskHeight))
        mask.position = CGPoint(x: 0, y: maskCenterY)
        crop.maskNode = mask

        // rise_01: starts small at hat level
        let startY = earsPosition.y - dancePosition.y
        let riseSpr = SKSpriteNode(texture: rise1Texture, size: danceSize)
        riseSpr.position = CGPoint(x: 0, y: startY)
        riseSpr.setScale(0.25)
        riseSpr.name = "rabbitBody"
        crop.addChild(riseSpr)
        currentSprite = riseSpr

        // Rise up med subtil pulsering
        let riseUp = SKAction.moveTo(y: 0, duration: 1.2)
        riseUp.timingMode = .easeOut
        let pulse = SKAction.sequence([
            SKAction.scale(to: 0.32, duration: 0.25),
            SKAction.scale(to: 0.18, duration: 0.25),
            SKAction.scale(to: 0.30, duration: 0.25),
            SKAction.scale(to: 0.18, duration: 0.25),
            SKAction.scale(to: 0.28, duration: 0.2),
        ])
        let riseAndGrow = SKAction.group([riseUp, pulse])

        // Start glitter + glow + bubble + comet trail from the beginning (rise_01)
        let startGlitter = SKAction.run { [weak self] in
            self?.startMagicGlitter(on: crop)
            self?.addMagicGlow(to: riseSpr)
            self?.startGlowSparkle(on: riseSpr)
            self?.addBubbleEffect(to: riseSpr)
        }

        // Dubbel-boom: rise_01 → dance_01 direkt
        let doubleBoom = SKAction.sequence([
            // Paus vid 0.2 — visa den lilla storleken
            SKAction.wait(forDuration: 0.6),

            // Avsluta bubble/glitter-effekter
            SKAction.run { [weak self] in
                guard let self else { return }
                self.removeBubbleEffect(from: riseSpr)
                self.stopMagicGlitter(on: crop)
            },
            SKAction.scale(to: 1.0, duration: 0.35),

            // BOOM 1 — expansion + burst
            SKAction.run { [weak self] in
                guard let self else { return }
                self.spawnMagicBurst(on: crop)
                self.startIntenseGlitter(on: crop)
            },
            SKAction.fadeAlpha(to: 0.85, duration: 0.06),
            SKAction.scale(to: 1.12, duration: 0.08),
            SKAction.group([
                SKAction.scale(to: 0.95, duration: 0.12),
                SKAction.fadeAlpha(to: 1.0, duration: 0.12)
            ]),

            // Kort paus mellan booms
            SKAction.wait(forDuration: 0.15),

            // BOOM 2 — ännu större, byter till dance_01
            SKAction.run { [weak self] in
                self?.spawnMagicBurst(on: crop)
            },
            SKAction.fadeAlpha(to: 0.82, duration: 0.05),
            SKAction.group([
                SKAction.scale(to: 1.15, duration: 0.08),
                SKAction.setTexture(self.danceFrames[0], resize: false),
            ]),
            SKAction.group([
                SKAction.scale(to: 1.0, duration: 0.2),
                SKAction.fadeAlpha(to: 1.0, duration: 0.2)
            ]),
        ])

        // Finalize: rensa effekter, flytta ut ur crop, starta andning
        let finalize = SKAction.run { [weak self] in
            guard let self else { return }
            self.stopIntenseGlitter(on: crop)
            riseSpr.removeAction(forKey: "glowSparkle")
            riseSpr.childNode(withName: "magicGlow")?.removeFromParent()
            riseSpr.childNode(withName: "magicGlowMid")?.removeFromParent()
            riseSpr.childNode(withName: "magicGlowInner")?.removeFromParent()
            riseSpr.removeFromParent()
            riseSpr.setScale(0.85)
            riseSpr.anchorPoint = CGPoint(x: 0.5, y: 0)
            riseSpr.position = CGPoint(x: self.dancePosition.x,
                                        y: self.dancePosition.y - self.danceSize.height * 0.5 - 350)
            self.addChild(riseSpr)
            self.currentSprite = riseSpr
            crop.removeFromParent()
            self.startDanceLoop()
        }

        riseSpr.run(SKAction.sequence([
            startGlitter,
            riseAndGrow,
            doubleBoom,
            finalize
        ]), withKey: "rise")
    }

    // MARK: - Magic Glitter

    private let pastelColors: [UIColor] = [
        UIColor(red: 1.0, green: 0.88, blue: 0.9, alpha: 1),    // pärlemor rosa
        UIColor(red: 0.88, green: 0.93, blue: 1.0, alpha: 1),   // pärlemor blå
        UIColor(red: 0.9, green: 1.0, blue: 0.92, alpha: 1),    // pärlemor mint
        UIColor(red: 1.0, green: 0.96, blue: 0.85, alpha: 1),   // pärlemor guld
        UIColor(red: 0.93, green: 0.88, blue: 1.0, alpha: 1),   // pärlemor lavendel
        UIColor(red: 1.0, green: 0.92, blue: 0.88, alpha: 1),   // pärlemor persika
    ]

    private func startMagicGlitter(on parent: SKNode) {
        let spawn = SKAction.run { [weak self] in
            self?.spawnGlitterParticle(on: parent, intense: false)
        }
        let delay = SKAction.wait(forDuration: 0.08)
        parent.run(SKAction.repeatForever(SKAction.sequence([spawn, delay])), withKey: "magicGlitter")
    }

    private func stopMagicGlitter(on parent: SKNode) {
        parent.removeAction(forKey: "magicGlitter")
        parent.enumerateChildNodes(withName: "glitterParticle") { node, _ in
            node.run(SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.3),
                SKAction.removeFromParent()
            ]))
        }
    }

    // Intense glitter for transformation: more particles, bigger, wider spread
    private func startIntenseGlitter(on parent: SKNode) {
        let spawn = SKAction.run { [weak self] in
            guard let self else { return }
            self.spawnGlitterParticle(on: parent, intense: true)
            self.spawnGlitterParticle(on: parent, intense: true)
        }
        let delay = SKAction.wait(forDuration: 0.05)
        parent.run(SKAction.repeatForever(SKAction.sequence([spawn, delay])), withKey: "intenseGlitter")
    }

    private func stopIntenseGlitter(on parent: SKNode) {
        parent.removeAction(forKey: "intenseGlitter")
        parent.enumerateChildNodes(withName: "glitterParticle") { node, _ in
            node.run(SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.5),
                SKAction.removeFromParent()
            ]))
        }
    }

    // Pulsing scale on sprite during transformation
    private func startTransformPulse(on sprite: SKSpriteNode) {
        let up = SKAction.scale(to: 1.02, duration: 0.3)
        up.timingMode = .easeInEaseOut
        let down = SKAction.scale(to: 0.98, duration: 0.3)
        down.timingMode = .easeInEaseOut
        sprite.run(SKAction.repeatForever(SKAction.sequence([up, down])), withKey: "transformPulse")
    }

    private func spawnGlitterParticle(on parent: SKNode, intense: Bool) {
        let pixelSize = intense ? CGFloat.random(in: 4...10) : CGFloat.random(in: 2...6)

        // White glittering pixel
        let pixel = SKShapeNode(rectOf: CGSize(width: pixelSize, height: pixelSize))
        pixel.fillColor = .white
        pixel.strokeColor = .clear
        pixel.name = "glitterParticle"
        pixel.zPosition = 20

        // Spread across room: dense near object, sparse far out
        let maxDist: CGFloat = 1400
        let r = pow(CGFloat.random(in: 0...1), 0.33) * maxDist
        let angle = CGFloat.random(in: 0...(.pi * 2))
        let offsetX = CGFloat.random(in: -60...60)
        let offsetY = CGFloat.random(in: -40...70)
        pixel.position = CGPoint(
            x: cos(angle) * r * CGFloat.random(in: 0.7...1.3) + offsetX,
            y: sin(angle) * r * CGFloat.random(in: 0.8...1.4) + offsetY
        )

        let distRatio = r / maxDist
        let startAlpha = CGFloat.random(in: 0.3...0.8) * (1.0 - distRatio * 0.5)
        let sizeScale = 1.0 - distRatio * 0.4
        pixel.setScale(0.2 * sizeScale)
        pixel.alpha = startAlpha
        parent.addChild(pixel)

        // Pulse: white pixel grows 0.2 → 2.0 with alpha shimmer
        let growDur = Double.random(in: 0.4...0.7)
        let scaleUp = SKAction.scale(to: 2.0, duration: growDur)
        scaleUp.timingMode = .easeOut

        let pulseDur = Double.random(in: 0.1...0.2)
        let pulseUp = SKAction.fadeAlpha(to: CGFloat.random(in: 0.7...1.0), duration: pulseDur)
        pulseUp.timingMode = .easeInEaseOut
        let pulseDown = SKAction.fadeAlpha(to: CGFloat.random(in: 0.15...0.35), duration: pulseDur)
        pulseDown.timingMode = .easeInEaseOut
        let pulseCount = intense ? 5 : 3
        let pulse = SKAction.repeat(SKAction.sequence([pulseUp, pulseDown]), count: pulseCount)

        // After pulse: mini explosion — fragments scatter across the screen
        let explode = SKAction.run { [weak self] in
            self?.spawnMiniExplosion(at: pixel.position, on: parent, size: pixelSize)
        }
        let pop = SKAction.group([
            SKAction.scale(to: 3.0, duration: 0.05),
            SKAction.fadeOut(withDuration: 0.05)
        ])

        pixel.run(SKAction.sequence([
            SKAction.group([scaleUp, pulse]),
            explode,
            pop,
            SKAction.removeFromParent()
        ]))
    }

    // Mini explosion: tiny white pixel fragments scatter across the whole screen
    private func spawnMiniExplosion(at origin: CGPoint, on parent: SKNode, size: CGFloat) {
        let fragCount = Int.random(in: 5...8)

        for _ in 0..<fragCount {
            let fragSize = size * CGFloat.random(in: 0.3...0.7)
            let frag = SKShapeNode(rectOf: CGSize(width: fragSize, height: fragSize))
            frag.fillColor = .white
            frag.strokeColor = .clear
            frag.position = origin
            frag.alpha = CGFloat.random(in: 0.5...1.0)
            frag.zPosition = 19
            parent.addChild(frag)

            // Fly outward across the screen
            let flyAngle = CGFloat.random(in: 0...(.pi * 2))
            let flyDist = CGFloat.random(in: 300...1400)
            let flyDur = Double.random(in: 0.8...2.0)
            let targetX = origin.x + cos(flyAngle) * flyDist
            let targetY = origin.y + sin(flyAngle) * flyDist

            let fly = SKAction.move(to: CGPoint(x: targetX, y: targetY), duration: flyDur)
            fly.timingMode = .easeOut

            let shrink = SKAction.scale(to: 0.1, duration: flyDur)
            shrink.timingMode = .easeIn

            // Flicker while flying
            let flickerDur = Double.random(in: 0.06...0.12)
            let flicker = SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: CGFloat.random(in: 0.7...1.0), duration: flickerDur),
                SKAction.fadeAlpha(to: CGFloat.random(in: 0.1...0.3), duration: flickerDur)
            ]))

            let fade = SKAction.sequence([
                SKAction.wait(forDuration: flyDur * 0.6),
                SKAction.fadeOut(withDuration: flyDur * 0.4)
            ])

            frag.run(SKAction.group([fly, shrink, flicker, fade])) {
                frag.removeFromParent()
            }
        }
    }

    // MARK: - Magic Burst (flash + expanding star ring at transformation moments)

    private func spawnMagicBurst(on parent: SKNode) {
        // Brief white flash
        let flash = SKShapeNode(circleOfRadius: 400)
        flash.fillColor = UIColor.white.withAlphaComponent(0.5)
        flash.strokeColor = .clear
        flash.zPosition = 25
        flash.name = "magicFlash"
        flash.setScale(0.3)
        parent.addChild(flash)

        let expand = SKAction.scale(to: 1.5, duration: 0.3)
        expand.timingMode = .easeOut
        let fade = SKAction.fadeOut(withDuration: 0.3)
        flash.run(SKAction.group([expand, fade])) {
            flash.removeFromParent()
        }

        // Expanding ring of white pixel fragments
        let starCount = 20
        for i in 0..<starCount {
            let angle = CGFloat(i) / CGFloat(starCount) * .pi * 2 + CGFloat.random(in: -0.1...0.1)
            let size = CGFloat.random(in: 3...8)

            let star = SKShapeNode(rectOf: CGSize(width: size, height: size))
            star.fillColor = .white
            star.strokeColor = .clear
            star.alpha = 0.9
            star.zPosition = 22
            star.position = .zero
            parent.addChild(star)

            let dist = CGFloat.random(in: 400...800)
            let targetX = cos(angle) * dist
            let targetY = sin(angle) * dist

            let flyOut = SKAction.move(to: CGPoint(x: targetX, y: targetY), duration: 0.5)
            flyOut.timingMode = .easeOut
            let shrink = SKAction.scale(to: 0.1, duration: 0.5)
            shrink.timingMode = .easeIn
            let flicker = SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.3, duration: 0.06),
                SKAction.fadeAlpha(to: 1.0, duration: 0.06),
            ]))

            star.run(SKAction.group([flyOut, shrink, flicker])) {
                star.removeFromParent()
            }
        }
    }

    // MARK: - Magic Glow (soft pulsing aura around the sprite)

    private func addMagicGlow(to sprite: SKSpriteNode) {
        // Layer 1: Large soft outer glow
        let outerGlow = SKShapeNode(circleOfRadius: 650)
        outerGlow.fillColor = UIColor(red: 0.85, green: 0.75, blue: 1.0, alpha: 0.08)
        outerGlow.strokeColor = .clear
        outerGlow.zPosition = -3
        outerGlow.name = "magicGlow"
        sprite.addChild(outerGlow)

        let outerUp = SKAction.group([
            SKAction.scale(to: 1.4, duration: 0.7),
            SKAction.fadeAlpha(to: 0.15, duration: 0.7)
        ])
        outerUp.timingMode = .easeInEaseOut
        let outerDown = SKAction.group([
            SKAction.scale(to: 0.85, duration: 0.7),
            SKAction.fadeAlpha(to: 0.04, duration: 0.7)
        ])
        outerDown.timingMode = .easeInEaseOut
        outerGlow.run(SKAction.repeatForever(SKAction.sequence([outerUp, outerDown])))

        // Layer 2: Mid glow — pärlemor color shift
        let midGlow = SKShapeNode(circleOfRadius: 480)
        midGlow.fillColor = UIColor(red: 0.9, green: 0.8, blue: 1.0, alpha: 0.12)
        midGlow.strokeColor = .clear
        midGlow.zPosition = -2
        midGlow.name = "magicGlowMid"
        sprite.addChild(midGlow)

        let midUp = SKAction.group([
            SKAction.scale(to: 1.25, duration: 0.5),
            SKAction.fadeAlpha(to: 0.22, duration: 0.5)
        ])
        midUp.timingMode = .easeInEaseOut
        let midDown = SKAction.group([
            SKAction.scale(to: 0.9, duration: 0.5),
            SKAction.fadeAlpha(to: 0.08, duration: 0.5)
        ])
        midDown.timingMode = .easeInEaseOut
        midGlow.run(SKAction.repeatForever(SKAction.sequence([midUp, midDown])))

        // Mid glow shifts color
        let glowColors: [(CGFloat, CGFloat, CGFloat)] = [
            (0.9, 0.8, 1.0),   // lavendel
            (0.8, 0.9, 1.0),   // ljusblå
            (1.0, 0.85, 0.9),  // rosa
            (0.85, 1.0, 0.9),  // mint
        ]
        var colorShifts: [SKAction] = []
        for i in 0..<glowColors.count {
            let cur = glowColors[i]
            let next = glowColors[(i + 1) % glowColors.count]
            let shift = SKAction.customAction(withDuration: 1.2) { node, elapsed in
                guard let shape = node as? SKShapeNode else { return }
                let p = elapsed / 1.2
                let r = cur.0 + (next.0 - cur.0) * p
                let g = cur.1 + (next.1 - cur.1) * p
                let b = cur.2 + (next.2 - cur.2) * p
                shape.fillColor = UIColor(red: r, green: g, blue: b, alpha: shape.alpha)
            }
            colorShifts.append(shift)
        }
        midGlow.run(SKAction.repeatForever(SKAction.sequence(colorShifts)), withKey: "glowColorShift")

        // Layer 3: Inner bright core glow
        let innerGlow = SKShapeNode(circleOfRadius: 300)
        innerGlow.fillColor = UIColor(red: 1.0, green: 0.95, blue: 1.0, alpha: 0.18)
        innerGlow.strokeColor = .clear
        innerGlow.zPosition = -1
        innerGlow.name = "magicGlowInner"
        sprite.addChild(innerGlow)

        let innerUp = SKAction.group([
            SKAction.scale(to: 1.15, duration: 0.35),
            SKAction.fadeAlpha(to: 0.3, duration: 0.35)
        ])
        innerUp.timingMode = .easeInEaseOut
        let innerDown = SKAction.group([
            SKAction.scale(to: 0.9, duration: 0.35),
            SKAction.fadeAlpha(to: 0.12, duration: 0.35)
        ])
        innerDown.timingMode = .easeInEaseOut
        innerGlow.run(SKAction.repeatForever(SKAction.sequence([innerUp, innerDown])))
    }

    // MARK: - Comet Trail (rise glitter tail)

    /// Glitter-textur: mjuk cirkel för kometsvans
    private static let cometDotTexture: SKTexture = {
        let size: CGFloat = 24
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let image = renderer.image { ctx in
            let center = CGPoint(x: size / 2, y: size / 2)
            let colors = [
                UIColor.white.withAlphaComponent(1.0).cgColor,
                UIColor.white.withAlphaComponent(0.4).cgColor,
                UIColor.white.withAlphaComponent(0.0).cgColor,
            ] as CFArray
            let locations: [CGFloat] = [0.0, 0.5, 1.0]
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                         colors: colors, locations: locations) {
                ctx.cgContext.drawRadialGradient(
                    gradient,
                    startCenter: center, startRadius: 0,
                    endCenter: center, endRadius: size / 2,
                    options: .drawsAfterEndLocation
                )
            }
        }
        return SKTexture(image: image)
    }()

    /// 4-uddig stjärna för kometsvans
    private static let cometStarTexture: SKTexture = {
        let size: CGFloat = 20
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let image = renderer.image { ctx in
            let c = ctx.cgContext
            let center = CGPoint(x: size / 2, y: size / 2)
            c.setFillColor(UIColor.white.cgColor)
            let path = UIBezierPath()
            for i in 0..<8 {
                let angle = CGFloat(i) * .pi / 4 - .pi / 2
                let r: CGFloat = (i % 2 == 0) ? size / 2 : size / 7
                let p = CGPoint(x: center.x + cos(angle) * r,
                                y: center.y + sin(angle) * r)
                if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
            }
            path.close()
            path.fill()
        }
        return SKTexture(image: image)
    }()

    /// Skapar TJOCK kometsvans-emitter — rävsvans-nivå.
    /// `trailParent`: noden partiklar lämnas i så de inte följer spriten.
    private func makeCometTrailEmitter(trailParent: SKNode) -> SKEmitterNode {
        let e = SKEmitterNode()
        e.particleTexture = Self.cometDotTexture

        e.particleLifetime = 2.0          // längre liv = längre svans
        e.particleLifetimeRange = 0.6

        e.particleBirthRate = 120         // TJOCK — massvis med partiklar

        // Stor start, VÄXER medan den fadar — fluffig rävsvans
        e.particleScale = 1.8
        e.particleScaleRange = 0.8
        e.particleScaleSpeed = 0.6        // expanderar = tjockare svans

        e.particleAlpha = 0.9
        e.particleAlphaRange = 0.1

        // Drift ut åt sidorna — bred svans
        e.emissionAngle = -.pi / 2
        e.emissionAngleRange = .pi * 0.7
        e.particleSpeed = 25
        e.particleSpeedRange = 20

        e.particleRotation = 0
        e.particleRotationRange = .pi
        e.particleRotationSpeed = 0.8

        // Färgsekvens: varm guld → vit → lavendel → ljusblå → transparent
        let colorSeq = SKKeyframeSequence(keyframeValues: [
            UIColor(red: 1.0, green: 0.92, blue: 0.6, alpha: 1.0),   // varm guld
            UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),    // vit
            UIColor(red: 0.92, green: 0.87, blue: 1.0, alpha: 1.0),  // lavendel
            UIColor(red: 0.85, green: 0.92, blue: 1.0, alpha: 1.0),  // ljusblå
        ], times: [0.0, 0.2, 0.5, 1.0])
        colorSeq.interpolationMode = .linear
        e.particleColorSequence = colorSeq
        e.particleColorBlendFactor = 1.0

        let alphaSeq = SKKeyframeSequence(keyframeValues: [
            NSNumber(value: 0.9),
            NSNumber(value: 0.7),
            NSNumber(value: 0.35),
            NSNumber(value: 0.0),
        ], times: [0.0, 0.2, 0.6, 1.0])
        alphaSeq.interpolationMode = .linear
        e.particleAlphaSequence = alphaSeq

        e.particleBlendMode = .add
        e.zPosition = -1
        e.targetNode = trailParent
        e.position = .zero

        return e
    }

    /// Skapar glitterstjärnor — rikligt, snurrande
    private func makeCometStarEmitter(trailParent: SKNode) -> SKEmitterNode {
        let e = SKEmitterNode()
        e.particleTexture = Self.cometStarTexture

        e.particleLifetime = 1.2          // längre liv
        e.particleLifetimeRange = 0.4

        e.particleBirthRate = 45          // massor av stjärnor

        e.particleScale = 0.6
        e.particleScaleRange = 0.35
        e.particleScaleSpeed = -0.2

        e.particleAlpha = 1.0
        e.particleAlphaRange = 0.15

        // Bred spridning — stjärnor flyger åt alla håll
        e.emissionAngle = -.pi / 2
        e.emissionAngleRange = .pi * 1.2
        e.particleSpeed = 50
        e.particleSpeedRange = 40

        e.particleRotation = 0
        e.particleRotationRange = .pi
        e.particleRotationSpeed = 8

        // Färgsekvens: guld → vit → rosa → lavendel
        let colorSeq = SKKeyframeSequence(keyframeValues: [
            UIColor(red: 1.0, green: 0.85, blue: 0.4, alpha: 1.0),   // guld
            UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),    // vit
            UIColor(red: 1.0, green: 0.85, blue: 0.95, alpha: 1.0),  // rosa
            UIColor(red: 0.88, green: 0.82, blue: 1.0, alpha: 1.0),  // lavendel
        ], times: [0.0, 0.3, 0.6, 1.0])
        colorSeq.interpolationMode = .linear
        e.particleColorSequence = colorSeq
        e.particleColorBlendFactor = 1.0

        let alphaSeq = SKKeyframeSequence(keyframeValues: [
            NSNumber(value: 1.0),
            NSNumber(value: 0.8),
            NSNumber(value: 0.3),
            NSNumber(value: 0.0),
        ], times: [0.0, 0.3, 0.7, 1.0])
        alphaSeq.interpolationMode = .linear
        e.particleAlphaSequence = alphaSeq

        e.particleBlendMode = .add
        e.zPosition = -1
        e.targetNode = trailParent
        e.position = .zero

        return e
    }

    /// Mjuk glöd-dimma — det som gör svansen TJOCK och fluffig
    private func makeCometHazeEmitter(trailParent: SKNode) -> SKEmitterNode {
        let e = SKEmitterNode()
        e.particleTexture = Self.cometDotTexture

        e.particleLifetime = 2.5
        e.particleLifetimeRange = 0.8

        e.particleBirthRate = 60

        // STOR — skapar dimma/moln-effekt runt svansen
        e.particleScale = 3.0
        e.particleScaleRange = 1.2
        e.particleScaleSpeed = 1.0        // expanderar rejält

        e.particleAlpha = 0.4
        e.particleAlphaRange = 0.15

        e.emissionAngle = -.pi / 2
        e.emissionAngleRange = .pi * 0.5
        e.particleSpeed = 10
        e.particleSpeedRange = 8

        e.particleRotation = 0
        e.particleRotationRange = .pi * 2
        e.particleRotationSpeed = 0.3

        // Pastell-skiftning: rosa → ljusblå → lavendel → mint
        let colorSeq = SKKeyframeSequence(keyframeValues: [
            UIColor(red: 1.0, green: 0.88, blue: 0.95, alpha: 1.0),  // rosa
            UIColor(red: 0.88, green: 0.94, blue: 1.0, alpha: 1.0),  // ljusblå
            UIColor(red: 0.93, green: 0.88, blue: 1.0, alpha: 1.0),  // lavendel
            UIColor(red: 0.88, green: 1.0, blue: 0.94, alpha: 1.0),  // mint
        ], times: [0.0, 0.3, 0.6, 1.0])
        colorSeq.interpolationMode = .linear
        e.particleColorSequence = colorSeq
        e.particleColorBlendFactor = 1.0

        let alphaSeq = SKKeyframeSequence(keyframeValues: [
            NSNumber(value: 0.4),
            NSNumber(value: 0.3),
            NSNumber(value: 0.12),
            NSNumber(value: 0.0),
        ], times: [0.0, 0.2, 0.6, 1.0])
        alphaSeq.interpolationMode = .linear
        e.particleAlphaSequence = alphaSeq

        e.particleBlendMode = .add
        e.zPosition = -2
        e.targetNode = trailParent
        e.position = .zero

        return e
    }

    /// Gles kometsvans för risen — luftig och subtil
    func attachCometTrailLight(to sprite: SKNode, trailParent: SKNode) {
        let haze = makeCometHazeEmitter(trailParent: trailParent)
        haze.name = "cometHaze"
        haze.particleBirthRate = 12
        haze.particleScale = 1.5
        sprite.addChild(haze)

        let dots = makeCometTrailEmitter(trailParent: trailParent)
        dots.name = "cometDots"
        dots.particleBirthRate = 20
        dots.particleScale = 0.8
        sprite.addChild(dots)

        let stars = makeCometStarEmitter(trailParent: trailParent)
        stars.name = "cometStars"
        stars.particleBirthRate = 8
        stars.particleScale = 0.3
        sprite.addChild(stars)
    }

    /// Fäster tjock kometsvans för pinball (3 lager: dimma + glöd + stjärnor)
    func attachCometTrail(to sprite: SKNode, trailParent: SKNode) {
        let haze = makeCometHazeEmitter(trailParent: trailParent)
        haze.name = "cometHaze"
        sprite.addChild(haze)

        let dots = makeCometTrailEmitter(trailParent: trailParent)
        dots.name = "cometDots"
        sprite.addChild(dots)

        let stars = makeCometStarEmitter(trailParent: trailParent)
        stars.name = "cometStars"
        sprite.addChild(stars)
    }

    /// Stoppa kometsvansen mjukt — partiklar fadar ut naturligt
    func stopCometTrail(on sprite: SKNode) {
        for name in ["cometHaze", "cometDots", "cometStars"] {
            if let emitter = sprite.childNode(withName: name) as? SKEmitterNode {
                emitter.particleBirthRate = 0
                emitter.run(SKAction.sequence([
                    SKAction.wait(forDuration: 3.0),
                    SKAction.removeFromParent()
                ]))
            }
        }
    }

    // MARK: - Bubble Effect (bubble_05 overlay on rise_01)

    private func addBubbleEffect(to sprite: SKSpriteNode) {
        // Soft pastel outer glow behind everything
        let glow = SKShapeNode(circleOfRadius: 500)
        glow.fillColor = UIColor(red: 0.8, green: 0.7, blue: 1.0, alpha: 0.12)
        glow.strokeColor = .clear
        glow.zPosition = -1
        glow.name = "bubbleGlow"
        sprite.addChild(glow)

        // Glow pulses in size and shifts between pastel colors
        let glowPulse = SKAction.repeatForever(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.25, duration: 0.6),
                SKAction.fadeAlpha(to: 0.2, duration: 0.6)
            ]),
            SKAction.group([
                SKAction.scale(to: 0.85, duration: 0.6),
                SKAction.fadeAlpha(to: 0.06, duration: 0.6)
            ])
        ]))
        glow.run(glowPulse)

        // Cycle glow through pastel colors
        let glowColors: [(CGFloat, CGFloat, CGFloat)] = [
            (0.8, 0.7, 1.0),   // lavendel
            (0.7, 0.85, 1.0),  // ljusblå
            (1.0, 0.75, 0.8),  // rosa
            (0.7, 1.0, 0.85),  // mint
            (1.0, 0.88, 0.7),  // persika
        ]
        var colorShifts: [SKAction] = []
        for i in 0..<glowColors.count {
            let next = glowColors[(i + 1) % glowColors.count]
            let cur = glowColors[i]
            let shift = SKAction.customAction(withDuration: 1.0) { node, elapsed in
                guard let shape = node as? SKShapeNode else { return }
                let p = elapsed / 1.0
                let r = cur.0 + (next.0 - cur.0) * p
                let g = cur.1 + (next.1 - cur.1) * p
                let b = cur.2 + (next.2 - cur.2) * p
                shape.fillColor = UIColor(red: r, green: g, blue: b, alpha: shape.alpha)
            }
            colorShifts.append(shift)
        }
        glow.run(SKAction.repeatForever(SKAction.sequence(colorShifts)), withKey: "glowColorShift")

        // Bubble overlay — more transparent
        let bubbleTex = SKTexture(imageNamed: "bubble_05")
        let overlay = SKSpriteNode(texture: bubbleTex, size: CGSize(width: 705, height: 701))
        overlay.alpha = 0.35
        overlay.zPosition = 1
        overlay.name = "bubbleOverlay"
        overlay.blendMode = .alpha
        sprite.addChild(overlay)

        // Stronger pulsing star feel
        let pulseUp = SKAction.scale(to: 1.08, duration: 0.3)
        pulseUp.timingMode = .easeInEaseOut
        let pulseDown = SKAction.scale(to: 0.93, duration: 0.3)
        pulseDown.timingMode = .easeInEaseOut
        sprite.run(SKAction.repeatForever(SKAction.sequence([pulseUp, pulseDown])), withKey: "bubblePulse")

        // Bubble overlay alpha shimmer — wider range
        let aUp = SKAction.fadeAlpha(to: 0.5, duration: 0.25)
        aUp.timingMode = .easeInEaseOut
        let aDown = SKAction.fadeAlpha(to: 0.15, duration: 0.25)
        aDown.timingMode = .easeInEaseOut
        overlay.run(SKAction.repeatForever(SKAction.sequence([aDown, aUp])), withKey: "bubbleAlphaShimmer")

        // Micro-glitter on the ball — tiny white pixels that flash
        let microSpawn = SKAction.run {
            let size = CGFloat.random(in: 2...5)
            let micro = SKShapeNode(rectOf: CGSize(width: size, height: size))
            micro.fillColor = .white
            micro.strokeColor = .clear
            micro.zPosition = 2
            let a = CGFloat.random(in: 0...(.pi * 2))
            let dist = CGFloat.random(in: 50...320)
            micro.position = CGPoint(x: cos(a) * dist, y: sin(a) * dist)
            micro.alpha = 0
            micro.setScale(0.2)
            sprite.addChild(micro)

            let flashIn = SKAction.group([
                SKAction.fadeAlpha(to: CGFloat.random(in: 0.6...1.0), duration: 0.05),
                SKAction.scale(to: CGFloat.random(in: 1.0...2.0), duration: 0.05)
            ])
            let flashOut = SKAction.group([
                SKAction.fadeOut(withDuration: Double.random(in: 0.08...0.2)),
                SKAction.scale(to: 0.1, duration: Double.random(in: 0.08...0.2))
            ])
            micro.run(SKAction.sequence([flashIn, flashOut, SKAction.removeFromParent()]))
        }
        let microDelay = SKAction.wait(forDuration: 0.03)
        sprite.run(SKAction.repeatForever(SKAction.sequence([microSpawn, microDelay])), withKey: "microGlitter")
    }

    private func removeBubbleEffect(from sprite: SKSpriteNode) {
        sprite.removeAction(forKey: "bubblePulse")
        sprite.removeAction(forKey: "microGlitter")
        sprite.setScale(1.0)

        let overlay = sprite.childNode(withName: "bubbleOverlay")
        let glow = sprite.childNode(withName: "bubbleGlow")

        let fadeOut = SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ])
        overlay?.run(fadeOut)
        glow?.run(fadeOut)
    }

    // MARK: - Glow Sparkle (small sparkles orbiting close to sprite)

    private func startGlowSparkle(on sprite: SKSpriteNode) {
        let spawn = SKAction.run {
            let size = CGFloat.random(in: 2...6)
            let sparkle = SKShapeNode(rectOf: CGSize(width: size, height: size))
            sparkle.fillColor = .white
            sparkle.strokeColor = .clear
            sparkle.zPosition = 21

            // Spawn near sprite edges
            let angle = CGFloat.random(in: 0...(.pi * 2))
            let dist = CGFloat.random(in: 150...400)
            sparkle.position = CGPoint(x: cos(angle) * dist, y: sin(angle) * dist)
            sparkle.alpha = 0
            sparkle.setScale(0.2)
            sprite.addChild(sparkle)

            // Quick flash in/out with size pulse
            let flashIn = SKAction.group([
                SKAction.fadeAlpha(to: CGFloat.random(in: 0.6...1.0), duration: 0.06),
                SKAction.scale(to: CGFloat.random(in: 1.5...2.5), duration: 0.06)
            ])
            let hold = SKAction.wait(forDuration: Double.random(in: 0.03...0.08))
            let flashOut = SKAction.group([
                SKAction.fadeOut(withDuration: Double.random(in: 0.1...0.25)),
                SKAction.scale(to: 0.1, duration: Double.random(in: 0.1...0.25))
            ])

            sparkle.run(SKAction.sequence([
                flashIn, hold, flashOut,
                SKAction.removeFromParent()
            ]))
        }

        let delay = SKAction.wait(forDuration: 0.04)
        sprite.run(SKAction.repeatForever(SKAction.sequence([spawn, delay])), withKey: "glowSparkle")
    }

    // MARK: - Roll (tap during dance → roll with boom)

    func startRoll() {
        guard state == .dancing, let sprite = currentSprite else { return }
        state = .rolling

        // Stop dance actions
        sprite.removeAction(forKey: "dance")
        sprite.removeAction(forKey: "danceBreath")
        sprite.removeAction(forKey: "danceWobble")
        sprite.removeAction(forKey: "dancePulse")
        sprite.removeAction(forKey: "danceIdlePulse")
        sprite.removeAction(forKey: "danceIdleWobble")
        sprite.removeAction(forKey: "glowSparkle")
        sprite.removeAction(forKey: "magicGlitter")
        sprite.removeAction(forKey: "danceBooms")

        // Reset transforms from dance
        sprite.xScale = abs(sprite.xScale) > 0 ? sprite.xScale / abs(sprite.xScale) : 1.0
        sprite.yScale = 1.0
        sprite.zRotation = 0

        // 1. BOOM — smooth flash + burst at transition from dance → roll
        let boom = SKAction.sequence([
            SKAction.run { [weak self] in
                guard let self else { return }
                self.spawnRollBoom(on: sprite)
                self.startIntenseGlitter(on: sprite)
            },
            SKAction.group([
                SKAction.scale(to: 1.12, duration: 0.08),
                SKAction.fadeAlpha(to: 0.88, duration: 0.08)
            ]),
            SKAction.group([
                SKAction.scale(to: 0.85, duration: 0.12),
                SKAction.fadeAlpha(to: 1.0, duration: 0.12)
            ])
        ])

        // 2. Roll frames 1–6 med boom mellan varje frame
        let frameBoom = { [weak self] () -> SKAction in
            return SKAction.sequence([
                SKAction.run {
                    guard let self else { return }
                    let anchor = SKNode()
                    anchor.position = .zero
                    anchor.setScale(CGFloat.random(in: 0.3...0.6))
                    anchor.alpha = CGFloat.random(in: 0.5...0.8)
                    sprite.addChild(anchor)
                    self.spawnMagicBurst(on: anchor)
                    anchor.run(SKAction.sequence([
                        SKAction.wait(forDuration: 1.5),
                        SKAction.removeFromParent()
                    ]))
                },
                SKAction.group([
                    SKAction.scale(to: 0.92, duration: 0.04),
                    SKAction.fadeAlpha(to: 0.85, duration: 0.04)
                ]),
                SKAction.group([
                    SKAction.scale(to: 0.85, duration: 0.06),
                    SKAction.fadeAlpha(to: 1.0, duration: 0.06)
                ])
            ])
        }

        // Boom 2 + 3 (ersätter frame1 och frame3)
        let boom2 = frameBoom()
        let boom3 = frameBoom()

        // Land on roll_06 + sista boom + stop glitter
        let frame6 = SKAction.sequence([
            crossFadeToFrame(rollFrames[5], duration: 0.18, stretchX: 1.0, stretchY: 1.0),
            frameBoom(),
            SKAction.run { [weak self] in
                self?.stopIntenseGlitter(on: sprite)
            }
        ])

        // 4. Shrink to 0.34, then rise up 500px
        let shrink = SKAction.scale(to: 0.34, duration: 0.3)
        shrink.timingMode = .easeInEaseOut

        let riseUp = SKAction.moveBy(x: 0, y: 500, duration: 0.6)
        riseUp.timingMode = .easeOut

        // 5. Settle into rollIdle — vibrate and wait for next tap
        let settle = SKAction.run { [weak self] in
            guard let self else { return }
            self.state = .rollIdle
            self.startRollIdleVibration()
            self.onRollComplete?()
        }

        sprite.run(SKAction.sequence([
            boom,
            boom2, boom3, frame6,
            shrink, riseUp,
            settle
        ]), withKey: "roll")
    }

    // MARK: - Roll Idle Vibration (trembling in place, waiting for tap)

    private func startRollIdleVibration() {
        guard let sprite = currentSprite else { return }

        // Gentle trembling
        let shakeRight = SKAction.moveBy(x: 1.5, y: 0, duration: 0.04)
        let shakeLeft = SKAction.moveBy(x: -3, y: 0, duration: 0.08)
        let shakeBack = SKAction.moveBy(x: 1.5, y: 0, duration: 0.04)
        let pause = SKAction.wait(forDuration: 0.04)
        let shake = SKAction.repeatForever(SKAction.sequence([shakeRight, shakeLeft, shakeBack, pause]))
        sprite.run(shake, withKey: "rollIdleShake")

        // Soft scale pulse (around 0.34 scale)
        let pulseUp = SKAction.scale(to: 0.345, duration: 0.2)
        pulseUp.timingMode = .easeInEaseOut
        let pulseDown = SKAction.scale(to: 0.335, duration: 0.2)
        pulseDown.timingMode = .easeInEaseOut
        sprite.run(SKAction.repeatForever(SKAction.sequence([pulseUp, pulseDown])), withKey: "rollIdlePulse")

        // Glitter while waiting
        startGlowSparkle(on: sprite)
    }

    // MARK: - Cross-Fade Helper

    private func crossFadeToFrame(_ texture: SKTexture, duration: TimeInterval, stretchX: CGFloat, stretchY: CGFloat) -> SKAction {
        let thirdDur = duration / 3.0
        // Mjuk fade ner
        let fadeDown = SKAction.fadeAlpha(to: 0.2, duration: thirdDur)
        fadeDown.timingMode = .easeIn
        // Byt textur vid botten, kort vila i transparens
        let swap = SKAction.setTexture(texture, resize: false)
        let hold = SKAction.wait(forDuration: thirdDur * 0.3)
        // Mjuk fade upp med stretch
        let stretch = SKAction.group([
            SKAction.scaleX(to: stretchX, duration: thirdDur),
            SKAction.scaleY(to: stretchY, duration: thirdDur)
        ])
        let fadeUp = SKAction.fadeAlpha(to: 1.0, duration: thirdDur * 1.7)
        fadeUp.timingMode = .easeInEaseOut
        return SKAction.sequence([
            fadeDown,
            swap,
            hold,
            SKAction.group([stretch, fadeUp])
        ])
    }

    // MARK: - Roll Boom Effect

    private func spawnRollBoom(on parent: SKNode) {
        // Larger flash (radius 500, alpha 0.65, expands to 2.0x)
        let flash = SKShapeNode(circleOfRadius: 500)
        flash.fillColor = UIColor.white.withAlphaComponent(0.65)
        flash.strokeColor = .clear
        flash.zPosition = 25
        flash.name = "rollFlash"
        flash.setScale(0.3)
        parent.addChild(flash)

        let expand = SKAction.scale(to: 2.0, duration: 0.2)
        expand.timingMode = .easeOut
        let fade = SKAction.fadeOut(withDuration: 0.2)
        flash.run(SKAction.group([expand, fade])) {
            flash.removeFromParent()
        }

        // Outer ring: 28 fragments, every 3rd pastel-colored
        let outerCount = 28
        for i in 0..<outerCount {
            let angle = CGFloat(i) / CGFloat(outerCount) * .pi * 2 + CGFloat.random(in: -0.08...0.08)
            let size = CGFloat.random(in: 4...10)

            let frag = SKShapeNode(rectOf: CGSize(width: size, height: size))
            frag.fillColor = (i % 3 == 0) ? pastelColors[i % pastelColors.count] : .white
            frag.strokeColor = .clear
            frag.alpha = 0.9
            frag.zPosition = 23
            frag.position = .zero
            parent.addChild(frag)

            let dist = CGFloat.random(in: 500...1000)
            let targetX = cos(angle) * dist
            let targetY = sin(angle) * dist
            let flyDur = Double.random(in: 0.4...0.7)

            let flyOut = SKAction.move(to: CGPoint(x: targetX, y: targetY), duration: flyDur)
            flyOut.timingMode = .easeOut
            let shrink = SKAction.scale(to: 0.1, duration: flyDur)
            shrink.timingMode = .easeIn
            let flicker = SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.3, duration: 0.05),
                SKAction.fadeAlpha(to: 1.0, duration: 0.05)
            ]))

            frag.run(SKAction.group([flyOut, shrink, flicker])) {
                frag.removeFromParent()
            }
        }

        // Inner ring: 12 pastel fragments, delayed 60ms, fly 200–500px
        let innerDelay = SKAction.wait(forDuration: 0.06)
        let spawnInner = SKAction.run { [weak self] in
            guard let self else { return }
            let innerCount = 12
            for i in 0..<innerCount {
                let angle = CGFloat(i) / CGFloat(innerCount) * .pi * 2 + CGFloat.random(in: -0.15...0.15)
                let size = CGFloat.random(in: 3...7)

                let frag = SKShapeNode(rectOf: CGSize(width: size, height: size))
                frag.fillColor = self.pastelColors[i % self.pastelColors.count]
                frag.strokeColor = .clear
                frag.alpha = 0.85
                frag.zPosition = 22
                frag.position = .zero
                parent.addChild(frag)

                let dist = CGFloat.random(in: 200...500)
                let targetX = cos(angle) * dist
                let targetY = sin(angle) * dist
                let flyDur = Double.random(in: 0.3...0.5)

                let flyOut = SKAction.move(to: CGPoint(x: targetX, y: targetY), duration: flyDur)
                flyOut.timingMode = .easeOut
                let shrink = SKAction.scale(to: 0.15, duration: flyDur)
                shrink.timingMode = .easeIn
                let fadeFrag = SKAction.fadeOut(withDuration: flyDur * 0.8)

                frag.run(SKAction.sequence([
                    SKAction.group([flyOut, shrink]),
                    fadeFrag,
                    SKAction.removeFromParent()
                ]))
            }
        }
        parent.run(SKAction.sequence([innerDelay, spawnInner]))
    }

    // MARK: - Dance (ping-pong loop: 1-2-3-4-5-4-3-2)

    private func startDanceLoop() {
        guard let sprite = currentSprite else { return }
        state = .dancing

        sprite.texture = danceFrames[0]
        sprite.zRotation = 0

        // Förväntansfull andning — subtil puls
        sprite.setScale(0.84)
        let breatheUp = SKAction.scale(to: 0.845, duration: 2.0)
        breatheUp.timingMode = .easeInEaseOut
        let breatheDown = SKAction.scale(to: 0.835, duration: 2.0)
        breatheDown.timingMode = .easeInEaseOut
        sprite.run(SKAction.repeatForever(SKAction.sequence([breatheUp, breatheDown])), withKey: "danceIdlePulse")

        // Glitter — dubbelt lager
        startGlowSparkle(on: sprite)
        startMagicGlitter(on: sprite)

        onDanceStarted?()
    }

    // MARK: - Random Dance Booms

    private func startRandomDanceBooms(on sprite: SKSpriteNode) {
        let delay = Double.random(in: 2.0...5.0)
        sprite.run(SKAction.sequence([
            SKAction.wait(forDuration: delay),
            SKAction.run { [weak self] in
                guard let self, self.state == .dancing else { return }
                // Boom at random position on the rabbit
                let offsetX = CGFloat.random(in: -250...250)
                let offsetY = CGFloat.random(in: -400...400)
                let anchor = SKNode()
                anchor.position = CGPoint(x: offsetX, y: offsetY)
                // Vary size and transparency
                let scale = CGFloat.random(in: 0.3...0.8)
                anchor.setScale(scale)
                anchor.alpha = CGFloat.random(in: 0.3...0.7)
                sprite.addChild(anchor)
                self.spawnMagicBurst(on: anchor)
                // Clean up anchor after burst finishes
                anchor.run(SKAction.sequence([
                    SKAction.wait(forDuration: 1.5),
                    SKAction.removeFromParent()
                ]))
                self.startRandomDanceBooms(on: sprite)
            }
        ]), withKey: "danceBooms")
    }

    // MARK: - Pinball Bounce

    func startPinball() {
        guard state == .rollIdle, let sprite = currentSprite else { return }
        state = .pinballing

        // Stop rollIdle actions
        sprite.removeAction(forKey: "rollIdleShake")
        sprite.removeAction(forKey: "rollIdlePulse")
        sprite.removeAction(forKey: "glowSparkle")

        // Reset sprite to clean state
        sprite.setScale(0.34)
        sprite.zPosition = 20  // Framför rökmoln (12-13) och glitter (15)
        // Launch burst — bollen "vaknar" med en STOR puff
        let launchAnchor = SKNode()
        launchAnchor.position = sprite.position
        launchAnchor.setScale(0.6)
        addChild(launchAnchor)
        spawnMagicBurst(on: launchAnchor)
        spawnSmokePuff(at: sprite.position, size: .huge)
        launchAnchor.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.5),
            SKAction.removeFromParent()
        ]))

        // Start emitter trail (smoke + aura + glitter)
        let emitter = BallTrailEmitter()
        emitter.attach(to: sprite, trailTarget: self)
        ballTrailEmitter = emitter
        lastSpritePosition = sprite.position

        // Kometsvans — samma rävsvans som på risen
        attachCometTrail(to: sprite, trailParent: self)

        // Hastighets-tracking varje frame
        let trackSpeed = SKAction.repeatForever(SKAction.sequence([
            SKAction.wait(forDuration: 0.016),
            SKAction.run { [weak self] in
                guard let self, self.state == .pinballing, let sprite = self.currentSprite else { return }
                let dx = sprite.position.x - self.lastSpritePosition.x
                let dy = sprite.position.y - self.lastSpritePosition.y
                let speed = hypot(dx, dy) / 0.016
                self.ballTrailEmitter?.updateIntensity(speed: speed)
                self.lastSpritePosition = sprite.position
            }
        ]))
        self.run(trackSpeed, withKey: "pinballSpeedTrack")

        // Start recursive bouncing — LOTS of bounces!
        launchPinballBounce(on: sprite, remaining: Int.random(in: 25...35))
    }

    private func launchPinballBounce(on sprite: SKSpriteNode, remaining: Int) {
        guard state == .pinballing, remaining > 0 else {
            // Done — dizzy exhausted slowdown
            sprite.removeAction(forKey: "pinballSpin")
            let dizzy = SKAction.sequence([
                SKAction.rotate(byAngle: 0.3, duration: 0.15),
                SKAction.rotate(byAngle: -0.5, duration: 0.2),
                SKAction.rotate(byAngle: 0.4, duration: 0.18),
                SKAction.rotate(byAngle: -0.2, duration: 0.12),
                SKAction.rotate(byAngle: 0.05, duration: 0.1),
            ])
            // Final big smoke puff — "pust, jag är slut"
            let finalPuff = SKAction.run { [weak self] in
                self?.spawnSmokePuff(at: sprite.position, size: .huge)
            }
            let settle = SKAction.sequence([
                dizzy, finalPuff,
                SKAction.wait(forDuration: 0.3),
                SKAction.run { [weak self] in
                    self?.stopPinball()
                }
            ])
            sprite.run(settle, withKey: "pinballBounce")
            return
        }

        // ====== KATT OCH RÅTTA PERSONLIGHET ======
        let move = Int.random(in: 0...9)

        if move <= 2 && remaining > 5 {
            // --- LURPAUS: Stanna, darra, "sikta"... sen ZOOM! ---
            doCatStalking(on: sprite, remaining: remaining)
        } else if move == 3 && remaining > 8 {
            // --- FINT: Kort fint åt ett håll, sen blixtsnabb åt andra ---
            doFakeout(on: sprite, remaining: remaining)
        } else if move == 4 && remaining > 6 {
            // --- ZIGZAG: Tre snabba små hopp i rad ---
            doZigzag(on: sprite, remaining: remaining)
        } else {
            // --- VANLIG STUDS: Snabb och vild ---
            doNormalBounce(on: sprite, remaining: remaining)
        }
    }

    // --- Katt-lurpaus: stanna, darra, titta runt, sen BLIXTSNABB utfall ---
    private func doCatStalking(on sprite: SKSpriteNode, remaining: Int) {
        // Stanna spinning
        sprite.removeAction(forKey: "pinballSpin")

        // Darra på stället (som en katt som siktar)
        let shakeR = SKAction.moveBy(x: 2.5, y: 0, duration: 0.03)
        let shakeL = SKAction.moveBy(x: -5, y: 0, duration: 0.06)
        let shakeB = SKAction.moveBy(x: 2.5, y: 0, duration: 0.03)
        let shakeY = SKAction.moveBy(x: 0, y: 2, duration: 0.03)
        let shakeYB = SKAction.moveBy(x: 0, y: -2, duration: 0.03)
        let tremble = SKAction.repeat(
            SKAction.sequence([shakeR, shakeL, shakeB, shakeY, shakeYB]),
            count: Int.random(in: 8...20)
        )

        // "Titta runt" — liten rotation fram och tillbaka
        let lookLeft = SKAction.rotate(byAngle: 0.15, duration: 0.12)
        lookLeft.timingMode = .easeInEaseOut
        let lookRight = SKAction.rotate(byAngle: -0.3, duration: 0.2)
        lookRight.timingMode = .easeInEaseOut
        let lookBack = SKAction.rotate(byAngle: 0.15, duration: 0.12)
        lookBack.timingMode = .easeInEaseOut

        // Pulsera lite — bygger spänning
        let tensePulse = SKAction.repeat(SKAction.sequence([
            SKAction.scale(to: 0.36, duration: 0.08),
            SKAction.scale(to: 0.32, duration: 0.08),
        ]), count: 3)

        // Smoke puff under pausen — bollen andas/pustar
        let breatheSmoke = SKAction.run { [weak self] in
            guard let self else { return }
            self.spawnSmokePuff(at: sprite.position, size: .small)
        }

        let stalk = SKAction.group([tremble, SKAction.sequence([lookLeft, lookRight, lookBack, tensePulse])])

        // PANG! Blixtsnabb utfall
        let target = randomTarget(from: sprite.position, minDist: 600, maxDist: 2000)
        let dist = hypot(target.x - sprite.position.x, target.y - sprite.position.y)
        let zapDuration = max(0.08, min(0.25, Double(dist / 6000)))

        let zapMove = SKAction.move(to: target, duration: zapDuration)
        zapMove.timingMode = .easeIn
        let zapSpin = SKAction.rotate(byAngle: CGFloat.random(in: 2...5) * (Bool.random() ? 1 : -1), duration: zapDuration)
        let zapStretch = SKAction.sequence([
            SKAction.group([
                SKAction.scaleX(to: 0.28, duration: zapDuration * 0.5),
                SKAction.scaleY(to: 0.45, duration: zapDuration * 0.5)
            ]),
            SKAction.group([
                SKAction.scaleX(to: 0.34, duration: zapDuration * 0.5),
                SKAction.scaleY(to: 0.34, duration: zapDuration * 0.5)
            ])
        ])
        let zap = SKAction.group([zapMove, zapSpin, zapStretch])

        let onArrive = SKAction.run { [weak self] in
            guard let self, self.state == .pinballing else { return }
            self.spawnBounceImpact(at: sprite.position, sprite: sprite)
            self.startPinballSpin(on: sprite)
            self.launchPinballBounce(on: sprite, remaining: remaining - 1)
        }

        sprite.run(SKAction.sequence([
            breatheSmoke, stalk,
            SKAction.scale(to: 0.34, duration: 0.02),
            zap, onArrive
        ]), withKey: "pinballBounce")
    }

    // --- Fint: kort fint åt ett håll, stannar, sen blixtsnabb åt ANDRA hållet ---
    private func doFakeout(on sprite: SKSpriteNode, remaining: Int) {
        // Kort fint — rör sig lite åt ett slumpmässigt håll
        let fakeAngle = CGFloat.random(in: 0...(.pi * 2))
        let fakeDist: CGFloat = CGFloat.random(in: 60...150)
        let fakeTarget = CGPoint(
            x: sprite.position.x + cos(fakeAngle) * fakeDist,
            y: sprite.position.y + sin(fakeAngle) * fakeDist
        )
        let fakeMove = SKAction.move(to: fakeTarget, duration: 0.08)
        fakeMove.timingMode = .easeOut

        // Paus
        let pause = SKAction.wait(forDuration: Double.random(in: 0.05...0.15))

        // Smoke puff vid finten
        let fakePuff = SKAction.run { [weak self] in
            self?.spawnSmokePuff(at: fakeTarget, size: .small)
        }

        // RIKTIG attack — motsatt riktning, mycket längre
        let realTarget = randomTarget(from: fakeTarget, minDist: 500, maxDist: 1800)
        let dist = hypot(realTarget.x - fakeTarget.x, realTarget.y - fakeTarget.y)
        let realDur = max(0.1, min(0.3, Double(dist / 5000)))

        let realMove = SKAction.move(to: realTarget, duration: realDur)
        realMove.timingMode = .easeIn
        let realSpin = SKAction.rotate(byAngle: CGFloat.random(in: 2...4) * (Bool.random() ? 1 : -1), duration: realDur)
        let realStretch = SKAction.sequence([
            SKAction.group([
                SKAction.scaleX(to: 0.28, duration: realDur * 0.4),
                SKAction.scaleY(to: 0.44, duration: realDur * 0.4)
            ]),
            SKAction.group([
                SKAction.scaleX(to: 0.34, duration: realDur * 0.6),
                SKAction.scaleY(to: 0.34, duration: realDur * 0.6)
            ])
        ])
        let attack = SKAction.group([realMove, realSpin, realStretch])

        let onArrive = SKAction.run { [weak self] in
            guard let self, self.state == .pinballing else { return }
            self.spawnBounceImpact(at: sprite.position, sprite: sprite)
            self.launchPinballBounce(on: sprite, remaining: remaining - 1)
        }

        sprite.run(SKAction.sequence([fakeMove, fakePuff, pause, attack, onArrive]), withKey: "pinballBounce")
    }

    // --- Zigzag: tre snabba hopp i rad utan paus ---
    private func doZigzag(on sprite: SKSpriteNode, remaining: Int) {
        var actions: [SKAction] = []
        var currentPos = sprite.position
        let hops = min(3, remaining)

        for i in 0..<hops {
            let hopDist: CGFloat = CGFloat.random(in: 200...600)
            let hopAngle = CGFloat.random(in: 0...(.pi * 2))
            var hopTarget = CGPoint(
                x: currentPos.x + cos(hopAngle) * hopDist,
                y: currentPos.y + sin(hopAngle) * hopDist
            )
            // Clamp to scene
            hopTarget.x = max(100, min(2632, hopTarget.x))
            hopTarget.y = max(100, min(1948, hopTarget.y))

            let d = hypot(hopTarget.x - currentPos.x, hopTarget.y - currentPos.y)
            let dur = max(0.06, min(0.18, Double(d / 4000)))

            let hopMove = SKAction.move(to: hopTarget, duration: dur)
            hopMove.timingMode = .easeIn
            let hopSpin = SKAction.rotate(byAngle: CGFloat.random(in: 1...3) * (Bool.random() ? 1 : -1), duration: dur)

            let hopPos = hopTarget
            let isLast = i == hops - 1
            let puff = SKAction.run { [weak self] in
                self?.spawnSmokePuff(at: hopPos, size: .medium)
                if isLast {
                    self?.spawnSmokePuff(at: hopPos, size: .big)
                }
            }

            // Impact squash
            let impactSquash = SKAction.sequence([
                SKAction.group([
                    SKAction.scaleX(to: 0.44, duration: 0.03),
                    SKAction.scaleY(to: 0.26, duration: 0.03)
                ]),
                SKAction.group([
                    SKAction.scaleX(to: 0.34, duration: 0.04),
                    SKAction.scaleY(to: 0.34, duration: 0.04)
                ])
            ])

            actions.append(contentsOf: [SKAction.group([hopMove, hopSpin]), puff, impactSquash])
            currentPos = hopTarget
        }

        let onArrive = SKAction.run { [weak self] in
            guard let self, self.state == .pinballing else { return }
            // Burst at final position
            let burstAnchor = SKNode()
            burstAnchor.position = sprite.position
            burstAnchor.setScale(0.4)
            burstAnchor.alpha = 0.6
            self.addChild(burstAnchor)
            self.spawnMagicBurst(on: burstAnchor)
            burstAnchor.run(SKAction.sequence([
                SKAction.wait(forDuration: 1.5),
                SKAction.removeFromParent()
            ]))
            self.launchPinballBounce(on: sprite, remaining: remaining - hops)
        }
        actions.append(onArrive)

        sprite.run(SKAction.sequence(actions), withKey: "pinballBounce")
    }

    // --- Normal studs: snabb och vild, med squash & stretch ---
    private func doNormalBounce(on sprite: SKSpriteNode, remaining: Int) {
        let target = randomTarget(from: sprite.position, minDist: 350, maxDist: 2200)
        let distance = hypot(target.x - sprite.position.x, target.y - sprite.position.y)

        // Snabbt!
        let speed = CGFloat.random(in: 3000...5500)
        let baseDuration = Double(distance / speed)
        let duration = max(0.12, min(0.5, baseDuration))

        // Sakta ner sista studsarna
        let slowFactor: Double
        if remaining <= 2 {
            slowFactor = 3.5
        } else if remaining <= 4 {
            slowFactor = 2.0
        } else if remaining <= 7 {
            slowFactor = 1.4
        } else {
            slowFactor = 1.0
        }
        let finalDuration = duration * slowFactor

        let move = SKAction.move(to: target, duration: finalDuration)
        move.timingMode = .easeIn

        // Vild spinning
        let spins = CGFloat.random(in: 1...4) * (Bool.random() ? 1 : -1)
        let rotate = SKAction.rotate(byAngle: spins * .pi, duration: finalDuration)

        // Squash & stretch
        let squashIn = SKAction.group([
            SKAction.scaleX(to: 0.42, duration: finalDuration * 0.3),
            SKAction.scaleY(to: 0.28, duration: finalDuration * 0.3)
        ])
        let stretchOut = SKAction.group([
            SKAction.scaleX(to: 0.28, duration: finalDuration * 0.4),
            SKAction.scaleY(to: 0.44, duration: finalDuration * 0.4)
        ])
        let normalise = SKAction.group([
            SKAction.scaleX(to: 0.34, duration: finalDuration * 0.3),
            SKAction.scaleY(to: 0.34, duration: finalDuration * 0.3)
        ])
        let squashStretch = SKAction.sequence([squashIn, stretchOut, normalise])

        let fly = SKAction.group([move, rotate, squashStretch])

        let onArrive = SKAction.run { [weak self] in
            guard let self, self.state == .pinballing else { return }
            self.spawnBounceImpact(at: sprite.position, sprite: sprite)
            self.launchPinballBounce(on: sprite, remaining: remaining - 1)
        }

        sprite.run(SKAction.sequence([fly, onArrive]), withKey: "pinballBounce")
    }

    // MARK: - Bounce Impact (squash + smoke + burst at landing)

    private func spawnBounceImpact(at position: CGPoint, sprite: SKSpriteNode) {
        // Squash flat on impact
        let impactSquash = SKAction.group([
            SKAction.scaleX(to: 0.48, duration: 0.03),
            SKAction.scaleY(to: 0.22, duration: 0.03)
        ])
        let impactBounce = SKAction.group([
            SKAction.scaleX(to: 0.30, duration: 0.05),
            SKAction.scaleY(to: 0.40, duration: 0.05)
        ])
        let impactSettle = SKAction.group([
            SKAction.scaleX(to: 0.34, duration: 0.04),
            SKAction.scaleY(to: 0.34, duration: 0.04)
        ])
        sprite.run(SKAction.sequence([impactSquash, impactBounce, impactSettle]))

        // Big smoke puff
        spawnSmokePuff(at: position, size: .big)

        // Magic burst
        let burstAnchor = SKNode()
        burstAnchor.position = position
        burstAnchor.setScale(CGFloat.random(in: 0.3...0.5))
        burstAnchor.alpha = CGFloat.random(in: 0.5...0.8)
        addChild(burstAnchor)
        spawnMagicBurst(on: burstAnchor)
        burstAnchor.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.5),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Random Target Helper

    private func randomTarget(from pos: CGPoint, minDist: CGFloat, maxDist: CGFloat) -> CGPoint {
        let margin: CGFloat = 100
        var target: CGPoint
        repeat {
            // Ibland sikta mot hörn
            if Int.random(in: 0...3) == 0 {
                let corners: [CGPoint] = [
                    CGPoint(x: margin + 50, y: margin + 50),
                    CGPoint(x: 2632, y: margin + 50),
                    CGPoint(x: margin + 50, y: 1948),
                    CGPoint(x: 2632, y: 1948),
                    CGPoint(x: 1366, y: margin + 50),   // mitten-botten
                    CGPoint(x: 1366, y: 1948),           // mitten-toppen
                ]
                let c = corners.randomElement()!
                target = CGPoint(
                    x: c.x + CGFloat.random(in: -100...100),
                    y: c.y + CGFloat.random(in: -100...100)
                )
            } else {
                target = CGPoint(
                    x: CGFloat.random(in: margin...2632),
                    y: CGFloat.random(in: margin...1948)
                )
            }
        } while hypot(target.x - pos.x, target.y - pos.y) < minDist
        return target
    }

    // MARK: - Pinball Spin

    private func startPinballSpin(on sprite: SKSpriteNode) {
        let spinSpeed = Double.random(in: 0.2...0.5)
        let spinDir: CGFloat = Bool.random() ? 1 : -1
        let spin = SKAction.rotate(byAngle: spinDir * .pi * 2, duration: spinSpeed)
        sprite.run(SKAction.repeatForever(spin), withKey: "pinballSpin")
    }

    // MARK: - Smoke Trail (thick continuous smoke along path)

    private func startPinballSmokeTrail(on sprite: SKSpriteNode) {
        // Layer 1: Tät röksvans — stora mjuka moln
        let spawnThickSmoke = SKAction.run { [weak self] in
            guard let self, self.state == .pinballing else { return }

            let radius = CGFloat.random(in: 30...65)
            let smoke = SKShapeNode(circleOfRadius: radius)
            let gray = CGFloat.random(in: 0.82...1.0)
            smoke.fillColor = UIColor(white: gray, alpha: 1.0)
            smoke.strokeColor = .clear
            smoke.zPosition = 13
            smoke.alpha = CGFloat.random(in: 0.3...0.5)
            smoke.setScale(CGFloat.random(in: 0.5...0.8))
            smoke.name = "pinballSmoke"

            smoke.position = CGPoint(
                x: sprite.position.x + CGFloat.random(in: -15...15),
                y: sprite.position.y + CGFloat.random(in: -15...15)
            )
            self.addChild(smoke)

            let lifetime = Double.random(in: 3.0...6.0)
            let expand = SKAction.scale(to: CGFloat.random(in: 2.5...5.0), duration: lifetime)
            expand.timingMode = .easeOut
            let fade = SKAction.fadeOut(withDuration: lifetime)
            fade.timingMode = .easeIn
            let drift = SKAction.moveBy(
                x: CGFloat.random(in: -50...50),
                y: CGFloat.random(in: 30...100),
                duration: lifetime
            )
            drift.timingMode = .easeOut

            smoke.run(SKAction.sequence([
                SKAction.group([expand, fade, drift]),
                SKAction.removeFromParent()
            ]))
        }

        // Layer 2: Små tunna rökpuffar — fyller i mellanrummen
        let spawnThinSmoke = SKAction.run { [weak self] in
            guard let self, self.state == .pinballing else { return }

            let radius = CGFloat.random(in: 15...35)
            let wisp = SKShapeNode(circleOfRadius: radius)
            wisp.fillColor = UIColor(white: CGFloat.random(in: 0.9...1.0), alpha: 1.0)
            wisp.strokeColor = .clear
            wisp.zPosition = 13
            wisp.alpha = CGFloat.random(in: 0.15...0.35)
            wisp.setScale(CGFloat.random(in: 0.3...0.6))
            wisp.name = "pinballSmoke"

            wisp.position = CGPoint(
                x: sprite.position.x + CGFloat.random(in: -25...25),
                y: sprite.position.y + CGFloat.random(in: -25...25)
            )
            self.addChild(wisp)

            let lifetime = Double.random(in: 2.0...4.0)
            let expand = SKAction.scale(to: CGFloat.random(in: 1.5...3.0), duration: lifetime)
            expand.timingMode = .easeOut
            let fade = SKAction.fadeOut(withDuration: lifetime)
            fade.timingMode = .easeIn
            let drift = SKAction.moveBy(
                x: CGFloat.random(in: -60...60),
                y: CGFloat.random(in: 10...60),
                duration: lifetime
            )

            wisp.run(SKAction.sequence([
                SKAction.group([expand, fade, drift]),
                SKAction.removeFromParent()
            ]))
        }

        // Tät spawn: tjock rök var 0.025s, tunn var 0.015s
        self.run(SKAction.repeatForever(SKAction.sequence([
            spawnThickSmoke,
            SKAction.wait(forDuration: 0.025)
        ])), withKey: "pinballSmokeTrail")

        self.run(SKAction.repeatForever(SKAction.sequence([
            spawnThinSmoke,
            SKAction.wait(forDuration: 0.015)
        ])), withKey: "pinballSmokeTrailThin")
    }

    // MARK: - Glitter Trail

    private func startPinballGlitterTrail(on sprite: SKSpriteNode) {
        let spawnGlitter = SKAction.run { [weak self] in
            guard let self, self.state == .pinballing else { return }

            let size = CGFloat.random(in: 3...8)
            let sparkle = SKShapeNode(rectOf: CGSize(width: size, height: size))
            sparkle.fillColor = Bool.random() ? .white : (self.pastelColors.randomElement() ?? .white)
            sparkle.strokeColor = .clear
            sparkle.zPosition = 15
            sparkle.alpha = CGFloat.random(in: 0.7...1.0)
            sparkle.setScale(0.3)
            sparkle.name = "pinballGlitter"

            sparkle.position = CGPoint(
                x: sprite.position.x + CGFloat.random(in: -20...20),
                y: sprite.position.y + CGFloat.random(in: -20...20)
            )
            self.addChild(sparkle)

            let lifetime = Double.random(in: 0.5...1.0)
            let flashUp = SKAction.group([
                SKAction.scale(to: CGFloat.random(in: 1.5...3.0), duration: 0.05),
                SKAction.fadeAlpha(to: 1.0, duration: 0.05)
            ])
            let fadeAway = SKAction.group([
                SKAction.fadeOut(withDuration: lifetime),
                SKAction.scale(to: 0.1, duration: lifetime),
                SKAction.moveBy(
                    x: CGFloat.random(in: -30...30),
                    y: CGFloat.random(in: -10...30),
                    duration: lifetime
                )
            ])

            sparkle.run(SKAction.sequence([
                flashUp, fadeAway,
                SKAction.removeFromParent()
            ]))
        }

        self.run(SKAction.repeatForever(SKAction.sequence([
            spawnGlitter,
            SKAction.wait(forDuration: 0.04)
        ])), withKey: "pinballGlitterTrail")
    }

    // MARK: - Smoke Puff (impact clouds)

    private enum SmokePuffSize {
        case small, medium, big, huge
    }

    private func spawnSmokePuff(at position: CGPoint, size: SmokePuffSize) {
        let puffCount: Int
        let radiusRange: ClosedRange<CGFloat>
        let alphaRange: ClosedRange<CGFloat>
        let expandRange: ClosedRange<CGFloat>
        let scatterRange: ClosedRange<CGFloat>

        switch size {
        case .small:
            puffCount = Int.random(in: 2...3)
            radiusRange = 20...40
            alphaRange = 0.2...0.35
            expandRange = 1.5...2.5
            scatterRange = -20...20
        case .medium:
            puffCount = Int.random(in: 3...5)
            radiusRange = 30...60
            alphaRange = 0.25...0.45
            expandRange = 2.0...3.5
            scatterRange = -30...30
        case .big:
            puffCount = Int.random(in: 5...8)
            radiusRange = 40...80
            alphaRange = 0.3...0.55
            expandRange = 2.5...4.5
            scatterRange = -50...50
        case .huge:
            puffCount = Int.random(in: 8...12)
            radiusRange = 50...100
            alphaRange = 0.35...0.6
            expandRange = 3.0...6.0
            scatterRange = -70...70
        }

        for _ in 0..<puffCount {
            let radius = CGFloat.random(in: radiusRange)
            let puff = SKShapeNode(circleOfRadius: radius)
            let gray = CGFloat.random(in: 0.85...1.0)
            puff.fillColor = UIColor(white: gray, alpha: 1.0)
            puff.strokeColor = .clear
            puff.zPosition = 12
            puff.alpha = CGFloat.random(in: alphaRange)
            puff.setScale(0.3)
            puff.name = "pinballSmoke"

            puff.position = CGPoint(
                x: position.x + CGFloat.random(in: scatterRange),
                y: position.y + CGFloat.random(in: scatterRange)
            )
            self.addChild(puff)

            let lifetime = Double.random(in: 2.5...5.0)
            let expand = SKAction.scale(to: CGFloat.random(in: expandRange), duration: lifetime)
            expand.timingMode = .easeOut
            let fade = SKAction.fadeOut(withDuration: lifetime)
            fade.timingMode = .easeIn

            let angle = CGFloat.random(in: 0...(.pi * 2))
            let dist = CGFloat.random(in: 40...150)
            let drift = SKAction.moveBy(
                x: cos(angle) * dist,
                y: sin(angle) * dist + CGFloat.random(in: 30...100),
                duration: lifetime
            )
            drift.timingMode = .easeOut

            puff.run(SKAction.sequence([
                SKAction.group([expand, fade, drift]),
                SKAction.removeFromParent()
            ]))
        }
    }

    func stopPinball() {
        guard let sprite = currentSprite else { return }

        // ── NUCLEAR CLEANUP ──
        // Stoppa ALLA actions på self och sprite omedelbart
        self.removeAllActions()
        sprite.removeAllActions()

        // Ta bort ALLA barn från sprite (döda emitters: BallTrailEmitter + comet trail)
        // Detta förhindrar emitters med stale targetNode-referenser
        sprite.removeAllChildren()

        // Ta bort ALLA ackumulerade barn från self (500-800 rök/glitter SKShapeNodes)
        // Behåll bara spriten
        let allChildren = self.children
        for child in allChildren where child !== sprite {
            child.removeAllActions()
            child.removeFromParent()
        }

        // Rensa state
        sprite.zRotation = 0
        sprite.setScale(0.34)
        ballTrailEmitter = nil

        // Magisk försvinnande — lätt, ingen reparenting
        startMagicVanish(sprite: sprite)
    }

    // MARK: - Rabbit Hole Sequence (pinball ending — Alice i Underlandet)

    /// Textur: 3D kaninhål — ljus jordkant, brett ockigt mörker i mitten
    private static let holeTexture: SKTexture = {
        let w: CGFloat = 400
        let h: CGFloat = 120   // mycket platt ellips — starkt golvperspektiv
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: w, height: h))
        let image = renderer.image { ctx in
            let c = ctx.cgContext
            let center = CGPoint(x: w / 2, y: h / 2)

            // --- Yttre ljus kant (jordkant runt hålet) ---
            c.saveGState()
            c.translateBy(x: center.x, y: center.y)
            c.scaleBy(x: 1.0, y: h / w)
            c.translateBy(x: -center.x, y: -center.y * w / h)

            let rimColors = [
                UIColor(red: 0.45, green: 0.35, blue: 0.25, alpha: 0.0).cgColor,
                UIColor(red: 0.45, green: 0.35, blue: 0.25, alpha: 0.0).cgColor,
                UIColor(red: 0.50, green: 0.40, blue: 0.28, alpha: 0.5).cgColor,
                UIColor(red: 0.55, green: 0.45, blue: 0.32, alpha: 0.7).cgColor,   // tydlig jordkant
                UIColor(red: 0.55, green: 0.45, blue: 0.32, alpha: 0.0).cgColor,
            ] as CFArray
            let rimLocs: [CGFloat] = [0.0, 0.55, 0.75, 0.90, 1.0]
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                         colors: rimColors, locations: rimLocs) {
                c.drawRadialGradient(
                    gradient,
                    startCenter: CGPoint(x: center.x, y: center.x),
                    startRadius: 0,
                    endCenter: CGPoint(x: center.x, y: center.x),
                    endRadius: w / 2,
                    options: .drawsAfterEndLocation
                )
            }
            c.restoreGState()

            // --- Inre mörker — brett ockigt, täcker bollen vid dykning ---
            c.saveGState()
            c.translateBy(x: center.x, y: center.y)
            c.scaleBy(x: 1.0, y: h / w)
            c.translateBy(x: -center.x, y: -center.y * w / h)

            let darkColors = [
                UIColor(red: 0.01, green: 0.005, blue: 0.03, alpha: 1.0).cgColor,   // kolsvart
                UIColor(red: 0.02, green: 0.01, blue: 0.05, alpha: 1.0).cgColor,
                UIColor(red: 0.04, green: 0.02, blue: 0.08, alpha: 0.98).cgColor,
                UIColor(red: 0.08, green: 0.05, blue: 0.12, alpha: 0.9).cgColor,
                UIColor(red: 0.14, green: 0.09, blue: 0.18, alpha: 0.5).cgColor,
                UIColor(red: 0.20, green: 0.15, blue: 0.22, alpha: 0.0).cgColor,
            ] as CFArray
            let darkLocs: [CGFloat] = [0.0, 0.2, 0.4, 0.55, 0.72, 0.85]
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                         colors: darkColors, locations: darkLocs) {
                c.drawRadialGradient(
                    gradient,
                    startCenter: CGPoint(x: center.x, y: center.x),
                    startRadius: 0,
                    endCenter: CGPoint(x: center.x, y: center.x),
                    endRadius: w / 2,
                    options: .drawsAfterEndLocation
                )
            }
            c.restoreGState()
        }
        return SKTexture(image: image)
    }()

    /// BOOM — bollen laddar, exploderar med tryckvåg, glitter och rökmoln.
    /// Ingen reparenting, alla effekter på self (RabbitNode).
    private func startMagicVanish(sprite: SKSpriteNode) {
        let pos = sprite.position

        // ── Fas 1: Bollen laddar upp — växer, darrar, lyser (0.3s) ──
        let tremble = SKAction.repeat(SKAction.sequence([
            SKAction.moveBy(x: 3, y: -2, duration: 0.02),
            SKAction.moveBy(x: -6, y: 4, duration: 0.02),
            SKAction.moveBy(x: 3, y: -2, duration: 0.02),
        ]), count: 5)

        let chargeUp = SKAction.group([
            SKAction.scale(to: 0.52, duration: 0.3),
            tremble
        ])

        sprite.run(SKAction.sequence([
            chargeUp,
            SKAction.run { [weak self] in
                guard let self else { return }
                sprite.removeFromParent()
                self.currentSprite = nil
                self.spawnBoomExplosion(at: pos)
            }
        ]))

        // ── Completion — vänta tills effekterna spelats klart ──
        self.run(SKAction.sequence([
            SKAction.wait(forDuration: 2.5),
            SKAction.run { [weak self] in
                guard let self else { return }
                self.state = .hidden
                self.onPinballComplete?()
            }
        ]))
    }

    /// Spawnar alla BOOM-effekter: blixt, tryckvågor över hela skärmen, glitter, rök
    private func spawnBoomExplosion(at pos: CGPoint) {

        // ── 1. SKÄRMBLIXT — vit overlay som täcker allt ──
        let flash = SKShapeNode(circleOfRadius: 120)
        flash.fillColor = .white
        flash.strokeColor = .clear
        flash.zPosition = 35
        flash.position = pos
        flash.alpha = 1.0
        flash.setScale(0.5)
        addChild(flash)
        flash.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 25.0, duration: 0.25),
                SKAction.fadeOut(withDuration: 0.5)
            ]),
            SKAction.removeFromParent()
        ]))

        // ── 2. STJÄRNBÄLTEN — 3 expanderande ringar av stjärnstoft ──
        for i in 0..<3 {
            let delay = Double(i) * 0.2
            let dur = 1.2 + Double(i) * 0.2
            let ringRadius: CGFloat = 1400 + CGFloat(i) * 200

            for _ in 0..<80 {
                let size = CGFloat.random(in: 1...2)
                let dot = SKShapeNode(rectOf: CGSize(width: size, height: size))
                dot.fillColor = Bool.random() ? .white : (pastelColors.randomElement() ?? .white)
                dot.strokeColor = .clear
                dot.zPosition = 28
                dot.position = pos
                dot.alpha = 0.0
                addChild(dot)

                let angle = CGFloat.random(in: 0...(.pi * 2))
                let dist = ringRadius * CGFloat.random(in: 0.85...1.15)
                let dotDur = dur * Double.random(in: 0.9...1.1)

                dot.run(SKAction.sequence([
                    SKAction.wait(forDuration: delay),
                    SKAction.fadeAlpha(to: CGFloat.random(in: 0.5...1.0), duration: 0.05),
                    SKAction.group([
                        SKAction.moveBy(x: cos(angle) * dist, y: sin(angle) * dist, duration: dotDur),
                        SKAction.sequence([
                            SKAction.wait(forDuration: dotDur * 0.5),
                            SKAction.fadeOut(withDuration: dotDur * 0.5)
                        ])
                    ]),
                    SKAction.removeFromParent()
                ]))
            }
        }

        // ── 3. STOFTEXPLOSION — 80 prickar som flyger ut från centrum ──
        for _ in 0..<80 {
            let size = CGFloat.random(in: 1...2)
            let dot = SKShapeNode(rectOf: CGSize(width: size, height: size))
            dot.fillColor = Bool.random() ? .white : (pastelColors.randomElement() ?? .white)
            dot.strokeColor = .clear
            dot.zPosition = 27
            dot.position = pos
            dot.alpha = 1.0
            addChild(dot)

            let angle = CGFloat.random(in: 0...(.pi * 2))
            let dist = CGFloat.random(in: 300...1400)
            let dur = Double.random(in: 0.6...1.5)

            dot.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: cos(angle) * dist, y: sin(angle) * dist, duration: dur),
                    SKAction.fadeOut(withDuration: dur)
                ]),
                SKAction.removeFromParent()
            ]))
        }

        // ── 4. STOFTREGN — 50 prickar som faller uppifrån ──
        for _ in 0..<50 {
            let size = CGFloat.random(in: 1...2)
            let dot = SKShapeNode(rectOf: CGSize(width: size, height: size))
            dot.fillColor = Bool.random() ? .white : (pastelColors.randomElement() ?? .white)
            dot.strokeColor = .clear
            dot.zPosition = 29
            dot.position = CGPoint(
                x: CGFloat.random(in: -200...2900),
                y: CGFloat.random(in: 1800...2200)
            )
            dot.alpha = 0.0
            addChild(dot)

            let delay = Double.random(in: 0.2...0.8)
            let fallDur = Double.random(in: 1.0...2.0)

            dot.run(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.fadeAlpha(to: CGFloat.random(in: 0.5...1.0), duration: 0.05),
                SKAction.group([
                    SKAction.moveBy(x: CGFloat.random(in: -80...80), y: CGFloat.random(in: -600 ... -300), duration: fallDur),
                    SKAction.sequence([
                        SKAction.wait(forDuration: fallDur * 0.6),
                        SKAction.fadeOut(withDuration: fallDur * 0.4)
                    ])
                ]),
                SKAction.removeFromParent()
            ]))
        }

        // ── 5. RÖKMOLN — 10 mjuka puffar ──
        for _ in 0..<10 {
            let radius = CGFloat.random(in: 50...100)
            let puff = SKShapeNode(circleOfRadius: radius)
            puff.fillColor = UIColor(white: CGFloat.random(in: 0.9...1.0), alpha: 1.0)
            puff.strokeColor = .clear
            puff.zPosition = 24
            puff.position = pos
            puff.alpha = CGFloat.random(in: 0.3...0.5)
            puff.setScale(0.3)
            addChild(puff)

            let lifetime = Double.random(in: 0.8...1.5)
            let angle = CGFloat.random(in: 0...(.pi * 2))
            let dist = CGFloat.random(in: 100...300)

            puff.run(SKAction.sequence([
                SKAction.group([
                    SKAction.scale(to: CGFloat.random(in: 3.0...6.0), duration: lifetime),
                    SKAction.fadeOut(withDuration: lifetime),
                    SKAction.moveBy(x: cos(angle) * dist, y: sin(angle) * dist + 40, duration: lifetime)
                ]),
                SKAction.removeFromParent()
            ]))
        }
    }

    // MARK: - Reset

    func reset() {
        self.removeAllActions()
        currentSprite?.removeAllActions()
        currentSprite?.removeAllChildren()
        currentSprite?.removeFromParent()
        currentSprite = nil
        earsCropNode?.removeAllActions()
        earsCropNode?.removeFromParent()
        earsCropNode = nil
        ballTrailEmitter = nil
        // Ta bort alla kvarvarande barn (rök, glitter, sparkles)
        let remaining = self.children
        for child in remaining {
            child.removeAllActions()
            child.removeFromParent()
        }
        state = .hidden
    }
}
