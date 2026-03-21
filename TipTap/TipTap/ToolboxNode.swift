import SpriteKit

class ToolboxNode: SKSpriteNode {

    // MARK: - Properties

    private var glowNode: SKSpriteNode?
    private var glitterEmitter: SKNode?

    // MARK: - Init

    convenience init() {
        let texture = SKTexture(imageNamed: "toolbox")
        self.init(texture: texture, color: .clear, size: CGSize(width: 162, height: 162))
        isUserInteractionEnabled = false
        blendMode = .multiply
        setupGlow()
        startGlitter()
        startAlphaPulse()
        startBreathing()
        startIdleShake()
    }

    // MARK: - Outer Glow

    private func setupGlow() {
        let glowSize: CGFloat = 280
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: glowSize, height: glowSize))
        let image = renderer.image { ctx in
            let colors = [
                UIColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 0.5).cgColor,
                UIColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 0.0).cgColor
            ]
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                         colors: colors as CFArray,
                                         locations: [0.0, 1.0]) {
                let center = CGPoint(x: glowSize / 2, y: glowSize / 2)
                ctx.cgContext.drawRadialGradient(gradient,
                                                 startCenter: center, startRadius: 0,
                                                 endCenter: center, endRadius: glowSize / 2,
                                                 options: [])
            }
        }

        let glow = SKSpriteNode(texture: SKTexture(image: image), size: CGSize(width: glowSize, height: glowSize))
        glow.zPosition = -1
        glow.alpha = 0.25
        glow.blendMode = .add
        addChild(glow)
        glowNode = glow

        let fadeUp = SKAction.fadeAlpha(to: 0.4, duration: 1.25)
        fadeUp.timingMode = .easeInEaseOut
        let fadeDown = SKAction.fadeAlpha(to: 0.1, duration: 1.25)
        fadeDown.timingMode = .easeInEaseOut
        glow.run(SKAction.repeatForever(SKAction.sequence([fadeUp, fadeDown])), withKey: "glowPulse")
    }

    // MARK: - Glitter

    func startGlitter() {
        stopGlitter()
        let container = SKNode()
        container.name = "glitter"
        container.zPosition = 2
        addChild(container)
        glitterEmitter = container

        let spawn = SKAction.run { [weak self] in
            self?.spawnGlitterParticle()
            self?.spawnGlitterParticle()
        }
        let delay = SKAction.wait(forDuration: 0.12)
        container.run(SKAction.repeatForever(SKAction.sequence([spawn, delay])), withKey: "glitterLoop")
    }

    func stopGlitter() {
        glitterEmitter?.removeAllActions()
        glitterEmitter?.removeAllChildren()
        glitterEmitter?.removeFromParent()
        glitterEmitter = nil
    }

    private func spawnGlitterParticle() {
        let isStar = Int.random(in: 0...3) == 0
        let particle: SKShapeNode

        if isStar {
            let size = CGFloat.random(in: 3...8)
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
            particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.5...4))
        }

        let colorRoll = Int.random(in: 0...2)
        switch colorRoll {
        case 0:
            particle.fillColor = SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1.0)
        case 1:
            particle.fillColor = SKColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        default:
            particle.fillColor = SKColor(red: 1.0, green: 0.95, blue: 0.6, alpha: 1.0)
        }
        particle.strokeColor = .clear
        particle.blendMode = .add
        particle.glowWidth = isStar ? 2.0 : 1.0

        let x = CGFloat.random(in: -90...90)
        let y = CGFloat.random(in: -90...90)
        particle.position = CGPoint(x: x, y: y)
        particle.alpha = 0
        particle.setScale(CGFloat.random(in: 0.4...1.0))

        glitterEmitter?.addChild(particle)

        let life = TimeInterval.random(in: 1.5...3.0)
        let peakAlpha: CGFloat = 0.6
        let pulseSpeed = TimeInterval.random(in: 0.5...1.0)

        let fadeIn = SKAction.fadeAlpha(to: peakAlpha, duration: life * 0.2)
        let drift = SKAction.moveBy(x: CGFloat.random(in: -8...8),
                                     y: CGFloat.random(in: 5...15), duration: life)
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

    // MARK: - Alpha Pulse

    private func startAlphaPulse() {
        let fadeDown = SKAction.fadeAlpha(to: 0.82, duration: 1.8)
        fadeDown.timingMode = .easeInEaseOut
        let fadeUp = SKAction.fadeAlpha(to: 1.0, duration: 1.8)
        fadeUp.timingMode = .easeInEaseOut
        run(SKAction.repeatForever(SKAction.sequence([fadeDown, fadeUp])), withKey: "alphaPulse")
    }

    private func stopAlphaPulse() {
        removeAction(forKey: "alphaPulse")
        alpha = 1.0
    }

    // MARK: - Breathing

    private func startBreathing() {
        let scaleUp = SKAction.scale(to: 1.01, duration: 2.0)
        scaleUp.timingMode = .easeInEaseOut
        let scaleDown = SKAction.scale(to: 1.0, duration: 2.0)
        scaleDown.timingMode = .easeInEaseOut
        run(SKAction.repeatForever(SKAction.sequence([scaleUp, scaleDown])), withKey: "breathe")
    }

    // MARK: - Idle Shake

    private func startIdleShake() {
        let wait = SKAction.wait(forDuration: 2.2, withRange: 0.9)
        let shakeX = SKAction.sequence([
            SKAction.moveBy(x: 3, y: 1.5, duration: 0.07),
            SKAction.moveBy(x: -5, y: -2.5, duration: 0.09),
            SKAction.moveBy(x: 4, y: 1.5, duration: 0.08),
            SKAction.moveBy(x: -3, y: -0.5, duration: 0.08),
            SKAction.moveBy(x: 1, y: 0, duration: 0.06)
        ])
        run(SKAction.repeatForever(SKAction.sequence([wait, shakeX])), withKey: "idleShake")
    }

    // MARK: - Fade Away / Back

    func fadeAway(duration: TimeInterval = 2.0) {
        stopAlphaPulse()
        stopGlitter()
        removeAction(forKey: "breathe")
        removeAction(forKey: "idleShake")
        removeAction(forKey: "fadeBack")
        // Byt till alpha-blend FÖRST, sedan fada ut — undviker svart multiply-artefakt
        blendMode = .alpha
        run(SKAction.fadeOut(withDuration: duration), withKey: "fadeAway")
        glowNode?.run(SKAction.fadeOut(withDuration: duration))
    }

    func fadeBack(duration: TimeInterval = 2.0) {
        removeAction(forKey: "fadeAway")
        // Starta osynlig i alpha-mode, fada in, byt till multiply när synlig
        blendMode = .alpha
        alpha = 0
        colorBlendFactor = 0
        run(SKAction.sequence([
            SKAction.fadeIn(withDuration: duration),
            SKAction.run { [weak self] in
                self?.blendMode = .multiply
                self?.startAlphaPulse()
                self?.startGlitter()
                self?.startBreathing()
                self?.startIdleShake()
            }
        ]), withKey: "fadeBack")
        glowNode?.run(SKAction.fadeAlpha(to: 0.25, duration: duration))
    }

    // MARK: - Cleanup

    func reset() {
        removeAction(forKey: "breathe")
        removeAction(forKey: "idleShake")
        glowNode?.removeAction(forKey: "glowPulse")
        glowNode?.removeFromParent()
        glowNode = nil
        stopGlitter()
        stopAlphaPulse()
        setupGlow()
        startGlitter()
        startAlphaPulse()
        startBreathing()
        startIdleShake()
    }
}
