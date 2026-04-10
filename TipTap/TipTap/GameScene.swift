import SpriteKit

class GameScene: SKScene {

    // MARK: - State

    enum SceneState {
        case sleeping, wakingUp, awake, blowing, wobbling, exploding, goingToSleep
        case hatActive, toolboxActive, portraitActive
    }

    private var sceneState: SceneState = .sleeping
    private var owl: OwlNode!
    private var bubble: BubbleNode?
    private var needsReset = false

    // Hat & Rabbit (ears only for now)
    private var hatNode: HatNode!
    private var rabbitNode: RabbitNode!

    // Toolbox + Hammer
    private var toolboxNode: ToolboxNode!
    private var hammerNode: HammerNode!

    // Portrait
    private var portraitStep = 0  // 0 = ingen, 1 = portrait2 monterad, 3 = portrait1 monterad (tavlan klar)
    private var currentPortrait: SKSpriteNode?
    private var portraitGlow: SKEffectNode?
    private var hammerClones: [SKSpriteNode] = []
    private var paradePhase = 0  // 0=inaktiv, 1=dans klar väntar, 2=karusell klar väntar
    private var carouselNode: SKNode?
    private var deerGlow: SKEffectNode?
    private var deerNode: SKNode?  // Container för alla rådjursdelar

    // Rådjurets individuella delar
    private var deerHead: SKSpriteNode?
    private var deerBody: SKSpriteNode?
    private var deerTail: SKSpriteNode?
    private var deerFrontLeg1Up: SKSpriteNode?
    private var deerFrontLeg1Down: SKSpriteNode?
    private var deerFrontLeg2Up: SKSpriteNode?
    private var deerFrontLeg2Down: SKSpriteNode?
    private var deerBackLeg1Up: SKSpriteNode?
    private var deerBackLeg1Down: SKSpriteNode?
    private var deerBackLeg2Up: SKSpriteNode?
    private var deerBackLeg2Down: SKSpriteNode?

    // Bengrupper — håller ihop över+underben så de alltid sitter ihop
    private var frontLeg1Group: SKNode?
    private var frontLeg2Group: SKNode?
    private var backLeg1Group: SKNode?
    private var backLeg2Group: SKNode?
    private var isDeerDancing = false
    private var isDeerPostDance = false

    // Focus system
    private var transitionManager = TransitionManager()

    // MARK: - Update loop

    override func update(_ currentTime: TimeInterval) {
        if needsReset {
            needsReset = false
            resetHatSequence()
        }
    }

    // MARK: - Setup

    override func didMove(to view: SKView) {
        setupHall()
        setupOwl()
        setupHat()
        setupRabbit()
        setupToolbox()
        setupHammer()
        setupDebugReset()
        setupGokur()
    }

