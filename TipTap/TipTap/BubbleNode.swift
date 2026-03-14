import SpriteKit

class BubbleNode: SKNode {

    // MARK: - Frame data (positioner från manualen, konverterade till SpriteKit-center)

    private struct FrameInfo {
        let imageName: String
        let size: CGSize
        let center: CGPoint  // Center i SpriteKit-koordinater (Y=2048-PSD_Y, sedan - H/2)
    }

    // Manualen anger top-left i SpriteKit-koordinater → center = (x + w/2, y - h/2)
    // Storlekar från faktiska PNG-filer (uppdaterade i manual v2)
    private let frameInfos: [FrameInfo] = [
        FrameInfo(imageName: "bubble_01", size: CGSize(width: 340,  height: 315),
                  center: CGPoint(x: 1831 + 170,   y: 841  - 157.5)),  // (2001, 683.5)
        FrameInfo(imageName: "bubble_02", size: CGSize(width: 386,  height: 391),
                  center: CGPoint(x: 1720 + 193,   y: 998  - 195.5)),  // (1913, 802.5)
        FrameInfo(imageName: "bubble_03", size: CGSize(width: 361,  height: 354),
                  center: CGPoint(x: 1442 + 180.5, y: 1156 - 177)),    // (1622.5, 979)
        FrameInfo(imageName: "bubble_04", size: CGSize(width: 489,  height: 490),
                  center: CGPoint(x: 1206 + 244.5, y: 1372 - 245)),    // (1450.5, 1127)
        FrameInfo(imageName: "bubble_05", size: CGSize(width: 705,  height: 701),
                  center: CGPoint(x: 963  + 352.5, y: 1630 - 350.5)),  // (1315.5, 1279.5)
        FrameInfo(imageName: "bubble_06", size: CGSize(width: 944,  height: 916),
                  center: CGPoint(x: 618  + 472,   y: 1824 - 458)),    // (1090, 1366)
        FrameInfo(imageName: "bubble_07", size: CGSize(width: 1562, height: 1526),
                  center: CGPoint(x: 333  + 781,   y: 2026 - 763)),    // (1114, 1263)
        FrameInfo(imageName: "bubble_08", size: CGSize(width: 2732, height: 2048),
                  center: CGPoint(x: 1366,          y: 1024)),          // Mitten av scenen
    ]

    private var currentSprite: SKSpriteNode?
    var onGrowComplete: (() -> Void)?

    // MARK: - Grow (Tap 2, 2.5s) — en bubbla som stiger i en bana

    func startGrowing() {
        guard let first = frameInfos.first else { return }

        let sprite = SKSpriteNode(texture: SKTexture(imageNamed: first.imageName),
                                  size: first.size)
        sprite.position = first.center
        sprite.zPosition = 30
        addChild(sprite)
        currentSprite = sprite

        // Såpbubbla-jiggle under växandet — mer uttrycksfullt
        let jiggle = SKAction.repeatForever(SKAction.sequence([
            SKAction.scaleX(to: 1.06, y: 0.94, duration: 0.16),
            SKAction.scaleX(to: 0.94, y: 1.06, duration: 0.16),
            SKAction.scaleX(to: 1.04, y: 0.96, duration: 0.14),
            SKAction.scaleX(to: 0.96, y: 1.04, duration: 0.14),
        ]))
        sprite.run(jiggle, withKey: "growJiggle")

        growToNextFrame(sprite: sprite, index: 1)
    }

    private func growToNextFrame(sprite: SKSpriteNode, index: Int) {
        guard index < frameInfos.count else {
            sprite.removeAction(forKey: "growJiggle")
            // Mjuk återställning till neutral skala
            sprite.run(SKAction.scaleX(to: 1.0, y: 1.0, duration: 0.15))
            onGrowComplete?()
            return
        }

        let info = frameInfos[index]
        let stepDuration: TimeInterval = 2.5 / Double(frameInfos.count - 1)

        // Smooth flytt + storleksändring
        let move = SKAction.move(to: info.center, duration: stepDuration)
        move.timingMode = .easeInEaseOut
        let resize = SKAction.resize(toWidth: info.size.width, height: info.size.height,
                                     duration: stepDuration)
        resize.timingMode = .easeInEaseOut

        // Byt textur med subtil alpha-dip mitt i steget
        let swapTexture = SKAction.sequence([
            SKAction.wait(forDuration: stepDuration * 0.4),
            SKAction.fadeAlpha(to: 0.85, duration: 0.05),
            SKAction.setTexture(SKTexture(imageNamed: info.imageName), resize: false),
            SKAction.fadeAlpha(to: 1.0, duration: 0.05)
        ])

        let step = SKAction.group([move, resize, swapTexture])
        let next = SKAction.run { [weak self] in
            self?.growToNextFrame(sprite: sprite, index: index + 1)
        }
        sprite.run(SKAction.sequence([step, next]))
    }

