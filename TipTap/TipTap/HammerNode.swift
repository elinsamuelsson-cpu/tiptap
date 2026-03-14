import SpriteKit

class HammerNode: SKSpriteNode {

    // MARK: - Init

    convenience init() {
        let texture = SKTexture(imageNamed: "hammer1")
        self.init(texture: texture, color: .clear, size: texture.size())
        isUserInteractionEnabled = false
        alpha = 0
    }

    // MARK: - Peek-a-boo (toolbox → fall → bounce → grow → tittut → center)

    func peekABoo(from origin: CGPoint, to center: CGPoint) {
        removeAllActions()

        // Startar pyttliten inne i toolboxen
        position = origin
        alpha = 0
        zRotation = 0
        setScale(0.08)
        anchorPoint = CGPoint(x: 0.5, y: 0.5)

        // Landningsplats — nedre delen av rummet
        let floorY: CGFloat = 500
        let landX = origin.x + CGFloat.random(in: -100...100)

        // ── Fas 1: Ramlar ut ur toolboxen ──

        // Tippar ut ur lådan med en liten snurr
        let tumbleOut = SKAction.group([
            SKAction.fadeAlpha(to: 1.0, duration: 0.1),
            SKAction.moveBy(x: 20, y: 40, duration: 0.15),
            SKAction.rotate(byAngle: 0.5, duration: 0.15),
            SKAction.scale(to: 0.12, duration: 0.15)
        ])
        tumbleOut.timingMode = .easeOut

        // ── Fas 2: Faller ner — växer från pyttliten till full storlek under fallet ──

        let fallDist = origin.y + 40 - floorY
        let fallDuration: TimeInterval = 0.8
        let fall = SKAction.customAction(withDuration: fallDuration) { node, elapsed in
            let t = elapsed / CGFloat(fallDuration)
            let easedT = t * t  // gravitation
            let startX = origin.x + 20
            let startY = origin.y + 40
            node.position.x = startX + (landX - startX) * t
            node.position.y = startY - fallDist * easedT
        }
        let fallSpin = SKAction.rotate(byAngle: .pi * 3, duration: fallDuration)
        // Växer under hela fallet: 0.12 → 0.5
        let fallGrow = SKAction.scale(to: 0.5, duration: fallDuration)
        fallGrow.timingMode = .easeIn

        let fallGroup = SKAction.group([fall, fallSpin, fallGrow])

        // ── Fas 3: Studsar på golvet — full storlek nu ──

        let bounce1 = makeBounce(height: 180, horizontalDrift: 60, duration: 0.35, spinAngle: .pi * 1.5)
        let bounce2 = makeBounce(height: 90, horizontalDrift: -40, duration: 0.28, spinAngle: .pi)
        let bounce3 = makeBounce(height: 35, horizontalDrift: 20, duration: 0.2, spinAngle: .pi * 0.5)

        // Landar plant — squash i full storlek
        let landSquash = SKAction.sequence([
            SKAction.rotate(toAngle: 0, duration: 0.06),
            SKAction.group([
                SKAction.scaleX(to: 0.65, duration: 0.04),
                SKAction.scaleY(to: 0.35, duration: 0.04)
            ]),
            SKAction.group([
                SKAction.scaleX(to: 0.45, duration: 0.06),
                SKAction.scaleY(to: 0.55, duration: 0.06)
            ]),
            SKAction.group([
                SKAction.scaleX(to: 0.5, duration: 0.04),
                SKAction.scaleY(to: 0.5, duration: 0.04)
            ])
        ])

        // Kort paus — "aj..."
        let restPause = SKAction.wait(forDuration: 0.4)

        // ── Fas 4: Vaknar till liv — redan stor, skakar av sig ──

        let wakeShake = SKAction.sequence([
            SKAction.rotate(toAngle: 0.15, duration: 0.06),
            SKAction.rotate(toAngle: -0.15, duration: 0.08),
            SKAction.rotate(toAngle: 0.1, duration: 0.06),
            SKAction.rotate(toAngle: -0.05, duration: 0.05),
            SKAction.rotate(toAngle: 0, duration: 0.04)
        ])

        // ── Fas 5: Tittut-lek! Hammaren visar vad den kan ──

        // Impact-effekt vid varje slag
        let spawnImpact = SKAction.run { [weak self] in
            self?.spawnStrikeEffect()
        }

        // Hammarslag — lyft → BANG ner → impact-effekt → studs
        let hammerStrike = SKAction.sequence([
            SKAction.rotate(toAngle: 0.6, duration: 0.08),
            SKAction.rotate(toAngle: -0.15, duration: 0.03),
            spawnImpact,
            SKAction.moveBy(x: 0, y: -8, duration: 0.02),
            SKAction.moveBy(x: 0, y: 8, duration: 0.04),
            SKAction.rotate(toAngle: 0, duration: 0.05)
        ])

        // Dubbel-slag
        let spawnImpact2 = SKAction.run { [weak self] in
            self?.spawnStrikeEffect()
        }
        let spawnImpact3 = SKAction.run { [weak self] in
            self?.spawnStrikeEffect()
        }
        let doubleStrike = SKAction.sequence([
            SKAction.rotate(toAngle: 0.5, duration: 0.06),
            SKAction.rotate(toAngle: -0.12, duration: 0.03),
            spawnImpact2,
            SKAction.moveBy(x: 0, y: -6, duration: 0.02),
            SKAction.moveBy(x: 0, y: 6, duration: 0.03),
            SKAction.rotate(toAngle: 0.45, duration: 0.05),
            SKAction.rotate(toAngle: -0.1, duration: 0.03),
            spawnImpact3,
            SKAction.moveBy(x: 0, y: -6, duration: 0.02),
            SKAction.moveBy(x: 0, y: 6, duration: 0.03),
            SKAction.rotate(toAngle: 0, duration: 0.04)
        ])

        // Trippel-slag — varje slag hårdare med fler effekter
        let spawnImpact4 = SKAction.run { [weak self] in
            self?.spawnStrikeEffect()
        }
        let spawnImpact5 = SKAction.run { [weak self] in
            self?.spawnStrikeEffect()
        }
        let spawnImpact6 = SKAction.run { [weak self] in
            self?.spawnStrikeEffect(big: true)
        }
        let tripleStrike = SKAction.sequence([
            SKAction.rotate(toAngle: 0.4, duration: 0.05),
            SKAction.rotate(toAngle: -0.1, duration: 0.025),
            spawnImpact4,
            SKAction.moveBy(x: 0, y: -5, duration: 0.02),
            SKAction.moveBy(x: 0, y: 5, duration: 0.02),
            SKAction.rotate(toAngle: 0.5, duration: 0.05),
            SKAction.rotate(toAngle: -0.15, duration: 0.025),
            spawnImpact5,
            SKAction.moveBy(x: 0, y: -7, duration: 0.02),
            SKAction.moveBy(x: 0, y: 7, duration: 0.02),
            SKAction.rotate(toAngle: 0.65, duration: 0.05),
            SKAction.rotate(toAngle: -0.2, duration: 0.03),
            spawnImpact6,
            SKAction.moveBy(x: 0, y: -10, duration: 0.02),
            SKAction.moveBy(x: 0, y: 10, duration: 0.03),
            SKAction.rotate(toAngle: 0, duration: 0.04)
        ])

        // Tittut #1 — hoppar åt vänster, hamrar!
        let peek1Jump = SKAction.group([
            SKAction.scale(to: 0.55, duration: 0.2),
            SKAction.moveBy(x: -120, y: 220, duration: 0.2)
        ])
        peek1Jump.timingMode = .easeOut

        let peek1Hold = SKAction.wait(forDuration: 0.1)

        // Duckar ner
        let hide1 = SKAction.group([
            SKAction.scale(to: 0.45, duration: 0.15),
            SKAction.moveBy(x: 120, y: -220, duration: 0.15)
        ])
        hide1.timingMode = .easeIn

        let pause1 = SKAction.wait(forDuration: 0.25)

        // Tittut #2 — hoppar åt höger, dubbel-slag!
        let peek2Jump = SKAction.group([
            SKAction.scale(to: 0.6, duration: 0.2),
            SKAction.moveBy(x: 140, y: 300, duration: 0.2)
        ])
        peek2Jump.timingMode = .easeOut

        let peek2Hold = SKAction.wait(forDuration: 0.08)

        // Duckar ner
        let hide2 = SKAction.group([
            SKAction.scale(to: 0.48, duration: 0.15),
            SKAction.moveBy(x: -140, y: -300, duration: 0.15)
        ])
        hide2.timingMode = .easeIn

        let pause2 = SKAction.wait(forDuration: 0.2)

        // Tittut #3 — snabb titt, trippel-slag! "Kolla vad jag kan!"
        let peek3 = SKAction.group([
            SKAction.scale(to: 0.55, duration: 0.1),
            SKAction.moveBy(x: 0, y: 150, duration: 0.1)
        ])
        peek3.timingMode = .easeOut

        let hide3 = SKAction.group([
            SKAction.scale(to: 0.5, duration: 0.08),
            SKAction.moveBy(x: 0, y: -150, duration: 0.08)
        ])
        hide3.timingMode = .easeIn

        let pause3 = SKAction.wait(forDuration: 0.12)

        // ── Fas 6: HOPP till mitten av skärmen ──

        // Kraftfull avfärd
        let launchUp = SKAction.group([
            SKAction.scale(to: 0.65, duration: 0.1),
            SKAction.moveBy(x: 0, y: 120, duration: 0.1)
        ])
        launchUp.timingMode = .easeOut

        // Båge via toppen
        let arcTop = CGPoint(x: (landX + center.x) / 2,
                             y: max(floorY, center.y) + 400)

        let jumpArc1 = SKAction.group([
            SKAction.move(to: arcTop, duration: 0.3),
            SKAction.scale(to: 0.85, duration: 0.3),
            SKAction.rotate(byAngle: .pi * 2, duration: 0.3)
        ])
        jumpArc1.timingMode = .easeOut

        let jumpArc2 = SKAction.group([
            SKAction.move(to: center, duration: 0.3),
            SKAction.scale(to: 1.1, duration: 0.3),
            SKAction.rotate(byAngle: .pi, duration: 0.3)
        ])
        jumpArc2.timingMode = .easeIn

        // ── Fas 7: Landning centriskt — squash & stretch ──

        let spawnLandImpact = SKAction.run { [weak self] in
            guard let self, let scene = self.parent?.scene else { return }
            let landOrigin = CGPoint(x: scene.frame.midX - 750, y: scene.frame.height * 0.66)
            self.spawnStrikeEffect(big: true, customOrigin: landOrigin)
        }
        let land = SKAction.sequence([
            spawnLandImpact,
            SKAction.group([
                SKAction.scaleX(to: 1.3, duration: 0.06),
                SKAction.scaleY(to: 0.75, duration: 0.06),
                SKAction.rotate(toAngle: 0, duration: 0.06)
            ]),
            SKAction.group([
                SKAction.scaleX(to: 0.85, duration: 0.08),
                SKAction.scaleY(to: 1.15, duration: 0.08)
            ]),
            SKAction.group([
                SKAction.scaleX(to: 1.08, duration: 0.06),
                SKAction.scaleY(to: 0.92, duration: 0.06),
                SKAction.moveBy(x: 0, y: -15, duration: 0.06)
            ]),
            SKAction.group([
                SKAction.scaleX(to: 0.95, duration: 0.06),
                SKAction.scaleY(to: 1.05, duration: 0.06),
                SKAction.moveBy(x: 0, y: 15, duration: 0.06)
            ]),
            SKAction.group([
                SKAction.scaleX(to: 1.0, duration: 0.05),
                SKAction.scaleY(to: 1.0, duration: 0.05)
            ])
        ])

        // ── Fas 8: Glad dans ──

        let happyWiggle = SKAction.sequence([
            SKAction.rotate(toAngle: 0.15, duration: 0.07),
            SKAction.rotate(toAngle: -0.15, duration: 0.07),
            SKAction.rotate(toAngle: 0.1, duration: 0.06),
            SKAction.rotate(toAngle: -0.1, duration: 0.06),
            SKAction.rotate(toAngle: 0.05, duration: 0.05),
            SKAction.rotate(toAngle: -0.05, duration: 0.05),
            SKAction.rotate(toAngle: 0, duration: 0.04)
        ])

        let miniHop1 = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 25, duration: 0.1),
            SKAction.moveBy(x: 0, y: -25, duration: 0.08)
        ])
        miniHop1.timingMode = .easeOut

        let miniHop2 = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 18, duration: 0.08),
            SKAction.moveBy(x: 0, y: -18, duration: 0.07)
        ])
        miniHop2.timingMode = .easeOut

        let celebration = SKAction.sequence([
            happyWiggle, miniHop1,
            SKAction.wait(forDuration: 0.08),
            miniHop2
        ])

        // ── Fas 9: Idle ──

        let startIdle = SKAction.run { [weak self] in
            self?.startIdleVibration()
        }

        // ── Hela sekvensen ──

        run(SKAction.sequence([
            // Ramlar ut och växer under fallet
            tumbleOut, fallGroup,
            // Studsar i full storlek
            bounce1, bounce2, bounce3, landSquash,
            // Vaknar — redan stor
            restPause, wakeShake,
            // Tittut-lek med hammarslag
            peek1Jump, peek1Hold, hammerStrike, hide1, pause1,
            peek2Jump, peek2Hold, doubleStrike, hide2, pause2,
            peek3, tripleStrike, hide3, pause3,
            // Flyger till mitten
            launchUp, jumpArc1, jumpArc2,
            land, celebration, startIdle
        ]), withKey: "peekABoo")
    }

    // MARK: - Bounce Helper

    /// Skapar en parabolisk studs med snurr.
    private func makeBounce(height: CGFloat, horizontalDrift: CGFloat,
                            duration: TimeInterval, spinAngle: CGFloat) -> SKAction {
        let upPhase = SKAction.moveBy(x: horizontalDrift * 0.5, y: height, duration: duration * 0.45)
        upPhase.timingMode = .easeOut
        let downPhase = SKAction.moveBy(x: horizontalDrift * 0.5, y: -height, duration: duration * 0.55)
        downPhase.timingMode = .easeIn
        let arc = SKAction.sequence([upPhase, downPhase])
        let spin = SKAction.rotate(byAngle: spinAngle, duration: duration)

        return SKAction.group([arc, spin])
    }

    // MARK: - Idle Vibration

    private func startIdleVibration() {
        let shake = SKAction.sequence([
            SKAction.moveBy(x: 2, y: 1, duration: 0.05),
            SKAction.moveBy(x: -3, y: -1.5, duration: 0.07),
            SKAction.moveBy(x: 2.5, y: 1, duration: 0.06),
            SKAction.moveBy(x: -1.5, y: -0.5, duration: 0.05)
        ])
        run(SKAction.repeatForever(shake), withKey: "idleShake")

        let breatheUp = SKAction.scale(to: 1.02, duration: 1.2)
        breatheUp.timingMode = .easeInEaseOut
        let breatheDown = SKAction.scale(to: 0.98, duration: 1.2)
        breatheDown.timingMode = .easeInEaseOut
        run(SKAction.repeatForever(SKAction.sequence([breatheUp, breatheDown])), withKey: "idleBreathe")

        let tiltLeft = SKAction.rotate(toAngle: 0.04, duration: 1.5)
        tiltLeft.timingMode = .easeInEaseOut
        let tiltRight = SKAction.rotate(toAngle: -0.04, duration: 1.5)
        tiltRight.timingMode = .easeInEaseOut
        run(SKAction.repeatForever(SKAction.sequence([tiltLeft, tiltRight])), withKey: "idleTilt")
    }

    // MARK: - Strike Effect (strålar från hammarens topp)

    /// Beräknar näbbens position i parent-koordinater.
    private func tipPosition() -> CGPoint {
        let tipLocal = CGPoint(x: 0, y: size.height * 0.45 * yScale)
        let cosA = cos(zRotation)
        let sinA = sin(zRotation)
        return CGPoint(x: position.x + tipLocal.x * cosA - tipLocal.y * sinA,
                       y: position.y + tipLocal.x * sinA + tipLocal.y * cosA)
    }

    private func spawnStrikeEffect(big: Bool = false, customOrigin: CGPoint? = nil) {
        guard let parent = self.parent, let scene = parent.scene else { return }

        let origin: CGPoint
        if let custom = customOrigin {
            origin = custom
        } else {
            let tip = tipPosition()
            origin = CGPoint(x: tip.x - 250 - 200 - 150, y: tip.y - 200)
        }

        // Helskärmsblixt — hela skärmen blixtar vitt!
        let flash = SKSpriteNode(color: .white,
                                 size: CGSize(width: scene.frame.width, height: scene.frame.height))
        flash.position = CGPoint(x: scene.frame.midX, y: scene.frame.midY)
        flash.zPosition = 999
        flash.alpha = 0
        parent.addChild(flash)

        flash.run(SKAction.sequence([
            // BLIXT! BLIXT! BLIXT!
            SKAction.fadeAlpha(to: 0.4, duration: 0.02),
            SKAction.fadeAlpha(to: 0.0, duration: 0.03),
            SKAction.fadeAlpha(to: 0.3, duration: 0.02),
            SKAction.fadeAlpha(to: 0.0, duration: 0.04),
            SKAction.fadeAlpha(to: 0.2, duration: 0.02),
            SKAction.fadeOut(withDuration: 0.06),
            SKAction.removeFromParent()
        ]))
        let count = big ? 18 : 14

        // Triangelstrålar — tjock bas vid epicentrum, smalnar av till spets
        let path = CGMutablePath()
        for _ in 0..<count {
            let angle = CGFloat.random(in: 0...(.pi * 2))
            let length = CGFloat.random(in: 1400...1800)
            let baseWidth = CGFloat.random(in: big ? 8...18 : 5...12)

            // Triangelns tre hörn: två vid basen, ett vid spetsen
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
        rays.fillColor = UIColor(white: 1.0, alpha: big ? 0.3 : 0.2)
        rays.strokeColor = .clear
        rays.glowWidth = big ? 3 : 1.5
        rays.zPosition = 1
        rays.alpha = 0
        parent.addChild(rays)

        let fadeDur = big ? 1.2 : 0.9
        rays.run(SKAction.sequence([
            // BOOM 1 — full kraft, skärmen exploderar
            SKAction.fadeAlpha(to: 1.0, duration: 0.02),
            SKAction.fadeAlpha(to: 0.0, duration: 0.03),
            // BOOM 2 — smäller till igen
            SKAction.fadeAlpha(to: 1.0, duration: 0.02),
            SKAction.fadeAlpha(to: 0.0, duration: 0.04),
            // BOOM 3 — tredje vågen
            SKAction.fadeAlpha(to: big ? 1.0 : 0.85, duration: 0.02),
            SKAction.fadeAlpha(to: 0.05, duration: 0.05),
            // Efterglöd — snabba flimmer
            SKAction.fadeAlpha(to: big ? 0.7 : 0.5, duration: 0.02),
            SKAction.fadeAlpha(to: 0.1, duration: 0.03),
            SKAction.fadeAlpha(to: big ? 0.5 : 0.35, duration: 0.02),
            SKAction.fadeAlpha(to: 0.05, duration: 0.04),
            SKAction.fadeAlpha(to: big ? 0.35 : 0.2, duration: 0.02),
            // Tonar ut
            SKAction.fadeOut(withDuration: fadeDur),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Comeback (efter portrait)

    func comebackSpin(at center: CGPoint) {
        removeAllActions()
        position = center
        setScale(1.0)
        zRotation = 0
        alpha = 0

        run(SKAction.sequence([
            // Dyker upp
            SKAction.fadeAlpha(to: 1.0, duration: 0.05),

            // Snurr!
            SKAction.rotate(byAngle: .pi * 2, duration: 0.3),

            // Några snabba hammarslag
            SKAction.rotate(toAngle: 0.5, duration: 0.06),
            SKAction.rotate(toAngle: -0.12, duration: 0.03),
            SKAction.run { [weak self] in self?.spawnStrikeEffect() },
            SKAction.moveBy(x: 0, y: -6, duration: 0.02),
            SKAction.moveBy(x: 0, y: 6, duration: 0.03),
            SKAction.rotate(toAngle: 0.4, duration: 0.05),
            SKAction.rotate(toAngle: -0.1, duration: 0.03),
            SKAction.run { [weak self] in self?.spawnStrikeEffect() },
            SKAction.moveBy(x: 0, y: -5, duration: 0.02),
            SKAction.moveBy(x: 0, y: 5, duration: 0.03),
            SKAction.rotate(toAngle: 0, duration: 0.04),

            // Lugnar ner sig
            SKAction.wait(forDuration: 0.2),

            // Tillbaka till idle
            SKAction.run { [weak self] in self?.startIdleVibration() }
        ]), withKey: "comeback")
    }

    /// Dyker upp efter flash, vinkar hejdå, studsar nyckfullt tillbaka till toolbox
    func waveBye(at center: CGPoint, toolboxPos: CGPoint, completion: @escaping () -> Void) {
        removeAllActions()
        position = center
        setScale(1.0)
        zRotation = 0
        alpha = 0

        let midX = (center.x + toolboxPos.x) / 2
        let floorY = toolboxPos.y + 200

        run(SKAction.sequence([
            // Dyker upp
            SKAction.fadeAlpha(to: 1.0, duration: 0.05),

            // Snurr!
            SKAction.rotate(byAngle: .pi * 2, duration: 0.3),

            // Knackning — tippa upp, slå ner, stråleffekt, liten studs
            SKAction.rotate(toAngle: 0.6, duration: 0.08),
            SKAction.rotate(toAngle: -0.15, duration: 0.03),
            SKAction.run { [weak self] in self?.spawnStrikeEffect(big: true) },
            SKAction.moveBy(x: 0, y: -8, duration: 0.02),
            SKAction.moveBy(x: 0, y: 8, duration: 0.04),
            SKAction.rotate(toAngle: 0, duration: 0.05),

            SKAction.wait(forDuration: 0.25),

            // Studs 1 — stor båge snett ner mot toolbox
            SKAction.group([
                SKAction.moveTo(x: midX, duration: 0.35),
                SKAction.sequence([
                    SKAction.moveBy(x: 0, y: 120, duration: 0.15),
                    SKAction.moveTo(y: floorY, duration: 0.20)
                ]),
                SKAction.scale(to: 0.55, duration: 0.35),
                SKAction.rotate(byAngle: .pi * 2, duration: 0.35)
            ]),

            // Studs 2 — mindre båge
            SKAction.group([
                SKAction.moveTo(x: toolboxPos.x + 30, duration: 0.25),
                SKAction.sequence([
                    SKAction.moveBy(x: 0, y: 80, duration: 0.10),
                    SKAction.moveTo(y: floorY, duration: 0.15)
                ]),
                SKAction.scale(to: 0.30, duration: 0.25),
                SKAction.rotate(byAngle: .pi * 1.5, duration: 0.25)
            ]),

            // Studs 3 — liten piruett ovanför toolbox
            SKAction.group([
                SKAction.moveTo(x: toolboxPos.x, duration: 0.18),
                SKAction.sequence([
                    SKAction.moveBy(x: 0, y: 40, duration: 0.08),
                    SKAction.moveTo(y: toolboxPos.y + 50, duration: 0.10)
                ]),
                SKAction.scale(to: 0.12, duration: 0.18),
                SKAction.rotate(byAngle: .pi, duration: 0.18)
            ]),

            // Dyker ner i lådan
            SKAction.group([
                SKAction.move(to: toolboxPos, duration: 0.12),
                SKAction.scale(to: 0.05, duration: 0.12),
                SKAction.fadeOut(withDuration: 0.12)
            ]),

            SKAction.run { completion() }
        ]), withKey: "waveBye")
    }

    // MARK: - Strike and Return to Toolbox

    /// Dyker upp stor, slår, studsar ner, krymper, hoppar tillbaka till toolbox.
    func strikeAndReturn(at center: CGPoint, toolboxPos: CGPoint, completion: @escaping () -> Void) {
        removeAllActions()
        position = center
        setScale(1.0)
        zRotation = 0
        alpha = 0

        let floorY: CGFloat = 500
        let landX = center.x + CGFloat.random(in: -80...80)

        run(SKAction.sequence([
            // Dyker upp stor
            SKAction.fadeAlpha(to: 1.0, duration: 0.05),

            // Snurr + slag
            SKAction.rotate(byAngle: .pi * 2, duration: 0.3),
            SKAction.rotate(toAngle: 0.6, duration: 0.08),
            SKAction.rotate(toAngle: -0.15, duration: 0.03),
            SKAction.run { [weak self] in self?.spawnStrikeEffect(big: true) },
            SKAction.moveBy(x: 0, y: -8, duration: 0.02),
            SKAction.moveBy(x: 0, y: 8, duration: 0.04),
            SKAction.rotate(toAngle: 0, duration: 0.05),

            // Kort paus
            SKAction.wait(forDuration: 0.3),

            // Studsar lekfullt ner mot golvet + krymper
            SKAction.group([
                SKAction.moveTo(y: floorY + 150, duration: 0.3),
                SKAction.moveTo(x: landX, duration: 0.3),
                SKAction.scale(to: 0.6, duration: 0.3),
                SKAction.rotate(byAngle: .pi * 1.5, duration: 0.3)
            ]),
            SKAction.group([
                SKAction.moveTo(y: floorY, duration: 0.2),
                SKAction.scale(to: 0.4, duration: 0.2),
                SKAction.rotate(byAngle: .pi, duration: 0.2)
            ]),

            // Liten studs
            SKAction.group([
                SKAction.moveBy(x: 30, y: 80, duration: 0.15),
                SKAction.scale(to: 0.25, duration: 0.15),
                SKAction.rotate(byAngle: .pi * 0.5, duration: 0.15)
            ]),
            SKAction.group([
                SKAction.moveBy(x: 20, y: -80, duration: 0.12),
                SKAction.scale(to: 0.15, duration: 0.12),
                SKAction.rotate(byAngle: .pi * 0.5, duration: 0.12)
            ]),

            // Kort paus på golvet
            SKAction.rotate(toAngle: 0, duration: 0.06),
            SKAction.wait(forDuration: 0.2),

            // Hoppar tillbaka till toolbox (omvänd peekABoo)
            SKAction.group([
                SKAction.move(to: CGPoint(x: toolboxPos.x, y: toolboxPos.y + 40), duration: 0.4),
                SKAction.scale(to: 0.08, duration: 0.4),
                SKAction.rotate(byAngle: -.pi * 2, duration: 0.4)
            ]),

            // Försvinner ner i toolboxen
            SKAction.group([
                SKAction.move(to: toolboxPos, duration: 0.1),
                SKAction.fadeOut(withDuration: 0.1)
            ]),

            SKAction.run { completion() }
        ]), withKey: "strikeReturn")
    }

    // MARK: - Reverse PeekABoo (stor → slag → studsar → krymper → toolbox)

    func reversePeekABoo(from center: CGPoint, to toolboxPos: CGPoint, completion: @escaping () -> Void) {
        removeAllActions()
        position = center
        setScale(1.0)
        zRotation = 0
        alpha = 0

        let floorY: CGFloat = 500
        let landX = center.x + CGFloat.random(in: -100...100)

        // ── Fas 1: Dyker upp stor — slag! ──

        let appear = SKAction.fadeAlpha(to: 1.0, duration: 0.05)
        let hammerStrike = SKAction.sequence([
            SKAction.rotate(toAngle: 0.6, duration: 0.08),
            SKAction.rotate(toAngle: -0.15, duration: 0.03),
            SKAction.run { [weak self] in self?.spawnStrikeEffect(big: true) },
            SKAction.moveBy(x: 0, y: -8, duration: 0.02),
            SKAction.moveBy(x: 0, y: 8, duration: 0.04),
            SKAction.rotate(toAngle: 0, duration: 0.05)
        ])

        // ── Fas 2: Båge ner från mitten till golvet — krymper ──

        let arcMid = CGPoint(x: (center.x + landX) / 2,
                             y: max(center.y, floorY) + 200)

        let arcDown1 = SKAction.group([
            SKAction.move(to: arcMid, duration: 0.25),
            SKAction.scale(to: 0.7, duration: 0.25),
            SKAction.rotate(byAngle: -.pi * 1.5, duration: 0.25)
        ])
        arcDown1.timingMode = .easeOut

        let arcDown2 = SKAction.group([
            SKAction.move(to: CGPoint(x: landX, y: floorY), duration: 0.25),
            SKAction.scale(to: 0.5, duration: 0.25),
            SKAction.rotate(byAngle: -.pi, duration: 0.25)
        ])
        arcDown2.timingMode = .easeIn

        // ── Fas 3: Studsar på golvet — krymper steg för steg ──

        let bounce1 = makeBounce(height: 120, horizontalDrift: -50, duration: 0.28, spinAngle: -.pi)
        let bounce2 = makeBounce(height: 60, horizontalDrift: 30, duration: 0.22, spinAngle: -.pi * 0.5)
        let bounce3 = makeBounce(height: 25, horizontalDrift: -15, duration: 0.15, spinAngle: -.pi * 0.3)

        let shrink1 = SKAction.scale(to: 0.35, duration: 0.28)
        let shrink2 = SKAction.scale(to: 0.2, duration: 0.22)
        let shrink3 = SKAction.scale(to: 0.12, duration: 0.15)

        let bouncePhase = SKAction.sequence([
            SKAction.group([bounce1, shrink1]),
            SKAction.group([bounce2, shrink2]),
            SKAction.group([bounce3, shrink3])
        ])

        // ── Fas 4: Hoppar tillbaka in i toolboxen ──

        let jumpToBox = SKAction.group([
            SKAction.move(to: CGPoint(x: toolboxPos.x, y: toolboxPos.y + 40), duration: 0.35),
            SKAction.scale(to: 0.08, duration: 0.35),
            SKAction.rotate(byAngle: -.pi * 2, duration: 0.35)
        ])
        jumpToBox.timingMode = .easeIn

        let slideIn = SKAction.group([
            SKAction.move(to: toolboxPos, duration: 0.1),
            SKAction.fadeOut(withDuration: 0.1)
        ])

        // ── Hela sekvensen ──

        run(SKAction.sequence([
            appear, hammerStrike,
            SKAction.wait(forDuration: 0.2),
            arcDown1, arcDown2,
            bouncePhase,
            SKAction.wait(forDuration: 0.15),
            jumpToBox, slideIn,
            SKAction.run { completion() }
        ]), withKey: "reversePeekABoo")
    }

    // MARK: - Quick Strike (före portrait)

    /// Snabb hamring med blixt, sedan completion.
    func quickStrike(completion: @escaping () -> Void) {
        removeAllActions()

        run(SKAction.sequence([
            // Lyft
            SKAction.rotate(toAngle: 0.6, duration: 0.08),
            // BANG ner
            SKAction.rotate(toAngle: -0.15, duration: 0.03),
            SKAction.run { [weak self] in self?.spawnStrikeEffect(big: true) },
            SKAction.moveBy(x: 0, y: -8, duration: 0.02),
            SKAction.moveBy(x: 0, y: 8, duration: 0.04),
            SKAction.rotate(toAngle: 0, duration: 0.05),
            // Kort paus efter slaget
            SKAction.wait(forDuration: 0.15),
            // Tonar ut
            SKAction.fadeOut(withDuration: 0.6),
            SKAction.run { completion() }
        ]), withKey: "quickStrike")
    }

    // MARK: - Cleanup

    func fadeAway(duration: TimeInterval = 0.6) {
        removeAllActions()
        run(SKAction.fadeOut(withDuration: duration), withKey: "hammerFade")
    }

    func reset() {
        removeAllActions()
        alpha = 0
        zRotation = 0
        setScale(0.08)
    }
}