    private func setupGokur() {
        // Container för alla gökurs-delar
        let gokurContainer = SKNode()
        gokurContainer.position = CGPoint(x: 2139, y: 1421)
        gokurContainer.zPosition = 5
        gokurContainer.setScale(0.421)
        gokurContainer.name = "gokur"
        addChild(gokurContainer)
        transitionManager.registerObject(id: .gokur, sprite: gokurContainer)

        // Lod bakom gökuret (z = -1, -2, -3)
        for i in 1...3 {
            let lod = SKSpriteNode(imageNamed: "lod\(i)")
            lod.zPosition = -CGFloat(i)
            lod.name = "lod\(i)"
            gokurContainer.addChild(lod)
        }

        // Flytta lod 1 & 2 uppåt 150px
        gokurContainer.childNode(withName: "lod1")?.position.y += 150
        gokurContainer.childNode(withName: "lod2")?.position.y += 150

        // Lod 1 & 2: pendling upp och ner
        if let lod1 = gokurContainer.childNode(withName: "lod1") {
            let down1 = SKAction.moveBy(x: 0, y: -50, duration: 1.4)
            down1.timingMode = .easeInEaseOut
            let up1 = SKAction.moveBy(x: 0, y: 50, duration: 1.4)
            up1.timingMode = .easeInEaseOut
            lod1.run(SKAction.repeatForever(SKAction.sequence([down1, up1])), withKey: "lodPendel")
        }

        if let lod2 = gokurContainer.childNode(withName: "lod2") {
            // Lite förskjuten i tid och hastighet
            let down2 = SKAction.moveBy(x: 0, y: -45, duration: 1.6)
            down2.timingMode = .easeInEaseOut
            let up2 = SKAction.moveBy(x: 0, y: 45, duration: 1.6)
            up2.timingMode = .easeInEaseOut
            lod2.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.6),
                SKAction.repeatForever(SKAction.sequence([down2, up2]))
            ]), withKey: "lodPendel")
        }

        // Lod 3: pendlar fram och tillbaka (horisontellt)
        if let lod3 = gokurContainer.childNode(withName: "lod3") {
            let left = SKAction.moveBy(x: -18, y: 0, duration: 1.8)
            left.timingMode = .easeInEaseOut
            let right = SKAction.moveBy(x: 18, y: 0, duration: 1.8)
            right.timingMode = .easeInEaseOut
            lod3.run(SKAction.repeatForever(SKAction.sequence([left, right])), withKey: "lodPendel")
        }

        // Gökurets kropp framför loden
        let body = SKSpriteNode(imageNamed: "gokur_open")
        body.zPosition = 1
        body.name = "gokurBody"
        gokurContainer.addChild(body)

        // Glitter
        let glitter = SKNode()
        glitter.name = "gokurGlitter"
        glitter.zPosition = 2
        gokurContainer.addChild(glitter)

        let spawn = SKAction.run { [weak glitter] in
            guard let glitter else { return }

            let isStar = Int.random(in: 0...3) == 0
            let particle: SKShapeNode

            if isStar {
                let size = CGFloat.random(in: 4...10)
                let path = CGMutablePath()
                path.move(to: CGPoint(x: 0, y: size))
                path.addLine(to: CGPoint(x: size * 0.2, y: size * 0.2))
                path.addLine(to: CGPoint(x: size, y: 0))
                path.addLine(to: CGPoint(x: size * 0.2, y: -size * 0.2))
                path.addLine(to: CGPoint(x: 0, y: -size))
                path.addLine(to: CGPoint(x: -size * 0.2, y: -size * 0.2))
                path.addLine(to: CGPoint(x: -size, y: 0))
                path.addLine(to: CGPoint(x: -size * 0.2, y: size * 0.2))
                path.closeSubpath()
                particle = SKShapeNode(path: path)
            } else {
                particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...5))
            }

            switch Int.random(in: 0...2) {
            case 0: particle.fillColor = SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1.0)
            case 1: particle.fillColor = SKColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            default: particle.fillColor = SKColor(red: 1.0, green: 0.95, blue: 0.6, alpha: 1.0)
            }
            particle.strokeColor = .clear
            particle.glowWidth = isStar ? 2.0 : 1.0

            let x = CGFloat.random(in: -400...400)
            let y = CGFloat.random(in: -200...500)
            particle.position = CGPoint(x: x, y: y)
            particle.alpha = 0
            particle.setScale(CGFloat.random(in: 0.4...1.2))
            glitter.addChild(particle)

            let life = TimeInterval.random(in: 2.0...3.5)
            let peakAlpha: CGFloat = 0.5
            let pulseSpeed = TimeInterval.random(in: 0.5...1.0)

            let fadeIn = SKAction.fadeAlpha(to: peakAlpha, duration: life * 0.2)
            let drift = SKAction.moveBy(x: CGFloat.random(in: -8...8),
                                         y: CGFloat.random(in: 6...15), duration: life)
            let fadeOut = SKAction.fadeOut(withDuration: life * 0.3)

            let pulseCount = Int(life / (pulseSpeed * 2))
            let pulse = SKAction.repeat(SKAction.sequence([
                SKAction.fadeAlpha(to: peakAlpha * 0.15, duration: pulseSpeed),
                SKAction.fadeAlpha(to: peakAlpha, duration: pulseSpeed),
            ]), count: max(2, pulseCount))

            particle.run(SKAction.sequence([
                fadeIn,
                SKAction.group([pulse, drift]),
                fadeOut,
                SKAction.removeFromParent()
            ]))
        }
        let delay = SKAction.wait(forDuration: 0.18)
        glitter.run(SKAction.repeatForever(SKAction.sequence([spawn, delay])), withKey: "glitterLoop")
    }

    private var eggWaitingForTap = false
    private var muggWaitingForTap = false
    private var gokurActive = false
    private var gokurWaitingAfterTittut = false
    private var eggLuckaPos: CGPoint = .zero

    private func showGokurEgg(in container: SKNode) {
        // Ta bort eventuellt befintligt ägg
        container.childNode(withName: "gokurEgg")?.removeFromParent()
        eggWaitingForTap = false

        // Säkra att alla andra objekt är gömda
        transitionManager.activateObject(id: .gokur)
        owl.removeAllActions()
        owl.alpha = 0
        toolboxNode.fadeAway()

        let luckaPos = CGPoint(x: -30, y: 440)
        eggLuckaPos = luckaPos

        let egg = SKSpriteNode(imageNamed: "egg")
        egg.position = luckaPos
        egg.zPosition = 50
        egg.setScale(0.5)
        egg.alpha = 0
        egg.name = "gokurEgg"
        container.addChild(egg)

        let shake = SKAction.repeat(SKAction.sequence([
            SKAction.moveBy(x: 3, y: 0, duration: 0.04),
            SKAction.moveBy(x: -6, y: 0, duration: 0.06),
            SKAction.moveBy(x: 5, y: 0, duration: 0.04),
            SKAction.moveBy(x: -2, y: 0, duration: 0.04),
        ]), count: 8)

        let growDouble = SKAction.scale(to: 1.0, duration: 0.8)
        growDouble.timingMode = .easeInEaseOut

        egg.run(SKAction.sequence([
            // Poppa ut
            SKAction.group([
                SKAction.fadeAlpha(to: 1.0, duration: 0.15),
                SKAction.moveBy(x: 0, y: 50, duration: 0.3),
            ]),
            // Darra
            shake,
            // Väx till dubbla storleken
            growDouble,
            // Vänta på tap
            SKAction.run { [weak self] in
                self?.eggWaitingForTap = true
            },
            // Pulsera medan vi väntar på tap
            SKAction.repeatForever(SKAction.sequence([
                SKAction.scale(to: 1.05, duration: 0.6),
                SKAction.scale(to: 0.95, duration: 0.6),
            ]))
        ]))
    }

    private func tapEgg() {
        guard eggWaitingForTap,
              let gokurContainer = childNode(withName: "gokur"),
              let egg = gokurContainer.childNode(withName: "gokurEgg") as? SKSpriteNode else { return }
        eggWaitingForTap = false
        egg.removeAllActions()

        // Säkra att alla andra objekt är gömda under ägg-sekvensen
        transitionManager.activateObject(id: .gokur)
        owl.removeAllActions()
        owl.alpha = 0
        toolboxNode.fadeAway()

        // Beräkna scenens mittpunkt i gökur-containerns koordinater
        let sceneCenter = CGPoint(x: frame.midX, y: frame.midY)
        let centerInGokur = convert(sceneCenter, to: gokurContainer)

        // Flytta till mitten och väx till full storlek
        let moveToCenter = SKAction.move(to: centerInGokur, duration: 0.6)
        moveToCenter.timingMode = .easeInEaseOut
        let growFull = SKAction.scale(to: 3.5, duration: 0.6)
        growFull.timingMode = .easeInEaseOut

        // Slumpmässigt: knäckas eller snurra
        let doHatch = Bool.random()
        let egg1Tex = SKTexture(imageNamed: "egg")
        let egg2Tex = SKTexture(imageNamed: "egg2")

        var funSequence: [SKAction] = []

        if doHatch {
            // Alternativ 1: Knäcks → kyckling → tillbaka till ägg
            let hatchShake = SKAction.repeat(SKAction.sequence([
                SKAction.rotate(byAngle: 0.08, duration: 0.05),
                SKAction.rotate(byAngle: -0.16, duration: 0.08),
                SKAction.rotate(byAngle: 0.08, duration: 0.05),
            ]), count: 4)

            // Liten darr-funktion
            func miniShake() -> SKAction {
                SKAction.sequence([
                    SKAction.moveBy(x: 4, y: 0, duration: 0.03),
                    SKAction.moveBy(x: -7, y: 2, duration: 0.04),
                    SKAction.moveBy(x: 5, y: -3, duration: 0.03),
                    SKAction.moveBy(x: -2, y: 1, duration: 0.03),
                ])
            }

            func preBoom(_ s: CGFloat, _ d: TimeInterval) -> SKAction {
                let a = SKAction.scale(to: s, duration: d)
                a.timingMode = .easeInEaseOut
                return a
            }

            funSequence = [
                SKAction.wait(forDuration: 0.2),

                // --- Boom boom som okläckt! ---
                preBoom(4.0, 0.3),
                miniShake(),
                preBoom(3.2, 0.25),
                SKAction.wait(forDuration: 0.3),

                preBoom(4.4, 0.25),
                miniShake(),
                preBoom(3.0, 0.2),
                SKAction.wait(forDuration: 0.25),

                preBoom(4.8, 0.2),
                miniShake(), miniShake(),
                preBoom(2.8, 0.18),
                SKAction.wait(forDuration: 0.2),

                // Sista stora BOOM innan kläckning
                preBoom(5.2, 0.15),
                miniShake(), miniShake(), miniShake(),
                preBoom(2.5, 0.15),
                SKAction.wait(forDuration: 0.15),

                hatchShake,

                // --- Vers 1: Långsam öppning, stor puls ---
                SKAction.scale(to: 4.2, duration: 0.18),
                SKAction.setTexture(egg2Tex, resize: false),
                SKAction.scale(to: 3.0, duration: 0.15),
                miniShake(),
                SKAction.scale(to: 3.5, duration: 0.12),
                SKAction.wait(forDuration: 0.6),

                // --- Vers 2: Snabbare rytm, stängs-öppnas ---
                SKAction.scale(to: 2.5, duration: 0.06),
                SKAction.setTexture(egg1Tex, resize: false),
                SKAction.scale(to: 3.8, duration: 0.08),
                miniShake(),
                SKAction.scale(to: 3.5, duration: 0.06),
                SKAction.wait(forDuration: 0.1),

                SKAction.scale(to: 2.8, duration: 0.05),
                SKAction.setTexture(egg2Tex, resize: false),
                SKAction.scale(to: 4.3, duration: 0.1),
                SKAction.scale(to: 3.5, duration: 0.08),
                SKAction.wait(forDuration: 0.15),

                // --- Refräng: Snabb dubbelpuls + darr ---
                SKAction.scale(to: 2.5, duration: 0.04),
                SKAction.setTexture(egg1Tex, resize: false),
                SKAction.scale(to: 4.0, duration: 0.06),
                SKAction.scale(to: 3.0, duration: 0.04),
                SKAction.scale(to: 4.2, duration: 0.06),
                miniShake(),
                SKAction.scale(to: 3.5, duration: 0.08),
                SKAction.wait(forDuration: 0.08),

                SKAction.scale(to: 2.8, duration: 0.04),
                SKAction.setTexture(egg2Tex, resize: false),
                SKAction.scale(to: 4.5, duration: 0.08),  // största!
                miniShake(),
                SKAction.scale(to: 2.5, duration: 0.06),
                SKAction.scale(to: 3.8, duration: 0.08),
                SKAction.scale(to: 3.5, duration: 0.06),
                SKAction.wait(forDuration: 0.3),

                // --- Brygga: Långsam, mjuk ---
                SKAction.scale(to: 3.8, duration: 0.25),
                SKAction.scale(to: 3.2, duration: 0.3),
                SKAction.scale(to: 3.6, duration: 0.2),
                SKAction.wait(forDuration: 0.2),

                // --- Outro: Snabb staccato, stängs ---
                SKAction.scale(to: 2.5, duration: 0.04),
                SKAction.setTexture(egg1Tex, resize: false),
                SKAction.scale(to: 3.9, duration: 0.06),
                miniShake(),
                SKAction.scale(to: 3.0, duration: 0.04),
                SKAction.setTexture(egg2Tex, resize: false),
                SKAction.scale(to: 4.0, duration: 0.06),
                SKAction.scale(to: 3.2, duration: 0.04),
                SKAction.setTexture(egg1Tex, resize: false),
                SKAction.scale(to: 3.7, duration: 0.06),
                miniShake(),
                SKAction.scale(to: 3.5, duration: 0.1),
                SKAction.wait(forDuration: 0.3),
            ]
        } else {
            // Alternativ 2: Mäktig slow-motion puls med snabba inslag
            func swell(_ s: CGFloat, _ d: TimeInterval) -> SKAction {
                let a = SKAction.scale(to: s, duration: d)
                a.timingMode = .easeInEaseOut
                return a
            }
            func snap(_ s: CGFloat) -> SKAction { SKAction.scale(to: s, duration: 0.04) }
            func softShake() -> SKAction {
                SKAction.sequence([
                    SKAction.moveBy(x: 3, y: -1, duration: 0.04),
                    SKAction.moveBy(x: -5, y: 2, duration: 0.06),
                    SKAction.moveBy(x: 4, y: -2, duration: 0.04),
                    SKAction.moveBy(x: -2, y: 1, duration: 0.04),
                ])
            }

            funSequence = [
                SKAction.wait(forDuration: 0.3),

                // --- Andning: långsam uppbyggnad ---
                swell(4.2, 0.5),
                swell(3.0, 0.4),
                SKAction.wait(forDuration: 0.2),
                swell(4.6, 0.6),
                swell(2.8, 0.5),
                SKAction.wait(forDuration: 0.25),

                // --- Hjärtslag: djupa, mjuka pulser ---
                swell(5.0, 0.4),
                softShake(),
                swell(2.5, 0.35),
                SKAction.wait(forDuration: 0.3),
                swell(5.3, 0.45),
                softShake(),
                swell(2.3, 0.35),
                SKAction.wait(forDuration: 0.35),

                // --- SNAP: plötsligt snabbt inslag + kyckling-blink ---
                snap(5.8), softShake(),
                SKAction.setTexture(egg2Tex, resize: false),
                SKAction.wait(forDuration: 0.07),
                SKAction.setTexture(egg1Tex, resize: false),
                swell(2.0, 0.5),
                SKAction.wait(forDuration: 0.4),

                // --- Stor våg: långsammast, mäktigast ---
                swell(5.5, 0.7),
                swell(2.5, 0.6),
                swell(5.8, 0.8),
                softShake(), softShake(),
                swell(2.0, 0.7),
                SKAction.wait(forDuration: 0.3),

                // --- DUBBEL-SNAP: två snabba mitt i lugnet ---
                snap(5.5), snap(2.5), snap(6.0),
                softShake(),
                swell(2.2, 0.6),
                SKAction.wait(forDuration: 0.3),

                // --- Utandning: mjuk landning ---
                swell(4.0, 0.5),
                swell(3.3, 0.4),
                swell(3.7, 0.3),
                swell(3.5, 0.25),
                SKAction.wait(forDuration: 0.3),
            ]
        }

        // Åk tillbaka till luckan
        let returnPos = CGPoint(x: eggLuckaPos.x, y: eggLuckaPos.y + 220)
        let returnToLucka = SKAction.move(to: returnPos, duration: 2.5)
        returnToLucka.timingMode = .easeIn
        let shrinkBack = SKAction.scale(to: 0.3, duration: 0.5)
        shrinkBack.timingMode = .easeIn

        let fullSequence: [SKAction] = [
            SKAction.group([moveToCenter, growFull]),
        ] + funSequence + [
            // Lekfullt tillbaka — pulserande krympning, aldrig under 0.5
            SKAction.group([
                returnToLucka,
                SKAction.rotate(toAngle: 0, duration: 0.5),
                SKAction.sequence([
                    SKAction.scale(to: 2.5, duration: 0.2),
                    SKAction.scale(to: 1.5, duration: 0.18),
                    SKAction.scale(to: 2.2, duration: 0.2),
                    SKAction.scale(to: 1.2, duration: 0.18),
                    SKAction.scale(to: 1.9, duration: 0.18),
                    SKAction.scale(to: 1.0, duration: 0.16),
                    SKAction.scale(to: 1.5, duration: 0.16),
                    SKAction.scale(to: 0.8, duration: 0.15),
                    SKAction.scale(to: 1.1, duration: 0.14),
                    SKAction.scale(to: 0.7, duration: 0.14),
                    SKAction.scale(to: 0.9, duration: 0.12),
                    SKAction.scale(to: 0.6, duration: 0.12),
                    SKAction.scale(to: 0.7, duration: 0.1),
                    SKAction.scale(to: 0.5, duration: 0.1),
                ]),
            ]),
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.run { [weak self] in
                // Stäng luckan och fada tillbaka alla objekt
                guard let self else { return }
                guard let body = gokurContainer.childNode(withName: "gokurBody") as? SKSpriteNode else { return }
                body.texture = SKTexture(imageNamed: "gokur_open")
                // Fada tillbaka efter en stunds lugn
                self.run(SKAction.sequence([
                    SKAction.wait(forDuration: 1.5),
                    SKAction.run {
                        self.gokurActive = false
                        self.transitionManager.deactivateAll()
                        self.toolboxNode.fadeBack()
                        self.owl.run(SKAction.sequence([
                            SKAction.wait(forDuration: 0.8),
                            SKAction.fadeIn(withDuration: 3.0),
                            SKAction.run { [weak self] in
                                self?.owl.startSleeping()
                            }
                        ]))
                    }
                ]))
            },
            SKAction.removeFromParent()
        ]

        egg.run(SKAction.sequence(fullSequence))
    }

    private func tapMugg() {
        guard muggWaitingForTap,
              let gokurContainer = childNode(withName: "gokur"),
              let mugg = gokurContainer.childNode(withName: "gokurMugg") as? SKSpriteNode else { return }
        muggWaitingForTap = false
        mugg.removeAllActions()

        // Säkra att allt är gömt
        transitionManager.activateObject(id: .gokur)
        owl.removeAllActions()
        owl.alpha = 0
        toolboxNode.fadeAway()

        let idleTex = SKTexture(imageNamed: "gokur_open")
        let muggTextures = (1...5).map { SKTexture(imageNamed: "mugg\($0)") }
        let returnPos = mugg.position

        // Beräkna scenens mittpunkt i gökur-containerns koordinater
        let sceneCenter = CGPoint(x: frame.midX, y: frame.midY)
        let centerInGokur = convert(sceneCenter, to: gokurContainer)

        // Flytta till mitten och väx
        let moveToCenter = SKAction.move(to: centerInGokur, duration: 0.5)
        moveToCenter.timingMode = .easeInEaseOut
        let growBig = SKAction.scale(to: 2.8, duration: 0.5)
        growBig.timingMode = .easeInEaseOut

        // Outer glow (Photoshop-stil) — stor spread, transparens 0.5
        let muggGlow = SKEffectNode()
        muggGlow.shouldRasterize = true
        muggGlow.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 60.0])
        muggGlow.zPosition = -1
        muggGlow.alpha = 0
        let glowSprite = SKSpriteNode(imageNamed: "mugg1")
        glowSprite.setScale(1.6)
        glowSprite.colorBlendFactor = 1.0
        glowSprite.color = SKColor(red: 1.0, green: 1.0, blue: 0.95, alpha: 1.0)
        muggGlow.addChild(glowSprite)
        mugg.addChild(muggGlow)

        let shimmer = SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.45, duration: 1.2),
            SKAction.fadeAlpha(to: 0.2, duration: 1.0),
            SKAction.fadeAlpha(to: 0.5, duration: 0.8),
            SKAction.fadeAlpha(to: 0.15, duration: 1.4),
        ]))
        muggGlow.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.fadeAlpha(to: 0.4, duration: 0.5),
            shimmer
        ]))

        // Disco-glitter / solkatter som virvlar runt i hela rummet, bakom muggen
        let glitterNode = SKNode()
        glitterNode.zPosition = -2  // bakom muggen
        glitterNode.name = "muggGlitter"
        mugg.addChild(glitterNode)

        let spawnGlitter = SKAction.run { [weak glitterNode] in
            guard let glitterNode else { return }

            let isStar = Int.random(in: 0...2) == 0
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 4...12))

            if isStar {
                let size = CGFloat.random(in: 6...16)
                let path = CGMutablePath()
                path.move(to: CGPoint(x: 0, y: size))
                path.addLine(to: CGPoint(x: size * 0.2, y: size * 0.2))
                path.addLine(to: CGPoint(x: size, y: 0))
                path.addLine(to: CGPoint(x: size * 0.2, y: -size * 0.2))
                path.addLine(to: CGPoint(x: 0, y: -size))
                path.addLine(to: CGPoint(x: -size * 0.2, y: -size * 0.2))
                path.addLine(to: CGPoint(x: -size, y: 0))
                path.addLine(to: CGPoint(x: -size * 0.2, y: size * 0.2))
                path.closeSubpath()
                particle.path = path
            }

            switch Int.random(in: 0...3) {
            case 0: particle.fillColor = SKColor(red: 1.0, green: 0.95, blue: 0.6, alpha: 1.0)
            case 1: particle.fillColor = .white
            case 2: particle.fillColor = SKColor(red: 1.0, green: 0.85, blue: 0.4, alpha: 1.0)
            default: particle.fillColor = SKColor(red: 0.95, green: 1.0, blue: 0.85, alpha: 1.0)
            }
            particle.strokeColor = .clear
            particle.glowWidth = isStar ? 4.0 : 2.0
            particle.blendMode = .add

            // Startar utspritt över hela rummet
            let startAngle = CGFloat.random(in: 0...(.pi * 2))
            let startRadius = CGFloat.random(in: 150...800)
            particle.position = CGPoint(x: cos(startAngle) * startRadius, y: sin(startAngle) * startRadius)
            particle.alpha = 0
            particle.setScale(CGFloat.random(in: 0.5...2.0))
            glitterNode.addChild(particle)

            // Virvlar i stora bågar genom rummet
            let arcAngle = CGFloat.random(in: 1.0...3.0) * (Bool.random() ? 1 : -1)
            let life = TimeInterval.random(in: 0.8...2.0)
            let endAngle = startAngle + arcAngle
            let endRadius = CGFloat.random(in: 150...800)
            let endPos = CGPoint(x: cos(endAngle) * endRadius, y: sin(endAngle) * endRadius)

            let peakAlpha = CGFloat.random(in: 0.4...0.8)
            particle.run(SKAction.sequence([
                SKAction.fadeAlpha(to: peakAlpha, duration: life * 0.15),
                SKAction.group([
                    SKAction.move(to: endPos, duration: life * 0.7),
                    SKAction.rotate(byAngle: CGFloat.random(in: 2...6), duration: life * 0.7),
                    SKAction.scale(to: CGFloat.random(in: 0.3...1.5), duration: life * 0.7),
                ]),
                SKAction.fadeOut(withDuration: life * 0.15),
                SKAction.removeFromParent()
            ]))
        }

        glitterNode.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.repeatForever(SKAction.sequence([
                spawnGlitter, spawnGlitter, spawnGlitter,
                SKAction.wait(forDuration: 0.04),
            ]))
        ]))

        func boom(_ s: CGFloat, _ d: TimeInterval) -> SKAction {
            let a = SKAction.scale(to: s, duration: d)
            a.timingMode = .easeInEaseOut
            return a
        }
        func snap(_ s: CGFloat) -> SKAction { SKAction.scale(to: s, duration: 0.04) }
        func shake() -> SKAction {
            SKAction.sequence([
                SKAction.moveBy(x: 4, y: -2, duration: 0.03),
                SKAction.moveBy(x: -7, y: 3, duration: 0.04),
                SKAction.moveBy(x: 5, y: -2, duration: 0.03),
                SKAction.moveBy(x: -2, y: 1, duration: 0.03),
            ])
        }
        func randomMugg() -> SKAction {
            SKAction.setTexture(muggTextures[Int.random(in: 0..<muggTextures.count)], resize: false)
        }

        // Specifika ansikten
        let mugg1 = muggTextures[0]  // normalt ansikte
        let mugg2 = muggTextures[1]  // ögon stängda (blinkar)
        let mugg3 = muggTextures[2]  // stora ögon (tittar)
        let mugg4 = muggTextures[3]  // blinkar med ena ögat
        let mugg5 = muggTextures[4]  // räcker ut tungan

        // Blink-helpers (blixtsnabbt ansiktsbyte)
        func face(_ tex: SKTexture) -> SKAction { SKAction.setTexture(tex, resize: false) }
        func blink(_ tex: SKTexture, _ dur: TimeInterval = 0.06) -> [SKAction] {
            [face(tex), SKAction.wait(forDuration: dur), face(mugg1)]
        }

        // === KOREOGRAFI: Frysta ögonblick ===
        // Varje "slag" = BOOM till stor storlek → FRYS → ett ansiktsbyte → BOOM tillbaka
        // Som en dansare som slår en pose, fryser, skiftar blick, och slår nästa

        let akt1: [SKAction] = [
            // --- Entré: Mjuk boom in ---
            SKAction.group([moveToCenter, growBig]),
            boom(3.0, 0.15), shake(),
            boom(2.6, 0.2),
            SKAction.wait(forDuration: 0.8),

            // --- Lugnt: Muggen tittar sig omkring ---
            boom(3.2, 0.5),
            SKAction.wait(forDuration: 0.4),
            face(mugg2),
            SKAction.wait(forDuration: 0.4),
            face(mugg1),
            SKAction.wait(forDuration: 0.6),
            face(mugg3),
            SKAction.wait(forDuration: 0.5),
            face(mugg1),
            boom(2.6, 0.4),
            SKAction.wait(forDuration: 0.5),
        ]

        let akt2: [SKAction] = [
            // --- Tittut börjar: lugnt men lekfullt ---
            boom(3.5, 0.35), shake(),
            face(mugg2),
            SKAction.wait(forDuration: 0.25),
            face(mugg1),
            boom(2.5, 0.3),
            SKAction.wait(forDuration: 0.4),

            boom(3.6, 0.3),
            face(mugg4),
            SKAction.wait(forDuration: 0.35),
            face(mugg1),
            boom(2.5, 0.25),
            SKAction.wait(forDuration: 0.5),

            // Överraskning — snabb blink!
            snap(3.8), shake(),
            face(mugg2), SKAction.wait(forDuration: 0.15), face(mugg1),
            boom(2.5, 0.2),
            SKAction.wait(forDuration: 0.5),
        ]

        let akt3: [SKAction] = [
            // --- Nyckfullt: Växlar tempo ---
            boom(3.4, 0.5),
            face(mugg3),
            SKAction.wait(forDuration: 0.5),
            face(mugg1),
            boom(2.5, 0.4),
            SKAction.wait(forDuration: 0.3),

            // Plötsligt snabbt!
            snap(4.0), shake(),
            face(mugg2), SKAction.wait(forDuration: 0.12), face(mugg1),
            boom(2.5, 0.12),

            // Lugnt igen...
            SKAction.wait(forDuration: 0.5),
            boom(3.5, 0.4),
            face(mugg4),
            SKAction.wait(forDuration: 0.4),
            face(mugg1),
            boom(2.5, 0.35),
            SKAction.wait(forDuration: 0.3),

            // Snabbt igen!
            snap(4.2), shake(), shake(),
            face(mugg3), SKAction.wait(forDuration: 0.12), face(mugg1),
            boom(2.5, 0.12),
            SKAction.wait(forDuration: 0.4),
        ]

        let akt4: [SKAction] = [
            // --- Crescendo ---
            boom(3.8, 0.25), shake(),
            face(mugg2), SKAction.wait(forDuration: 0.15), face(mugg1),
            boom(2.4, 0.2),
            SKAction.wait(forDuration: 0.15),

            boom(4.0, 0.2), shake(),
            face(mugg4), SKAction.wait(forDuration: 0.15), face(mugg1),
            boom(2.3, 0.15),
            SKAction.wait(forDuration: 0.12),

            snap(4.3), shake(),
            face(mugg3), SKAction.wait(forDuration: 0.12), face(mugg1),
            boom(2.3, 0.12),
            SKAction.wait(forDuration: 0.1),

            snap(4.5), shake(),
            face(mugg2), SKAction.wait(forDuration: 0.1), face(mugg1),
            boom(2.3, 0.1),
            SKAction.wait(forDuration: 0.08),

            snap(4.7), shake(), shake(),
            face(mugg4), SKAction.wait(forDuration: 0.08), face(mugg1),
            boom(2.3, 0.08),
            SKAction.wait(forDuration: 0.15),
        ]

        let finale: [SKAction] = [
            // --- Andning in ---
            boom(1.8, 0.4),
            SKAction.wait(forDuration: 0.3),

            // --- BIGGEST BOOM + TUNGAN ---
            snap(5.0), shake(), shake(), shake(),
            face(mugg5),
            SKAction.wait(forDuration: 1.0),

            // --- Mjuk nedstängning ---
            face(mugg2),
            boom(3.5, 0.4),
            SKAction.wait(forDuration: 0.4),
            face(mugg1),
            boom(2.8, 0.5),
            SKAction.wait(forDuration: 0.3),
        ]

        let boomSequence = akt1 + akt2 + akt3 + akt4 + finale

        // Pulserande retur till luckan
        let returnToLucka = SKAction.move(to: returnPos, duration: 2.0)
        returnToLucka.timingMode = .easeIn

        let returnSequence: [SKAction] = [
            SKAction.group([
                returnToLucka,
                SKAction.sequence([
                    boom(1.8, 0.15), boom(1.0, 0.12),
                    boom(1.5, 0.13), boom(0.85, 0.12),
                    boom(1.3, 0.12), boom(0.75, 0.11),
                    boom(1.1, 0.11), boom(0.7, 0.1),
                    boom(0.9, 0.1), boom(0.6, 0.1),
                    boom(0.75, 0.08), boom(0.55, 0.08),
                ]),
            ]),
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.run { [weak self] in
                guard let self else { return }
                guard let body = gokurContainer.childNode(withName: "gokurBody") as? SKSpriteNode else { return }
                body.texture = idleTex
                self.run(SKAction.sequence([
                    SKAction.wait(forDuration: 1.5),
                    SKAction.run {
                        self.gokurActive = false
                        self.transitionManager.deactivateAll()
                        self.toolboxNode.fadeBack()
                        self.owl.run(SKAction.sequence([
                            SKAction.wait(forDuration: 0.8),
                            SKAction.fadeIn(withDuration: 3.0),
                            SKAction.run { [weak self] in
                                self?.owl.startSleeping()
                            }
                        ]))
                    }
                ]))
            },
            SKAction.removeFromParent()
        ]

        mugg.run(SKAction.sequence(boomSequence + returnSequence))
    }

    private func showGokurMugg(in container: SKNode) {
        container.childNode(withName: "gokurMugg")?.removeFromParent()

        // Säkra att alla andra objekt är gömda
        transitionManager.activateObject(id: .gokur)
        owl.removeAllActions()
        owl.alpha = 0
        toolboxNode.fadeAway()

        let mugg = SKSpriteNode(imageNamed: "mugg1")
        mugg.position = CGPoint(x: 50, y: 320)  // vid stora luckan
        mugg.zPosition = 50
        mugg.setScale(0.1)
        mugg.alpha = 0
        mugg.name = "gokurMugg"
        container.addChild(mugg)

        let idleTex = SKTexture(imageNamed: "gokur_open")

        // Poppa ut liten, väx, darr, stanna, krympa tillbaka
        let shake = SKAction.repeat(SKAction.sequence([
            SKAction.moveBy(x: 3, y: 0, duration: 0.04),
            SKAction.moveBy(x: -5, y: 2, duration: 0.05),
            SKAction.moveBy(x: 4, y: -3, duration: 0.04),
            SKAction.moveBy(x: -2, y: 1, duration: 0.03),
        ]), count: 5)

        mugg.run(SKAction.sequence([
            // Poppa ut
            SKAction.group([
                SKAction.fadeAlpha(to: 1.0, duration: 0.1),
                SKAction.sequence([
                    SKAction.scale(to: 0.58, duration: 0.15),
                    SKAction.scale(to: 0.45, duration: 0.08),
                    SKAction.scale(to: 0.52, duration: 0.06),
                ]),
                SKAction.moveBy(x: 0, y: 40, duration: 0.2),
            ]),
            // Darr
            shake,
            // Väx till full storlek (1.3x av förut)
            SKAction.scale(to: 0.72, duration: 0.5),
            // Vänta på tap — darra medan vi väntar
            SKAction.run { [weak self] in
                self?.muggWaitingForTap = true
            },
            SKAction.repeatForever(SKAction.sequence([
                SKAction.moveBy(x: 3, y: 0, duration: 0.06),
                SKAction.moveBy(x: -5, y: 1, duration: 0.08),
                SKAction.moveBy(x: 4, y: -2, duration: 0.06),
                SKAction.moveBy(x: -2, y: 1, duration: 0.05),
                SKAction.wait(forDuration: 0.15),
            ]))
        ]))
    }

    private func tapGokur() {
        guard let gokurContainer = childNode(withName: "gokur"),
              let body = gokurContainer.childNode(withName: "gokurBody") as? SKSpriteNode else { return }

        // Efter tittut — slumpa bara mellan ägg och stor lucka
        let variant: Int
        if gokurWaitingAfterTittut {
            gokurWaitingAfterTittut = false
            variant = Bool.random() ? 0 : 1  // ägg eller stor lucka
        } else {
            variant = Int.random(in: 0...2)
        }
        let openTex: SKTexture
        switch variant {
        case 0: openTex = SKTexture(imageNamed: "gokur_open_liten")   // lilla luckan
        case 1: openTex = SKTexture(imageNamed: "gokur_open_stor")    // stora luckan
        default: openTex = SKTexture(imageNamed: "gokur_closed")       // båda luckorna
        }
        let idleTex = SKTexture(imageNamed: "gokur_open")

        body.removeAction(forKey: "gokurTap")

        // Fada ut andra objekt (om inte redan utfadade)
        if !gokurActive {
            gokurActive = true
            transitionManager.activateObject(id: .gokur)
            toolboxNode.fadeAway()
            owl.removeAllActions()
            owl.run(SKAction.fadeOut(withDuration: 0.4), withKey: "gokurFade")
        }

        // Visa ägg vid lilla luckan
        let showEgg = variant == 0
        let bothDoors = variant == 2
        let closedTex = SKTexture(imageNamed: "gokur_closed")  // båda öppna

        if showEgg {
            // Luckan förblir öppen tills ägget åker tillbaka
            body.texture = openTex
            showGokurEgg(in: gokurContainer)
        } else if bothDoors {
            // Tittut! Öppna och stäng luckorna lekfullt
            body.run(SKAction.sequence([
                // Första tittut — långsamt
                SKAction.setTexture(closedTex, resize: false),
                SKAction.wait(forDuration: 0.6),
                SKAction.setTexture(idleTex, resize: false),
                SKAction.wait(forDuration: 0.4),

                // Andra — lite snabbare
                SKAction.setTexture(closedTex, resize: false),
                SKAction.wait(forDuration: 0.4),
                SKAction.setTexture(idleTex, resize: false),
                SKAction.wait(forDuration: 0.3),

                // Tredje — snabbt
                SKAction.setTexture(closedTex, resize: false),
                SKAction.wait(forDuration: 0.2),
                SKAction.setTexture(idleTex, resize: false),
                SKAction.wait(forDuration: 0.15),

                // Fjärde — blixtsnabbt
                SKAction.setTexture(closedTex, resize: false),
                SKAction.wait(forDuration: 0.1),
                SKAction.setTexture(idleTex, resize: false),
                SKAction.wait(forDuration: 0.1),

                // Femte — blixtsnabbt
                SKAction.setTexture(closedTex, resize: false),
                SKAction.wait(forDuration: 0.08),
                SKAction.setTexture(idleTex, resize: false),
                SKAction.wait(forDuration: 0.08),

                // Paus — håller öppet
                SKAction.setTexture(closedTex, resize: false),
                SKAction.wait(forDuration: 0.8),

                // Sista stängning — väntar på nästa tap
                SKAction.setTexture(idleTex, resize: false),

                SKAction.run { [weak self] in
                    self?.gokurWaitingAfterTittut = true
                }
            ]), withKey: "gokurTap")
        } else {
            // Stor lucka — mugg dyker upp
            body.texture = openTex
            showGokurMugg(in: gokurContainer)
        }
    }

    private func setupHall() {
        let bg = SKSpriteNode(imageNamed: "hall_day")
        bg.position = CGPoint(x: frame.midX, y: frame.midY)
        bg.zPosition = 0
        bg.name = "hall"
        addChild(bg)
    }

    private func setupOwl() {
        owl = OwlNode()
        owl.position = CGPoint(x: 2331, y: 678)
        owl.zPosition = 10
        owl.name = "owl"


        owl.onAwake = { [weak self] in
            self?.sceneState = .awake
        }

        owl.onTap2 = { [weak self] in
            self?.startBubbleSequence()
        }

        owl.onSleeping = { [weak self] in
            guard let self else { return }
            guard !self.gokurActive else { return }  // Stör inte gökur-sekvensen
            self.sceneState = .sleeping
            self.transitionManager.deactivateAll()
            self.toolboxNode.fadeBack()
            if self.portraitStep == 3 { self.startPortraitGlow() }
        }

        addChild(owl)
        transitionManager.registerObject(id: .owl, sprite: owl)
    }

    private func setupHat() {
        hatNode = HatNode()
        hatNode.position = CGPoint(x: 715, y: 408)
        hatNode.zPosition = 10
        hatNode.name = "hat"


        addChild(hatNode)
        transitionManager.registerObject(id: .hat, sprite: hatNode)
    }

    private func setupRabbit() {
        rabbitNode = RabbitNode()
        rabbitNode.zPosition = 15
        addChild(rabbitNode)

        rabbitNode.onEarsComplete = {
            // Ears breathing, waiting for tap → rise
        }
    }

    private func setupToolbox() {
        toolboxNode = ToolboxNode()
        toolboxNode.position = CGPoint(x: 1222, y: 1898)
        toolboxNode.zPosition = 10
        toolboxNode.name = "toolbox"
        addChild(toolboxNode)
        transitionManager.registerObject(id: .toolbox, sprite: toolboxNode)
    }

    private func setupHammer() {
        hammerNode = HammerNode()
        hammerNode.zPosition = 14
        hammerNode.name = "hammer"
        addChild(hammerNode)
    }

    // MARK: - Debug Reset Button

    private func setupDebugReset() {
        let radius: CGFloat = 40
        let diameter = radius * 2
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: diameter, height: diameter))
        let image = renderer.image { ctx in
            UIColor.white.withAlphaComponent(0.3).setFill()
            ctx.cgContext.fillEllipse(in: CGRect(x: 0, y: 0, width: diameter, height: diameter))
        }
        let texture = SKTexture(image: image)
        let btn = SKSpriteNode(texture: texture, size: CGSize(width: diameter, height: diameter))
        btn.position = CGPoint(x: 150, y: 1900)
        btn.zPosition = 1000
        btn.name = "debugReset"
        addChild(btn)
    }

    private func debugResetScene() {
        removeAllChildren()
        removeAllActions()
        bubble = nil
        sceneState = .sleeping
        portraitStep = 0
        currentPortrait = nil
        gokurActive = false
        gokurWaitingAfterTittut = false
        eggWaitingForTap = false
        muggWaitingForTap = false
        transitionManager = TransitionManager()
        setupHall()
        setupOwl()
        setupHat()
        setupRabbit()
        setupToolbox()
        setupHammer()
        setupDebugReset()

        // Mjuk fade-in för ugglan efter reset
        owl.removeAllActions()
        owl.alpha = 0.0
        owl.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.9),
            SKAction.fadeIn(withDuration: 3.0)
        ]))

        // Mjuk fade-in för toolbox efter reset
        toolboxNode.removeAction(forKey: "alphaPulse")
        toolboxNode.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.9),
            SKAction.run { [weak self] in
                self?.toolboxNode.fadeBack(duration: 3.0)
            }
        ]))
    }

    // MARK: - Bubbel-sekvens (Owl Tap 2)

    private func startBubbleSequence() {
        guard sceneState == .awake else { return }
        sceneState = .blowing

        let bubble = BubbleNode()
        bubble.zPosition = 20
        bubble.name = "bubble"
        addChild(bubble)
        self.bubble = bubble

        owl.startBlowing()
        owl.startTrembling()
        bubble.startGrowing()

        bubble.onGrowComplete = { [weak self] in
            guard let self else { return }
            self.owl.stopTrembling()
            self.owl.startAwake()
            bubble.startWobble()
            self.sceneState = .wobbling
        }
    }

    // MARK: - Explosion (Owl Tap 3)

    private func popBubble() {
        guard sceneState == .wobbling, let bubble else { return }
        sceneState = .exploding

        // Frys ugglan vid massiva pion-explosionen, återuppta efter den fallit
        run(SKAction.sequence([
            SKAction.wait(forDuration: 7.8),
            SKAction.run { [weak self] in self?.owl.freeze() },
            SKAction.wait(forDuration: 1.75),
            SKAction.run { [weak self] in self?.owl.unfreeze() }
        ]), withKey: "owlFreeze")

        bubble.pop(in: self) { [weak self, weak bubble] in
            guard let self else { return }
            bubble?.removeFromParent()
            self.bubble = nil
            self.sceneState = .goingToSleep
            self.owl.goToSleep()
        }
    }

    // MARK: - Toolbox Sequence

    private func startToolboxSequence() {
        sceneState = .toolboxActive
        stopPortraitGlow()
        transitionManager.activateObject(id: .toolbox)

        // Göm ugglan helt under hammar-sekvensen
        owl.removeAllActions()
        owl.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.6),
            SKAction.run { [weak self] in self?.owl.isHidden = true }
        ]), withKey: "owlFade")

        let hammerOrigin = toolboxNode.position
        let hammerCenter = CGPoint(x: frame.midX - 300, y: frame.midY)
        hammerNode.peekABoo(from: hammerOrigin, to: hammerCenter)
    }

    // MARK: - Portrait Sequence (tap idle hammer)

    private func startPortraitSequence() {
        let screenCenter = CGPoint(x: frame.midX, y: frame.midY)
        let wallPos = CGPoint(x: 1495, y: 1450) // höger om dörren

        // Blockera ytterligare tap under hela sekvensen
        portraitStep = -1

        // Hammaren slår till med blixt, sedan tonar ut
        hammerNode.quickStrike { [weak self] in
            guard let self else { return }

            // Portrait dyker upp centriskt i full storlek
            let portrait = SKSpriteNode(imageNamed: "portrait_hall2")
            portrait.position = screenCenter
            portrait.zPosition = 5
            portrait.setScale(1.0)
            portrait.alpha = 0
            portrait.name = "portrait"
            self.addChild(portrait)
            self.currentPortrait = portrait

            portrait.run(SKAction.sequence([
                // Väntar — tomt i bilden, bygger förväntan
                SKAction.wait(forDuration: 1.0),
                // Fadar in långsamt
                SKAction.fadeAlpha(to: 1.0, duration: 0.6),

                // Vibrerar på plats ~2.5 sekunder
                SKAction.repeat(SKAction.sequence([
                    SKAction.moveBy(x: 3, y: 2, duration: 0.04),
                    SKAction.moveBy(x: -5, y: -3, duration: 0.06),
                    SKAction.moveBy(x: 4, y: 2, duration: 0.05),
                    SKAction.moveBy(x: -2, y: -1, duration: 0.04)
                ]), count: 13),

                // Flyger till väggen höger om dörren
                SKAction.group([
                    SKAction.move(to: wallPos, duration: 0.6),
                    SKAction.scale(to: 0.289, duration: 0.6)
                ])
            ]))

            // Flash + hammer comeback efter portrait landat
            self.run(SKAction.sequence([
                SKAction.wait(forDuration: 5.5),
                SKAction.run { [weak self] in
                    guard let self else { return }

                    let flash2 = SKSpriteNode(color: .white,
                                              size: CGSize(width: self.frame.width, height: self.frame.height))
                    flash2.position = screenCenter
                    flash2.zPosition = 999
                    flash2.alpha = 0
                    self.addChild(flash2)
                    flash2.run(SKAction.sequence([
                        SKAction.fadeAlpha(to: 0.3, duration: 0.02),
                        SKAction.fadeAlpha(to: 0.0, duration: 0.03),
                        SKAction.fadeAlpha(to: 0.2, duration: 0.02),
                        SKAction.fadeOut(withDuration: 0.06),
                        SKAction.removeFromParent()
                    ]))

                    let hammerPos = CGPoint(x: self.frame.midX - 300, y: self.frame.midY)
                    self.hammerNode.comebackSpin(at: hammerPos)
                    self.portraitStep = 1
                }
            ]))
        }
    }

    // MARK: - Hammer Parade Steg 1: Dela på sig → dansa → vänta

    private func startHammerParade() {
        paradePhase = -1  // animerar
        let count = Int.random(in: 2...4)
        hammerNode.parade(count: count) { [weak self] clones in
            guard let self else { return }
            self.hammerClones = clones
            let allHammers: [SKSpriteNode] = [self.hammerNode] + clones

            // Dans — alla dansar synkroniserat med vågeffekt
            for (i, hammer) in allHammers.enumerated() {
                let offset = Double(i) * 0.08
                let dance = SKAction.sequence([
                    SKAction.wait(forDuration: offset),
                    SKAction.rotate(toAngle: 0.3, duration: 0.15),
                    SKAction.rotate(toAngle: -0.3, duration: 0.2),
                    SKAction.rotate(toAngle: 0, duration: 0.12),
                    SKAction.moveBy(x: 0, y: 60, duration: 0.15),
                    SKAction.moveBy(x: 0, y: -60, duration: 0.12),
                    SKAction.rotate(toAngle: -0.25, duration: 0.1),
                    SKAction.rotate(toAngle: 0.25, duration: 0.12),
                    SKAction.rotate(toAngle: 0, duration: 0.06),
                    SKAction.moveBy(x: 0, y: 40, duration: 0.1),
                    SKAction.moveBy(x: 0, y: -40, duration: 0.08),
                    SKAction.moveBy(x: 0, y: 55, duration: 0.12),
                    SKAction.moveBy(x: 0, y: -55, duration: 0.1),
                    SKAction.rotate(byAngle: .pi * 2, duration: 0.4),
                    SKAction.rotate(toAngle: 0.15, duration: 0.08),
                    SKAction.rotate(toAngle: -0.15, duration: 0.1),
                    SKAction.rotate(toAngle: 0, duration: 0.05),
                    SKAction.moveBy(x: 0, y: 70, duration: 0.15),
                    SKAction.moveBy(x: 0, y: -70, duration: 0.12)
                ])
                hammer.run(dance, withKey: "paradeDance")
            }

            // Beräkna danstid och starta idle-vickning när klart
            let maxOffset = Double(allHammers.count - 1) * 0.08
            let danceDuration = maxOffset + 2.35

            self.run(SKAction.sequence([
                SKAction.wait(forDuration: danceDuration),
                SKAction.run {
                    for hammer in allHammers {
                        self.startParadeIdle(hammer)
                    }
                    self.paradePhase = 1
                }
            ]), withKey: "paradeWait")
        }
    }

    // MARK: - Hammer Parade Steg 2: Dubbla → karusell → vänta

    private func startHammerCarousel() {
        paradePhase = -1  // animerar

        // Tre storlekar — stor inre, mellan, liten yttre
        let innerScale: CGFloat = 0.45
        let middleScale: CGFloat = 0.32
        let outerScale: CGFloat = 0.22

        // Ta bort ALLA gamla kloner och hammarens animationer
        let allOld = [hammerNode!] + hammerClones
        let totalCount = allOld.count * 2
        for clone in hammerClones {
            clone.removeAllActions()
            clone.removeFromParent()
        }
        hammerClones = []
        hammerNode.removeAllActions()

        // Göm originalet — använd BARA identiska kloner i karusellen
        hammerNode.removeFromParent()
        hammerNode.alpha = 0

        // Skapa ALLA hammare i en enda loop — garanterat identiska
        let refHammer = SKSpriteNode(imageNamed: "hammer1")
        let cloneSize = refHammer.size
        refHammer.removeFromParent()  // Användes bara för att läsa size

        var allHammers: [SKSpriteNode] = []
        for _ in 0..<totalCount {
            let clone = SKSpriteNode(imageNamed: "hammer1")
            clone.zPosition = hammerNode.zPosition
            clone.position = CGPoint(x: frame.midX, y: frame.midY)
            clone.setScale(innerScale)
            clone.name = "hammerClone"
            addChild(clone)
            hammerClones.append(clone)
            allHammers.append(clone)
        }

        // Karusell-container i mitten av skärmen
        let center = CGPoint(x: frame.midX, y: frame.midY)
        let hammerHeight = cloneSize.height * innerScale
        let radius: CGFloat = hammerHeight / 2 + 80
        let container = SKNode()
        container.position = center
        container.zPosition = hammerNode.zPosition
        addChild(container)
        carouselNode = container

        // Flytta alla hammare till karusell-positioner (som en urtavla)
        let angleStep = (.pi * 2) / CGFloat(totalCount)

        for (i, hammer) in allHammers.enumerated() {
            let angle = angleStep * CGFloat(i) - .pi / 2  // Börja klockan 12
            let targetLocal = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
            let targetWorld = CGPoint(x: center.x + targetLocal.x, y: center.y + targetLocal.y)

            // Flytta till position + vinkla skaftet mot mitten
            let hammerRotation = angle - .pi / 2
            // Alla hammare över tavlan (zPosition 5)
            hammer.zPosition = 12
            let moveToCircle = SKAction.group([
                SKAction.move(to: targetWorld, duration: 0.5),
                SKAction.rotate(toAngle: hammerRotation, duration: 0.5)
            ])
            moveToCircle.timingMode = .easeInEaseOut
            hammer.run(SKAction.sequence([
                SKAction.wait(forDuration: Double(i) * 0.05),
                moveToCircle,
                SKAction.run {
                    // Reparentera till container med lokal position
                    hammer.removeFromParent()
                    hammer.position = targetLocal
                    hammer.zRotation = hammerRotation
                    container.addChild(hammer)
                }
            ]))
        }

        // Starta snurrning efter alla landat
        let setupTime = Double(totalCount) * 0.05 + 0.5

        let minRadius: CGFloat = hammerHeight / 2 + 40
        let maxRadius: CGFloat = max(frame.width, frame.height) / 2
        let pulseDuration: TimeInterval = 1.0

        let innerRadius = radius
        let outerRadius: CGFloat = radius + 300
        let thirdRingRadius: CGFloat = radius + 600
        let edgeRadius: CGFloat = max(frame.width, frame.height) / 2

        run(SKAction.sequence([
            SKAction.wait(forDuration: setupTime + 0.2),

            // ── Varv 1: Snurra med pulsering + strikes ──
            SKAction.run { [weak self] in
                guard let self else { return }

                let spin1 = SKAction.rotate(byAngle: .pi * 2, duration: 3.0)
                spin1.timingMode = .easeInEaseOut
                container.run(spin1, withKey: "carouselSpin")

                for child in container.children {
                    guard let hammer = child as? SKSpriteNode else { continue }
                    let currentAngle = atan2(hammer.position.y, hammer.position.x)

                    let moveIn = SKAction.move(to: CGPoint(x: cos(currentAngle) * minRadius,
                                                            y: sin(currentAngle) * minRadius),
                                               duration: pulseDuration)
                    moveIn.timingMode = .easeInEaseOut
                    let moveOut = SKAction.move(to: CGPoint(x: cos(currentAngle) * edgeRadius,
                                                             y: sin(currentAngle) * edgeRadius),
                                                duration: pulseDuration)
                    moveOut.timingMode = .easeInEaseOut
                    let moveBack = SKAction.move(to: CGPoint(x: cos(currentAngle) * innerRadius,
                                                              y: sin(currentAngle) * innerRadius),
                                                 duration: pulseDuration)
                    moveBack.timingMode = .easeInEaseOut

                    let strike = SKAction.run { [weak self] in
                        guard let self else { return }
                        let tipLocal = CGPoint(x: 0, y: hammer.size.height * 0.45 * hammer.yScale)
                        let tipInContainer = CGPoint(
                            x: hammer.position.x + tipLocal.x * cos(hammer.zRotation) - tipLocal.y * sin(hammer.zRotation),
                            y: hammer.position.y + tipLocal.x * sin(hammer.zRotation) + tipLocal.y * cos(hammer.zRotation))
                        let tipInScene = container.convert(tipInContainer, to: self)
                        self.spawnCarouselStrike(at: tipInScene)
                    }

                    hammer.run(SKAction.sequence([
                        moveIn, strike, moveOut, strike, moveBack
                    ]), withKey: "radiusPulse")
                }
            },
            SKAction.wait(forDuration: 3.2),

            // ── Alla ut till kanten ──
            SKAction.run {
                for child in container.children {
                    guard let hammer = child as? SKSpriteNode else { continue }
                    let currentAngle = atan2(hammer.position.y, hammer.position.x)
                    let moveToEdge = SKAction.move(to: CGPoint(x: cos(currentAngle) * edgeRadius,
                                                                y: sin(currentAngle) * edgeRadius),
                                                   duration: 0.6)
                    moveToEdge.timingMode = .easeInEaseOut
                    hammer.run(moveToEdge, withKey: "radiusPulse")
                }
            },
            SKAction.wait(forDuration: 0.7),

            // ── Dubbla: skapa yttre ring ──
            SKAction.run { [weak self] in
                guard let self else { return }
                self.spawnDoubleFlash()
                let innerHammers = container.children.compactMap { $0 as? SKSpriteNode }
                let innerCount = innerHammers.count

                // Flytta inre ringen tillbaka till innerRadius
                for hammer in innerHammers {
                    let currentAngle = atan2(hammer.position.y, hammer.position.x)
                    let moveIn = SKAction.move(to: CGPoint(x: cos(currentAngle) * innerRadius,
                                                            y: sin(currentAngle) * innerRadius),
                                               duration: 0.5)
                    moveIn.timingMode = .easeInEaseOut
                    hammer.run(moveIn, withKey: "radiusPulse")
                }

                // Yttre ring — samma antal, förskjutet en halv position
                let outerAngleStep = (.pi * 2) / CGFloat(innerCount)
                let angleOffset = outerAngleStep / 2  // Halvt steg förskjutet

                for i in 0..<innerCount {
                    let angle = outerAngleStep * CGFloat(i) - .pi / 2 + angleOffset
                    let clone = SKSpriteNode(imageNamed: "hammer1")
                    clone.setScale(0.01)
                    clone.zRotation = angle - .pi / 2
                    clone.alpha = 0
                    clone.name = "hammerClone"
                    clone.zPosition = 11  // Mellanringen — under inre

                    // Startar i mitten, poppar ut till yttre ringen med mellanstorlek
                    clone.position = .zero
                    container.addChild(clone)
                    self.hammerClones.append(clone)

                    let targetPos = CGPoint(x: cos(angle) * outerRadius, y: sin(angle) * outerRadius)
                    let popOut = SKAction.group([
                        SKAction.fadeAlpha(to: 1.0, duration: 0.2),
                        SKAction.move(to: targetPos, duration: 0.5),
                        SKAction.scale(to: middleScale, duration: 0.5)
                    ])
                    popOut.timingMode = .easeOut
                    clone.run(SKAction.sequence([
                        SKAction.wait(forDuration: Double(i) * 0.04),
                        popOut
                    ]))
                }
            },
            SKAction.wait(forDuration: 0.8),

            // ── Varv 2: Båda ringarna snurrar + hammarslag + vågpuls ──
            SKAction.run { [weak self] in
                guard let self else { return }

                // Containern snurrar medurs
                let spin2 = SKAction.rotate(byAngle: .pi * 2, duration: 3.5)
                spin2.timingMode = .easeInEaseOut
                container.run(spin2, withKey: "carouselSpin2")

                // Hitta hammare per ring baserat på zPosition-tagg
                let allH = container.children.compactMap { $0 as? SKSpriteNode }
                let innerRing = allH.filter { $0.zPosition == 12 }
                let outerRing = allH.filter { $0.zPosition == 11 }

                // Inre ringen: rytmiska hammarslag
                for (i, hammer) in innerRing.enumerated() {
                    let delay = Double(i) * 0.1
                    let slam = SKAction.sequence([
                        SKAction.wait(forDuration: delay),
                        SKAction.repeatForever(SKAction.sequence([
                            SKAction.rotate(byAngle: 0.3, duration: 0.12),
                            SKAction.rotate(byAngle: -0.3, duration: 0.06),
                            SKAction.wait(forDuration: 0.32)
                        ]))
                    ])
                    hammer.run(slam, withKey: "hammerSlam")
                }

                // Yttre ringen: vågpuls — skala upp/ner sekventiellt
                for (i, hammer) in outerRing.enumerated() {
                    let delay = Double(i) * 0.15
                    let wave = SKAction.sequence([
                        SKAction.wait(forDuration: delay),
                        SKAction.repeatForever(SKAction.sequence([
                            SKAction.scale(to: middleScale * 1.4, duration: 0.2),
                            SKAction.scale(to: middleScale, duration: 0.2),
                            SKAction.wait(forDuration: 0.4)
                        ]))
                    ])
                    hammer.run(wave, withKey: "wavePulse")
                }
            },
            SKAction.wait(forDuration: 3.7),

            // Stoppa individuella effekter och återställ skalor
            SKAction.run { [weak self] in
                guard let self else { return }
                let allH = container.children.compactMap { $0 as? SKSpriteNode }
                let midDist = (innerRadius + outerRadius) / 2
                for hammer in allH {
                    hammer.removeAction(forKey: "hammerSlam")
                    hammer.removeAction(forKey: "wavePulse")
                    hammer.zRotation = atan2(hammer.position.y, hammer.position.x) - .pi / 2
                    // Återställ skala baserat på ring-tagg (zPosition)
                    if hammer.zPosition == 12 {
                        hammer.setScale(innerScale)
                    } else {
                        hammer.setScale(middleScale)
                    }
                }
            },

            // ── Alla ut till kanten igen ──
            SKAction.run {
                for child in container.children {
                    guard let hammer = child as? SKSpriteNode else { continue }
                    let currentAngle = atan2(hammer.position.y, hammer.position.x)
                    let moveToEdge = SKAction.move(to: CGPoint(x: cos(currentAngle) * edgeRadius,
                                                                y: sin(currentAngle) * edgeRadius),
                                                   duration: 0.6)
                    moveToEdge.timingMode = .easeInEaseOut
                    hammer.run(moveToEdge, withKey: "radiusPulse")
                }
            },
            SKAction.wait(forDuration: 0.7),

            // ── Dubbla igen: tredje ring ──
            SKAction.run { [weak self] in
                guard let self else { return }
                self.spawnDoubleFlash()
                let currentHammers = container.children.compactMap { $0 as? SKSpriteNode }
                let currentCount = currentHammers.count

                // Flytta befintliga tillbaka till sina ringar
                for hammer in currentHammers {
                    let currentAngle = atan2(hammer.position.y, hammer.position.x)
                    let dist = hypot(hammer.position.x, hammer.position.y)
                    let targetR = dist < (innerRadius + outerRadius) / 2 ? innerRadius : outerRadius
                    let moveBack = SKAction.move(to: CGPoint(x: cos(currentAngle) * targetR,
                                                              y: sin(currentAngle) * targetR),
                                                 duration: 0.5)
                    moveBack.timingMode = .easeInEaseOut
                    hammer.run(moveBack, withKey: "radiusPulse")
                }

                // Tredje ring — samma antal som nuvarande, förskjutet, minst storlek
                let thirdAngleStep = (.pi * 2) / CGFloat(currentCount)
                let thirdOffset = thirdAngleStep / 3

                for i in 0..<currentCount {
                    let angle = thirdAngleStep * CGFloat(i) - .pi / 2 + thirdOffset
                    let clone = SKSpriteNode(imageNamed: "hammer1")
                    clone.setScale(0.01)
                    clone.zRotation = angle - .pi / 2
                    clone.alpha = 0
                    clone.name = "hammerClone"
                    clone.zPosition = 10  // Yttersta ringen — underst men över tavlan

                    clone.position = .zero
                    container.addChild(clone)
                    self.hammerClones.append(clone)

                    let targetPos = CGPoint(x: cos(angle) * thirdRingRadius, y: sin(angle) * thirdRingRadius)
                    let popOut = SKAction.group([
                        SKAction.fadeAlpha(to: 1.0, duration: 0.2),
                        SKAction.move(to: targetPos, duration: 0.5),
                        SKAction.scale(to: outerScale, duration: 0.5)
                    ])
                    popOut.timingMode = .easeOut
                    clone.run(SKAction.sequence([
                        SKAction.wait(forDuration: Double(i) * 0.03),
                        popOut
                    ]))
                }
            },
            SKAction.wait(forDuration: 0.8),

            // ── Varv 3: Tre motroterande ringar + hammarslag + våg ──
            SKAction.run { [weak self] in
                guard let self else { return }

                // Containern snurrar medurs (inre + yttre följer med)
                let spin3 = SKAction.rotate(byAngle: .pi * 2, duration: 4.0)
                spin3.timingMode = .easeInEaseOut
                container.run(spin3, withKey: "carouselSpin3")

                // Hitta hammare per ring
                // Hitta hammare per ring baserat på zPosition-tagg
                let allH = container.children.compactMap { $0 as? SKSpriteNode }
                let ring1 = allH.filter { $0.zPosition == 12 }
                let ring2 = allH.filter { $0.zPosition == 11 }
                let ring3 = allH.filter { $0.zPosition == 10 }

                // Mellanringen: motrotera (snurr individuellt moturs runt sin position)
                for hammer in ring2 {
                    let currentAngle = atan2(hammer.position.y, hammer.position.x)
                    let r = hypot(hammer.position.x, hammer.position.y)

                    // Rotera runt mitten moturs via position-animation
                    let counterSpin = SKAction.customAction(withDuration: 4.0) { node, elapsed in
                        let t = elapsed / 4.0
                        let newAngle = currentAngle - CGFloat.pi * 2 * 2 * t  // 2 varv moturs
                        node.position = CGPoint(x: cos(newAngle) * r, y: sin(newAngle) * r)
                        node.zRotation = newAngle - .pi / 2  // Skaft mot mitten
                    }
                    hammer.run(counterSpin, withKey: "counterSpin")
                }

                // Inre ringen: synkroniserade hammarslag med flash
                for (i, hammer) in ring1.enumerated() {
                    let delay = Double(i) * 0.08
                    let slam = SKAction.sequence([
                        SKAction.wait(forDuration: delay),
                        SKAction.repeatForever(SKAction.sequence([
                            SKAction.rotate(byAngle: 0.35, duration: 0.1),
                            SKAction.rotate(byAngle: -0.35, duration: 0.05),
                            SKAction.wait(forDuration: 0.35)
                        ]))
                    ])
                    hammer.run(slam, withKey: "hammerSlam")
                }

                // Yttre ringen: vågpuls
                for (i, hammer) in ring3.enumerated() {
                    let delay = Double(i) * 0.12
                    let wave = SKAction.sequence([
                        SKAction.wait(forDuration: delay),
                        SKAction.repeatForever(SKAction.sequence([
                            SKAction.scale(to: outerScale * 1.5, duration: 0.18),
                            SKAction.scale(to: outerScale, duration: 0.18),
                            SKAction.wait(forDuration: 0.3)
                        ]))
                    ])
                    hammer.run(wave, withKey: "wavePulse")
                }

                // Flash vid halvvägs och slutet
                self.run(SKAction.sequence([
                    SKAction.wait(forDuration: 2.0),
                    SKAction.run { self.spawnDoubleFlash() },
                    SKAction.wait(forDuration: 1.8),
                    SKAction.run { self.spawnDoubleFlash() }
                ]))
            },
            SKAction.wait(forDuration: 4.2),

            // Stoppa alla individuella effekter och återställ skalor
            SKAction.run {
                let allH = container.children.compactMap { $0 as? SKSpriteNode }
                let midInner = (innerRadius + outerRadius) / 2
                let midOuter = (outerRadius + thirdRingRadius) / 2
                for hammer in allH {
                    hammer.removeAction(forKey: "hammerSlam")
                    hammer.removeAction(forKey: "wavePulse")
                    hammer.removeAction(forKey: "counterSpin")
                    // Återställ skala baserat på ring-tagg (zPosition)
                    if hammer.zPosition == 12 {
                        hammer.setScale(innerScale)
                    } else if hammer.zPosition == 11 {
                        hammer.setScale(middleScale)
                    } else {
                        hammer.setScale(outerScale)
                    }
                }
            },

            // ── Sprida ut i jämna centrerade rader + marsch på plats ──
            SKAction.run { [weak self] in
                guard let self else { return }
                self.spawnDoubleFlash()

                let allH = container.children.compactMap { $0 as? SKSpriteNode }
                let total = allH.count
                guard total > 0 else { return }

                // Stoppa allt och nollställ alla hammare
                for hammer in allH {
                    hammer.removeAllActions()
                    hammer.zRotation = 0
                }

                let margin: CGFloat = 60
                let screenW = self.frame.width
                let screenH = self.frame.height

                // Beräkna grid: fasta kolumner baserat på antal
                let cols: Int
                if total <= 4 { cols = 2 }
                else if total <= 9 { cols = 3 }
                else if total <= 16 { cols = 4 }
                else if total <= 25 { cols = 5 }
                else { cols = 6 }
                let rows = Int(ceil(Double(total) / Double(cols)))

                // Alla hammare samma storlek — baserat på cellstorlek
                let cellW = (screenW - margin * 2) / CGFloat(cols)
                let cellH = (screenH - margin * 2) / CGFloat(rows)
                let refSize = SKSpriteNode(imageNamed: "hammer1").size
                let gridScale = min(cellW / refSize.width,
                                    cellH / refSize.height) * 0.9

                // Reparentera alla till scenen
                for hammer in allH {
                    let worldPos = container.convert(hammer.position, to: self)
                    hammer.removeFromParent()
                    hammer.position = worldPos
                    self.addChild(hammer)
                }
                container.removeFromParent()
                self.carouselNode = nil

                // Placera i centrerade rader
                var hammerIndex = 0
                let totalGridHeight = CGFloat(rows) * cellH
                let startY = screenH / 2 + totalGridHeight / 2 - cellH / 2

                for row in 0..<rows {
                    // Antal i denna rad (sista raden kan ha färre)
                    let countInRow = min(cols, total - row * cols)
                    let rowWidth = CGFloat(countInRow) * cellW
                    let rowStartX = (screenW - rowWidth) / 2 + cellW / 2
                    let y = startY - CGFloat(row) * cellH

                    for col in 0..<countInRow {
                        guard hammerIndex < allH.count else { break }
                        let hammer = allH[hammerIndex]
                        hammer.removeAllActions()

                        let x = rowStartX + CGFloat(col) * cellW

                        let moveToGrid = SKAction.group([
                            SKAction.move(to: CGPoint(x: x, y: y), duration: 0.6),
                            SKAction.scale(to: gridScale, duration: 0.6),
                            SKAction.rotate(toAngle: 0, duration: 0.4)
                        ])
                        moveToGrid.timingMode = .easeOut

                        // Slumpmässigt beteende — varje hammare gör sitt
                        let marchDelay = Double(hammerIndex) * 0.03

                        hammer.run(SKAction.sequence([
                            SKAction.wait(forDuration: marchDelay),
                            moveToGrid,
                            SKAction.wait(forDuration: TimeInterval.random(in: 0.1...0.5)),
                            SKAction.run { [weak self] in
                                self?.startGridIdle(hammer)
                            }
                        ]), withKey: "gridMarch")

                        hammerIndex += 1
                    }
                }

                // Efter 4 sekunder grid-kaos: synkroniserad knackning → idle-vickning
                let gridIdleDuration: TimeInterval = 4.0
                self.run(SKAction.sequence([
                    SKAction.wait(forDuration: gridIdleDuration),
                    SKAction.run { [weak self] in
                        guard let self else { return }
                        let gridHammers = self.hammerClones

                        // Stoppa allt
                        for hammer in gridHammers {
                            hammer.removeAllActions()
                            hammer.zRotation = 0
                        }

                        // Synkroniserade snurrar — alla snurrar samtidigt
                        self.spawnDoubleFlash()

                        for (i, hammer) in gridHammers.enumerated() {
                            let delay = Double(i) * 0.015
                            hammer.run(SKAction.sequence([
                                SKAction.wait(forDuration: delay),
                                // Snurr 1
                                SKAction.rotate(byAngle: .pi * 2, duration: 0.35),
                                SKAction.wait(forDuration: 0.1),
                                // Snurr 2 — snabbare
                                SKAction.rotate(byAngle: .pi * 2, duration: 0.25),
                                SKAction.wait(forDuration: 0.08),
                                // Snurr 3 — ännu snabbare
                                SKAction.rotate(byAngle: .pi * 2, duration: 0.2),
                                SKAction.rotate(toAngle: 0, duration: 0.05)
                            ]), withKey: "gridSlam")
                        }

                        // Flash vid sista snurren
                        self.run(SKAction.sequence([
                            SKAction.wait(forDuration: 0.35 + 0.1 + 0.25 + 0.08 + 0.2),
                            SKAction.run { [weak self] in self?.spawnDoubleFlash() }
                        ]))
                    },

                    // Vänta tills snurrarna är klara
                    SKAction.wait(forDuration: 1.5),
                    SKAction.run { [weak self] in
                        guard let self else { return }
                        for hammer in self.hammerClones {
                            hammer.removeAction(forKey: "gridSlam")
                            hammer.zRotation = 0
                            self.startParadeIdle(hammer)
                        }
                        self.paradePhase = 2
                        self.startGridNudge()
                    }
                ]), withKey: "gridFinale")
            }
        ]), withKey: "carouselWait")
    }

    // MARK: - Hammer Parade Steg 3: Samla ihop → tillbaka till toolbox

    private func spawnDoubleFlash() {
        let screenCenter = CGPoint(x: frame.midX, y: frame.midY)
        let flashSize = CGSize(width: frame.width, height: frame.height)

        // Blixt 1
        let flash1 = SKSpriteNode(color: .white, size: flashSize)
        flash1.position = screenCenter
        flash1.zPosition = 999
        flash1.alpha = 0
        addChild(flash1)
        flash1.run(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.5, duration: 0.03),
            SKAction.fadeAlpha(to: 0.0, duration: 0.05),
            SKAction.fadeAlpha(to: 0.4, duration: 0.02),
            SKAction.fadeOut(withDuration: 0.08),
            SKAction.removeFromParent()
        ]))

        // Blixt 2 — fördröjd
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.15),
            SKAction.run { [weak self] in
                guard let self else { return }
                let flash2 = SKSpriteNode(color: .white, size: flashSize)
                flash2.position = screenCenter
                flash2.zPosition = 999
                flash2.alpha = 0
                self.addChild(flash2)
                flash2.run(SKAction.sequence([
                    SKAction.fadeAlpha(to: 0.6, duration: 0.03),
                    SKAction.fadeAlpha(to: 0.0, duration: 0.04),
                    SKAction.fadeAlpha(to: 0.35, duration: 0.02),
                    SKAction.fadeOut(withDuration: 0.1),
                    SKAction.removeFromParent()
                ]))
            }
        ]))
    }

    // MARK: - Grid Nudge (påminnelse att trycka)

    private func startGridNudge() {
        run(SKAction.sequence([
            SKAction.wait(forDuration: TimeInterval.random(in: 6.0...10.0)),
            SKAction.run { [weak self] in
                guard let self, self.paradePhase == 2, !self.hammerClones.isEmpty else { return }

                // Välj en slumpmässig hammare
                let hammer = self.hammerClones[Int.random(in: 0..<self.hammerClones.count)]
                hammer.removeAction(forKey: "gridIdle")

                // Snurr + strålar från nosen
                hammer.run(SKAction.sequence([
                    SKAction.rotate(byAngle: .pi * 2, duration: 0.3),
                    SKAction.run { [weak self] in
                        let tipY = hammer.size.height * 0.45 * hammer.yScale
                        let cosA = cos(hammer.zRotation)
                        let sinA = sin(hammer.zRotation)
                        let tipPos = CGPoint(x: hammer.position.x - tipY * sinA,
                                             y: hammer.position.y + tipY * cosA)
                        self?.spawnCarouselStrike(at: tipPos)
                    },
                    SKAction.rotate(toAngle: 0, duration: 0.05),
                    SKAction.run { [weak self] in
                        self?.startGridIdle(hammer)
                    }
                ]), withKey: "gridIdle")

                // Starta nästa nudge
                self.startGridNudge()
            }
        ]), withKey: "gridNudge")
    }

    // MARK: - Grid Idle (slumpmässiga hammareffekter)

    private func startGridIdle(_ hammer: SKSpriteNode) {
        let roll = Int.random(in: 0...4)
        let action: SKAction

        switch roll {
        case 0:
            // Marsch-steg — stor rörelse
            let tilt: CGFloat = 0.2
            let bob: CGFloat = 12
            action = SKAction.sequence([
                SKAction.group([
                    SKAction.rotate(toAngle: tilt, duration: 0.12),
                    SKAction.moveBy(x: -4, y: bob, duration: 0.12)
                ]),
                SKAction.group([
                    SKAction.rotate(toAngle: 0, duration: 0.03),
                    SKAction.moveBy(x: 4, y: -bob, duration: 0.03)
                ]),
                SKAction.group([
                    SKAction.rotate(toAngle: -tilt, duration: 0.12),
                    SKAction.moveBy(x: 4, y: bob, duration: 0.12)
                ]),
                SKAction.group([
                    SKAction.rotate(toAngle: 0, duration: 0.03),
                    SKAction.moveBy(x: -4, y: -bob, duration: 0.03)
                ]),
                SKAction.wait(forDuration: TimeInterval.random(in: 0.1...0.4))
            ])

        case 1:
            // Helsnurr
            action = SKAction.sequence([
                SKAction.rotate(byAngle: .pi * 2, duration: 0.4),
                SKAction.rotate(toAngle: 0, duration: 0.05),
                SKAction.wait(forDuration: TimeInterval.random(in: 0.5...1.5))
            ])

        case 2:
            // Knackning med strålar från hammarens nos
            action = SKAction.sequence([
                SKAction.rotate(toAngle: 0.35, duration: 0.1),
                SKAction.rotate(toAngle: -0.1, duration: 0.04),
                SKAction.run { [weak self] in
                    // Beräkna nosposition
                    let tipY = hammer.size.height * 0.45 * hammer.yScale
                    let cosA = cos(hammer.zRotation)
                    let sinA = sin(hammer.zRotation)
                    let tipPos = CGPoint(x: hammer.position.x - tipY * sinA,
                                         y: hammer.position.y + tipY * cosA)
                    self?.spawnCarouselStrike(at: tipPos)
                },
                SKAction.moveBy(x: 0, y: -6, duration: 0.02),
                SKAction.moveBy(x: 0, y: 6, duration: 0.03),
                SKAction.rotate(toAngle: 0, duration: 0.05),
                SKAction.wait(forDuration: TimeInterval.random(in: 0.8...2.0))
            ])

        case 3:
            // Snabb skakning — kraftigare
            action = SKAction.sequence([
                SKAction.moveBy(x: 6, y: 3, duration: 0.03),
                SKAction.moveBy(x: -10, y: -5, duration: 0.04),
                SKAction.moveBy(x: 8, y: 4, duration: 0.03),
                SKAction.moveBy(x: -4, y: -2, duration: 0.03),
                SKAction.wait(forDuration: TimeInterval.random(in: 0.2...0.5))
            ])

        default:
            // Vickning — större rörelse
            action = SKAction.sequence([
                SKAction.rotate(toAngle: 0.18, duration: 0.3),
                SKAction.rotate(toAngle: -0.18, duration: 0.35),
                SKAction.rotate(toAngle: 0.1, duration: 0.2),
                SKAction.rotate(toAngle: 0, duration: 0.15),
                SKAction.wait(forDuration: TimeInterval.random(in: 0.1...0.3))
            ])
        }

        // Kör actionen, sedan starta nästa slumpmässiga action
        hammer.run(SKAction.sequence([
            action,
            SKAction.run { [weak self] in
                self?.startGridIdle(hammer)
            }
        ]), withKey: "gridIdle")
    }

    private func endHammerParade() {
        paradePhase = -1  // animerar
        removeAction(forKey: "gridNudge")
        let center = CGPoint(x: frame.midX, y: frame.midY)

        // Dubbelflash
        spawnDoubleFlash()

        // Samla alla kloner (kan vara i carousel-container eller scene)
        var clones: [SKSpriteNode] = []
        if let container = carouselNode {
            for child in container.children {
                if let hammer = child as? SKSpriteNode {
                    let worldPos = container.convert(hammer.position, to: self)
                    hammer.removeFromParent()
                    hammer.position = worldPos
                    addChild(hammer)
                    clones.append(hammer)
                }
            }
            container.removeFromParent()
            carouselNode = nil
        } else {
            clones = hammerClones
        }

        // Stoppa alla pågående animationer
        for clone in clones {
            clone.removeAllActions()
        }

        // ── Stora hammaren dyker upp FÖRST i mitten, överst ──
        if hammerNode.parent == nil {
            addChild(hammerNode)
        }
        hammerNode.position = center
        hammerNode.setScale(0.01)
        hammerNode.zRotation = 0
        hammerNode.alpha = 1.0
        hammerNode.zPosition = 20  // Överst — ovanpå alla kloner

        // Poppar upp till full storlek
        let popUp = SKAction.scale(to: 1.0, duration: 0.3)
        popUp.timingMode = .easeOut
        hammerNode.run(popUp)

        // ── Klonerna sugs in mot stora hammaren ──
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.4),
            SKAction.run { [weak self] in
                guard let self else { return }
                for (i, clone) in clones.enumerated() {
                    let suckIn = SKAction.group([
                        SKAction.move(to: center, duration: 0.35),
                        SKAction.scale(to: 0.05, duration: 0.35),
                        SKAction.fadeOut(withDuration: 0.3)
                    ])
                    suckIn.timingMode = .easeIn
                    clone.run(SKAction.sequence([
                        SKAction.wait(forDuration: Double(i) * 0.03),
                        suckIn,
                        SKAction.removeFromParent()
                    ]))
                }
            }
        ]))
        hammerClones = []

        let mergeTime = 0.4 + Double(clones.count) * 0.03 + 0.45

        // Dubbelflash + waveBye
        run(SKAction.sequence([
            SKAction.wait(forDuration: mergeTime),
            SKAction.run { [weak self] in
                self?.spawnDoubleFlash()
            },
            SKAction.wait(forDuration: 0.3),
            SKAction.run { [weak self] in
                guard let self else { return }
                // Återställ zPosition
                self.hammerNode.zPosition = 14

                self.hammerNode.waveBye(at: center, toolboxPos: self.toolboxNode.position) {
                    // 2-3 sekunder tomt, sedan fada tillbaka
                    self.run(SKAction.sequence([
                        SKAction.wait(forDuration: 2.5),
                        SKAction.run {
                            self.owl.isHidden = false
                            self.owl.alpha = 0
                            self.owl.run(SKAction.sequence([
                                SKAction.fadeIn(withDuration: 1.0),
                                SKAction.run { self.owl.startSleeping() }
                            ]))
                            self.transitionManager.deactivateAll()
                            self.toolboxNode.fadeBack()
                            self.hammerNode.reset()
                            self.paradePhase = 0
                            self.sceneState = .sleeping
                            self.startPortraitGlow()
                        }
                    ]))
                }
            }
        ]), withKey: "paradeEnd")
    }

    // MARK: - Carousel Strike (flash + radiella strålar från hammarens huvud)

    private func spawnCarouselStrike(at origin: CGPoint) {
        // Helskärmsblixt
        let flash = SKSpriteNode(color: .white,
                                  size: CGSize(width: frame.width, height: frame.height))
        flash.position = CGPoint(x: frame.midX, y: frame.midY)
        flash.zPosition = 999
        flash.alpha = 0
        addChild(flash)
        flash.run(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.02),
            SKAction.fadeAlpha(to: 0.0, duration: 0.03),
            SKAction.fadeAlpha(to: 0.2, duration: 0.02),
            SKAction.fadeOut(withDuration: 0.06),
            SKAction.removeFromParent()
        ]))

        // Triangelstrålar från hammarens huvud
        let rayCount = 12
        let path = CGMutablePath()
        for _ in 0..<rayCount {
            let angle = CGFloat.random(in: 0...(.pi * 2))
            let length = CGFloat.random(in: 1200...1600)
            let baseWidth = CGFloat.random(in: 4...10)

            let perpX = -sin(angle)
            let perpY = cos(angle)
            let bx1 = origin.x + perpX * baseWidth * 0.5
            let by1 = origin.y + perpY * baseWidth * 0.5
            let bx2 = origin.x - perpX * baseWidth * 0.5
            let by2 = origin.y - perpY * baseWidth * 0.5
            let tx = origin.x + cos(angle) * length
            let ty = origin.y + sin(angle) * length

            path.move(to: CGPoint(x: bx1, y: by1))
            path.addLine(to: CGPoint(x: tx, y: ty))
            path.addLine(to: CGPoint(x: bx2, y: by2))
            path.closeSubpath()
        }

        let rays = SKShapeNode(path: path)
        rays.fillColor = UIColor(white: 1.0, alpha: 0.2)
        rays.strokeColor = .clear
        rays.glowWidth = 1.5
        rays.zPosition = 1
        rays.alpha = 0
        addChild(rays)

        rays.run(SKAction.sequence([
            SKAction.fadeAlpha(to: 1.0, duration: 0.02),
            SKAction.fadeAlpha(to: 0.0, duration: 0.03),
            SKAction.fadeAlpha(to: 0.85, duration: 0.02),
            SKAction.fadeAlpha(to: 0.0, duration: 0.04),
            SKAction.fadeAlpha(to: 0.5, duration: 0.02),
            SKAction.fadeAlpha(to: 0.05, duration: 0.04),
            SKAction.fadeAlpha(to: 0.3, duration: 0.02),
            SKAction.fadeOut(withDuration: 0.8),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Parade Idle (mjuk vickning medan hammare väntar)

    private func startParadeIdle(_ hammer: SKSpriteNode) {
        let wiggle = SKAction.sequence([
            SKAction.rotate(byAngle: 0.06, duration: 0.8),
            SKAction.rotate(byAngle: -0.12, duration: 0.9),
            SKAction.rotate(byAngle: 0.09, duration: 0.7),
            SKAction.rotate(byAngle: -0.03, duration: 0.8)
        ])
        hammer.run(SKAction.repeatForever(wiggle), withKey: "paradeIdle")
    }

    // MARK: - Portrait Swap (portrait2 → portrait1)

    private func startPortraitSwapSequence() {
        let screenCenter = CGPoint(x: frame.midX, y: frame.midY)

        guard let oldPortrait = currentPortrait else { return }

        // Blockera ytterligare tap under hela swap-sekvensen
        portraitStep = 2

        // Hammaren slår till med blixt, sedan tonar ut
        hammerNode.quickStrike { [weak self] in
            guard let self else { return }

            // Portrait 1 läggs ovanpå portrait 2, samma position och storlek
            let newPortrait = SKSpriteNode(imageNamed: "portrait_hall1")
            newPortrait.position = oldPortrait.position
            newPortrait.zPosition = oldPortrait.zPosition + 1
            newPortrait.setScale(oldPortrait.xScale)
            newPortrait.alpha = 0
            newPortrait.name = "portrait"
            self.addChild(newPortrait)

            // Fadar in portrait 1 långsamt, sedan tar bort portrait 2
            newPortrait.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.5),
                SKAction.fadeAlpha(to: 1.0, duration: 1.2),
                SKAction.run { [weak self] in
                    oldPortrait.removeFromParent()
                    self?.currentPortrait = newPortrait
                }
            ]))

            // Flash + hammer comeback efter portrait bytt
            self.run(SKAction.sequence([
                SKAction.wait(forDuration: 2.5),
                SKAction.run { [weak self] in
                    guard let self else { return }

                    let flash2 = SKSpriteNode(color: .white,
                                              size: CGSize(width: self.frame.width, height: self.frame.height))
                    flash2.position = screenCenter
                    flash2.zPosition = 999
                    flash2.alpha = 0
                    self.addChild(flash2)
                    flash2.run(SKAction.sequence([
                        SKAction.fadeAlpha(to: 0.3, duration: 0.02),
                        SKAction.fadeAlpha(to: 0.0, duration: 0.03),
                        SKAction.fadeAlpha(to: 0.2, duration: 0.02),
                        SKAction.fadeOut(withDuration: 0.06),
                        SKAction.removeFromParent()
                    ]))

                    // Slutfanfar — dubbelblixt!
                    let screenCenter = CGPoint(x: self.frame.midX, y: self.frame.midY)
                    let flashSize = CGSize(width: self.frame.width, height: self.frame.height)

                    // Blixt 1
                    let fanfare1 = SKSpriteNode(color: .white, size: flashSize)
                    fanfare1.position = screenCenter
                    fanfare1.zPosition = 999
                    fanfare1.alpha = 0
                    self.addChild(fanfare1)
                    fanfare1.run(SKAction.sequence([
                        SKAction.fadeAlpha(to: 0.5, duration: 0.03),
                        SKAction.fadeAlpha(to: 0.0, duration: 0.05),
                        SKAction.fadeAlpha(to: 0.4, duration: 0.02),
                        SKAction.fadeOut(withDuration: 0.08),
                        SKAction.removeFromParent()
                    ]))

                    // Blixt 2 — fördröjd
                    self.run(SKAction.sequence([
                        SKAction.wait(forDuration: 0.25),
                        SKAction.run {
                            let fanfare2 = SKSpriteNode(color: .white, size: flashSize)
                            fanfare2.position = screenCenter
                            fanfare2.zPosition = 999
                            fanfare2.alpha = 0
                            self.addChild(fanfare2)
                            fanfare2.run(SKAction.sequence([
                                SKAction.fadeAlpha(to: 0.6, duration: 0.03),
                                SKAction.fadeAlpha(to: 0.0, duration: 0.04),
                                SKAction.fadeAlpha(to: 0.35, duration: 0.02),
                                SKAction.fadeOut(withDuration: 0.1),
                                SKAction.removeFromParent()
                            ]))
                        }
                    ]))

                    // Hejdå-hammare medan rummet är tomt
                    self.run(SKAction.sequence([
                        SKAction.wait(forDuration: 2.5),
                        SKAction.run {
                            // Blixt
                            let flash = SKSpriteNode(color: .white,
                                                      size: CGSize(width: self.frame.width, height: self.frame.height))
                            flash.position = screenCenter
                            flash.zPosition = 999
                            flash.alpha = 0
                            self.addChild(flash)
                            flash.run(SKAction.sequence([
                                SKAction.fadeAlpha(to: 0.3, duration: 0.02),
                                SKAction.fadeAlpha(to: 0.0, duration: 0.03),
                                SKAction.fadeAlpha(to: 0.2, duration: 0.02),
                                SKAction.fadeOut(withDuration: 0.06),
                                SKAction.removeFromParent()
                            ]))

                            // Hammare: fade in → knackning → studs till toolbox → försvinner
                            let hammerPos = CGPoint(x: self.frame.midX - 300, y: self.frame.midY)
                            self.hammerNode.waveBye(at: hammerPos, toolboxPos: self.toolboxNode.position) {
                                // 1.5s tomt rum, sedan fadea in föremålen
                                self.run(SKAction.sequence([
                                    SKAction.wait(forDuration: 1.5),
                                    SKAction.run {
                                        self.owl.isHidden = false
                                        self.owl.alpha = 0
                                        self.owl.run(SKAction.sequence([
                                            SKAction.fadeIn(withDuration: 1.0),
                                            SKAction.run { self.owl.startSleeping() }
                                        ]))
                                        self.transitionManager.deactivateAll()
                                        self.toolboxNode.fadeBack()
                                        self.hammerNode.reset()
                                        self.portraitStep = 3
                                        self.sceneState = .sleeping
                                        self.startPortraitGlow()
                                    }
                                ]))
                            }
                        }
                    ]))
                }
            ]))
        }
    }

    // MARK: - Portrait Glow (idle shimmer)

    private func startPortraitGlow() {
        stopPortraitGlow()
        guard let portrait = currentPortrait else { return }

        // Photoshop-style outer glow: blurrad vit kopia bakom tavlan
        let glowNode = SKEffectNode()
        glowNode.shouldRasterize = true
        glowNode.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 25.0])
        glowNode.zPosition = portrait.zPosition - 1
        glowNode.position = portrait.position
        glowNode.alpha = 0
        addChild(glowNode)

        // Vit version av tavlan, lite större
        let glowSprite = SKSpriteNode(imageNamed: "portrait_hall1")
        glowSprite.setScale(portrait.xScale * 1.08)
        glowSprite.colorBlendFactor = 1.0
        glowSprite.color = .white
        glowNode.addChild(glowSprite)

        // Pulserande outer glow
        let shimmer = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.9, duration: 1.2),
            SKAction.fadeAlpha(to: 0.4, duration: 1.0),
            SKAction.fadeAlpha(to: 1.0, duration: 0.8),
            SKAction.fadeAlpha(to: 0.35, duration: 1.4)
        ])
        glowNode.run(SKAction.repeatForever(shimmer), withKey: "portraitShimmer")

        portraitGlow = glowNode
    }

    private func stopPortraitGlow() {
        portraitGlow?.removeAllActions()
        portraitGlow?.removeFromParent()
        portraitGlow = nil
    }

    // MARK: - Portrait Tap Sequence (tryck på uppsatt tavla)

    private func startPortraitTapSequence() {
        sceneState = .portraitActive
        stopPortraitGlow()

        // Fada ut hat, owl, toolbox
        transitionManager.activateObject(id: .toolbox) // fadar ut hat + owl
        toolboxNode.fadeAway()
        owl.removeAllActions()
        owl.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.6),
            SKAction.run { [weak self] in self?.owl.isHidden = true }
        ]), withKey: "owlFade")

        guard let portrait = currentPortrait else { return }

        // Portrait_hall2 fadar in ovanpå portrait_hall1, samma position och storlek
        let overlay = SKSpriteNode(imageNamed: "portrait_hall2")
        overlay.position = portrait.position
        overlay.zPosition = portrait.zPosition + 1
        overlay.setScale(portrait.xScale)
        overlay.alpha = 0
        overlay.name = "portraitOverlay"
        addChild(overlay)

        overlay.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.fadeAlpha(to: 1.0, duration: 1.2)
        ]))

        // Rådjuret fadar in — uppbyggt av separata delar
        let deer = SKNode()
        deer.position = CGPoint(x: frame.midX - 600, y: 910)
        deer.zPosition = 15
        deer.setScale(0.84)
        deer.alpha = 0
        deer.name = "deer"
        addChild(deer)
        deerNode = deer

        // Skapa alla delar med BENGRUPPER som håller ihop över+underben
        // Z-ordning: bakben → svans → kropp → framben → huvud
        //
        // Underben har anchorPoint vid knäleden så rotation = knäböj.
        // Kompenserande position så de visuellt hamnar rätt.
        // Canvas: 1269×2030. Knäposition estimerad från sprite-centrumpunkter.

        // --- Bakben 1 (längst vänster — FRAMFÖR body, z=6) ---
        // Skelett: grupp(höft) → överben(anchorPoint=höft) → underben(anchorPoint=knä).
        // Överbenet har anchorPoint vid höftleden — pivoterar som ett lår i höftkula.
        // Underbenet är barn av överbenet — sitter fast vid knäet.
        let bl1Group = SKNode()
        bl1Group.zPosition = 6
        bl1Group.position = CGPoint(x: -225, y: -16)    // 50px under topmost pixel
        deer.addChild(bl1Group)
        backLeg1Group = bl1Group

        let backLeg1Up = SKSpriteNode(imageNamed: "deer1_backleg1up")
        backLeg1Up.anchorPoint = CGPoint(x: 0.3223, y: 0.4921)  // 50px under topmost pixel
        backLeg1Up.position = .zero
        backLeg1Up.zPosition = 1
        bl1Group.addChild(backLeg1Up)
        deerBackLeg1Up = backLeg1Up

        let backLeg1Down = SKSpriteNode(imageNamed: "deer1_backleg1down")
        backLeg1Down.anchorPoint = CGPoint(x: 0.22, y: 0.29)
        backLeg1Down.position = CGPoint(x: -130, y: -410)       // knä relativt höft
        backLeg1Down.zPosition = -1
        backLeg1Up.addChild(backLeg1Down)
        deerBackLeg1Down = backLeg1Down

        // --- Bakben 2 (näst längst vänster — BAKOM body, z=1) ---
        let bl2Group = SKNode()
        bl2Group.zPosition = 1
        bl2Group.position = CGPoint(x: -159, y: -211)   // 50px under topmost pixel
        deer.addChild(bl2Group)
        backLeg2Group = bl2Group

        let backLeg2Up = SKSpriteNode(imageNamed: "deer1_backleg2up")
        backLeg2Up.anchorPoint = CGPoint(x: 0.3751, y: 0.3961)  // 50px under topmost pixel
        backLeg2Up.position = .zero
        backLeg2Up.zPosition = 1
        bl2Group.addChild(backLeg2Up)
        deerBackLeg2Up = backLeg2Up

        let backLeg2Down = SKSpriteNode(imageNamed: "deer1_backleg2down")
        backLeg2Down.anchorPoint = CGPoint(x: 0.37, y: 0.30)
        backLeg2Down.position = CGPoint(x: -6, y: -195)         // knä relativt höft
        backLeg2Down.zPosition = -1
        backLeg2Up.addChild(backLeg2Down)
        deerBackLeg2Down = backLeg2Down

        // Svans: pivoterar vid roten (nedersta pixeln = fästpunkt mot kroppen)
        let tail = SKSpriteNode(imageNamed: "deer1_tail")
        tail.anchorPoint = CGPoint(x: 0.2876, y: 0.5714)  // nedersta synliga pixeln
        tail.position = CGPoint(x: -269, y: 110)           // fästpunkt i deer-space (35px ner)
        tail.zPosition = 4
        deer.addChild(tail)
        deerTail = tail

        let body = SKSpriteNode(imageNamed: "deer1_body")
        body.zPosition = 5
        deer.addChild(body)
        deerBody = body

        // --- Framben 1 (närmare framben — FRAMFÖR body, z=7) ---
        let fl1Group = SKNode()
        fl1Group.zPosition = 7
        fl1Group.position = CGPoint(x: 126, y: -85)     // 50px under topmost pixel
        deer.addChild(fl1Group)
        frontLeg1Group = fl1Group

        let frontLeg1Up = SKSpriteNode(imageNamed: "deer1_frontleg1up")
        frontLeg1Up.anchorPoint = CGPoint(x: 0.5997, y: 0.4581)  // 50px under topmost pixel
        frontLeg1Up.position = .zero
        frontLeg1Up.zPosition = 1
        fl1Group.addChild(frontLeg1Up)
        deerFrontLeg1Up = frontLeg1Up

        let frontLeg1Down = SKSpriteNode(imageNamed: "deer1_frontleg1down")
        frontLeg1Down.anchorPoint = CGPoint(x: 0.61, y: 0.24)
        frontLeg1Down.position = CGPoint(x: 13, y: -443)        // knä relativt axel
        frontLeg1Down.zPosition = -1
        frontLeg1Up.addChild(frontLeg1Down)
        deerFrontLeg1Down = frontLeg1Down

        // --- Framben 2 (bortre framben — BAKOM body, z=2) ---
        let fl2Group = SKNode()
        fl2Group.zPosition = 2
        fl2Group.position = CGPoint(x: 368, y: -181)    // 50px under topmost pixel
        deer.addChild(fl2Group)
        frontLeg2Group = fl2Group

        let frontLeg2Up = SKSpriteNode(imageNamed: "deer1_frontleg2up")
        frontLeg2Up.anchorPoint = CGPoint(x: 0.7896, y: 0.4108)  // 50px under topmost pixel
        frontLeg2Up.position = .zero
        frontLeg2Up.zPosition = 1
        fl2Group.addChild(frontLeg2Up)
        deerFrontLeg2Up = frontLeg2Up

        let frontLeg2Down = SKSpriteNode(imageNamed: "deer1_frontleg2down")
        frontLeg2Down.anchorPoint = CGPoint(x: 0.79, y: 0.26)
        frontLeg2Down.position = CGPoint(x: 1, y: -306)         // knä relativt axel
        frontLeg2Down.zPosition = -1
        frontLeg2Up.addChild(frontLeg2Down)
        deerFrontLeg2Down = frontLeg2Down

        let head = SKSpriteNode(imageNamed: "deer1_head")
        head.anchorPoint = CGPoint(x: 0.7227, y: 0.5847)  // 50px ovan bottommost pixel — nacken
        head.position = CGPoint(x: 283, y: 172)            // kompenserar anchorPoint-flytten
        head.zPosition = 10
        deer.addChild(head)
        deerHead = head

        deer.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.fadeAlpha(to: 1.0, duration: 1.2),
            SKAction.run { [weak self] in
                guard let self else { return }

                // Stilla andning
                let breatheUp = SKAction.scale(to: 0.84 * 1.015, duration: 1.4)
                breatheUp.timingMode = .easeInEaseOut
                let breatheDown = SKAction.scale(to: 0.84 * 0.985, duration: 1.4)
                breatheDown.timingMode = .easeInEaseOut
                deer.run(SKAction.repeatForever(SKAction.sequence([breatheUp, breatheDown])), withKey: "deerBreathe")

                // Sällsynt slumpmässig blink
                let normalTex = SKTexture(imageNamed: "deer1_head")
                let blinkTex = SKTexture(imageNamed: "deer1_head_blink")
                head.run(SKAction.repeatForever(SKAction.sequence([
                    SKAction.wait(forDuration: 4.0, withRange: 3.0),
                    SKAction.setTexture(blinkTex, resize: false),
                    SKAction.wait(forDuration: 0.12),
                    SKAction.setTexture(normalTex, resize: false),
                ])), withKey: "idleBlink")

                // Outer glow (samma stil som tavlan)
                let deerGlow = SKEffectNode()
                deerGlow.shouldRasterize = true
                deerGlow.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 40.0])
                deerGlow.zPosition = deer.zPosition - 1
                deerGlow.position = deer.position
                deerGlow.alpha = 0
                self.addChild(deerGlow)

                let glowSprite = SKSpriteNode(imageNamed: "deer1_body")
                glowSprite.setScale(deer.xScale * 1.08)
                glowSprite.colorBlendFactor = 1.0
                glowSprite.color = .white
                deerGlow.addChild(glowSprite)

                let shimmer = SKAction.sequence([
                    SKAction.fadeAlpha(to: 0.5, duration: 1.2),
                    SKAction.fadeAlpha(to: 0.2, duration: 1.0),
                    SKAction.fadeAlpha(to: 0.55, duration: 0.8),
                    SKAction.fadeAlpha(to: 0.15, duration: 1.4)
                ])
                deerGlow.run(SKAction.repeatForever(shimmer), withKey: "deerShimmer")

                self.deerGlow = deerGlow

                // Maskros-fröställning vid hovarna
                // Maskrosor sparade till annat rum:
                // self.spawnMaskrosBoll(on: deer)
                // self.spawnExtraMaskrosBollar(on: deer)
                // self.spawnTeaserMaskrosor(on: deer)
                self.startHoofGlitter(on: deer)
            }
        ]))
    }

    // MARK: - Maskros-fröställning

    private func spawnMaskrosBoll(on deer: SKNode) {
        let maskrosGlow = SKEffectNode()
        maskrosGlow.shouldRasterize = true
        maskrosGlow.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 25.0])
        maskrosGlow.position = CGPoint(x: 50, y: -1100)
        maskrosGlow.zPosition = 19
        maskrosGlow.alpha = 0
        maskrosGlow.name = "maskrosGlow"
        deer.addChild(maskrosGlow)

        let maskrosCarousel = SKNode()
        maskrosCarousel.position = CGPoint(x: 50, y: -1100)
        maskrosCarousel.zPosition = 20
        maskrosCarousel.alpha = 0
        maskrosCarousel.name = "maskrosCarousel"
        deer.addChild(maskrosCarousel)

        let maskrosNames = ["maskros1", "maskros2", "maskros3"]
        let count = 9
        let radius: CGFloat = 0
        let angleStep = (.pi * 2) / CGFloat(count)

        for i in 0..<count {
            let angle = angleStep * CGFloat(i) - .pi / 2

            let container = SKNode()
            container.position = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
            container.name = "maskrosItem"
            maskrosCarousel.addChild(container)

            let invertNode = SKEffectNode()
            invertNode.shouldRasterize = true
            invertNode.filter = CIFilter(name: "CIColorInvert")
            let m = SKSpriteNode(imageNamed: maskrosNames[i % 3])
            m.zRotation = angle - .pi / 2
            m.setScale(1.0)
            m.anchorPoint = CGPoint(x: 0.5, y: 0.0)
            invertNode.addChild(m)
            container.addChild(invertNode)

            let glow = SKEffectNode()
            glow.shouldRasterize = true
            glow.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 14.0])
            glow.zPosition = -1
            let glowSprite = SKSpriteNode(imageNamed: maskrosNames[i % 3])
            glowSprite.zRotation = angle - .pi / 2
            glowSprite.anchorPoint = CGPoint(x: 0.5, y: 0.0)
            glowSprite.setScale(1.1)
            glowSprite.colorBlendFactor = 1.0
            glowSprite.color = .white
            glowSprite.alpha = 0.85
            glow.addChild(glowSprite)
            container.addChild(glow)

            let delay = Double(i) * 0.08
            let wiggleAmount: CGFloat = CGFloat.random(in: 0.10...0.20)
            let wiggleSpeed = TimeInterval.random(in: 0.3...0.5)
            let wiggleR = SKAction.rotate(byAngle: wiggleAmount, duration: wiggleSpeed)
            wiggleR.timingMode = .easeInEaseOut
            let wiggleL = SKAction.rotate(byAngle: -wiggleAmount * 2, duration: wiggleSpeed * 2)
            wiggleL.timingMode = .easeInEaseOut
            let wiggleBack = SKAction.rotate(byAngle: wiggleAmount, duration: wiggleSpeed)
            wiggleBack.timingMode = .easeInEaseOut
            invertNode.run(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.repeatForever(SKAction.sequence([wiggleR, wiggleL, wiggleBack]))
            ]), withKey: "maskrosWiggle")
        }

        // Glow-kopior
        for i in 0..<count {
            let angle = angleStep * CGFloat(i) - .pi / 2
            let g = SKSpriteNode(imageNamed: maskrosNames[i % 3])
            g.position = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
            g.zRotation = angle - .pi / 2
            g.setScale(1.1)
            g.anchorPoint = CGPoint(x: 0.5, y: 0.0)
            g.colorBlendFactor = 1.0
            g.color = .white
            maskrosGlow.addChild(g)
        }

        let shimmer = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.9, duration: 1.2),
            SKAction.fadeAlpha(to: 0.4, duration: 1.0),
            SKAction.fadeAlpha(to: 1.0, duration: 0.8),
            SKAction.fadeAlpha(to: 0.35, duration: 1.4)
        ])

        // Fada in och vicka
        maskrosCarousel.run(SKAction.fadeAlpha(to: 1.0, duration: 0.5))
        maskrosGlow.run(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.8, duration: 0.5),
            SKAction.repeatForever(shimmer)
        ]))
    }

    private func spawnExtraMaskrosBollar(on deer: SKNode) {
        let maskrosNames = ["maskros1", "maskros2", "maskros3"]
        // Första vågen: 10-12 st, sedan andra vågen: dubbelt så många
        let wave1Count = Int.random(in: 10...12)
        let wave2Count = wave1Count * 2
        let extraCount = wave1Count + wave2Count
        let angleStep = (.pi * 2) / CGFloat(9)  // samma som originalet

        for b in 0..<extraCount {
            let isWave2 = b >= wave1Count
            let spawnDelay = isWave2
                ? TimeInterval.random(in: 2.5...4.0)   // andra vågen: mer fördröjning
                : TimeInterval.random(in: 0.1...1.2)    // första vågen
            let scale = isWave2
                ? CGFloat.random(in: 0.3...0.8)         // andra vågen: mer variation
                : CGFloat.random(in: 0.5...1.0)

            // Bred spridning med mer åt vänster
            let spreadR: CGFloat = isWave2 ? 1500 : 1300
            let spreadL: CGFloat = isWave2 ? 1500 : 1300
            let posX = CGFloat.random(in: -spreadL...spreadR)
            let posY = CGFloat.random(in: -1600 ... -600)

            let bollNode = SKNode()
            bollNode.position = CGPoint(x: posX, y: posY)
            bollNode.setScale(0.0)  // startar osynlig, poppar upp
            bollNode.zPosition = Int.random(in: 1...100) <= 35 ? 25 : 3  // 65% bakom, 35% framför  // framför eller bakom rådjuret
            bollNode.alpha = 0
            bollNode.name = "extraMaskros"
            deer.addChild(bollNode)

            // Glow bakom
            let bollGlow = SKEffectNode()
            bollGlow.shouldRasterize = true
            bollGlow.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 20.0])
            bollGlow.zPosition = -1
            bollGlow.alpha = 0.7
            bollNode.addChild(bollGlow)

            // 9 maskrosor per boll
            for i in 0..<9 {
                let angle = angleStep * CGFloat(i) - .pi / 2

                let container = SKNode()
                container.name = "maskrosItem"
                bollNode.addChild(container)

                let invertNode = SKEffectNode()
                invertNode.shouldRasterize = true
                invertNode.filter = CIFilter(name: "CIColorInvert")
                let m = SKSpriteNode(imageNamed: maskrosNames[i % 3])
                m.zRotation = angle - .pi / 2
                m.setScale(1.0)
                m.anchorPoint = CGPoint(x: 0.5, y: 0.0)
                invertNode.addChild(m)
                container.addChild(invertNode)

                // Individuell glow per stjälk
                let glow = SKEffectNode()
                glow.shouldRasterize = true
                glow.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 14.0])
                glow.zPosition = -1
                let gs = SKSpriteNode(imageNamed: maskrosNames[i % 3])
                gs.zRotation = angle - .pi / 2
                gs.anchorPoint = CGPoint(x: 0.5, y: 0.0)
                gs.setScale(1.1)
                gs.colorBlendFactor = 1.0
                gs.color = .white
                gs.alpha = 0.85
                glow.addChild(gs)
                container.addChild(glow)

                // Vickning
                let wiggleAmount: CGFloat = CGFloat.random(in: 0.10...0.20)
                let wiggleSpeed = TimeInterval.random(in: 0.3...0.5)
                let wR = SKAction.rotate(byAngle: wiggleAmount, duration: wiggleSpeed)
                wR.timingMode = .easeInEaseOut
                let wL = SKAction.rotate(byAngle: -wiggleAmount * 2, duration: wiggleSpeed * 2)
                wL.timingMode = .easeInEaseOut
                let wB = SKAction.rotate(byAngle: wiggleAmount, duration: wiggleSpeed)
                wB.timingMode = .easeInEaseOut
                invertNode.run(SKAction.sequence([
                    SKAction.wait(forDuration: Double(i) * 0.08),
                    SKAction.repeatForever(SKAction.sequence([wR, wL, wB]))
                ]), withKey: "maskrosWiggle")

                // Glow-kopia för bollGlow
                let gc = SKSpriteNode(imageNamed: maskrosNames[i % 3])
                gc.zRotation = angle - .pi / 2
                gc.setScale(1.1)
                gc.anchorPoint = CGPoint(x: 0.5, y: 0.0)
                gc.colorBlendFactor = 1.0
                gc.color = .white
                bollGlow.addChild(gc)
            }

            // Shimmer på glowen
            let shimmer = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.9, duration: CGFloat.random(in: 0.8...1.4)),
                SKAction.fadeAlpha(to: 0.4, duration: CGFloat.random(in: 0.7...1.2)),
                SKAction.fadeAlpha(to: 1.0, duration: CGFloat.random(in: 0.6...1.0)),
                SKAction.fadeAlpha(to: 0.35, duration: CGFloat.random(in: 0.9...1.5))
            ])
            bollGlow.run(SKAction.repeatForever(shimmer))

            // Poppa upp! Studsig overshoot som en blomma som slår ut
            let popScale = scale
            bollNode.run(SKAction.sequence([
                SKAction.wait(forDuration: spawnDelay),
                SKAction.group([
                    SKAction.fadeAlpha(to: 1.0, duration: 0.08),
                    SKAction.sequence([
                        SKAction.scale(to: popScale * 1.3, duration: 0.12),
                        SKAction.scale(to: popScale * 0.85, duration: 0.08),
                        SKAction.scale(to: popScale * 1.1, duration: 0.06),
                        SKAction.scale(to: popScale, duration: 0.06),
                    ]),
                    SKAction.moveBy(x: 0, y: CGFloat.random(in: 8...20), duration: 0.12),
                ])
            ]))

            // Individuell pulsering
            let pulseSpeed = TimeInterval.random(in: 0.5...1.0)
            let pulseAmt = popScale * CGFloat.random(in: 0.06...0.14)
            let pUp = SKAction.scale(to: popScale + pulseAmt, duration: pulseSpeed)
            pUp.timingMode = .easeInEaseOut
            let pDown = SKAction.scale(to: popScale - pulseAmt * 0.5, duration: pulseSpeed)
            pDown.timingMode = .easeInEaseOut
            bollNode.run(SKAction.sequence([
                SKAction.wait(forDuration: spawnDelay + 0.35),
                SKAction.repeatForever(SKAction.sequence([pUp, pDown]))
            ]), withKey: "bollPulse")
        }
    }

    private func blowAwayMaskros() {
        guard let deer = deerNode else { return }

        // Blås bort originalbollen först (0.5s fördröjning)
        if let carousel = deer.childNode(withName: "maskrosCarousel"),
           let glow = deer.childNode(withName: "maskrosGlow") {
            blowAwayBoll(carousel, glow: glow, delay: 0.5)
        }

        // Blås bort extra bollar en och en med korta intervall, 1s efter originalet
        var extraDelay: TimeInterval = 1.5
        deer.enumerateChildNodes(withName: "extraMaskros") { node, _ in
            let delay = extraDelay
            extraDelay += TimeInterval.random(in: 0.08...0.2)

            // Hitta bollens glow (första SKEffectNode-barnet)
            node.run(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.run { [weak self] in
                    self?.blowAwayExtraBoll(node)
                }
            ]))
        }
    }

    /// Blåser bort en hel boll (carousel + glow) — frön åt alla håll (stamp, inte vind)
    private func blowAwayBoll(_ carousel: SKNode, glow: SKNode, delay: TimeInterval) {
        carousel.run(SKAction.sequence([
            SKAction.wait(forDuration: delay),
            // Glad puff innan explosion
            SKAction.scale(to: 1.25, duration: 0.07),
            SKAction.scale(to: 0.9, duration: 0.05),
            SKAction.scale(to: 1.0, duration: 0.04),
            SKAction.run {
                carousel.enumerateChildNodes(withName: "maskrosItem") { container, _ in
                    let baseAngle = CGFloat.random(in: 0...(.pi * 2))
                    let distance = CGFloat.random(in: 350...900)
                    let duration = TimeInterval.random(in: 0.8...1.4)
                    let itemDelay = TimeInterval.random(in: 0...0.2)

                    // Dansande spiral-bana
                    let mid1X = cos(baseAngle + 0.5) * distance * 0.3
                    let mid1Y = sin(baseAngle + 0.5) * distance * 0.3 + CGFloat.random(in: 50...130)
                    let mid2X = cos(baseAngle - 0.4) * distance * 0.7
                    let mid2Y = sin(baseAngle - 0.4) * distance * 0.7 + CGFloat.random(in: 80...220)
                    let endX = cos(baseAngle) * distance
                    let endY = sin(baseAngle) * distance + CGFloat.random(in: 100...300)

                    let step1 = duration * 0.3
                    let step2 = duration * 0.35
                    let step3 = duration * 0.35

                    let curve = SKAction.sequence([
                        SKAction.moveBy(x: mid1X, y: mid1Y, duration: step1),
                        SKAction.moveBy(x: mid2X - mid1X, y: mid2Y - mid1Y, duration: step2),
                        SKAction.moveBy(x: endX - mid2X, y: endY - mid2Y, duration: step3),
                    ])
                    let spin = SKAction.rotate(byAngle: CGFloat.random(in: 4...10) * (Bool.random() ? 1 : -1), duration: duration)
                    let shrink = SKAction.sequence([
                        SKAction.scale(to: 1.2, duration: duration * 0.12),
                        SKAction.scale(to: 0.15, duration: duration * 0.88),
                    ])
                    let fade = SKAction.sequence([
                        SKAction.wait(forDuration: duration * 0.5),
                        SKAction.fadeOut(withDuration: duration * 0.5),
                    ])

                    container.run(SKAction.sequence([
                        SKAction.wait(forDuration: itemDelay),
                        SKAction.group([curve, spin, shrink, fade])
                    ]))
                }
            },
            SKAction.wait(forDuration: 2.0),
            SKAction.removeFromParent()
        ]))

        glow.run(SKAction.sequence([
            SKAction.wait(forDuration: delay),
            SKAction.fadeOut(withDuration: 0.6),
            SKAction.removeFromParent()
        ]))
    }

    /// Blåser bort en extra maskrosboll — frön åt alla håll
    private func blowAwayExtraBoll(_ boll: SKNode) {
        // Liten glad skakning innan fröna flyger — som ett "poff!"
        boll.run(SKAction.sequence([
            SKAction.scale(to: boll.xScale * 1.2, duration: 0.06),
            SKAction.scale(to: boll.xScale * 0.9, duration: 0.04),
            SKAction.scale(to: boll.xScale, duration: 0.03),
        ]))

        boll.enumerateChildNodes(withName: "maskrosItem") { container, _ in
            // Spiralande bana — inte rak linje, mer som ett dansande frö
            let baseAngle = CGFloat.random(in: 0...(.pi * 2))
            let distance = CGFloat.random(in: 300...900)
            let duration = TimeInterval.random(in: 0.8...1.4)
            let itemDelay = TimeInterval.random(in: 0...0.12)

            // Kurvad bana i tre steg — fröet dansar iväg
            let mid1X = cos(baseAngle + 0.4) * distance * 0.3
            let mid1Y = sin(baseAngle + 0.4) * distance * 0.3 + CGFloat.random(in: 40...120)
            let mid2X = cos(baseAngle - 0.3) * distance * 0.7
            let mid2Y = sin(baseAngle - 0.3) * distance * 0.7 + CGFloat.random(in: 80...200)
            let endX = cos(baseAngle) * distance
            let endY = sin(baseAngle) * distance + CGFloat.random(in: 100...300)

            let step1 = duration * 0.3
            let step2 = duration * 0.35
            let step3 = duration * 0.35

            let curve = SKAction.sequence([
                SKAction.moveBy(x: mid1X, y: mid1Y, duration: step1),
                SKAction.moveBy(x: mid2X - mid1X, y: mid2Y - mid1Y, duration: step2),
                SKAction.moveBy(x: endX - mid2X, y: endY - mid2Y, duration: step3),
            ])

            // Piruett + pulsande krympning
            let spin = SKAction.rotate(byAngle: CGFloat.random(in: 4...10) * (Bool.random() ? 1 : -1), duration: duration)
            let shrink = SKAction.sequence([
                SKAction.scale(to: 1.15, duration: duration * 0.15),  // liten puff uppåt
                SKAction.scale(to: 0.15, duration: duration * 0.85),
            ])
            let fade = SKAction.sequence([
                SKAction.wait(forDuration: duration * 0.5),
                SKAction.fadeOut(withDuration: duration * 0.5),
            ])

            container.run(SKAction.sequence([
                SKAction.wait(forDuration: itemDelay),
                SKAction.group([curve, spin, shrink, fade])
            ]))
        }

        boll.run(SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Teaser-maskrosor (innan dansen, lockar barnet)

    private func spawnTeaserMaskrosor(on deer: SKNode) {
        let maskrosNames = ["maskros1", "maskros2", "maskros3"]

        // Spawna enskilda bollar med slumpmässiga intervall
        let teaserAction = SKAction.repeatForever(SKAction.sequence([
            SKAction.wait(forDuration: 2.5, withRange: 3.0),  // var 1–4s
            SKAction.run { [weak self] in
                guard let self, !self.isDeerDancing, self.deerNode != nil else { return }

                let scale = CGFloat.random(in: 0.3...0.7)
                let posX = CGFloat.random(in: -1400...1400)
                let posY = CGFloat.random(in: -1600 ... -600)

                let boll = SKNode()
                boll.position = CGPoint(x: posX, y: posY)
                boll.setScale(0.0)
                boll.zPosition = Int.random(in: 1...100) <= 35 ? 25 : 3  // 65% bakom, 35% framför
                boll.name = "teaserMaskros"
                deer.addChild(boll)

                let stemCount = Int.random(in: 4...7)
                for i in 0..<stemCount {
                    let angle = (.pi * 2) / CGFloat(stemCount) * CGFloat(i) - .pi / 2
                    let container = SKNode()
                    container.name = "maskrosItem"
                    boll.addChild(container)

                    let invertNode = SKEffectNode()
                    invertNode.shouldRasterize = true
                    invertNode.filter = CIFilter(name: "CIColorInvert")
                    let m = SKSpriteNode(imageNamed: maskrosNames[i % 3])
                    m.zRotation = angle - .pi / 2
                    m.setScale(1.0)
                    m.anchorPoint = CGPoint(x: 0.5, y: 0.0)
                    invertNode.addChild(m)
                    container.addChild(invertNode)

                    let wa: CGFloat = CGFloat.random(in: 0.08...0.18)
                    let ws = TimeInterval.random(in: 0.3...0.5)
                    invertNode.run(SKAction.repeatForever(SKAction.sequence([
                        SKAction.rotate(byAngle: wa, duration: ws),
                        SKAction.rotate(byAngle: -wa * 2, duration: ws * 2),
                        SKAction.rotate(byAngle: wa, duration: ws),
                    ])))
                }

                // Poppa upp, lev en stund, blås bort mjukt
                let aliveTime = TimeInterval.random(in: 1.5...3.5)
                let blowDur = TimeInterval.random(in: 0.8...1.2)

                boll.run(SKAction.sequence([
                    // Pop in
                    SKAction.group([
                        SKAction.fadeAlpha(to: 1.0, duration: 0.06),
                        SKAction.sequence([
                            SKAction.scale(to: scale * 1.25, duration: 0.1),
                            SKAction.scale(to: scale * 0.88, duration: 0.07),
                            SKAction.scale(to: scale, duration: 0.05),
                        ]),
                    ]),
                    // Vicka och vänta
                    SKAction.wait(forDuration: aliveTime),
                    // Mjuk bortblåsning
                    SKAction.run {
                        boll.enumerateChildNodes(withName: "maskrosItem") { container, _ in
                            let ba = CGFloat.random(in: 0...(.pi * 2))
                            let dist = CGFloat.random(in: 150...400)
                            let dx = cos(ba) * dist
                            let dy = sin(ba) * dist + CGFloat.random(in: 30...100)
                            container.run(SKAction.group([
                                SKAction.moveBy(x: dx, y: dy, duration: blowDur),
                                SKAction.rotate(byAngle: CGFloat.random(in: 2...5) * (Bool.random() ? 1 : -1), duration: blowDur),
                                SKAction.scale(to: 0.15, duration: blowDur),
                                SKAction.sequence([
                                    SKAction.wait(forDuration: blowDur * 0.4),
                                    SKAction.fadeOut(withDuration: blowDur * 0.6),
                                ])
                            ]))
                        }
                    },
                    SKAction.wait(forDuration: blowDur + 0.3),
                    SKAction.removeFromParent()
                ]))
            }
        ]))
        deer.run(teaserAction, withKey: "teaserMaskros")
    }

    // MARK: - Maskros-storm (kontinuerlig under dansen)

    private func startMaskrosStorm(on deer: SKNode) {
        let maskrosNames = ["maskros1", "maskros2", "maskros3"]
        let angleStep = (.pi * 2) / CGFloat(9)

        // Spawna en enskild maskrosboll som poppar upp och snabbt blåser bort
        func spawnAndBlow() {
            guard self.isDeerDancing else { return }

            let scale = CGFloat.random(in: 0.25...0.85)
            let posX = CGFloat.random(in: -1500...1500)
            let posY = CGFloat.random(in: -1600 ... -600)

            let boll = SKNode()
            boll.position = CGPoint(x: posX, y: posY)
            boll.setScale(0.0)
            // Slumpmässigt framför eller bakom rådjuret
            boll.zPosition = Int.random(in: 1...100) <= 35 ? 25 : 3  // 65% bakom, 35% framför
            boll.name = "stormMaskros"
            deer.addChild(boll)

            // Bygg bollen (förenklad — färre effekt-noder för prestanda)
            let stemCount = Int.random(in: 5...9)
            for i in 0..<stemCount {
                let angle = (.pi * 2) / CGFloat(stemCount) * CGFloat(i) - .pi / 2
                let container = SKNode()
                container.name = "maskrosItem"
                boll.addChild(container)

                let invertNode = SKEffectNode()
                invertNode.shouldRasterize = true
                invertNode.filter = CIFilter(name: "CIColorInvert")
                let m = SKSpriteNode(imageNamed: maskrosNames[i % 3])
                m.zRotation = angle - .pi / 2
                m.setScale(1.0)
                m.anchorPoint = CGPoint(x: 0.5, y: 0.0)
                invertNode.addChild(m)
                container.addChild(invertNode)

                // Varje stjälk vickar, lever olika länge, och blåser bort individuellt
                let wa: CGFloat = CGFloat.random(in: 0.12...0.25)
                let ws = TimeInterval.random(in: 0.2...0.35)
                let stemAlive = TimeInterval.random(in: 0.8...4.0)
                let stemBlowDur = TimeInterval.random(in: 0.5...1.2)
                let stemDelay = TimeInterval.random(in: 0...0.3)

                let ba = CGFloat.random(in: 0...(.pi * 2))
                let dist = CGFloat.random(in: 250...700)
                let midX = cos(ba + 0.4) * dist * 0.35
                let midY = sin(ba + 0.4) * dist * 0.35 + CGFloat.random(in: 30...120)
                let endX = cos(ba) * dist
                let endY = sin(ba) * dist + CGFloat.random(in: 60...200)

                let curve = SKAction.sequence([
                    SKAction.moveBy(x: midX, y: midY, duration: stemBlowDur * 0.35),
                    SKAction.moveBy(x: endX - midX, y: endY - midY, duration: stemBlowDur * 0.65),
                ])
                let spinAway = SKAction.rotate(byAngle: CGFloat.random(in: 3...8) * (Bool.random() ? 1 : -1), duration: stemBlowDur)
                let shrink = SKAction.sequence([
                    SKAction.scale(to: 1.15, duration: stemBlowDur * 0.1),
                    SKAction.scale(to: 0.1, duration: stemBlowDur * 0.9),
                ])
                let fade = SKAction.sequence([
                    SKAction.wait(forDuration: stemBlowDur * 0.4),
                    SKAction.fadeOut(withDuration: stemBlowDur * 0.6),
                ])

                container.run(SKAction.sequence([
                    SKAction.wait(forDuration: stemDelay),
                    // Vicka medan den lever
                    SKAction.group([
                        SKAction.repeat(SKAction.sequence([
                            SKAction.rotate(byAngle: wa, duration: ws),
                            SKAction.rotate(byAngle: -wa * 2, duration: ws * 2),
                            SKAction.rotate(byAngle: wa, duration: ws),
                        ]), count: max(1, Int(stemAlive / (ws * 4)))),
                    ]),
                    // Blås bort individuellt
                    SKAction.group([curve, spinAway, shrink, fade]),
                    SKAction.removeFromParent()
                ]))
            }

            // Poppa upp bollen
            let maxStemLife: TimeInterval = 4.5
            boll.run(SKAction.sequence([
                SKAction.group([
                    SKAction.fadeAlpha(to: 1.0, duration: 0.06),
                    SKAction.sequence([
                        SKAction.scale(to: scale * 1.3, duration: 0.1),
                        SKAction.scale(to: scale * 0.85, duration: 0.07),
                        SKAction.scale(to: scale, duration: 0.05),
                    ]),
                ]),
                // Vänta tills alla stjälkar blåst bort + marginal
                SKAction.wait(forDuration: maxStemLife + 1.5),
                SKAction.removeFromParent()
            ]))

            // Individuell pulsering under hela livstiden
            let pulseSpeed = TimeInterval.random(in: 0.4...0.8)
            let pulseAmount = scale * CGFloat.random(in: 0.08...0.18)
            let pulseUp = SKAction.scale(to: scale + pulseAmount, duration: pulseSpeed)
            pulseUp.timingMode = .easeInEaseOut
            let pulseDown = SKAction.scale(to: scale - pulseAmount * 0.5, duration: pulseSpeed)
            pulseDown.timingMode = .easeInEaseOut
            boll.run(SKAction.repeatForever(SKAction.sequence([pulseUp, pulseDown])), withKey: "bollPulse")
        }

        // Starta storm-loopen — popp popp popp flax popp!
        let stormAction = SKAction.repeatForever(SKAction.sequence([
            SKAction.run {
                spawnAndBlow()
                // Ibland 2-3 extra samtidigt för burst-effekt
                if Int.random(in: 0...2) == 0 { spawnAndBlow() }
                if Int.random(in: 0...4) == 0 { spawnAndBlow() }
            },
            SKAction.wait(forDuration: 0.12, withRange: 0.16),  // 0.04–0.20s mellan varje
        ]))
        deer.run(stormAction, withKey: "maskrosStorm")
    }

    private func stopMaskrosStorm() {
        deerNode?.removeAction(forKey: "maskrosStorm")
    }

    /// Alla maskrosbollar sveper vänster-höger-vänster under moonwalk
    private func moonwalkMaskrosor(duration: TimeInterval) {
        guard let deer = deerNode else { return }
        let names = ["stormMaskros", "extraMaskros", "teaserMaskros"]
        let swingDist: CGFloat = 180
        let stepDur = duration / 3.0

        let swingL = SKAction.moveBy(x: -swingDist, y: 0, duration: stepDur)
        swingL.timingMode = .easeInEaseOut
        let swingR = SKAction.moveBy(x: swingDist * 2, y: 0, duration: stepDur)
        swingR.timingMode = .easeInEaseOut
        let swingBack = SKAction.moveBy(x: -swingDist, y: 0, duration: stepDur)
        swingBack.timingMode = .easeInEaseOut

        for name in names {
            deer.enumerateChildNodes(withName: name) { boll, _ in
                // Individuell variation — lite olika avstånd och timing
                let personalDist = swingDist * CGFloat.random(in: 0.6...1.4)
                let personalDelay = TimeInterval.random(in: 0...0.3)

                let pL = SKAction.moveBy(x: -personalDist, y: 0, duration: stepDur)
                pL.timingMode = .easeInEaseOut
                let pR = SKAction.moveBy(x: personalDist * 2, y: 0, duration: stepDur)
                pR.timingMode = .easeInEaseOut
                let pBack = SKAction.moveBy(x: -personalDist, y: 0, duration: stepDur)
                pBack.timingMode = .easeInEaseOut

                boll.run(SKAction.sequence([
                    SKAction.wait(forDuration: personalDelay),
                    pL, pR, pBack
                ]), withKey: "moonSwing")
            }
        }
    }

    /// Alla synliga maskrosbollar snurrar och kompenserar deer-lyft vid stegring
    private func spinAllMaskrosor() {
        guard let deer = deerNode else { return }
        let names = ["stormMaskros", "extraMaskros", "teaserMaskros"]

        // Deer lyfter ~55-85px under stegring — kompensera med motrörelse nedåt
        let compensateDown = SKAction.moveBy(x: 0, y: -70, duration: 0.33)
        compensateDown.timingMode = .easeOut
        let compensateUp = SKAction.moveBy(x: 0, y: 70, duration: 0.22)
        compensateUp.timingMode = .easeIn

        for name in names {
            deer.enumerateChildNodes(withName: name) { boll, _ in
                let dir: CGFloat = Bool.random() ? 1 : -1
                let duration = TimeInterval.random(in: 0.9...1.4)
                boll.run(SKAction.rotate(byAngle: .pi * 6 * dir, duration: duration), withKey: "rearSpin")
                // Motrörelse: ner när deer lyfter, upp när deer landar
                boll.run(SKAction.sequence([
                    compensateDown,
                    SKAction.wait(forDuration: duration * 0.6),
                    compensateUp
                ]), withKey: "rearCompensate")
            }
        }
    }

    // MARK: - Hoof Disco Glitter

    // Hovpositioner i deer-space (nedre änden av benen)
    private let hoofPositions: [CGPoint] = [
        CGPoint(x: -50, y: -690),   // bakre vänster övre
        CGPoint(x: -650, y: -890),   // bakre vänster yttre
        CGPoint(x: -505, y: -900),   // bakre vänster
        CGPoint(x: -409, y: -870),   // bakre höger
        CGPoint(x: 126, y: -910),    // främre vänster
        CGPoint(x: 318, y: -880),    // främre höger
        CGPoint(x: 326, y: -910),    // främre vänster yttre
        CGPoint(x: 468, y: -880),    // främre höger yttre
    ]

    /// Mjukt glitter vid fyra hovar innan dansen — lockar barnet
    private func startHoofGlitter(on deer: SKNode) {
        for (i, pos) in hoofPositions.enumerated() {
            let glitter = SKNode()
            glitter.position = pos
            glitter.zPosition = 3
            glitter.name = "hoofGlitter\(i)"
            deer.addChild(glitter)

            let spawnAction = SKAction.run { [weak glitter] in
                guard let glitter else { return }
                Self.spawnDiscoParticle(in: glitter, spread: 200, life: 1.5...3.0, scale: 0.5...1.5)
            }
            glitter.run(SKAction.sequence([
                SKAction.wait(forDuration: Double(i) * 0.3),
                SKAction.repeatForever(SKAction.sequence([
                    spawnAction,
                    SKAction.wait(forDuration: 0.2, withRange: 0.15),
                ]))
            ]), withKey: "hoofGlitterLoop")
        }
    }

    /// Explosiv disco-storm vid fyra hovar under dansen
    private func startDanceGlitterStorm(on deer: SKNode) {
        // Ta bort idle-glitter
        for i in 0..<hoofPositions.count {
            deer.childNode(withName: "hoofGlitter\(i)")?.removeAllActions()
            deer.childNode(withName: "hoofGlitter\(i)")?.removeFromParent()
        }

        // Skapa storm-nod vid varje hov
        for (i, pos) in hoofPositions.enumerated() {
            let storm = SKNode()
            storm.position = pos
            storm.zPosition = 3
            storm.name = "hoofStorm\(i)"
            deer.addChild(storm)

            let spawnBurst = SKAction.run { [weak storm] in
                guard let storm else { return }
                for _ in 0..<2 {
                    Self.spawnDiscoParticle(in: storm, spread: 400, life: 0.6...1.5, scale: 0.8...2.5)
                }
            }

            storm.run(SKAction.repeatForever(SKAction.sequence([
                spawnBurst,
                SKAction.wait(forDuration: 0.06, withRange: 0.04),
            ])), withKey: "stormLoop")
        }

        // Kontinuerlig synkad burst-loop — anpassar sig till alla faser
        let beat: TimeInterval = 0.22
        let mBeat: TimeInterval = 0.35
        let rb: TimeInterval = beat * 1.5  // riverdance beat

        // Burst vid hovnedslag — vanlig + blinkande mix
        func hoofHit(_ n: Int, _ s: CGFloat, _ sc: ClosedRange<CGFloat>) -> SKAction {
            SKAction.run { [weak self] in self?.burstAtHooves(intensity: n, spread: s, scale: sc) }
        }
        func hoofBlink(_ n: Int, _ s: CGFloat, _ sc: ClosedRange<CGFloat>) -> SKAction {
            SKAction.run { [weak self] in self?.blinkBurstAtHooves(intensity: n, spread: s, scale: sc) }
        }

        // Stepp-fas: vanliga + blinkande vid bigBounce
        let steppBursts = SKAction.sequence([
            SKAction.wait(forDuration: beat * 0.8), hoofHit(5, 400, 0.8...2.0),
            SKAction.wait(forDuration: beat * 0.8), hoofHit(5, 400, 0.8...2.0),
            SKAction.wait(forDuration: beat * 0.8), hoofHit(5, 400, 0.8...2.0), hoofBlink(2, 500, 1.0...2.5),
            SKAction.wait(forDuration: beat * 0.8), hoofHit(5, 400, 0.8...2.0), hoofBlink(2, 500, 1.0...2.5),
            SKAction.wait(forDuration: beat * 0.8), hoofHit(8, 600, 1.0...3.0), hoofBlink(4, 700, 1.5...3.0),
            SKAction.wait(forDuration: beat * 0.8), hoofHit(8, 600, 1.0...3.0), hoofBlink(4, 700, 1.5...3.0),
            SKAction.wait(forDuration: beat * 0.8), hoofHit(8, 600, 1.0...3.0), hoofBlink(5, 800, 1.5...3.5),
            SKAction.wait(forDuration: beat * 0.8), hoofHit(10, 700, 1.5...3.5), hoofBlink(6, 900, 2.0...4.0),
        ])

        // Moonwalk: mjukare, varannan blinkande
        let moonBursts = SKAction.repeat(SKAction.sequence([
            SKAction.wait(forDuration: mBeat * 0.9), hoofHit(4, 350, 0.6...2.0),
            SKAction.wait(forDuration: mBeat * 0.9), hoofHit(4, 350, 0.6...2.0), hoofBlink(2, 500, 1.0...2.5),
        ]), count: 6)

        // Riverdance: varje landning — dubbla + blinkande
        let riverBursts = SKAction.repeat(SKAction.sequence([
            SKAction.wait(forDuration: rb * 0.65),
            hoofHit(7, 500, 1.0...2.5),
            hoofBlink(4, 600, 1.5...3.0),
            hoofHit(4, 300, 0.5...1.5),
        ]), count: 8)

        // Stegring: massiv blinkande explosion
        let rearBursts = SKAction.sequence([
            SKAction.wait(forDuration: beat * 6),
            hoofHit(15, 900, 1.5...4.0),
            hoofBlink(15, 1000, 2.0...4.5),
            hoofHit(10, 700, 1.0...3.0),
            hoofBlink(8, 800, 1.5...3.5),
        ])

        // Kör alla bursts i sekvens matchande dansens koreografi
        // Ordning: intro(2s) → fas1 → fas2 → riverdance → stegring → outro
        let moonFirst = true  // matchar inte exakt men ger bra synk oavsett
        deer.run(SKAction.sequence([
            SKAction.wait(forDuration: 2.0),  // intro
            steppBursts,  // fas 1 eller moon
            SKAction.wait(forDuration: 0.2),
            moonBursts,   // fas 2 eller stepp
            SKAction.wait(forDuration: 0.2),
            riverBursts,  // riverdance
            SKAction.wait(forDuration: 0.2),
            rearBursts,   // stegring
        ]), withKey: "hoofBurstSync")
    }

    /// Explosion vid alla fyra hovar
    private func burstAtHooves(intensity: Int, spread: CGFloat, scale: ClosedRange<CGFloat>) {
        guard let deer = deerNode else { return }
        for i in 0..<hoofPositions.count {
            if let storm = deer.childNode(withName: "hoofStorm\(i)") {
                for _ in 0..<intensity {
                    Self.spawnDiscoParticle(in: storm, spread: spread, life: 0.5...1.2, scale: scale)
                }
            }
        }
    }

    private func stopDanceGlitterStorm() {
        guard let deer = deerNode else { return }
        deer.removeAction(forKey: "hoofBurstSync")

        for i in 0..<hoofPositions.count {
            guard let storm = deer.childNode(withName: "hoofStorm\(i)") else { continue }
            storm.removeAction(forKey: "stormLoop")

            // Avslutnande mjuka partiklar — stillsamma, spridda, långsamt utdöende
            let fadeSpawn = SKAction.run { [weak storm] in
                guard let storm else { return }
                Self.spawnDiscoParticle(in: storm, spread: 1200, life: 2.5...4.5, scale: 0.3...1.0)
            }
            storm.run(SKAction.sequence([
                // Glesa, stillsamma partiklar som sprids ut över rummet
                SKAction.repeat(SKAction.sequence([
                    fadeSpawn,
                    SKAction.wait(forDuration: 0.3, withRange: 0.2),
                ]), count: 8),
                // Vänta tills alla dött ut
                SKAction.wait(forDuration: 5.0),
                SKAction.removeFromParent()
            ]))
        }
    }

    /// Blinkande burst vid alla hovar
    private func blinkBurstAtHooves(intensity: Int, spread: CGFloat, scale: ClosedRange<CGFloat>) {
        guard let deer = deerNode else { return }
        for i in 0..<hoofPositions.count {
            if let storm = deer.childNode(withName: "hoofStorm\(i)") {
                for _ in 0..<intensity {
                    Self.spawnBlinkingDiscoParticle(in: storm, spread: spread, life: 1.0...2.5, scale: scale)
                }
            }
        }
    }

    /// Extra explosion vid stegring — blinkande partiklar + massiv front-explosion
    private func burstHoofGlitter() {
        guard let deer = deerNode else { return }
        let beat: TimeInterval = 0.22

        // Alla befintliga partiklar blinkar extra vid stegring
        for i in 0..<hoofPositions.count {
            deer.childNode(withName: "hoofStorm\(i)")?.enumerateChildNodes(withName: "*") { particle, _ in
                let speed = TimeInterval.random(in: 0.03...0.08)
                let blinkCount = Int.random(in: 5...10)
                var actions: [SKAction] = []
                for _ in 0..<blinkCount {
                    actions.append(SKAction.fadeAlpha(to: CGFloat.random(in: 0.0...0.1), duration: speed))
                    actions.append(SKAction.fadeAlpha(to: CGFloat.random(in: 0.6...1.0), duration: speed * CGFloat.random(in: 0.5...1.5)))
                    if Bool.random() {
                        actions.append(SKAction.wait(forDuration: TimeInterval.random(in: 0.01...0.08)))
                    }
                }
                particle.run(SKAction.sequence(actions), withKey: "rearBlink")
            }
        }

        // Extra intensiv blinkning vid de nedre hovarna (0-2)
        for i in 0...2 {
            deer.childNode(withName: "hoofStorm\(i)")?.enumerateChildNodes(withName: "*") { particle, _ in
                let speed = TimeInterval.random(in: 0.02...0.05)
                let extraCount = Int.random(in: 8...15)
                var extra: [SKAction] = [SKAction.wait(forDuration: TimeInterval.random(in: 0...0.1))]
                for _ in 0..<extraCount {
                    extra.append(SKAction.fadeAlpha(to: 0, duration: speed))
                    extra.append(SKAction.fadeAlpha(to: CGFloat.random(in: 0.7...1.0), duration: speed * 0.6))
                    extra.append(SKAction.fadeAlpha(to: CGFloat.random(in: 0.0...0.05), duration: speed * 0.5))
                    extra.append(SKAction.fadeAlpha(to: CGFloat.random(in: 0.8...1.0), duration: speed * 0.8))
                }
                particle.run(SKAction.sequence(extra), withKey: "rearExtraBlink")
            }
        }

        // Lyft bara bakhovarnas storm-noder (0-2) uppåt med stegringen
        for i in 0...2 {
            if let storm = deer.childNode(withName: "hoofStorm\(i)") {
                let liftUp = SKAction.moveBy(x: 0, y: 80, duration: beat * 1.5)
                liftUp.timingMode = .easeOut
                let holdUp = SKAction.wait(forDuration: beat * 4)
                let comeDown = SKAction.moveBy(x: 0, y: -80, duration: beat)
                comeDown.timingMode = .easeIn
                storm.run(SKAction.sequence([liftUp, holdUp, comeDown]), withKey: "rearLift")
            }
        }

        // Blinkande burst vid alla hovar
        for i in 0..<hoofPositions.count {
            if let storm = deer.childNode(withName: "hoofStorm\(i)") {
                for _ in 0..<9 {
                    Self.spawnBlinkingDiscoParticle(in: storm, spread: 1000, life: 1.5...3.0, scale: 1.5...4.0)
                }
            }
        }

        // Extra blinkande burst vid de främre hovarna
        let frontHoofOffsets: [CGPoint] = [
            CGPoint(x: hoofPositions[3].x + 1150, y: hoofPositions[3].y + 200),
            CGPoint(x: hoofPositions[4].x + 1150, y: hoofPositions[4].y + 200),
            CGPoint(x: hoofPositions[5].x + 1150, y: hoofPositions[5].y + 200),
            CGPoint(x: hoofPositions[6].x + 1150, y: hoofPositions[6].y + 200),
            CGPoint(x: hoofPositions[7].x + 1150, y: hoofPositions[7].y + 200),
        ]
        for pos in frontHoofOffsets {
            let burst = SKNode()
            burst.position = pos
            burst.zPosition = 3
            deer.addChild(burst)
            for _ in 0..<9 {
                Self.spawnBlinkingDiscoParticle(in: burst, spread: 800, life: 1.2...2.5, scale: 1.5...4.0)
            }
            burst.run(SKAction.sequence([
                SKAction.wait(forDuration: 3.0),
                SKAction.removeFromParent()
            ]))
        }

        // Massiv front-explosion framför rådjuret som sprids i hela rummet
        guard let deer = deerNode else { return }

        // Mini sparkles framför hovarna
        let miniSparklePositions = [
            CGPoint(x: 500, y: -700),
            CGPoint(x: 700, y: -650),
        ]
        for pos in miniSparklePositions {
            let mini = SKNode()
            mini.position = pos
            mini.zPosition = 25
            deer.addChild(mini)
            for _ in 0..<5 {
                Self.spawnBlinkingDiscoParticle(in: mini, spread: 400, life: 1.0...2.0, scale: 0.8...2.0)
            }
            mini.run(SKAction.sequence([
                SKAction.wait(forDuration: 3.0),
                SKAction.removeFromParent()
            ]))
        }

        // 50% av befintliga partiklar snabbfadar ut när rådjuret landar
        let fadeLanding = SKAction.sequence([
            SKAction.wait(forDuration: beat * 5.5),
            SKAction.run { [weak deer] in
                guard let deer else { return }
                for i in 0..<self.hoofPositions.count {
                    deer.childNode(withName: "hoofStorm\(i)")?.enumerateChildNodes(withName: "*") { particle, _ in
                        guard Bool.random() else { return }  // 50% chans
                        let fadeDur = TimeInterval.random(in: 0.2...0.6)
                        let driftX = CGFloat.random(in: -200...200)
                        let driftY = CGFloat.random(in: 50...200)
                        particle.run(SKAction.group([
                            SKAction.fadeOut(withDuration: fadeDur),
                            SKAction.moveBy(x: driftX, y: driftY, duration: fadeDur),
                        ]))
                    }
                }
            }
        ])
        deer.run(fadeLanding, withKey: "rearFadeLanding")

        // Sparkle som dyker upp när rådjuret landar från stegringen
        let landingSparkle = SKNode()
        landingSparkle.position = CGPoint(x: 600, y: -950)
        landingSparkle.zPosition = 25
        deer.addChild(landingSparkle)
        landingSparkle.run(SKAction.sequence([
            SKAction.wait(forDuration: beat * 5.5),  // dyker upp på väg ner
            SKAction.run {
                for _ in 0..<12 {
                    Self.spawnBlinkingDiscoParticle(in: landingSparkle, spread: 600, life: 1.0...2.5, scale: 1.0...3.0)
                }
            },
            SKAction.wait(forDuration: 3.0),
            SKAction.removeFromParent()
        ]))

        let frontBurst = SKNode()
        frontBurst.position = CGPoint(x: 800, y: -400)  // framför rådjuret
        frontBurst.zPosition = 25  // framför rådjuret
        frontBurst.name = "frontBurst"
        deer.addChild(frontBurst)

        // Våg 1: Blinkande explosion uppåt och utåt
        for _ in 0..<18 {
            Self.spawnBlinkingDiscoParticle(in: frontBurst, spread: 1500, life: 1.5...3.0, scale: 2.0...5.0)
        }

        // Våg 2: Fördröjd blinkande efterchock
        frontBurst.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.15),
            SKAction.run {
                for _ in 0..<15 {
                    Self.spawnBlinkingDiscoParticle(in: frontBurst, spread: 2000, life: 2.0...4.0, scale: 1.5...4.0)
                }
            },
            // Våg 3: Sista regnande blinkande glitter
            SKAction.wait(forDuration: 0.3),
            SKAction.run {
                for _ in 0..<9 {
                    Self.spawnBlinkingDiscoParticle(in: frontBurst, spread: 2500, life: 2.5...4.5, scale: 1.0...3.0)
                }
            },
            // Rensa efter att partiklarna dött ut
            SKAction.wait(forDuration: 5.0),
            SKAction.removeFromParent()
        ]))
    }

    /// Generisk disco-partikel (solkatt/glitter)
    private static func spawnDiscoParticle(in container: SKNode, spread: CGFloat,
                                            life lifeRange: ClosedRange<TimeInterval>,
                                            scale scaleRange: ClosedRange<CGFloat>) {
        let rawScale = CGFloat.random(in: scaleRange)
        let isLarge = rawScale > 2.5
        let particleScale = isLarge ? rawScale * 0.5 : rawScale * 0.7
        let isStar = isLarge || Int.random(in: 0...2) == 0  // stora = alltid sparkle

        let particle: SKShapeNode
        if isLarge {
            // Sparkle — 6-uddad stjärna med tunna strålar
            let size = CGFloat.random(in: 10...22)
            let path = CGMutablePath()
            for j in 0..<12 {
                let angle = CGFloat(j) * .pi / 6 - .pi / 2
                let r: CGFloat = (j % 2 == 0) ? size : size * 0.12
                let p = CGPoint(x: cos(angle) * r, y: sin(angle) * r)
                if j == 0 { path.move(to: p) } else { path.addLine(to: p) }
            }
            path.closeSubpath()
            particle = SKShapeNode(path: path)
        } else if isStar {
            // 4-uddad stjärna
            let size = CGFloat.random(in: 6...16)
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: size))
            path.addLine(to: CGPoint(x: size * 0.2, y: size * 0.2))
            path.addLine(to: CGPoint(x: size, y: 0))
            path.addLine(to: CGPoint(x: size * 0.2, y: -size * 0.2))
            path.addLine(to: CGPoint(x: 0, y: -size))
            path.addLine(to: CGPoint(x: -size * 0.2, y: -size * 0.2))
            path.addLine(to: CGPoint(x: -size, y: 0))
            path.addLine(to: CGPoint(x: -size * 0.2, y: size * 0.2))
            path.closeSubpath()
            particle = SKShapeNode(path: path)
        } else {
            particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 4...12))
        }

        if isLarge {
            // Sparkles: ljusare, mer magiska färger
            switch Int.random(in: 0...2) {
            case 0: particle.fillColor = .white
            case 1: particle.fillColor = SKColor(red: 1.0, green: 1.0, blue: 0.9, alpha: 1.0)
            default: particle.fillColor = SKColor(red: 0.95, green: 0.98, blue: 1.0, alpha: 1.0)
            }
            particle.glowWidth = 6.0
        } else {
            switch Int.random(in: 0...3) {
            case 0: particle.fillColor = SKColor(red: 1.0, green: 0.95, blue: 0.6, alpha: 1.0)
            case 1: particle.fillColor = .white
            case 2: particle.fillColor = SKColor(red: 1.0, green: 0.85, blue: 0.4, alpha: 1.0)
            default: particle.fillColor = SKColor(red: 0.95, green: 1.0, blue: 0.85, alpha: 1.0)
            }
            particle.glowWidth = isStar ? 4.0 : 2.0
        }
        particle.strokeColor = .clear
        particle.blendMode = .add

        // Startposition — spritt runt hovarna
        let startAngle = CGFloat.random(in: 0...(.pi * 2))
        let startRadius = CGFloat.random(in: 20...spread * 0.4)
        particle.position = CGPoint(x: cos(startAngle) * startRadius, y: sin(startAngle) * startRadius)
        particle.alpha = 0
        particle.setScale(particleScale)
        container.addChild(particle)

        // Virvlar utåt i en båge
        let life = TimeInterval.random(in: lifeRange)
        let endAngle = startAngle + CGFloat.random(in: 0.8...2.5) * (Bool.random() ? 1 : -1)
        let endRadius = CGFloat.random(in: spread * 0.3...spread)
        let endPos = CGPoint(x: cos(endAngle) * endRadius, y: sin(endAngle) * endRadius)
        let peakAlpha = CGFloat.random(in: 0.4...0.9)

        particle.run(SKAction.sequence([
            SKAction.fadeAlpha(to: peakAlpha, duration: life * 0.15),
            SKAction.group([
                SKAction.move(to: endPos, duration: life * 0.7),
                SKAction.rotate(byAngle: CGFloat.random(in: 2...6), duration: life * 0.7),
                SKAction.scale(to: CGFloat.random(in: 0.3...1.5), duration: life * 0.7),
            ]),
            SKAction.fadeOut(withDuration: life * 0.15),
            SKAction.removeFromParent()
        ]))
    }

    /// Blinkande disco-partikel — dubbelblinksar innan den fadar ut i rummet
    private static func spawnBlinkingDiscoParticle(in container: SKNode, spread: CGFloat,
                                                     life lifeRange: ClosedRange<TimeInterval>,
                                                     scale scaleRange: ClosedRange<CGFloat>) {
        let rawScale = CGFloat.random(in: scaleRange)
        let isLarge = rawScale > 2.5
        let particleScale = isLarge ? rawScale * 0.5 : rawScale * 0.7
        let isStar = isLarge || Int.random(in: 0...2) == 0

        let particle: SKShapeNode
        if isLarge {
            let size = CGFloat.random(in: 10...22)
            let path = CGMutablePath()
            for j in 0..<12 {
                let angle = CGFloat(j) * .pi / 6 - .pi / 2
                let r: CGFloat = (j % 2 == 0) ? size : size * 0.12
                let p = CGPoint(x: cos(angle) * r, y: sin(angle) * r)
                if j == 0 { path.move(to: p) } else { path.addLine(to: p) }
            }
            path.closeSubpath()
            particle = SKShapeNode(path: path)
            particle.fillColor = .white
            particle.glowWidth = 6.0
        } else if isStar {
            let size = CGFloat.random(in: 6...16)
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: size))
            path.addLine(to: CGPoint(x: size * 0.2, y: size * 0.2))
            path.addLine(to: CGPoint(x: size, y: 0))
            path.addLine(to: CGPoint(x: size * 0.2, y: -size * 0.2))
            path.addLine(to: CGPoint(x: 0, y: -size))
            path.addLine(to: CGPoint(x: -size * 0.2, y: -size * 0.2))
            path.addLine(to: CGPoint(x: -size, y: 0))
            path.addLine(to: CGPoint(x: -size * 0.2, y: size * 0.2))
            path.closeSubpath()
            particle = SKShapeNode(path: path)
            particle.fillColor = SKColor(red: 1.0, green: 0.95, blue: 0.6, alpha: 1.0)
            particle.glowWidth = 4.0
        } else {
            particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 4...12))
            particle.fillColor = SKColor(red: 1.0, green: 0.85, blue: 0.4, alpha: 1.0)
            particle.glowWidth = 2.0
        }
        particle.strokeColor = .clear
        particle.blendMode = .add

        let startAngle = CGFloat.random(in: 0...(.pi * 2))
        let startRadius = CGFloat.random(in: 20...spread * 0.3)
        particle.position = CGPoint(x: cos(startAngle) * startRadius, y: sin(startAngle) * startRadius)
        particle.alpha = 0
        particle.setScale(particleScale)
        container.addChild(particle)

        let life = TimeInterval.random(in: lifeRange)
        let endAngle = startAngle + CGFloat.random(in: 0.8...2.5) * (Bool.random() ? 1 : -1)
        let endRadius = CGFloat.random(in: spread * 0.4...spread)
        let endPos = CGPoint(x: cos(endAngle) * endRadius, y: sin(endAngle) * endRadius)
        let peakAlpha = CGFloat.random(in: 0.5...1.0)

        // Magiska blinkar — slumpmässigt antal och rytm
        let blinkCount = Int.random(in: 4...8)
        var blinkActions: [SKAction] = []
        for _ in 0..<blinkCount {
            let speed = TimeInterval.random(in: 0.04...0.12)
            let dimTo = peakAlpha * CGFloat.random(in: 0.0...0.15)
            blinkActions.append(SKAction.fadeAlpha(to: dimTo, duration: speed))
            blinkActions.append(SKAction.fadeAlpha(to: peakAlpha, duration: speed * CGFloat.random(in: 0.6...1.2)))
            // Slumpmässig paus — ibland snabbt, ibland med andrum
            if Bool.random() {
                blinkActions.append(SKAction.wait(forDuration: TimeInterval.random(in: 0.02...0.15)))
            }
        }
        let blinks = SKAction.sequence(blinkActions)

        // Fortsätt blinka under resan också
        let travelBlinkCount = Int.random(in: 2...5)
        var travelBlinks: [SKAction] = []
        for _ in 0..<travelBlinkCount {
            let speed = TimeInterval.random(in: 0.05...0.15)
            travelBlinks.append(SKAction.wait(forDuration: TimeInterval.random(in: 0.1...0.3)))
            travelBlinks.append(SKAction.fadeAlpha(to: peakAlpha * CGFloat.random(in: 0.0...0.1), duration: speed))
            travelBlinks.append(SKAction.fadeAlpha(to: peakAlpha * CGFloat.random(in: 0.5...1.0), duration: speed))
        }

        particle.run(SKAction.sequence([
            SKAction.fadeAlpha(to: peakAlpha, duration: life * 0.08),
            blinks,
            SKAction.group([
                SKAction.move(to: endPos, duration: life * 0.6),
                SKAction.rotate(byAngle: CGFloat.random(in: 2...6), duration: life * 0.6),
                SKAction.scale(to: CGFloat.random(in: 0.2...1.0), duration: life * 0.6),
                SKAction.sequence(travelBlinks),
            ]),
            SKAction.fadeOut(withDuration: life * 0.2),
            SKAction.removeFromParent()
        ]))
    }

    /// Blinkning synkad med stepp-fasens hovnedslag
    private func steppGlitterBlink() {
        guard let deer = deerNode else { return }
        let beat: TimeInterval = 0.22

        // Blink vid varje bounce-landning: 4 vanliga + 4 stora
        var blinkActions: [SKAction] = []
        for i in 0..<8 {
            let isLarge = i >= 4
            blinkActions.append(SKAction.wait(forDuration: beat * 0.75))
            blinkActions.append(SKAction.run { [weak deer, weak self] in
                guard let deer, let self else { return }
                for j in 0..<self.hoofPositions.count {
                    deer.childNode(withName: "hoofStorm\(j)")?.enumerateChildNodes(withName: "*") { particle, _ in
                        // Fler blinkar vid bigBounce
                        let chance: Int = isLarge ? 80 : 50
                        guard Int.random(in: 0..<100) < chance else { return }
                        let speed = TimeInterval.random(in: 0.03...0.06)
                        let dim = CGFloat.random(in: 0.0...0.1)
                        let bright = CGFloat.random(in: isLarge ? 0.8...1.0 : 0.6...1.0)
                        particle.run(SKAction.sequence([
                            SKAction.fadeAlpha(to: dim, duration: speed),
                            SKAction.fadeAlpha(to: bright, duration: speed * 0.7),
                            isLarge ? SKAction.sequence([
                                SKAction.fadeAlpha(to: dim, duration: speed * 0.5),
                                SKAction.fadeAlpha(to: bright, duration: speed * 0.6),
                            ]) : SKAction.wait(forDuration: 0),
                        ]), withKey: "steppBlink")
                    }
                }
            })
        }

        deer.run(SKAction.sequence(blinkActions), withKey: "steppGlitterBlink")
    }

    /// Extra blinkning på alla solkatter under moonwalk — mjukare rytm
    private func moonwalkGlitterBlink() {
        guard let deer = deerNode else { return }
        let mBeat: TimeInterval = 0.35

        // Pulserande blink i moonwalk-rytm — var mBeat
        let moonBlinkLoop = SKAction.repeat(SKAction.sequence([
            SKAction.wait(forDuration: mBeat * 0.7),
            SKAction.run { [weak deer] in
                guard let deer else { return }
                for i in 0..<self.hoofPositions.count {
                    deer.childNode(withName: "hoofStorm\(i)")?.enumerateChildNodes(withName: "*") { particle, _ in
                        guard Bool.random() else { return }  // ~50% blinkar varje gång
                        let speed = TimeInterval.random(in: 0.04...0.08)
                        particle.run(SKAction.sequence([
                            SKAction.fadeAlpha(to: CGFloat.random(in: 0.0...0.1), duration: speed),
                            SKAction.fadeAlpha(to: CGFloat.random(in: 0.6...1.0), duration: speed * 0.8),
                        ]), withKey: "moonBlink")
                    }
                }
            }
        ]), count: 12)

        deer.run(moonBlinkLoop, withKey: "moonGlitterBlink")
    }

    // MARK: - Deer Dance

    /// Hjälpfunktion: återställ alla delar till neutralposition
    private func resetDeerParts() {
        // Nollställ bengrupper till pivot-positioner (höft/axel)
        backLeg1Group?.removeAllActions()
        backLeg1Group?.position = CGPoint(x: -225, y: -16)
        backLeg1Group?.zRotation = 0

        backLeg2Group?.removeAllActions()
        backLeg2Group?.position = CGPoint(x: -159, y: -211)
        backLeg2Group?.zRotation = 0

        frontLeg1Group?.removeAllActions()
        frontLeg1Group?.position = CGPoint(x: 126, y: -85)
        frontLeg1Group?.zRotation = 0

        frontLeg2Group?.removeAllActions()
        frontLeg2Group?.position = CGPoint(x: 368, y: -181)
        frontLeg2Group?.zRotation = 0

        // Nollställ kropp (position 0,0)
        deerBody?.removeAllActions()
        deerBody?.position = .zero
        deerBody?.zRotation = 0

        // Nollställ huvud (anchorPoint vid nacken)
        deerHead?.removeAllActions()
        deerHead?.texture = SKTexture(imageNamed: "deer1_head")
        deerHead?.position = CGPoint(x: 283, y: 172)
        deerHead?.zRotation = 0

        // Svans: pivot vid roten (nedersta pixeln)
        deerTail?.removeAllActions()
        deerTail?.position = CGPoint(x: -269, y: 110)
        deerTail?.zRotation = 0

        // Överben: anchorPoint vid höft/axel, position (0,0) i gruppen
        let upperLegs: [SKSpriteNode?] = [deerBackLeg1Up, deerBackLeg2Up, deerFrontLeg1Up, deerFrontLeg2Up]
        for leg in upperLegs {
            leg?.removeAllActions()
            leg?.position = .zero
            leg?.zRotation = 0
        }

        // Underben: sitter fast vid överbenet, knäposition relativt höft/axel
        deerBackLeg1Down?.removeAllActions()
        deerBackLeg1Down?.position = CGPoint(x: -130, y: -410)
        deerBackLeg1Down?.zRotation = 0

        deerBackLeg2Down?.removeAllActions()
        deerBackLeg2Down?.position = CGPoint(x: -6, y: -195)
        deerBackLeg2Down?.zRotation = 0

        deerFrontLeg1Down?.removeAllActions()
        deerFrontLeg1Down?.position = CGPoint(x: 13, y: -443)
        deerFrontLeg1Down?.zRotation = 0

        deerFrontLeg2Down?.removeAllActions()
        deerFrontLeg2Down?.position = CGPoint(x: 1, y: -306)
        deerFrontLeg2Down?.zRotation = 0
    }

    private func startDeerDance() {
        guard !isDeerDancing,
              let deer = deerNode,
              let head = deerHead, let body = deerBody, let tail = deerTail,
              let fl1Down = deerFrontLeg1Down,
              let fl2Down = deerFrontLeg2Down,
              let bl1Down = deerBackLeg1Down,
              let bl2Down = deerBackLeg2Down,
              let fl1Grp = frontLeg1Group, let fl2Grp = frontLeg2Group,
              let bl1Grp = backLeg1Group, let bl2Grp = backLeg2Group
        else { return }

        isDeerDancing = true

        // Göm alla andra objekt under dansen
        hatNode.run(SKAction.fadeOut(withDuration: 0.4))
        toolboxNode.fadeAway()
        if let gokur = childNode(withName: "gokur") {
            gokur.run(SKAction.fadeOut(withDuration: 0.4))
        }

        // Maskrosor sparade till annat rum:
        // deer.removeAction(forKey: "teaserMaskros")
        // blowAwayMaskros()
        // startMaskrosStorm(on: deer)

        // Disco-glitter exploderar vid hovarna under dansen
        startDanceGlitterStorm(on: deer)

        // Stoppa idle-animationer och glow
        deer.removeAction(forKey: "deerBreathe")
        deerGlow?.removeAllActions()
        deerGlow?.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))
        deerGlow = nil

        let baseScale: CGFloat = 0.84
        let startPos = deer.position

        // ═══════════════════════════════════════════════════════════════════
        // KOMBINERAD DANS — stepp, moonwalk, stegring i en sekvens!
        //
        // Fasordningen varierar slumpmässigt. Containern driver timing.
        // Varje fas startas via SKAction.run, allt nollställs mellan faser.
        //
        // Fas S:  Stepp + sprätter (8 beats à 0.22s = 1.76s)
        // Fas M:  Moonwalk fram+tillbaka (12 mBeats à 0.35s = 4.2s)
        // Fas R:  Stegring (7 beats à 0.22s = 1.54s)
        // Fas J:  Skutt + landning (~2s)
        // ═══════════════════════════════════════════════════════════════════

        let beat: TimeInterval = 0.22
        let mBeat: TimeInterval = 0.35

        // Blink-texturer för danssekvensen
        let normalTex = SKTexture(imageNamed: "deer1_head")
        let blinkTex = SKTexture(imageNamed: "deer1_head_blink")
        func quickBlink() -> SKAction {
            SKAction.sequence([
                SKAction.setTexture(blinkTex, resize: false),
                SKAction.wait(forDuration: 0.1),
                SKAction.setTexture(normalTex, resize: false),
            ])
        }
        let deg15: CGFloat = 0.26
        let deg30: CGFloat = 0.52
        let deg45: CGFloat = 0.79
        let moonSlidePerStep: CGFloat = 35
        let moonSteps = 6
        let moonTotal = moonSlidePerStep * CGFloat(moonSteps)

        // Slumpmässig ordning av de två första faserna
        let moonFirst = Bool.random()

        // ═══════════════════════════════════════════
        // Fas-funktioner — startar alla noder parallellt
        // ═══════════════════════════════════════════

        // --- FAS S: STEPP + SPRÄTTER (8 beats) ---
        func startSteppPhase() {
            func rest() -> SKAction { SKAction.wait(forDuration: beat) }
            // Tydlig bakåt-pendel för alla ben (testvärden — stor vinkel)
            func legKickBack() -> SKAction {
                SKAction.sequence([
                    SKAction.rotate(toAngle: -0.20, duration: beat * 0.3),
                    SKAction.rotate(toAngle: 0, duration: beat * 0.5),
                    SKAction.wait(forDuration: beat * 0.2)
                ])
            }
            func knäböj() -> SKAction {
                SKAction.sequence([
                    SKAction.rotate(toAngle: -deg15, duration: beat * 0.25),
                    SKAction.rotate(toAngle: 0, duration: beat * 0.35),
                    SKAction.wait(forDuration: beat * 0.4)
                ])
            }
            func sprätt() -> SKAction {
                SKAction.sequence([
                    SKAction.rotate(toAngle: -deg30, duration: beat * 0.15),
                    SKAction.rotate(toAngle: -deg45, duration: beat * 0.15),
                    SKAction.rotate(toAngle: 0, duration: beat * 0.35),             // aldrig framåt!
                    SKAction.rotate(toAngle: 0, duration: beat * 0.15),
                    SKAction.wait(forDuration: beat * 0.2)
                ])
            }
            func bounce() -> SKAction {
                SKAction.sequence([
                    SKAction.moveBy(x: 0, y: 18, duration: beat * 0.25),
                    SKAction.moveBy(x: 0, y: -18, duration: beat * 0.55),
                    SKAction.wait(forDuration: beat * 0.2)
                ])
            }
            func bigBounce() -> SKAction {
                SKAction.sequence([
                    SKAction.moveBy(x: 0, y: 25, duration: beat * 0.25),
                    SKAction.moveBy(x: 0, y: -25, duration: beat * 0.55),
                    SKAction.wait(forDuration: beat * 0.2)
                ])
            }
            func headNod() -> SKAction {
                SKAction.sequence([
                    SKAction.moveBy(x: 5, y: 8, duration: beat * 0.25),
                    SKAction.moveBy(x: -5, y: -8, duration: beat * 0.55),
                    SKAction.wait(forDuration: beat * 0.2)
                ])
            }
            // Svans: pendel-viftning (roterar kring fästpunkten)
            func tailWag() -> SKAction {
                SKAction.sequence([
                    SKAction.rotate(toAngle: 0.06, duration: beat * 0.25),
                    SKAction.rotate(toAngle: 0, duration: beat * 0.55),
                    SKAction.wait(forDuration: beat * 0.2)
                ])
            }

            // Container: 4 bounce + 4 bigBounce
            deer.run(SKAction.sequence([
                bounce(), bounce(), bounce(), bounce(),
                bigBounce(), bigBounce(), bigBounce(), bigBounce()
            ]), withKey: "deerPhase")

            // Alla ben kickar bakåt — tydlig pendel från höft/axel
            fl1Grp.run(SKAction.sequence([
                legKickBack(), rest(), legKickBack(), rest(),
                legKickBack(), rest(), legKickBack(), rest()
            ]), withKey: "fl1Phase")
            fl2Grp.run(SKAction.sequence([
                rest(), legKickBack(), rest(), legKickBack(),
                rest(), legKickBack(), rest(), legKickBack()
            ]), withKey: "fl2Phase")
            bl1Grp.run(SKAction.sequence([
                rest(), legKickBack(), rest(), legKickBack(),
                rest(), legKickBack(), rest(), legKickBack()
            ]), withKey: "bl1Phase")
            bl2Grp.run(SKAction.sequence([
                legKickBack(), rest(), legKickBack(), rest(),
                legKickBack(), rest(), legKickBack(), rest()
            ]), withKey: "bl2Phase")

            // Underben: 4 knäböj + 4 sprätt
            fl1Down.run(SKAction.sequence([
                knäböj(), rest(), knäböj(), rest(),
                sprätt(), rest(), sprätt(), rest()
            ]), withKey: "fl1dPhase")
            fl2Down.run(SKAction.sequence([
                rest(), knäböj(), rest(), knäböj(),
                rest(), sprätt(), rest(), sprätt()
            ]), withKey: "fl2dPhase")
            bl1Down.run(SKAction.sequence([
                rest(), knäböj(), rest(), knäböj(),
                rest(), sprätt(), rest(), sprätt()
            ]), withKey: "bl1dPhase")
            bl2Down.run(SKAction.sequence([
                knäböj(), rest(), knäböj(), rest(),
                sprätt(), rest(), sprätt(), rest()
            ]), withKey: "bl2dPhase")

            // Huvud + svans
            head.run(SKAction.sequence([
                headNod(), headNod(), headNod(), headNod(),
                headNod(), headNod(), headNod(), headNod()
            ]), withKey: "headPhase")
            // Blink på beat 3 och 7 (synkat med bounce)
            head.run(SKAction.sequence([
                SKAction.wait(forDuration: beat * 2), quickBlink(),
                SKAction.wait(forDuration: beat * 4), quickBlink(),
            ]), withKey: "blinkPhase")
            tail.run(SKAction.sequence([
                tailWag(), tailWag(), tailWag(), tailWag(),
                tailWag(), tailWag(), tailWag(), tailWag()
            ]), withKey: "tailPhase")
        }

        // --- FAS M: MOONWALK (12 mBeats) ---
        func startMoonwalkPhase() {
            // Pendelrörelse för bengrupper vid moonwalk
            func mPendulumFwd() -> SKAction {
                SKAction.sequence([
                    SKAction.rotate(toAngle: 0.10, duration: mBeat * 0.45),
                    SKAction.rotate(toAngle: 0, duration: mBeat * 0.35),
                    SKAction.wait(forDuration: mBeat * 0.2)
                ])
            }
            func mPendulumBack() -> SKAction {
                SKAction.sequence([
                    SKAction.rotate(toAngle: -0.10, duration: mBeat * 0.45),
                    SKAction.rotate(toAngle: 0, duration: mBeat * 0.35),
                    SKAction.wait(forDuration: mBeat * 0.2)
                ])
            }
            func mSlide() -> SKAction { SKAction.wait(forDuration: mBeat) }
            func toeSnap() -> SKAction {
                SKAction.sequence([
                    SKAction.rotate(toAngle: -deg15, duration: mBeat * 0.10),
                    SKAction.wait(forDuration: mBeat * 0.55),
                    SKAction.rotate(toAngle: 0, duration: mBeat * 0.20),
                    SKAction.wait(forDuration: mBeat * 0.15)
                ])
            }
            func toeFlat() -> SKAction { SKAction.wait(forDuration: mBeat) }
            func headBob() -> SKAction {
                SKAction.sequence([
                    SKAction.moveBy(x: 0, y: 5, duration: mBeat * 0.3),
                    SKAction.moveBy(x: 0, y: -5, duration: mBeat * 0.5),
                    SKAction.wait(forDuration: mBeat * 0.2)
                ])
            }

            // Container: glid vänster + höger
            let glideL = SKAction.moveBy(x: -moonTotal, y: 0, duration: mBeat * Double(moonSteps))
            glideL.timingMode = .linear
            let glideR = SKAction.moveBy(x: moonTotal, y: 0, duration: mBeat * Double(moonSteps))
            glideR.timingMode = .linear
            deer.run(SKAction.sequence([glideL, glideR]), withKey: "deerPhase")

            // Par A (fl1+bl2): pendel, slide, pendel, slide...
            fl1Grp.run(SKAction.sequence([
                mPendulumFwd(), mSlide(), mPendulumFwd(), mSlide(), mPendulumFwd(), mSlide(),
                mPendulumBack(), mSlide(), mPendulumBack(), mSlide(), mPendulumBack(), mSlide()
            ]), withKey: "fl1Phase")
            bl2Grp.run(SKAction.sequence([
                mPendulumBack(), mSlide(), mPendulumBack(), mSlide(), mPendulumBack(), mSlide(),
                mPendulumFwd(), mSlide(), mPendulumFwd(), mSlide(), mPendulumFwd(), mSlide()
            ]), withKey: "bl2Phase")
            fl1Down.run(SKAction.sequence([
                toeSnap(), toeFlat(), toeSnap(), toeFlat(), toeSnap(), toeFlat(),
                toeSnap(), toeFlat(), toeSnap(), toeFlat(), toeSnap(), toeFlat()
            ]), withKey: "fl1dPhase")
            // bl2 underben: försiktig liten spark bakåt under moonwalk
            func gentleKick() -> SKAction {
                SKAction.sequence([
                    SKAction.rotate(toAngle: -deg15 * 0.6, duration: mBeat * 0.15),
                    SKAction.rotate(toAngle: -deg15, duration: mBeat * 0.15),
                    SKAction.rotate(toAngle: 0, duration: mBeat * 0.50),
                    SKAction.wait(forDuration: mBeat * 0.20)
                ])
            }
            bl2Down.run(SKAction.sequence([
                gentleKick(), toeFlat(), gentleKick(), toeFlat(), gentleKick(), toeFlat(),
                gentleKick(), toeFlat(), gentleKick(), toeFlat(), gentleKick(), toeFlat()
            ]), withKey: "bl2dPhase")

            // Par B (fl2+bl1): slide, pendel, slide, pendel...
            fl2Grp.run(SKAction.sequence([
                mSlide(), mPendulumFwd(), mSlide(), mPendulumFwd(), mSlide(), mPendulumFwd(),
                mSlide(), mPendulumBack(), mSlide(), mPendulumBack(), mSlide(), mPendulumBack()
            ]), withKey: "fl2Phase")
            bl1Grp.run(SKAction.sequence([
                mSlide(), mPendulumBack(), mSlide(), mPendulumBack(), mSlide(), mPendulumBack(),
                mSlide(), mPendulumFwd(), mSlide(), mPendulumFwd(), mSlide(), mPendulumFwd()
            ]), withKey: "bl1Phase")
            // fl2 underben: försiktig liten spark under moonwalk
            func gentleKickFl2() -> SKAction {
                SKAction.sequence([
                    SKAction.rotate(toAngle: -deg15 * 0.5, duration: mBeat * 0.15),
                    SKAction.rotate(toAngle: -deg15 * 0.8, duration: mBeat * 0.15),
                    SKAction.rotate(toAngle: 0, duration: mBeat * 0.50),
                    SKAction.wait(forDuration: mBeat * 0.20)
                ])
            }
            fl2Down.run(SKAction.sequence([
                toeFlat(), gentleKickFl2(), toeFlat(), gentleKickFl2(), toeFlat(), gentleKickFl2(),
                toeFlat(), gentleKickFl2(), toeFlat(), gentleKickFl2(), toeFlat(), gentleKickFl2()
            ]), withKey: "fl2dPhase")
            bl1Down.run(SKAction.sequence([
                toeFlat(), toeSnap(), toeFlat(), toeSnap(), toeFlat(), toeSnap(),
                toeFlat(), toeSnap(), toeFlat(), toeSnap(), toeFlat(), toeSnap()
            ]), withKey: "bl1dPhase")

            // Huvud: mjuk cirkelrörelse
            let circleR: CGFloat = 12
            let circleDur: TimeInterval = mBeat * 2
            // En cirkel: höger → upp → vänster → ner
            func headCircle() -> SKAction {
                let q = circleDur / 4
                let r = SKAction.moveBy(x: circleR, y: 0, duration: q)
                r.timingMode = .easeInEaseOut
                let u = SKAction.moveBy(x: 0, y: circleR, duration: q)
                u.timingMode = .easeInEaseOut
                let l = SKAction.moveBy(x: -circleR, y: 0, duration: q)
                l.timingMode = .easeInEaseOut
                let d = SKAction.moveBy(x: 0, y: -circleR, duration: q)
                d.timingMode = .easeInEaseOut
                return SKAction.sequence([r, u, l, d])
            }
            head.run(SKAction.sequence([
                headCircle(), headCircle(), headCircle(),
                headCircle(), headCircle(), headCircle()
            ]), withKey: "headPhase")
            // Blink mitt i varje riktningsbyte
            head.run(SKAction.sequence([
                SKAction.wait(forDuration: mBeat * 3), quickBlink(),
                SKAction.wait(forDuration: mBeat * 5), quickBlink(),
            ]), withKey: "blinkPhase")

            // Kropp: lätt lean
            body.run(SKAction.sequence([
                SKAction.moveBy(x: -4, y: 3, duration: mBeat * 0.5),
                SKAction.wait(forDuration: mBeat * 11),
                SKAction.moveBy(x: 4, y: -3, duration: mBeat * 0.5)
            ]), withKey: "bodyPhase")

            // Svans: pendelvaggning (roterar kring fästpunkten)
            tail.run(SKAction.sequence([
                SKAction.repeat(SKAction.sequence([
                    SKAction.rotate(toAngle: -0.08, duration: mBeat),
                    SKAction.rotate(toAngle: 0.08, duration: mBeat)
                ]), count: 3),
                SKAction.repeat(SKAction.sequence([
                    SKAction.rotate(toAngle: 0.08, duration: mBeat),
                    SKAction.rotate(toAngle: -0.08, duration: mBeat)
                ]), count: 3)
            ]), withKey: "tailPhase")
        }

        // --- FAS R: STEGRING (7 beats) ---
        func startRearingPhase() {
            func rest() -> SKAction { SKAction.wait(forDuration: beat) }
            func kratsRot() -> SKAction {
                SKAction.sequence([
                    SKAction.rotate(toAngle: 0, duration: beat * 0.15),              // aldrig framåt!
                    SKAction.rotate(toAngle: -deg30, duration: beat * 0.2),
                    SKAction.rotate(toAngle: 0, duration: beat * 0.15),              // aldrig framåt!
                    SKAction.rotate(toAngle: -deg30, duration: beat * 0.2),
                    SKAction.rotate(toAngle: 0, duration: beat * 0.3)
                ])
            }

            // Container: stegring + gungar + ner
            deer.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: -35, y: 55, duration: beat * 1.5),
                    SKAction.rotate(toAngle: 0.22, duration: beat * 1.5)
                ]),
                SKAction.wait(forDuration: beat * 0.5),
                SKAction.sequence([SKAction.moveBy(x: 0, y: -6, duration: beat * 0.35), SKAction.moveBy(x: 0, y: 6, duration: beat * 0.65)]),
                SKAction.sequence([SKAction.moveBy(x: 2, y: -6, duration: beat * 0.35), SKAction.moveBy(x: -2, y: 6, duration: beat * 0.65)]),
                SKAction.sequence([SKAction.moveBy(x: -2, y: -6, duration: beat * 0.35), SKAction.moveBy(x: 2, y: 6, duration: beat * 0.65)]),
                SKAction.sequence([SKAction.moveBy(x: 0, y: -6, duration: beat * 0.35), SKAction.moveBy(x: 0, y: 6, duration: beat * 0.65)]),
                SKAction.group([
                    SKAction.moveBy(x: 35, y: -70, duration: beat),
                    SKAction.rotate(toAngle: 0, duration: beat)
                ])
            ]), withKey: "deerPhase")

            // Framben: pendlar uppåt (framåt) + krats
            func kratsSwing() -> SKAction {
                SKAction.sequence([
                    SKAction.rotate(toAngle: 0.18, duration: beat * 0.5),
                    SKAction.rotate(toAngle: 0.25, duration: beat * 0.5)
                ])
            }
            // Motfas-krats: stora sparkar!
            func kratsSwingHigh() -> SKAction {
                SKAction.sequence([
                    SKAction.rotate(toAngle: 0.50, duration: beat * 0.5),
                    SKAction.rotate(toAngle: 0.25, duration: beat * 0.5)
                ])
            }
            func kratsSwingLow() -> SKAction {
                SKAction.sequence([
                    SKAction.rotate(toAngle: 0.10, duration: beat * 0.5),
                    SKAction.rotate(toAngle: 0.40, duration: beat * 0.5)
                ])
            }
            fl1Grp.run(SKAction.sequence([
                SKAction.rotate(toAngle: 0.45, duration: beat * 1.5),
                SKAction.wait(forDuration: beat * 0.5),
                kratsSwingHigh(), kratsSwingLow(), kratsSwingHigh(), kratsSwingLow(),
                SKAction.rotate(toAngle: 0, duration: beat * 0.5),
                SKAction.wait(forDuration: beat * 0.5)
            ]), withKey: "fl1Phase")
            fl2Grp.run(SKAction.sequence([
                SKAction.rotate(toAngle: 0.40, duration: beat * 1.5),
                SKAction.wait(forDuration: beat * 0.5),
                kratsSwingLow(), kratsSwingHigh(), kratsSwingLow(), kratsSwingHigh(),
                SKAction.rotate(toAngle: 0, duration: beat * 0.5),
                SKAction.wait(forDuration: beat * 0.5)
            ]), withKey: "fl2Phase")

            // Framben underben: stora sparkar i motfas
            let deg45 = CGFloat.pi / 4
            func kratsRotHard() -> SKAction {
                SKAction.sequence([
                    SKAction.rotate(toAngle: 0, duration: beat * 0.12),
                    SKAction.rotate(toAngle: -deg45, duration: beat * 0.18),
                    SKAction.rotate(toAngle: -deg15, duration: beat * 0.12),
                    SKAction.rotate(toAngle: -deg45, duration: beat * 0.18),
                    SKAction.rotate(toAngle: 0, duration: beat * 0.4)
                ])
            }
            func kratsRotSoft() -> SKAction {
                SKAction.sequence([
                    SKAction.rotate(toAngle: 0, duration: beat * 0.2),
                    SKAction.rotate(toAngle: -deg30, duration: beat * 0.3),
                    SKAction.rotate(toAngle: 0, duration: beat * 0.5)
                ])
            }
            fl1Down.run(SKAction.sequence([
                SKAction.rotate(toAngle: -deg15, duration: beat * 1.5),
                SKAction.wait(forDuration: beat * 0.5),
                kratsRotHard(), kratsRotSoft(), kratsRotHard(), kratsRotSoft(),
                SKAction.rotate(toAngle: 0, duration: beat * 0.5),
                SKAction.wait(forDuration: beat * 0.5)
            ]), withKey: "fl1dPhase")
            fl2Down.run(SKAction.sequence([
                SKAction.rotate(toAngle: -deg15, duration: beat * 1.5),
                SKAction.wait(forDuration: beat * 0.5),
                kratsRotSoft(), kratsRotHard(), kratsRotSoft(), kratsRotHard(),
                SKAction.rotate(toAngle: 0, duration: beat * 0.5),
                SKAction.wait(forDuration: beat * 0.5)
            ]), withKey: "fl2dPhase")

            // Bakben: planterade — motrotation från höften
            let backLegCounter: [SKAction] = [
                SKAction.rotate(toAngle: -0.22, duration: beat * 1.5),
                SKAction.wait(forDuration: beat * 0.5),
                SKAction.sequence([SKAction.rotate(toAngle: -0.20, duration: beat * 0.35), SKAction.rotate(toAngle: -0.22, duration: beat * 0.65)]),
                SKAction.sequence([SKAction.rotate(toAngle: -0.24, duration: beat * 0.35), SKAction.rotate(toAngle: -0.22, duration: beat * 0.65)]),
                SKAction.sequence([SKAction.rotate(toAngle: -0.20, duration: beat * 0.35), SKAction.rotate(toAngle: -0.22, duration: beat * 0.65)]),
                SKAction.sequence([SKAction.rotate(toAngle: -0.24, duration: beat * 0.35), SKAction.rotate(toAngle: -0.22, duration: beat * 0.65)]),
                SKAction.rotate(toAngle: 0, duration: beat)
            ]
            bl1Grp.run(SKAction.sequence(backLegCounter), withKey: "bl1Phase")
            bl2Grp.run(SKAction.sequence(backLegCounter), withKey: "bl2Phase")
            bl1Down.run(SKAction.sequence([SKAction.wait(forDuration: beat * 7)]), withKey: "bl1dPhase")
            bl2Down.run(SKAction.sequence([SKAction.wait(forDuration: beat * 7)]), withKey: "bl2dPhase")

            // Huvud: följer med kroppen — bara en tom wait så fasen har rätt längd
            head.run(SKAction.sequence([
                SKAction.wait(forDuration: beat * 7)
            ]), withKey: "headPhase")
            // Blink vid toppen av stegringen
            head.run(SKAction.sequence([
                SKAction.wait(forDuration: beat * 2.5), quickBlink(),
                SKAction.wait(forDuration: beat * 2), quickBlink(),
            ]), withKey: "blinkPhase")

            // Svans: lyfts uppåt (pendlar kring fästpunkten)
            tail.run(SKAction.sequence([
                SKAction.rotate(toAngle: 0.20, duration: beat * 1.5),
                SKAction.wait(forDuration: beat * 0.5),
                SKAction.sequence([SKAction.rotate(toAngle: 0.28, duration: beat * 0.35), SKAction.rotate(toAngle: 0.20, duration: beat * 0.65)]),
                SKAction.sequence([SKAction.rotate(toAngle: 0.14, duration: beat * 0.35), SKAction.rotate(toAngle: 0.20, duration: beat * 0.65)]),
                SKAction.sequence([SKAction.rotate(toAngle: 0.28, duration: beat * 0.35), SKAction.rotate(toAngle: 0.20, duration: beat * 0.65)]),
                SKAction.sequence([SKAction.rotate(toAngle: 0.14, duration: beat * 0.35), SKAction.rotate(toAngle: 0.20, duration: beat * 0.65)]),
                SKAction.rotate(toAngle: 0, duration: beat * 0.5),
                SKAction.wait(forDuration: beat * 0.5)
            ]), withKey: "tailPhase")
        }

        // --- FAS R2: STOR GLAD STEGRING (9 beats) ---
        func startBigRearingPhase() {
            func rest() -> SKAction { SKAction.wait(forDuration: beat) }
            func kratsRot() -> SKAction {
                SKAction.sequence([
                    SKAction.rotate(toAngle: 0, duration: beat * 0.15),
                    SKAction.rotate(toAngle: -deg30, duration: beat * 0.2),
                    SKAction.rotate(toAngle: 0, duration: beat * 0.15),
                    SKAction.rotate(toAngle: -deg30, duration: beat * 0.2),
                    SKAction.rotate(toAngle: 0, duration: beat * 0.3)
                ])
            }
            func kratsSwing() -> SKAction {
                SKAction.sequence([
                    SKAction.rotate(toAngle: 0.22, duration: beat * 0.5),
                    SKAction.rotate(toAngle: 0.35, duration: beat * 0.5)
                ])
            }

            // Container: högre stegring + fler glada gungar + ner
            deer.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: -45, y: 85, duration: beat * 1.5),
                    SKAction.rotate(toAngle: 0.30, duration: beat * 1.5)
                ]),
                SKAction.wait(forDuration: beat * 0.5),
                // 5 glada gungar (mer energi)
                SKAction.sequence([SKAction.moveBy(x: 0, y: -8, duration: beat * 0.3), SKAction.moveBy(x: 0, y: 8, duration: beat * 0.7)]),
                SKAction.sequence([SKAction.moveBy(x: 3, y: -10, duration: beat * 0.3), SKAction.moveBy(x: -3, y: 10, duration: beat * 0.7)]),
                SKAction.sequence([SKAction.moveBy(x: -3, y: -8, duration: beat * 0.3), SKAction.moveBy(x: 3, y: 8, duration: beat * 0.7)]),
                SKAction.sequence([SKAction.moveBy(x: 3, y: -10, duration: beat * 0.3), SKAction.moveBy(x: -3, y: 10, duration: beat * 0.7)]),
                SKAction.sequence([SKAction.moveBy(x: 0, y: -8, duration: beat * 0.3), SKAction.moveBy(x: 0, y: 8, duration: beat * 0.7)]),
                SKAction.group([
                    SKAction.moveBy(x: 45, y: -100, duration: beat),
                    SKAction.rotate(toAngle: 0, duration: beat)
                ])
            ]), withKey: "deerPhase")

            // Framben: högre lyft + ivriga krats i motfas
            func bigKratsHigh() -> SKAction {
                SKAction.sequence([
                    SKAction.rotate(toAngle: 0.40, duration: beat * 0.5),
                    SKAction.rotate(toAngle: 0.25, duration: beat * 0.5)
                ])
            }
            func bigKratsLow() -> SKAction {
                SKAction.sequence([
                    SKAction.rotate(toAngle: 0.15, duration: beat * 0.5),
                    SKAction.rotate(toAngle: 0.35, duration: beat * 0.5)
                ])
            }
            fl1Grp.run(SKAction.sequence([
                SKAction.rotate(toAngle: 0.40, duration: beat * 1.5),
                SKAction.wait(forDuration: beat * 0.5),
                bigKratsHigh(), bigKratsLow(), bigKratsHigh(), bigKratsLow(), bigKratsHigh(),
                SKAction.rotate(toAngle: 0, duration: beat * 0.5),
                SKAction.wait(forDuration: beat * 0.5)
            ]), withKey: "fl1Phase")
            fl2Grp.run(SKAction.sequence([
                SKAction.rotate(toAngle: 0.35, duration: beat * 1.5),
                SKAction.wait(forDuration: beat * 0.5),
                bigKratsLow(), bigKratsHigh(), bigKratsLow(), bigKratsHigh(), bigKratsLow(),
                SKAction.rotate(toAngle: 0, duration: beat * 0.5),
                SKAction.wait(forDuration: beat * 0.5)
            ]), withKey: "fl2Phase")

            // Framben underben: ivrig krats i motfas
            fl1Down.run(SKAction.sequence([
                SKAction.rotate(toAngle: -deg15, duration: beat * 1.5),
                SKAction.wait(forDuration: beat * 0.5),
                kratsRot(), kratsRot(), kratsRot(), kratsRot(), kratsRot(),
                SKAction.rotate(toAngle: 0, duration: beat * 0.5),
                SKAction.wait(forDuration: beat * 0.5)
            ]), withKey: "fl1dPhase")
            fl2Down.run(SKAction.sequence([
                SKAction.rotate(toAngle: -deg15, duration: beat * 1.5),
                SKAction.wait(forDuration: beat * 0.5),
                SKAction.wait(forDuration: beat * 0.5),
                kratsRot(), kratsRot(), kratsRot(), kratsRot(),
                SKAction.rotate(toAngle: 0, duration: beat * 0.5)
            ]), withKey: "fl2dPhase")

            // Bakben: planterade — starkare motrotation
            let backCounter: [SKAction] = [
                SKAction.rotate(toAngle: -0.30, duration: beat * 1.5),
                SKAction.wait(forDuration: beat * 0.5),
                SKAction.sequence([SKAction.rotate(toAngle: -0.27, duration: beat * 0.3), SKAction.rotate(toAngle: -0.30, duration: beat * 0.7)]),
                SKAction.sequence([SKAction.rotate(toAngle: -0.33, duration: beat * 0.3), SKAction.rotate(toAngle: -0.30, duration: beat * 0.7)]),
                SKAction.sequence([SKAction.rotate(toAngle: -0.27, duration: beat * 0.3), SKAction.rotate(toAngle: -0.30, duration: beat * 0.7)]),
                SKAction.sequence([SKAction.rotate(toAngle: -0.33, duration: beat * 0.3), SKAction.rotate(toAngle: -0.30, duration: beat * 0.7)]),
                SKAction.sequence([SKAction.rotate(toAngle: -0.27, duration: beat * 0.3), SKAction.rotate(toAngle: -0.30, duration: beat * 0.7)]),
                SKAction.rotate(toAngle: 0, duration: beat)
            ]
            bl1Grp.run(SKAction.sequence(backCounter), withKey: "bl1Phase")
            bl2Grp.run(SKAction.sequence(backCounter), withKey: "bl2Phase")
            bl1Down.run(SKAction.sequence([SKAction.wait(forDuration: beat * 9)]), withKey: "bl1dPhase")
            bl2Down.run(SKAction.sequence([SKAction.wait(forDuration: beat * 9)]), withKey: "bl2dPhase")

            // Huvud: glad lyftning
            head.run(SKAction.sequence([
                SKAction.moveBy(x: 8, y: 45, duration: beat * 1.5),
                SKAction.wait(forDuration: beat * 0.5),
                SKAction.moveBy(x: 15, y: 8, duration: beat),
                SKAction.moveBy(x: -25, y: 0, duration: beat),
                SKAction.moveBy(x: 20, y: 0, duration: beat),
                SKAction.moveBy(x: -18, y: 0, duration: beat),
                SKAction.moveBy(x: 15, y: 0, duration: beat),
                SKAction.moveBy(x: -7, y: -8, duration: beat * 0.5),
                SKAction.moveBy(x: -8, y: -45, duration: beat * 0.5)
            ]), withKey: "headPhase")
            // Blink vid toppen + mitt i krats
            head.run(SKAction.sequence([
                SKAction.wait(forDuration: beat * 2), quickBlink(),
                SKAction.wait(forDuration: beat * 3), quickBlink(),
                SKAction.wait(forDuration: beat * 2), quickBlink(),
            ]), withKey: "blinkPhase")

            // Svans: glad hög viftning
            tail.run(SKAction.sequence([
                SKAction.rotate(toAngle: 0.30, duration: beat * 1.5),
                SKAction.wait(forDuration: beat * 0.5),
                SKAction.sequence([SKAction.rotate(toAngle: 0.40, duration: beat * 0.3), SKAction.rotate(toAngle: 0.25, duration: beat * 0.7)]),
                SKAction.sequence([SKAction.rotate(toAngle: 0.18, duration: beat * 0.3), SKAction.rotate(toAngle: 0.30, duration: beat * 0.7)]),
                SKAction.sequence([SKAction.rotate(toAngle: 0.40, duration: beat * 0.3), SKAction.rotate(toAngle: 0.25, duration: beat * 0.7)]),
                SKAction.sequence([SKAction.rotate(toAngle: 0.18, duration: beat * 0.3), SKAction.rotate(toAngle: 0.30, duration: beat * 0.7)]),
                SKAction.sequence([SKAction.rotate(toAngle: 0.40, duration: beat * 0.3), SKAction.rotate(toAngle: 0.25, duration: beat * 0.7)]),
                SKAction.rotate(toAngle: 0, duration: beat * 0.5),
                SKAction.wait(forDuration: beat * 0.5)
            ]), withKey: "tailPhase")
        }

        // --- FAS RD: RIVERDANCE (8 beats) ---
        func startRiverdancePhase() {
            // Höga knälyft omväxlande — riverdance-stil
            // Benen lyfts framåt (positiv rotation) med snabba lyft/ner

            let rb = beat * 1.5  // riverdance-beat — långsammare
            func kneeLift() -> SKAction {
                let up = SKAction.rotate(toAngle: 0.60, duration: rb * 0.35)
                up.timingMode = .easeInEaseOut
                let down = SKAction.rotate(toAngle: 0, duration: rb * 0.35)
                down.timingMode = .easeInEaseOut
                return SKAction.sequence([up, down])
            }
            func kneeHold() -> SKAction {
                SKAction.sequence([SKAction.wait(forDuration: rb * 0.7)])
            }
            func lowerKick() -> SKAction {
                let kick = SKAction.rotate(toAngle: -0.35, duration: rb * 0.3)
                kick.timingMode = .easeInEaseOut
                let back = SKAction.rotate(toAngle: 0, duration: rb * 0.4)
                back.timingMode = .easeInEaseOut
                return SKAction.sequence([kick, back])
            }
            func lowerHold() -> SKAction {
                SKAction.sequence([SKAction.wait(forDuration: rb * 0.7)])
            }

            // Container: mjuk studs
            let bounceUp = SKAction.moveBy(x: 15, y: 25, duration: rb * 0.35)
            bounceUp.timingMode = .easeOut
            let bounceDown = SKAction.moveBy(x: -15, y: -25, duration: rb * 0.35)
            bounceDown.timingMode = .easeIn
            let bounce = SKAction.sequence([bounceUp, bounceDown])
            deer.run(SKAction.sequence([
                bounce, bounce, bounce, bounce,
                bounce, bounce, bounce, bounce
            ]), withKey: "deerPhase")

            // Framben 1: lyft på beat 1, 3, 5, 7
            fl1Grp.run(SKAction.sequence([
                kneeLift(), kneeHold(), kneeLift(), kneeHold(),
                kneeLift(), kneeHold(), kneeLift(), kneeHold()
            ]), withKey: "fl1Phase")

            // Framben 2: lite i otakt (fördröjd 0.3 beats)
            fl2Grp.run(SKAction.sequence([
                SKAction.wait(forDuration: rb * 0.3),
                kneeLift(), kneeHold(), kneeLift(), kneeHold(),
                kneeLift(), kneeHold(), kneeLift(),
                SKAction.wait(forDuration: rb * 0.4)
            ]), withKey: "fl2Phase")

            // Framben underben: sparkar ut vid lyft
            fl1Down.run(SKAction.sequence([
                lowerKick(), lowerHold(), lowerKick(), lowerHold(),
                lowerKick(), lowerHold(), lowerKick(), lowerHold()
            ]), withKey: "fl1dPhase")
            // fl2 underben: lite större spark
            func fl2Kick() -> SKAction {
                let kick = SKAction.rotate(toAngle: -0.55, duration: rb * 0.25)
                kick.timingMode = .easeOut
                let back = SKAction.rotate(toAngle: 0, duration: rb * 0.45)
                back.timingMode = .easeInEaseOut
                return SKAction.sequence([kick, back])
            }
            fl2Down.run(SKAction.sequence([
                SKAction.wait(forDuration: rb * 0.3),
                fl2Kick(), lowerHold(), fl2Kick(), lowerHold(),
                fl2Kick(), lowerHold(), fl2Kick(),
                SKAction.wait(forDuration: rb * 0.4)
            ]), withKey: "fl2dPhase")

            // Bakben: lätt motpendling (planterade)
            let backSwayDown = SKAction.rotate(toAngle: -0.08, duration: rb * 0.35)
            backSwayDown.timingMode = .easeInEaseOut
            let backSwayUp = SKAction.rotate(toAngle: 0, duration: rb * 0.35)
            backSwayUp.timingMode = .easeInEaseOut
            let backSway = SKAction.sequence([backSwayDown, backSwayUp])
            bl1Grp.run(SKAction.sequence([
                backSway, backSway, backSway, backSway,
                backSway, backSway, backSway, backSway
            ]), withKey: "bl1Phase")
            bl2Grp.run(SKAction.sequence([
                SKAction.wait(forDuration: rb * 0.35),
                backSway, backSway, backSway, backSway,
                backSway, backSway, backSway,
                SKAction.wait(forDuration: rb * 0.35)
            ]), withKey: "bl2Phase")
            // Bakben underben: mjuk böjning i takt
            let blKickDown = SKAction.rotate(toAngle: -0.20, duration: rb * 0.35)
            blKickDown.timingMode = .easeInEaseOut
            let blKickUp = SKAction.rotate(toAngle: 0, duration: rb * 0.35)
            blKickUp.timingMode = .easeInEaseOut
            let blKick = SKAction.sequence([blKickDown, blKickUp])
            bl1Down.run(SKAction.sequence([
                blKick, blKick, blKick, blKick,
                blKick, blKick, blKick, blKick
            ]), withKey: "bl1dPhase")
            bl2Down.run(SKAction.sequence([
                SKAction.wait(forDuration: rb * 0.35),
                blKick, blKick, blKick, blKick,
                blKick, blKick, blKick,
                SKAction.wait(forDuration: rb * 0.35)
            ]), withKey: "bl2dPhase")

            // Huvud: mjuk nick i takt
            let nodDown = SKAction.moveBy(x: 0, y: -5, duration: rb * 0.35)
            nodDown.timingMode = .easeInEaseOut
            let nodUp = SKAction.moveBy(x: 0, y: 5, duration: rb * 0.35)
            nodUp.timingMode = .easeInEaseOut
            let headNod = SKAction.sequence([nodDown, nodUp])
            head.run(SKAction.sequence([
                headNod, headNod, headNod, headNod,
                headNod, headNod, headNod, headNod
            ]), withKey: "headPhase")
            // Blink synkad med knälyft (beat 2, 5, 8)
            head.run(SKAction.sequence([
                SKAction.wait(forDuration: rb * 1.5), quickBlink(),
                SKAction.wait(forDuration: rb * 3), quickBlink(),
                SKAction.wait(forDuration: rb * 2.5), quickBlink(),
            ]), withKey: "blinkPhase")

            // Svans: mjuk viftning
            let wagRight = SKAction.rotate(toAngle: 0.15, duration: rb * 0.35)
            wagRight.timingMode = .easeInEaseOut
            let wagLeft = SKAction.rotate(toAngle: -0.10, duration: rb * 0.35)
            wagLeft.timingMode = .easeInEaseOut
            let tailWag = SKAction.sequence([wagRight, wagLeft])
            tail.run(SKAction.sequence([
                tailWag, tailWag, tailWag, tailWag,
                tailWag, tailWag, tailWag, tailWag
            ]), withKey: "tailPhase")
        }

        // --- FAS J: SKUTT + LANDNING (~2s) --- (kvar men ej i koreografin)
        func startSkuttPhase() {
            // Container
            deer.run(SKAction.sequence([
                SKAction.group([
                    SKAction.scale(to: baseScale * 0.92, duration: 0.08),
                    SKAction.moveBy(x: 0, y: -18, duration: 0.08)
                ]),
                SKAction.group([
                    SKAction.moveBy(x: 0, y: 190, duration: 0.22),
                    SKAction.scale(to: baseScale * 1.05, duration: 0.22)
                ]),
                SKAction.wait(forDuration: 0.12),
                SKAction.scale(to: baseScale * 0.9, duration: 0.08),
                SKAction.group([
                    SKAction.moveBy(x: 0, y: -172, duration: 0.2),
                    SKAction.scale(to: baseScale, duration: 0.2)
                ]),
                SKAction.scale(to: baseScale * 0.9, duration: 0.04),
                SKAction.group([
                    SKAction.moveBy(x: 0, y: 30, duration: 0.1),
                    SKAction.scale(to: baseScale * 1.05, duration: 0.1)
                ]),
                SKAction.group([
                    SKAction.moveBy(x: 0, y: -30, duration: 0.08),
                    SKAction.scale(to: baseScale * 0.97, duration: 0.08)
                ]),
                SKAction.group([
                    SKAction.moveBy(x: 0, y: 12, duration: 0.07),
                    SKAction.scale(to: baseScale * 1.02, duration: 0.07)
                ]),
                SKAction.group([
                    SKAction.moveBy(x: 0, y: -12, duration: 0.06),
                    SKAction.scale(to: baseScale, duration: 0.06)
                ])
            ]), withKey: "deerPhase")

            // Ben: pendelkick från höft/axel
            let frontKick: [SKAction] = [
                SKAction.rotate(toAngle: 0.12, duration: 0.15),
                SKAction.rotate(toAngle: -0.06, duration: 0.12),
                SKAction.rotate(toAngle: 0.04, duration: 0.08),
                SKAction.rotate(toAngle: 0, duration: 0.15),
                SKAction.rotate(toAngle: 0.06, duration: 0.05),
                SKAction.rotate(toAngle: -0.02, duration: 0.15),
                SKAction.rotate(toAngle: 0, duration: 0.3),
                SKAction.rotate(toAngle: 0, duration: 0.5)
            ]
            let backKick: [SKAction] = [
                SKAction.rotate(toAngle: -0.12, duration: 0.15),
                SKAction.rotate(toAngle: 0.08, duration: 0.12),
                SKAction.rotate(toAngle: -0.04, duration: 0.08),
                SKAction.rotate(toAngle: 0, duration: 0.15),
                SKAction.rotate(toAngle: -0.08, duration: 0.05),
                SKAction.rotate(toAngle: 0.02, duration: 0.15),
                SKAction.rotate(toAngle: 0, duration: 0.3),
                SKAction.rotate(toAngle: 0, duration: 0.5)
            ]
            fl1Grp.run(SKAction.sequence(frontKick), withKey: "fl1Phase")
            fl2Grp.run(SKAction.sequence(frontKick), withKey: "fl2Phase")
            bl1Grp.run(SKAction.sequence(backKick), withKey: "bl1Phase")
            bl2Grp.run(SKAction.sequence(backKick), withKey: "bl2Phase")

            // Underben: kick-rotation (bara bakåt = negativt, aldrig framåt)
            let legDownKick: [SKAction] = [
                SKAction.rotate(toAngle: -deg15, duration: 0.15),
                SKAction.rotate(toAngle: -deg30, duration: 0.12),
                SKAction.rotate(toAngle: 0, duration: 0.08),
                SKAction.rotate(toAngle: 0, duration: 0.15),
                SKAction.rotate(toAngle: -deg30, duration: 0.05),
                SKAction.rotate(toAngle: 0, duration: 0.1),              // aldrig framåt!
                SKAction.rotate(toAngle: -deg15, duration: 0.08),
                SKAction.rotate(toAngle: 0, duration: 0.3),
                SKAction.rotate(toAngle: 0, duration: 0.5)
            ]
            fl1Down.run(SKAction.sequence(legDownKick), withKey: "fl1dPhase")
            fl2Down.run(SKAction.sequence(legDownKick), withKey: "fl2dPhase")
            bl1Down.run(SKAction.sequence(legDownKick), withKey: "bl1dPhase")
            bl2Down.run(SKAction.sequence(legDownKick), withKey: "bl2dPhase")

            // Huvud: skutt-rörelse
            head.run(SKAction.sequence([
                SKAction.moveBy(x: 0, y: 28, duration: 0.15),
                SKAction.moveBy(x: 0, y: 5, duration: 0.12),
                SKAction.moveBy(x: 0, y: -5, duration: 0.08),
                SKAction.moveBy(x: 0, y: -28, duration: 0.15),
                SKAction.moveBy(x: 0, y: -10, duration: 0.05),
                SKAction.moveBy(x: 0, y: 15, duration: 0.08),
                SKAction.moveBy(x: 0, y: -5, duration: 0.07),
                SKAction.move(to: .zero, duration: 0.3),
                SKAction.move(to: .zero, duration: 0.5)
            ]), withKey: "headPhase")

            // Svans: pendelkick (roterar kring fästpunkten)
            tail.run(SKAction.sequence([
                SKAction.rotate(toAngle: 0.18, duration: 0.15),
                SKAction.rotate(toAngle: 0.22, duration: 0.12),
                SKAction.rotate(toAngle: 0.15, duration: 0.08),
                SKAction.rotate(toAngle: 0, duration: 0.15),
                SKAction.rotate(toAngle: 0.12, duration: 0.05),
                SKAction.rotate(toAngle: -0.04, duration: 0.1),
                SKAction.rotate(toAngle: 0.03, duration: 0.15),
                SKAction.rotate(toAngle: 0, duration: 0.3),
                SKAction.rotate(toAngle: 0, duration: 0.5)
            ]), withKey: "tailPhase")
        }

        // ═══════════════════════════════════════════
        // Stoppa alla fas-aktioner och nollställ
        // ═══════════════════════════════════════════
        func stopPhaseActions() {
            let phaseKeys = ["deerPhase", "fl1Phase", "fl2Phase", "bl1Phase", "bl2Phase",
                             "fl1dPhase", "fl2dPhase", "bl1dPhase", "bl2dPhase",
                             "headPhase", "tailPhase", "bodyPhase", "danceBreath", "blinkPhase"]
            let nodes: [SKNode?] = [deer, fl1Grp, fl2Grp, bl1Grp, bl2Grp,
                                     fl1Down, fl2Down, bl1Down, bl2Down,
                                     head, tail, body]
            for node in nodes {
                for key in phaseKeys {
                    node?.removeAction(forKey: key)
                }
            }
        }

        // ═══════════════════════════════════════════
        // KOREOGRAFI — kedjar faserna via container
        // ═══════════════════════════════════════════

        let steppDur = beat * 8
        let moonDur = mBeat * Double(moonSteps) * 2  // 6 steg × 2 riktningar
        let riverDur = beat * 1.5 * 8  // rb = beat * 1.5, 8 beats
        let rearDur = beat * 7
        let bigRearDur = beat * 9

        // Bestäm fasordning
        let phase1: () -> Void = moonFirst ? startMoonwalkPhase : startSteppPhase
        let phase1Dur = moonFirst ? moonDur : steppDur
        let phase2: () -> Void = moonFirst ? startSteppPhase : startMoonwalkPhase
        let phase2Dur = moonFirst ? steppDur : moonDur

        // Progressiv andning — börjar försiktig, ökar med varje fas
        func startDanceBreath(bodyScale: CGFloat, headBob: CGFloat, speed: TimeInterval) {
            let bIn = SKAction.scale(to: 1.0 + bodyScale, duration: speed)
            bIn.timingMode = .easeInEaseOut
            let bOut = SKAction.scale(to: 1.0 - bodyScale, duration: speed)
            bOut.timingMode = .easeInEaseOut
            body.run(SKAction.repeatForever(SKAction.sequence([bIn, bOut])), withKey: "danceBreath")

            let hUp = SKAction.moveBy(x: 0, y: headBob, duration: speed)
            hUp.timingMode = .easeInEaseOut
            let hDown = SKAction.moveBy(x: 0, y: -headBob, duration: speed)
            hDown.timingMode = .easeInEaseOut
            head.run(SKAction.repeatForever(SKAction.sequence([hUp, hDown])), withKey: "danceBreath")
        }

        // Huvudsekvens som driver timing + fasövergångar
        deer.run(SKAction.sequence([
            // Intro — kroppen andas, benen stilla, huvudet cirklar
            SKAction.run { startDanceBreath(bodyScale: 0.015, headBob: 0, speed: 0.5) },
            SKAction.run {
                let cR: CGFloat = 6
                let cDur: TimeInterval = 1.0
                let q = cDur / 4
                let r = SKAction.moveBy(x: cR, y: 0, duration: q); r.timingMode = .easeInEaseOut
                let u = SKAction.moveBy(x: 0, y: cR, duration: q); u.timingMode = .easeInEaseOut
                let l = SKAction.moveBy(x: -cR, y: 0, duration: q); l.timingMode = .easeInEaseOut
                let d = SKAction.moveBy(x: 0, y: -cR, duration: q); d.timingMode = .easeInEaseOut
                head.run(SKAction.repeatForever(SKAction.sequence([r, u, l, d])), withKey: "danceBreath")
            },
            SKAction.wait(forDuration: 2.0),
            SKAction.run { [weak self] in stopPhaseActions(); self?.resetDeerParts() },

            // Fas 1 — försiktig andning
            SKAction.run { startDanceBreath(bodyScale: 0.008, headBob: 1.5, speed: 0.45) },
            SKAction.run { phase1() },
            SKAction.run { [weak self] in if moonFirst { self?.moonwalkGlitterBlink() } else { self?.steppGlitterBlink() } },
            SKAction.wait(forDuration: phase1Dur + 0.05),
            SKAction.run { [weak self] in stopPhaseActions(); self?.resetDeerParts() },
            SKAction.wait(forDuration: 0.15),

            // Fas 2 — lite mer andning
            SKAction.run { startDanceBreath(bodyScale: 0.012, headBob: 2.0, speed: 0.40) },
            SKAction.run { phase2() },
            SKAction.run { [weak self] in if !moonFirst { self?.moonwalkGlitterBlink() } else { self?.steppGlitterBlink() } },
            SKAction.wait(forDuration: phase2Dur + 0.05),
            SKAction.run { [weak self] in stopPhaseActions(); self?.resetDeerParts() },
            SKAction.wait(forDuration: 0.15),

            // Fas RD: Riverdance — märkbar andning
            SKAction.run { startDanceBreath(bodyScale: 0.018, headBob: 3.0, speed: 0.35) },
            SKAction.run { startRiverdancePhase() },
            SKAction.wait(forDuration: riverDur + 0.05),
            SKAction.run { [weak self] in stopPhaseActions(); self?.resetDeerParts() },
            SKAction.wait(forDuration: 0.15),

            // Fas R: Stegring — tydlig andning
            SKAction.run { startDanceBreath(bodyScale: 0.022, headBob: 4.0, speed: 0.32) },
            SKAction.run { startRearingPhase() },
            // SKAction.run { [weak self] in self?.spinAllMaskrosor() },
            SKAction.run { [weak self] in self?.burstHoofGlitter() },
            SKAction.wait(forDuration: rearDur + 0.05),
            SKAction.run { [weak self] in stopPhaseActions(); self?.resetDeerParts() },
            SKAction.wait(forDuration: 0.15),

            // Outro — kroppen andas ut, benen stilla, huvudet cirklar
            SKAction.run { startDanceBreath(bodyScale: 0.025, headBob: 0, speed: 0.35) },
            SKAction.run {
                let cR: CGFloat = 8
                let cDur: TimeInterval = 0.8
                let q = cDur / 4
                let r = SKAction.moveBy(x: cR, y: 0, duration: q); r.timingMode = .easeInEaseOut
                let u = SKAction.moveBy(x: 0, y: cR, duration: q); u.timingMode = .easeInEaseOut
                let l = SKAction.moveBy(x: -cR, y: 0, duration: q); l.timingMode = .easeInEaseOut
                let d = SKAction.moveBy(x: 0, y: -cR, duration: q); d.timingMode = .easeInEaseOut
                head.run(SKAction.repeatForever(SKAction.sequence([r, u, l, d])), withKey: "danceBreath")
            },
            SKAction.wait(forDuration: 2.5),
            SKAction.run { [weak self] in stopPhaseActions(); self?.resetDeerParts() },

            // Flash — blixt mellan dans och vila
            SKAction.run { [weak self] in
                guard let self, let scene = self.scene ?? self as? SKScene else { return }
                let flash = SKSpriteNode(color: .white,
                                         size: CGSize(width: scene.frame.width, height: scene.frame.height))
                flash.position = CGPoint(x: scene.frame.midX, y: scene.frame.midY)
                flash.zPosition = 999
                flash.alpha = 0
                self.addChild(flash)
                flash.run(SKAction.sequence([
                    SKAction.fadeAlpha(to: 0.5, duration: 0.05),
                    SKAction.fadeAlpha(to: 0, duration: 0.08),
                    SKAction.fadeAlpha(to: 0.3, duration: 0.04),
                    SKAction.fadeOut(withDuration: 0.15),
                    SKAction.removeFromParent()
                ]))
            },

            // Avslut — smidig övergång tillbaka till startposition
            SKAction.wait(forDuration: 0.2),
            SKAction.move(to: startPos, duration: 0.6),
            SKAction.run { [weak self] in
                guard let self else { return }
                self.resetDeerParts()
                self.isDeerDancing = false
                self.isDeerPostDance = true
                // self.stopMaskrosStorm()
                self.stopDanceGlitterStorm()
                self.startHoofGlitter(on: deer)

                // Andning — kroppen
                let breatheUp = SKAction.scale(to: baseScale * 1.015, duration: 1.4)
                breatheUp.timingMode = .easeInEaseOut
                let breatheDown = SKAction.scale(to: baseScale * 0.985, duration: 1.4)
                breatheDown.timingMode = .easeInEaseOut
                deer.run(SKAction.repeatForever(SKAction.sequence([breatheUp, breatheDown])), withKey: "deerBreathe")

                // Glad nickning på huvudet
                guard let head = self.deerHead else { return }
                let nodDown = SKAction.moveBy(x: 0, y: -12, duration: 0.8)
                nodDown.timingMode = .easeInEaseOut
                let nodUp = SKAction.moveBy(x: 0, y: 12, duration: 0.8)
                nodUp.timingMode = .easeInEaseOut
                head.run(SKAction.repeatForever(SKAction.sequence([nodDown, nodUp])), withKey: "idleNod")

                // Slumpmässig blink
                let normalTex = SKTexture(imageNamed: "deer1_head")
                let blinkTex = SKTexture(imageNamed: "deer1_head_blink")
                let blink = SKAction.repeatForever(SKAction.sequence([
                    SKAction.wait(forDuration: 5.0, withRange: 4.0),
                    SKAction.setTexture(blinkTex, resize: false),
                    SKAction.wait(forDuration: 0.12),
                    SKAction.setTexture(normalTex, resize: false),
                ]))
                head.run(blink, withKey: "idleBlink")

                // Glad svansviftning
                guard let tail = self.deerTail else { return }
                let wagR = SKAction.rotate(toAngle: 0.12, duration: 0.8)
                wagR.timingMode = .easeInEaseOut
                let wagL = SKAction.rotate(toAngle: -0.08, duration: 0.8)
                wagL.timingMode = .easeInEaseOut
                tail.run(SKAction.repeatForever(SKAction.sequence([wagR, wagL])), withKey: "idleWag")

                self.startDeerGlow()
            }
        ]), withKey: "deerDance")
    }

    // MARK: - End Deer Sequence (fade out deer, fade in portrait + room)

    private func endDeerSequence() {
        guard let deer = deerNode else { return }
        isDeerPostDance = false

        // Stoppa alla idle-animationer
        deer.removeAllActions()
        deerHead?.removeAllActions()
        deerTail?.removeAllActions()
        deerGlow?.removeAllActions()

        // Steg 1: Fada ut dansrådjuret först
        deer.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 1.2),
            SKAction.run { [weak self] in
                deer.removeFromParent()
                self?.deerNode = nil
                self?.deerGlow?.removeFromParent()
                self?.deerGlow = nil
            }
        ]))

        // Fada ut overlay samtidigt
        if let overlay = childNode(withName: "portraitOverlay") {
            overlay.run(SKAction.sequence([
                SKAction.fadeOut(withDuration: 1.2),
                SKAction.removeFromParent()
            ]))
        }

        // Steg 2: Fada in tavlan EFTER att rådjuret försvunnit
        currentPortrait?.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.3),
            SKAction.fadeAlpha(to: 1.0, duration: 1.2)
        ]))

        // Steg 3: Rumsobjekten fadar in 2s efter tavlan
        run(SKAction.sequence([
            SKAction.wait(forDuration: 1.3 + 1.2 + 2.0),
            SKAction.run { [weak self] in
                guard let self else { return }

                // Fada in owl + tillbaka till idle (sovande)
                self.owl.isHidden = false
                self.owl.run(SKAction.sequence([
                    SKAction.fadeAlpha(to: 1.0, duration: 0.6),
                    SKAction.run { self.owl.startSleeping() }
                ]))

                // Fada in hat + starta idle
                self.hatNode.run(SKAction.sequence([
                    SKAction.fadeAlpha(to: 1.0, duration: 0.6),
                    SKAction.run { self.hatNode.startIdleTimer() }
                ]))

                // Fada in toolbox + starta idle
                self.toolboxNode.fadeBack()

                // Återställ transition manager + gökur
                self.transitionManager.deactivateAll()
                if let gokur = self.childNode(withName: "gokur") {
                    gokur.run(SKAction.fadeAlpha(to: 1.0, duration: 0.6))
                }

                // Tavlan: starta glow
                if self.portraitStep == 3 { self.startPortraitGlow() }

                // Tillbaka till sleeping — allt tryckbart igen
                self.sceneState = .sleeping
            }
        ]))
    }

    private func startDeerGlow() {
        guard let deer = deerNode else { return }
        deerGlow?.removeAllActions()
        deerGlow?.removeFromParent()

        let glow = SKEffectNode()
        glow.shouldRasterize = true
        glow.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 40.0])
        glow.zPosition = deer.zPosition - 1
        glow.position = deer.position
        glow.alpha = 0
        addChild(glow)

        let glowSprite = SKSpriteNode(imageNamed: "deer1_body")
        glowSprite.setScale(deer.xScale * 1.08)
        glowSprite.colorBlendFactor = 1.0
        glowSprite.color = .white
        glow.addChild(glowSprite)

        let shimmer = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.5, duration: 1.2),
            SKAction.fadeAlpha(to: 0.2, duration: 1.0),
            SKAction.fadeAlpha(to: 0.55, duration: 0.8),
            SKAction.fadeAlpha(to: 0.15, duration: 1.4)
        ])
        glow.run(SKAction.repeatForever(shimmer), withKey: "deerShimmer")
        deerGlow = glow
    }

    // MARK: - Hat Sequence

    private func startHatSequence() {
        sceneState = .hatActive
        transitionManager.activateObject(id: .hat)
        stopPortraitGlow()
        hatNode.stopGlitter()
        hatNode.stopIdleTimer()
        toolboxNode.fadeAway()
        toolboxNode.isHidden = true

        // Släck ugglan + skugga under hela hatt/kanin-sessionen
        owl.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.8),
            SKAction.run { [weak self] in self?.owl.isHidden = true }
        ]), withKey: "owlFade")

        rabbitNode.startEarsGrow()

        // När pinball är klar — sätt flagga, update() gör resetten nästa frame
        rabbitNode.onPinballComplete = { [weak self] in
            self?.needsReset = true
        }
    }

    private func resetHatSequence() {
        rabbitNode.reset()
        hatNode.reset()

        // Tomt rum 2 sekunder, sedan mjuk fade-in
        owl.removeAction(forKey: "owlFade")
        owl.isHidden = false
        owl.alpha = 0
        owl.run(SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.fadeIn(withDuration: 3.0)
        ]))

        // Toolbox tillbaka — visa och fada in mjukt
        toolboxNode.removeAllActions()
        toolboxNode.isHidden = false
        toolboxNode.run(SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.run { [weak self] in self?.toolboxNode.fadeBack() }
        ]))

        sceneState = .sleeping
        transitionManager.deactivateAll()
        if portraitStep == 3 { startPortraitGlow() }
    }

    // MARK: - Touch

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tappedNodes = nodes(at: location)

        if tappedNodes.contains(where: { $0.name == "debugReset" }) {
            debugResetScene()
            return
        }

        switch sceneState {
        case .sleeping:
            // Mugg tap
            if muggWaitingForTap && tappedNodes.contains(where: { $0.name == "gokurMugg" }) {
                tapMugg()
                return
            }

            // Ägg tap — interagera med ägget
            if eggWaitingForTap && tappedNodes.contains(where: { $0.name == "gokurEgg" }) {
                tapEgg()
                return
            }

            // Gökur tap — öppna uret
            if tappedNodes.contains(where: { $0.name == "gokur" || $0.parent?.name == "gokur" }) {
                tapGokur()
                return
            }

            // Hat tap — start hat sequence
            if tappedNodes.contains(where: { $0.name == "hat" }) {
                startHatSequence()
                return
            }

            // Portrait tap — tryckbar som val i rummet efter montering
            if portraitStep == 3 && tappedNodes.contains(where: { $0.name == "portrait" }) {
                startPortraitTapSequence()
                return
            }

            // Toolbox tap — start toolbox sequence
            if tappedNodes.contains(where: { $0.name == "toolbox" }) {
                if portraitStep == 3 {
                    // TODO: Ny sekvens efter hammaren spikat upp tavlan
                }
                startToolboxSequence()
                return
            }

            // Owl tap — wake up owl, fade hat + toolbox
            if tappedNodes.contains(where: { $0.name == "owl" }) {
                stopPortraitGlow()
                transitionManager.activateObject(id: .owl)
                toolboxNode.fadeAway()
                owl.onTap()
                sceneState = .wakingUp
            }

        case .awake:
            // Owl tap 2 — start bubble
            if tappedNodes.contains(where: { $0.name == "owl" }) {
                owl.onTap()
            }

        case .hatActive:
            // Tap on ears → rise sequence → dance
            if tappedNodes.contains(where: { $0.name == "rabbitEars" }) {
                rabbitNode.startRiseSequence()
            }
            // Tap on rabbit body → roll with boom, or pinball if in rollIdle
            if tappedNodes.contains(where: { $0.name == "rabbitBody" }) {
                rabbitNode.startRoll()      // state guard: only runs in .dancing
                rabbitNode.startPinball()   // state guard: only runs in .rollIdle
            }

        case .portraitActive:
            if tappedNodes.contains(where: { $0.name == "deer" || $0.parent?.name == "deer" || $0.parent?.parent?.name == "deer" }) {
                if isDeerPostDance {
                    endDeerSequence()
                } else if !isDeerDancing {
                    startDeerDance()
                }
            }

        case .toolboxActive:
            // Tap on hammer eller klon
            let tappedHammer = tappedNodes.contains(where: { $0.name == "hammer" || $0.name == "hammerClone" })
            guard tappedHammer else { break }

            // Paradflödet (tavlan på plats)
            if portraitStep == 3 {
                // Blockera alla tap under pågående animationer
                guard hammerNode.action(forKey: "peekABoo") == nil,
                      hammerNode.action(forKey: "parade") == nil,
                      hammerNode.action(forKey: "waveBye") == nil,
                      hammerNode.action(forKey: "quickStrike") == nil,
                      hammerNode.action(forKey: "comeback") == nil else { break }
                switch paradePhase {
                case 0: startHammerParade()
                case 1: startHammerCarousel()
                case 2: endHammerParade()
                default: break  // -1 = animerar, blockera tap
                }
                break
            }

            // Tavelflödet — bara om alla animationer är klara
            guard hammerNode.action(forKey: "peekABoo") == nil,
                  hammerNode.action(forKey: "quickStrike") == nil,
                  hammerNode.action(forKey: "comeback") == nil,
                  hammerNode.action(forKey: "waveBye") == nil else { break }
            if portraitStep == 0 {
                startPortraitSequence()
            } else if portraitStep == 1 {
                startPortraitSwapSequence()
            }

        case .wobbling:
            popBubble()

        default:
            break
        }
    }
}