    // MARK: - Wobble (efter bubble_08) — organisk såpbubbla

    func startWobble() {
        guard let sprite = currentSprite else { return }

        // Squash/stretch — subtilt, bubblan är stor och stabil
        let squashStretch = SKAction.repeatForever(SKAction.sequence([
            SKAction.scaleX(to: 1.015, y: 0.985, duration: 0.4),
            SKAction.scaleX(to: 0.99,  y: 1.01,  duration: 0.35),
            SKAction.scaleX(to: 1.01,  y: 0.99,  duration: 0.3),
            SKAction.scaleX(to: 0.985, y: 1.015, duration: 0.35),
            SKAction.scaleX(to: 1.0,   y: 1.0,   duration: 0.25),
        ]))
        sprite.run(squashStretch, withKey: "squash")

        // Långsam drift — bubblan flyter runt lite
        let drift = SKAction.repeatForever(SKAction.sequence([
            SKAction.moveBy(x: 12, y: 8, duration: 0.6),
            SKAction.moveBy(x: -8, y: 6, duration: 0.5),
            SKAction.moveBy(x: -10, y: -10, duration: 0.55),
            SKAction.moveBy(x: 6, y: -4, duration: 0.45),
        ]))
        sprite.run(drift, withKey: "drift")

        // Subtil rotation — bubblan snurrar sakta
        let rotate = SKAction.repeatForever(SKAction.sequence([
            SKAction.rotate(byAngle: 0.025, duration: 0.4),
            SKAction.rotate(byAngle: -0.05, duration: 0.8),
            SKAction.rotate(byAngle: 0.025, duration: 0.4),
        ]))
        sprite.run(rotate, withKey: "rotate")
    }

    func stopWobble() {
        currentSprite?.removeAction(forKey: "squash")
        currentSprite?.removeAction(forKey: "drift")
        currentSprite?.removeAction(forKey: "rotate")
    }

    // MARK: - Pop + Explosion (Tap 3)

