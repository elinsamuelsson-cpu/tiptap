import SpriteKit

class HatNode: SKSpriteNode {

    // MARK: - Properties

    private var glitterEmitter: SKNode?
    private var idleTimer: Timer?
    private let idleTimeout: TimeInterval = 30.0

    var onTap: (() -> Void)?

    // MARK: - Init

    convenience init() {
        let texture = SKTexture(imageNamed: "hat")
        self.init(texture: texture, color: .clear, size: CGSize(width: 700, height: 600))
        isUserInteractionEnabled = false
        startGlitter()
        startBreathing()
    }

    // MARK: - Glitter (onboarding)

    func startGlitter() {
        stopGlitter()
        let container = SKNode()
        container.name = "glitter"
        addChild(container)
        glitterEmitter = container

        let spawn = SKAction.run { [weak self] in
            self?.spawnGlitterParticle()
            self?.spawnGlitterParticle()
        }
        let delay = SKAction.wait(forDuration: 0.15)
        container.run(SKAction.repeatForever(SKAction.sequence([spawn, delay])), withKey: "glitterLoop")
    }

    func stopGlitter() {
        glitterEmitter?.removeAllActions()
        glitterEmitter?.removeAllChildren()
        glitterEmitter?.removeFromParent()
        glitterEmitter = nil
    }

    private func spawnGlitterParticle() {
        // Mix of round sparkles and star-shaped glints
        let isStar = Int.random(in: 0...3) == 0
        let particle: SKShapeNode

        if isStar {
            // Star shape — 4-pointed glint
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
            particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...6))
        }

        let colorRoll = Int.random(in: 0...2)
        switch colorRoll {
        case 0: // Gold
            particle.fillColor = SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1.0)
        case 1: // Bright white
            particle.fillColor = SKColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        default: // Warm shimmer
            particle.fillColor = SKColor(red: 1.0, green: 0.95, blue: 0.6, alpha: 1.0)
        }
        particle.strokeColor = .clear
        particle.zPosition = 1
        particle.glowWidth = isStar ? 2.0 : 1.0

        let x = CGFloat.random(in: -280...280)
        let y = CGFloat.random(in: -220...220)
        particle.position = CGPoint(x: x, y: y)
        particle.alpha = 0
        particle.setScale(CGFloat.random(in: 0.4...1.2))

        glitterEmitter?.addChild(particle)

        let life = TimeInterval.random(in: 2.0...4.0)
        let peakAlpha: CGFloat = 0.5
        let pulseSpeed = TimeInterval.random(in: 0.6...1.2)

        let fadeIn = SKAction.fadeAlpha(to: peakAlpha, duration: life * 0.2)
        let drift = SKAction.moveBy(x: CGFloat.random(in: -10...10),
                                     y: CGFloat.random(in: 8...20), duration: life)
        let fadeOut = SKAction.fadeOut(withDuration: life * 0.3)
        let scaleDown = SKAction.scale(to: 0.3, duration: life)

        // Slow gentle pulse — like stars twinkling
        let pulseCount = Int(life / (pulseSpeed * 2))
        let pulse = SKAction.repeat(SKAction.sequence([
            SKAction.fadeAlpha(to: peakAlpha * 0.15, duration: pulseSpeed),
            SKAction.fadeAlpha(to: peakAlpha, duration: pulseSpeed),
        ]), count: max(2, pulseCount))

        particle.run(SKAction.sequence([
            fadeIn,
            SKAction.group([pulse, drift, scaleDown]),
            fadeOut,
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Idle timer

    func startIdleTimer() {
        stopIdleTimer()
        idleTimer = Timer.scheduledTimer(withTimeInterval: idleTimeout, repeats: false) { [weak self] _ in
            self?.startGlitter()
        }
    }

    func stopIdleTimer() {
        idleTimer?.invalidate()
        idleTimer = nil
    }

    // MARK: - Breathing

    private func startBreathing() {
        let scaleUp = SKAction.scale(to: 1.015, duration: 2.0)
        scaleUp.timingMode = .easeInEaseOut
        let scaleDown = SKAction.scale(to: 1.0, duration: 2.0)
        scaleDown.timingMode = .easeInEaseOut
        run(SKAction.repeatForever(SKAction.sequence([scaleUp, scaleDown])), withKey: "breathe")
    }

    private func stopBreathing() {
        removeAction(forKey: "breathe")
        run(SKAction.scale(to: 1.0, duration: 0.2))
    }

    // MARK: - Cleanup

    func reset() {
        stopIdleTimer()
        startGlitter()
        startBreathing()
    }
}
