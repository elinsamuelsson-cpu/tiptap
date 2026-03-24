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
            }
        ]))
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

        // Maskros-fröställning — 9 maskrosor i ring som snurrar
        // Outer glow på hela karusellen (samma stil som tavlan)
        let maskrosGlow = SKEffectNode()
        maskrosGlow.shouldRasterize = true
        maskrosGlow.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 25.0])
        maskrosGlow.position = CGPoint(x: 50, y: -750)
        maskrosGlow.zPosition = 19
        maskrosGlow.alpha = 0
        maskrosGlow.name = "maskrosGlow"
        deer.addChild(maskrosGlow)

        let maskrosCarousel = SKNode()
        maskrosCarousel.position = CGPoint(x: 50, y: -750)  // vid hovarna
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

            // Container per maskros — för individuell vickning
            let container = SKNode()
            container.position = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
            container.name = "maskrosItem"
            maskrosCarousel.addChild(container)

            // Inverterad maskros via CIColorInvert
            let invertNode = SKEffectNode()
            invertNode.shouldRasterize = true
            invertNode.filter = CIFilter(name: "CIColorInvert")
            let m = SKSpriteNode(imageNamed: maskrosNames[i % 3])
            m.zRotation = angle - .pi / 2  // stjälken pekar inåt
            m.setScale(1.0)
            m.anchorPoint = CGPoint(x: 0.5, y: 0.0)  // pivot vid stjälkens bas
            invertNode.addChild(m)
            container.addChild(invertNode)

            // Outer glow
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

            // Individuell vickning — varje maskros vaggar från basen
            let delay = Double(i) * 0.15
            let wiggleAmount: CGFloat = CGFloat.random(in: 0.08...0.15)
            let wiggleSpeed = TimeInterval.random(in: 0.6...1.0)
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

        // Bygg glow-kopia av alla maskrosor (vit, blurrad)
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

        // Pulserande shimmer på glowen (samma som tavlan)
        let shimmer = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.9, duration: 1.2),
            SKAction.fadeAlpha(to: 0.4, duration: 1.0),
            SKAction.fadeAlpha(to: 1.0, duration: 0.8),
            SKAction.fadeAlpha(to: 0.35, duration: 1.4)
        ])

        // Fada in → stanna → blås bort som fröställning
        maskrosCarousel.run(SKAction.fadeAlpha(to: 1.0, duration: 1.0))
        maskrosGlow.run(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.8, duration: 1.0),
            SKAction.repeatForever(shimmer)
        ]))

        // Efter 3.5s: blås bort alla maskrosor åt höger (som vinden tar dem)
        maskrosCarousel.run(SKAction.sequence([
            SKAction.wait(forDuration: 3.5),
            SKAction.run {
                maskrosCarousel.enumerateChildNodes(withName: "maskrosItem") { container, _ in
                    // Varje maskros blåser iväg åt höger-uppåt med slumpmässig spridning
                    let windX = CGFloat.random(in: 400...900)
                    let windY = CGFloat.random(in: 100...500)
                    let spinAngle = CGFloat.random(in: 2...6) * (Bool.random() ? 1 : -1)
                    let duration = TimeInterval.random(in: 1.2...2.5)
                    let delay = TimeInterval.random(in: 0...0.6)

                    container.run(SKAction.sequence([
                        SKAction.wait(forDuration: delay),
                        SKAction.group([
                            SKAction.moveBy(x: windX, y: windY, duration: duration),
                            SKAction.rotate(byAngle: spinAngle, duration: duration),
                            SKAction.scale(to: 0.3, duration: duration),
                            SKAction.sequence([
                                SKAction.wait(forDuration: duration * 0.5),
                                SKAction.fadeOut(withDuration: duration * 0.5),
                            ])
                        ])
                    ]))
                }
            },
            // Ta bort karusellen efter att alla blåst bort
            SKAction.wait(forDuration: 3.5),
            SKAction.removeFromParent()
        ]))

        // Glowen fadear ut samtidigt
        maskrosGlow.run(SKAction.sequence([
            SKAction.wait(forDuration: 3.5),
            SKAction.fadeOut(withDuration: 1.0),
            SKAction.removeFromParent()
        ]))

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
            SKAction.wait(forDuration: phase1Dur + 0.05),
            SKAction.run { [weak self] in stopPhaseActions(); self?.resetDeerParts() },
            SKAction.wait(forDuration: 0.15),

            // Fas 2 — lite mer andning
            SKAction.run { startDanceBreath(bodyScale: 0.012, headBob: 2.0, speed: 0.40) },
            SKAction.run { phase2() },
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

                // Fada ut maskros-karusellen + glow
                for name in ["maskrosCarousel", "maskrosGlow"] {
                    if let node = deer.childNode(withName: name) {
                        node.run(SKAction.sequence([
                            SKAction.fadeOut(withDuration: 1.5),
                            SKAction.removeFromParent()
                        ]))
                    }
                }

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

                // Återställ transition manager
                self.transitionManager.deactivateAll()

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