    func pop(in scene: SKScene, completion: @escaping () -> Void) {
        guard let sprite = currentSprite else { completion(); return }
        stopWobble()

        // Fas 1: Snabb uppblåsning (0.1s)
        let tensionScale = SKAction.scale(to: 1.15, duration: 0.05)
        let pause        = SKAction.wait(forDuration: 0.05)

        // Fas 2: Explosion (0.3s)
        let burst = SKAction.run { [weak self] in
            self?.spawnParticles(at: sprite.position, in: scene)
        }
        let fadeBubble = SKAction.sequence([
            SKAction.fadeAlpha(to: 0, duration: 0.2),
            SKAction.removeFromParent()
        ])

        sprite.run(SKAction.sequence([tensionScale, pause, fadeBubble]))

        // Completion körs på BubbleNode (self), INTE på sprite —
        // annars dödas sekvensen när sprite tas bort med removeFromParent()
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.1),
            burst,
            SKAction.wait(forDuration: 19.0),  // Fyrverkeri + grand finale + massiv pion + encore + grand encore
            SKAction.wait(forDuration: 0.5),   // Lugn paus
            SKAction.run { completion() }
        ]))

        currentSprite = nil
    }

    // MARK: - Kinesiskt fyrverkeri (bubble_04 textur, bubbelfärger)

    private let bubbleW: CGFloat = 489
    private let bubbleH: CGFloat = 490

    private func spawnParticles(at center: CGPoint, in scene: SKScene) {
        let tex = SKTexture(imageNamed: "bubble_04")
        spawnFlash(in: scene)
        spawnExpandingRings(at: center, in: scene)
        spawnPeonyShells(at: center, in: scene, texture: tex)
        spawnWillowShells(at: center, in: scene, texture: tex)
        spawnCrossetteShells(at: center, in: scene, texture: tex)

        // Grand finale — avfyras sent när de flesta noder redan är borta
        run(SKAction.sequence([
            SKAction.wait(forDuration: 4.5),
            SKAction.run { [weak self] in
                self?.spawnGrandFinale(at: CGPoint(x: 1366, y: 1024), in: scene, texture: tex)
            }
        ]))

        // Massiv pion — centrerad jätteexplosion innan de spridda
        run(SKAction.sequence([
            SKAction.wait(forDuration: 7.0),
            SKAction.run { [weak self] in
                self?.spawnMassivePeony(at: CGPoint(x: 1366, y: 1024), in: scene, texture: tex)
            }
        ]))

        // Encore — 5 överraskningsexplosioner spridda över skärmen
        run(SKAction.sequence([
            SKAction.wait(forDuration: 9.5),
            SKAction.run { [weak self] in
                self?.spawnEncoreBursts(in: scene, texture: tex)
            }
        ]))

        // Grand encore — alla 5 sprickar upp IGEN, spridda över hela skärmen
        run(SKAction.sequence([
            SKAction.wait(forDuration: 13.0),
            SKAction.run { [weak self] in
                self?.spawnGrandEncore(in: scene, texture: tex)
            }
        ]))
    }

    // MARK: Blixt

    private func spawnFlash(in scene: SKScene) {
        let flash = SKSpriteNode(color: SKColor(red: 0.85, green: 0.95, blue: 1, alpha: 1),
                                 size: CGSize(width: 2732, height: 2048))
        flash.position = CGPoint(x: 1366, y: 1024)
        flash.zPosition = 100
        flash.alpha = 0
        scene.addChild(flash)
        flash.run(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.9, duration: 0.04),
            SKAction.fadeAlpha(to: 0, duration: 0.35),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: Expanderande bubbelringar — exploderar vid ytterkant

    private func spawnExpandingRings(at center: CGPoint, in scene: SKScene) {
        let tex = SKTexture(imageNamed: "bubble_04")
        for wave in 0..<3 {
            let delay = TimeInterval(wave) * 0.3
            let count = 10 + wave * 4
            let radius: CGFloat = 150 + CGFloat(wave) * 120
            let expandTo: CGFloat = 1800 + CGFloat(wave) * 500
            for i in 0..<count {
                let angle = CGFloat(i) * (.pi * 2 / CGFloat(count))
                let scale = CGFloat.random(in: 0.08...0.22)
                let b = SKSpriteNode(texture: tex, size: CGSize(width: bubbleW * scale, height: bubbleH * scale))
                b.position = CGPoint(x: center.x + cos(angle) * radius,
                                     y: center.y + sin(angle) * radius)
                b.zPosition = 85
                b.alpha = 0
                scene.addChild(b)

                let expandDur = TimeInterval.random(in: 0.8...1.3)
                let endR = expandTo + CGFloat.random(in: -100...100)
                let move = SKAction.customAction(withDuration: expandDur) { node, elapsed in
                    let p = elapsed / CGFloat(expandDur)
                    let r = radius + (endR - radius) * p
                    node.position.x = center.x + cos(angle) * r
                    node.position.y = center.y + sin(angle) * r
                }
                let appear = SKAction.fadeAlpha(to: CGFloat.random(in: 0.6...1.0), duration: 0.08)

                // Pop vid ytterkant → 3–5 småbubblor som sprids ut
                let pop = SKAction.run { [weak self, weak b] in
                    guard let self, let b, let scene = b.scene else { return }
                    let pos = b.position
                    self.spawnRingBurst(at: pos, baseAngle: angle, in: scene, texture: tex)
                }
                let popFade = SKAction.group([
                    SKAction.scale(to: 1.4, duration: 0.06),
                    SKAction.fadeOut(withDuration: 0.06)
                ])

                b.run(SKAction.sequence([
                    SKAction.wait(forDuration: delay),
                    appear,
                    move,
                    SKAction.group([pop, popFade]),
                    SKAction.removeFromParent()
                ]))
            }
        }
    }

    // Varje ring-bubbla exploderar i pion-mönster över hela skärmen
    private func spawnRingBurst(at origin: CGPoint, baseAngle: CGFloat,
                                in scene: SKScene, texture: SKTexture) {
        let gravity: CGFloat = -60
        let petalCount = Int.random(in: 6...10)
        for i in 0..<petalCount {
            let angle = CGFloat(i) * (.pi * 2 / CGFloat(petalCount)) + CGFloat.random(in: -0.3...0.3)
            let speed = CGFloat.random(in: 800...1800)
            let scale = CGFloat.random(in: 0.06...0.18)
            let petal = SKSpriteNode(texture: texture,
                                     size: CGSize(width: bubbleW * scale, height: bubbleH * scale))
            petal.position = origin
            petal.zPosition = 83
            petal.alpha = 0
            scene.addChild(petal)

            let dx = cos(angle) * speed
            let dy = sin(angle) * speed
            let duration = TimeInterval.random(in: 2.5...4.0)

            let move = SKAction.customAction(withDuration: duration) { node, elapsed in
                let t = elapsed
                node.position.x = origin.x + dx * t
                node.position.y = origin.y + dy * t + 0.5 * gravity * t * t
            }
            let appear = SKAction.fadeAlpha(to: CGFloat.random(in: 0.5...0.9), duration: 0.06)
            let fade = SKAction.sequence([
                SKAction.wait(forDuration: duration * 0.5),
                SKAction.fadeOut(withDuration: duration * 0.5)
            ])
            let spin = SKAction.rotate(byAngle: CGFloat.random(in: -3...3), duration: duration)
            petal.run(SKAction.sequence([
                appear,
                SKAction.group([move, fade, spin]),
                SKAction.removeFromParent()
            ]))
        }
    }

    // MARK: Pion-fyrverkerier (sfärisk burst → långsam kaskad)

    private func spawnPeonyShells(at center: CGPoint, in scene: SKScene, texture: SKTexture) {
        let gravity: CGFloat = -120
        for shell in 0..<6 {
            let delay = TimeInterval(shell) * 0.35
            let shellAngle = CGFloat.random(in: 0...(2 * .pi))
            let shellDist = CGFloat.random(in: 400...1100)
            let burstCenter = CGPoint(x: center.x + cos(shellAngle) * shellDist,
                                      y: center.y + sin(shellAngle) * shellDist + 200)
            let petalCount = Int.random(in: 16...24)

            for i in 0..<petalCount {
                let angle = CGFloat(i) * (.pi * 2 / CGFloat(petalCount)) + CGFloat.random(in: -0.12...0.12)
                let speed = CGFloat.random(in: 500...1000)
                let scale = CGFloat.random(in: 0.06...0.20)
                let b = SKSpriteNode(texture: texture, size: CGSize(width: bubbleW * scale, height: bubbleH * scale))
                b.position = burstCenter
                b.zPosition = 75
                b.alpha = 0
                scene.addChild(b)

                let dx = cos(angle) * speed
                let dy = sin(angle) * speed
                let duration = TimeInterval.random(in: 2.5...4.0)

                let move = SKAction.customAction(withDuration: duration) { node, elapsed in
                    let t = elapsed
                    node.position.x = burstCenter.x + dx * t
                    node.position.y = burstCenter.y + dy * t + 0.5 * gravity * t * t
                }
                let appear = SKAction.fadeAlpha(to: CGFloat.random(in: 0.6...1.0), duration: 0.08)
                let fade = SKAction.sequence([
                    SKAction.wait(forDuration: duration * 0.55),
                    SKAction.fadeOut(withDuration: duration * 0.45)
                ])
                let spin = SKAction.rotate(byAngle: CGFloat.random(in: -4...4), duration: duration)
                let trail = SKAction.run { [weak self] in
                    self?.spawnTrail(for: b, in: scene, texture: texture, duration: duration, gravity: gravity,
                                     origin: burstCenter, dx: dx, dy: dy)
                }

                b.run(SKAction.sequence([
                    SKAction.wait(forDuration: delay),
                    appear,
                    trail,
                    SKAction.group([move, fade, spin]),
                    SKAction.removeFromParent()
                ]))
            }
        }
    }

    // Glödande svans bakom varje pion-bubbla
    private func spawnTrail(for leader: SKSpriteNode, in scene: SKScene, texture: SKTexture,
                            duration: TimeInterval, gravity: CGFloat,
                            origin: CGPoint, dx: CGFloat, dy: CGFloat) {
        let trailCount = 2
        for i in 1...trailCount {
            let trailDelay = TimeInterval(i) * 0.15
            let scale = leader.xScale * CGFloat(1.0 - Double(i) * 0.25)
            guard scale > 0.01 else { continue }
            let ghost = SKSpriteNode(texture: texture,
                                     size: CGSize(width: bubbleW * scale, height: bubbleH * scale))
            ghost.position = origin
            ghost.zPosition = 72
            ghost.alpha = 0
            scene.addChild(ghost)

            let ghostDur = duration - trailDelay
            guard ghostDur > 0 else { ghost.removeFromParent(); continue }
            let move = SKAction.customAction(withDuration: ghostDur) { node, elapsed in
                let t = elapsed
                node.position.x = origin.x + dx * t
                node.position.y = origin.y + dy * t + 0.5 * gravity * t * t
            }
            let appear = SKAction.fadeAlpha(to: CGFloat(0.35 - Double(i) * 0.1), duration: 0.05)
            let fade = SKAction.sequence([
                SKAction.wait(forDuration: ghostDur * 0.3),
                SKAction.fadeOut(withDuration: ghostDur * 0.7)
            ])
            ghost.run(SKAction.sequence([
                SKAction.wait(forDuration: trailDelay),
                appear,
                SKAction.group([move, fade]),
                SKAction.removeFromParent()
            ]))
        }
    }

    // MARK: Pilträd-fyrverkerier (bågform, singlar ner långsamt)

    private func spawnWillowShells(at center: CGPoint, in scene: SKScene, texture: SKTexture) {
        let gravity: CGFloat = -160
        for shell in 0..<4 {
            let delay = TimeInterval(shell) * 0.35 + 0.15
            let shellX = center.x + CGFloat.random(in: -1200...1200)
            let shellY = center.y + CGFloat.random(in: -200...600)
            let burstCenter = CGPoint(x: shellX, y: shellY)
            let strandCount = Int.random(in: 18...28)

            for i in 0..<strandCount {
                let angle = CGFloat(i) * (.pi * 2 / CGFloat(strandCount)) + CGFloat.random(in: -0.1...0.1)
                let speed = CGFloat.random(in: 350...700)
                let scale = CGFloat.random(in: 0.04...0.14)
                let b = SKSpriteNode(texture: texture, size: CGSize(width: bubbleW * scale, height: bubbleH * scale))
                b.position = burstCenter
                b.zPosition = 70
                b.alpha = 0
                scene.addChild(b)

                let dx = cos(angle) * speed
                let dy = sin(angle) * speed * 0.7
                let duration = TimeInterval.random(in: 2.0...3.5)

                let move = SKAction.customAction(withDuration: duration) { node, elapsed in
                    let t = elapsed
                    node.position.x = burstCenter.x + dx * t
                    node.position.y = burstCenter.y + dy * t + 0.5 * gravity * t * t
                }
                let appear = SKAction.fadeAlpha(to: CGFloat.random(in: 0.4...0.8), duration: 0.1)
                let fade = SKAction.sequence([
                    SKAction.wait(forDuration: duration * 0.6),
                    SKAction.fadeOut(withDuration: duration * 0.4)
                ])
                b.run(SKAction.sequence([
                    SKAction.wait(forDuration: delay),
                    appear,
                    SKAction.group([move, fade]),
                    SKAction.removeFromParent()
                ]))
            }
        }
    }

    // MARK: Crossette-fyrverkerier (bubblor som delar sig)

    private func spawnCrossetteShells(at center: CGPoint, in scene: SKScene, texture: SKTexture) {
        let gravity: CGFloat = -200
        for shell in 0..<3 {
            let delay = TimeInterval(shell) * 0.6 + 0.1
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let dist = CGFloat.random(in: 500...1200)
            let splitPoint = CGPoint(x: center.x + cos(angle) * dist,
                                     y: center.y + sin(angle) * dist + 150)

            // Huvudbubbla flyger ut till splitpunkten
            let scale: CGFloat = CGFloat.random(in: 0.12...0.25)
            let main = SKSpriteNode(texture: texture, size: CGSize(width: bubbleW * scale, height: bubbleH * scale))
            main.position = center
            main.zPosition = 80
            main.alpha = 0
            scene.addChild(main)

            let flyDur: TimeInterval = 0.5
            let flyTo = SKAction.move(to: splitPoint, duration: flyDur)
            flyTo.timingMode = .easeOut
            let appear = SKAction.fadeAlpha(to: 0.9, duration: 0.08)

            let split = SKAction.run { [weak self] in
                self?.spawnCrossetteSplit(at: splitPoint, in: scene, texture: texture, gravity: gravity)
            }
            let popFade = SKAction.group([
                SKAction.scale(to: 1.4, duration: 0.06),
                SKAction.fadeOut(withDuration: 0.06)
            ])
            main.run(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                appear,
                flyTo,
                SKAction.group([split, popFade]),
                SKAction.removeFromParent()
            ]))
        }
    }

    private func spawnCrossetteSplit(at origin: CGPoint, in scene: SKScene,
                                     texture: SKTexture, gravity: CGFloat) {
        let arms = 4
        for arm in 0..<arms {
            let armAngle = CGFloat(arm) * (.pi / 2) + CGFloat.random(in: -0.2...0.2)
            let armSpeed = CGFloat.random(in: 600...1100)
            let dx = cos(armAngle) * armSpeed
            let dy = sin(armAngle) * armSpeed
            let splitDur: TimeInterval = 0.6

            // Varje arm splittar igen efter kort flygning
            let scale = CGFloat.random(in: 0.06...0.15)
            let armBubble = SKSpriteNode(texture: texture,
                                         size: CGSize(width: bubbleW * scale, height: bubbleH * scale))
            armBubble.position = origin
            armBubble.zPosition = 78
            scene.addChild(armBubble)

            let endX = origin.x + dx * CGFloat(splitDur)
            let endY = origin.y + dy * CGFloat(splitDur) + 0.5 * gravity * CGFloat(splitDur * splitDur)
            let endPt = CGPoint(x: endX, y: endY)

            let fly = SKAction.customAction(withDuration: splitDur) { node, elapsed in
                let t = elapsed
                node.position.x = origin.x + dx * t
                node.position.y = origin.y + dy * t + 0.5 * gravity * t * t
            }
            let finalSplit = SKAction.run { [weak self] in
                self?.spawnFinalDrizzle(at: endPt, in: scene, texture: texture)
            }
            let pop = SKAction.group([
                SKAction.scale(to: 1.3, duration: 0.05),
                SKAction.fadeOut(withDuration: 0.05)
            ])
            armBubble.run(SKAction.sequence([
                fly,
                SKAction.group([finalSplit, pop]),
                SKAction.removeFromParent()
            ]))
        }
    }

    // MARK: Grand Finale — kaskaderande explosioner (3 nivåer)

    private func spawnGrandFinale(at center: CGPoint, in scene: SKScene, texture: SKTexture) {
        // Blixt
        let flash = SKSpriteNode(color: SKColor(red: 0.9, green: 0.97, blue: 1, alpha: 1),
                                 size: CGSize(width: 2732, height: 2048))
        flash.position = center
        flash.zPosition = 100
        flash.alpha = 0
        scene.addChild(flash)
        flash.run(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.7, duration: 0.03),
            SKAction.fadeAlpha(to: 0, duration: 0.3),
            SKAction.removeFromParent()
        ]))

        // 3 ringar → varje bubbla kaskaderar 3 gånger
        let gravity: CGFloat = -100
        for ring in 0..<3 {
            let count = 14 + ring * 5
            let baseSpeed = CGFloat(300 + ring * 180)
            let delay = TimeInterval(ring) * 0.12
            for i in 0..<count {
                let angle = CGFloat(i) * (.pi * 2 / CGFloat(count)) + CGFloat.random(in: -0.05...0.05)
                let speed = baseSpeed + CGFloat.random(in: -40...40)
                let scale = CGFloat.random(in: 0.06...0.16)
                spawnCascadeBubble(at: center, in: scene, texture: texture,
                                   angle: angle, speed: speed, scale: scale,
                                   gravity: gravity, cascadesLeft: 3, delay: delay)
            }
        }
    }

    private func spawnCascadeBubble(at origin: CGPoint, in scene: SKScene, texture: SKTexture,
                                     angle: CGFloat, speed: CGFloat, scale: CGFloat,
                                     gravity: CGFloat, cascadesLeft: Int, delay: TimeInterval) {
        let b = SKSpriteNode(texture: texture,
                             size: CGSize(width: bubbleW * scale, height: bubbleH * scale))
        b.position = origin
        b.zPosition = CGFloat(85 - (3 - cascadesLeft))
        b.alpha = 0
        scene.addChild(b)

        let dx = cos(angle) * speed
        let dy = sin(angle) * speed
        let flyDuration = TimeInterval.random(in: 0.5...0.8)

        let fly = SKAction.customAction(withDuration: flyDuration) { node, elapsed in
            let t = elapsed
            node.position.x = origin.x + dx * t
            node.position.y = origin.y + dy * t + 0.5 * gravity * t * t
        }
        let appear = SKAction.fadeAlpha(to: CGFloat.random(in: 0.5...1.0), duration: 0.06)

        if cascadesLeft > 0 {
            let pop = SKAction.run { [weak self, weak b] in
                guard let self, let b, let scene = b.scene else { return }
                let pos = b.position
                let childCount = cascadesLeft > 1 ? 2 : 3
                for _ in 0..<childCount {
                    let childAngle = CGFloat.random(in: 0...(2 * .pi))
                    let childSpeed = speed * 0.65
                    let childScale = scale * 0.65
                    self.spawnCascadeBubble(at: pos, in: scene, texture: texture,
                                            angle: childAngle, speed: childSpeed,
                                            scale: childScale, gravity: gravity * 0.8,
                                            cascadesLeft: cascadesLeft - 1, delay: 0)
                }
            }
            let popFade = SKAction.group([
                SKAction.scale(to: 1.3, duration: 0.06),
                SKAction.fadeOut(withDuration: 0.06)
            ])
            b.run(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                appear,
                fly,
                SKAction.group([pop, popFade]),
                SKAction.removeFromParent()
            ]))
        } else {
            // Sista nivån: singla ner långsamt
            let drift = SKAction.customAction(withDuration: 2.0) { node, elapsed in
                let t = elapsed
                node.position.x = origin.x + dx * 0.3 * t
                node.position.y = origin.y + dy * 0.3 * t + 0.5 * (-50) * t * t
            }
            let fade = SKAction.sequence([
                SKAction.wait(forDuration: 1.2),
                SKAction.fadeOut(withDuration: 0.8)
            ])
            b.run(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                appear,
                fly,
                SKAction.group([drift, fade]),
                SKAction.removeFromParent()
            ]))
        }
    }

    // MARK: Encore — 5 överraskningsexplosioner spridda över skärmen

    private func spawnEncoreBursts(in scene: SKScene, texture: SKTexture) {
        let positions: [CGPoint] = [
            CGPoint(x: 300,  y: 1700),   // uppe vänster
            CGPoint(x: 2400, y: 1700),   // uppe höger
            CGPoint(x: 1366, y: 400),    // nere mitten
            CGPoint(x: 400,  y: 700),    // nere vänster
            CGPoint(x: 2300, y: 400),    // nere höger
        ]
        let gravity: CGFloat = -70
        for (i, pos) in positions.enumerated() {
            let delay = TimeInterval(i) * 0.6

            // 12 bubblor med 2 kaskadnivåer
            for j in 0..<12 {
                let angle = CGFloat(j) * (.pi * 2 / 12) + CGFloat.random(in: -0.1...0.1)
                let speed = CGFloat.random(in: 400...800)
                let scale = CGFloat.random(in: 0.05...0.14)
                spawnCascadeBubble(at: pos, in: scene, texture: texture,
                                   angle: angle, speed: speed, scale: scale,
                                   gravity: gravity, cascadesLeft: 2, delay: delay)
            }
        }
    }

    // MARK: Massiv pion — centrerad jätteexplosion

    private func spawnMassivePeony(at center: CGPoint, in scene: SKScene, texture: SKTexture) {
        // Stor blixt
        let flash = SKSpriteNode(color: SKColor(red: 1.0, green: 0.95, blue: 0.85, alpha: 1),
                                 size: CGSize(width: 2732, height: 2048))
        flash.position = center
        flash.zPosition = 100
        flash.alpha = 0
        scene.addChild(flash)
        flash.run(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.85, duration: 0.04),
            SKAction.fadeAlpha(to: 0.3, duration: 0.15),
            SKAction.fadeAlpha(to: 0, duration: 0.4),
            SKAction.removeFromParent()
        ]))

        // 4 vågor med ökande radie — massiv sfärisk explosion
        let gravity: CGFloat = -80
        let waves: [(count: Int, speed: CGFloat, delay: TimeInterval, cascades: Int)] = [
            (count: 28, speed: 600,  delay: 0.0,  cascades: 3),   // inre kärna — tät
            (count: 36, speed: 900,  delay: 0.06, cascades: 3),   // mellanring
            (count: 44, speed: 1200, delay: 0.12, cascades: 2),   // yttre ring — massiv
            (count: 20, speed: 1500, delay: 0.18, cascades: 2),   // extremring — skärmfyllande
        ]

        for wave in waves {
            for i in 0..<wave.count {
                let angle = CGFloat(i) * (.pi * 2 / CGFloat(wave.count)) + CGFloat.random(in: -0.08...0.08)
                let speed = wave.speed + CGFloat.random(in: -60...60)
                let scale = CGFloat.random(in: 0.08...0.22)

                // Pion-bubbla med trail
                let b = SKSpriteNode(texture: texture,
                                     size: CGSize(width: bubbleW * scale, height: bubbleH * scale))
                b.position = center
                b.zPosition = 80
                b.alpha = 0
                scene.addChild(b)

                let dx = cos(angle) * speed
                let dy = sin(angle) * speed
                let duration = TimeInterval.random(in: 2.8...4.5)

                let move = SKAction.customAction(withDuration: duration) { node, elapsed in
                    let t = elapsed
                    node.position.x = center.x + dx * t
                    node.position.y = center.y + dy * t + 0.5 * gravity * t * t
                }
                let appear = SKAction.fadeAlpha(to: CGFloat.random(in: 0.7...1.0), duration: 0.06)
                let fade = SKAction.sequence([
                    SKAction.wait(forDuration: duration * 0.5),
                    SKAction.fadeOut(withDuration: duration * 0.5)
                ])
                let spin = SKAction.rotate(byAngle: CGFloat.random(in: -5...5), duration: duration)
                let trail = SKAction.run { [weak self] in
                    self?.spawnTrail(for: b, in: scene, texture: texture, duration: duration,
                                     gravity: gravity, origin: center, dx: dx, dy: dy)
                }

                // Kaskad vid slutet
                if wave.cascades > 0 {
                    let cascadePop = SKAction.run { [weak self] in
                        guard let self, let scene = b.scene else { return }
                        let pos = b.position
                        for _ in 0..<3 {
                            let childAngle = CGFloat.random(in: 0...(2 * .pi))
                            let childSpeed = speed * 0.5
                            let childScale = scale * 0.6
                            self.spawnCascadeBubble(at: pos, in: scene, texture: texture,
                                                    angle: childAngle, speed: childSpeed,
                                                    scale: childScale, gravity: gravity * 0.7,
                                                    cascadesLeft: wave.cascades - 1, delay: 0)
                        }
                    }
                    b.run(SKAction.sequence([
                        SKAction.wait(forDuration: wave.delay),
                        appear, trail,
                        SKAction.group([move, fade, spin]),
                        cascadePop,
                        SKAction.removeFromParent()
                    ]))
                } else {
                    b.run(SKAction.sequence([
                        SKAction.wait(forDuration: wave.delay),
                        appear, trail,
                        SKAction.group([move, fade, spin]),
                        SKAction.removeFromParent()
                    ]))
                }
            }
        }
    }

    // MARK: Grand encore — alla 5 positioner sprickar IGEN, spridda över hela skärmen

    private func spawnGrandEncore(in scene: SKScene, texture: SKTexture) {
        // Blixt
        let flash = SKSpriteNode(color: SKColor(red: 0.92, green: 0.88, blue: 1.0, alpha: 1),
                                 size: CGSize(width: 2732, height: 2048))
        flash.position = CGPoint(x: 1366, y: 1024)
        flash.zPosition = 100
        flash.alpha = 0
        scene.addChild(flash)
        flash.run(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.6, duration: 0.04),
            SKAction.fadeAlpha(to: 0, duration: 0.5),
            SKAction.removeFromParent()
        ]))

        // Fler positioner nu — sprids över HELA skärmen
        let positions: [CGPoint] = [
            CGPoint(x: 300,  y: 1700),
            CGPoint(x: 2400, y: 1700),
            CGPoint(x: 1366, y: 400),
            CGPoint(x: 400,  y: 700),
            CGPoint(x: 2300, y: 400),
            CGPoint(x: 1366, y: 1500),  // topp mitten
            CGPoint(x: 700,  y: 1200),  // vänster mitt
            CGPoint(x: 2000, y: 1200),  // höger mitt
        ]

        let gravity: CGFloat = -60
        // Alla smäller nästan samtidigt — liten fördröjning för dramatik
        for (i, pos) in positions.enumerated() {
            let delay = TimeInterval(i) * 0.15

            // Lokal rund blixt-puff vid varje position
            let puffShape = SKShapeNode(circleOfRadius: 150)
            puffShape.fillColor = SKColor(red: 1, green: 1, blue: 0.95, alpha: 0.6)
            puffShape.strokeColor = .clear
            puffShape.position = pos
            puffShape.zPosition = 90
            puffShape.alpha = 0
            scene.addChild(puffShape)
            puffShape.run(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.fadeAlpha(to: 0.7, duration: 0.03),
                SKAction.group([
                    SKAction.scale(to: 3.0, duration: 0.3),
                    SKAction.fadeAlpha(to: 0, duration: 0.3)
                ]),
                SKAction.removeFromParent()
            ]))

            // 18 bubblor per position — riklig spridning
            let count = 18
            for j in 0..<count {
                let angle = CGFloat(j) * (.pi * 2 / CGFloat(count)) + CGFloat.random(in: -0.15...0.15)
                let speed = CGFloat.random(in: 500...1100)
                let scale = CGFloat.random(in: 0.06...0.18)
                spawnCascadeBubble(at: pos, in: scene, texture: texture,
                                   angle: angle, speed: speed, scale: scale,
                                   gravity: gravity, cascadesLeft: 2, delay: delay)
            }
        }

        // Finalt duggregn från mitten
        run(SKAction.sequence([
            SKAction.wait(forDuration: 2.5),
            SKAction.run { [weak self] in
                self?.spawnFinalDrizzle(at: CGPoint(x: 1366, y: 1500), in: scene, texture: texture)
                self?.spawnFinalDrizzle(at: CGPoint(x: 600, y: 1400), in: scene, texture: texture)
                self?.spawnFinalDrizzle(at: CGPoint(x: 2100, y: 1400), in: scene, texture: texture)
            }
        ]))
    }

    // Sista duggregnet — mikrobubblor som singlar långsamt ner
    private func spawnFinalDrizzle(at origin: CGPoint, in scene: SKScene, texture: SKTexture) {
        let gravity: CGFloat = -80
        for _ in 0..<Int.random(in: 8...14) {
            let scale = CGFloat.random(in: 0.02...0.06)
            let drop = SKSpriteNode(texture: texture,
                                    size: CGSize(width: bubbleW * scale, height: bubbleH * scale))
            drop.position = origin
            drop.zPosition = 65
            drop.alpha = CGFloat.random(in: 0.4...0.8)
            scene.addChild(drop)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 60...180)
            let dx = cos(angle) * speed
            let dy = sin(angle) * speed
            let duration = TimeInterval.random(in: 2.5...4.5)

            let move = SKAction.customAction(withDuration: duration) { node, elapsed in
                let t = elapsed
                node.position.x = origin.x + dx * t
                node.position.y = origin.y + dy * t + 0.5 * gravity * t * t
            }
            let fade = SKAction.sequence([
                SKAction.wait(forDuration: duration * 0.65),
                SKAction.fadeOut(withDuration: duration * 0.35)
            ])
            drop.run(SKAction.sequence([
                SKAction.group([move, fade]),
                SKAction.removeFromParent()
            ]))
        }
    }
}
