import SpriteKit

/// En SKSpriteNode med stöd för:
///  - Idle-loop (PNG-sekvens som loopar)
///  - Tap-animation (PNG-sekvens som spelas en gång, sedan tillbaka till idle)
///  - onTapHandler-callback för spellogik
class AnimatedSpriteNode: SKSpriteNode {

    // MARK: - Properties

    var onTapHandler: (() -> Void)?

    private var idleFrames: [SKTexture] = []
    private var tapFrames: [SKTexture] = []
    private var isPlayingTap = false

    private enum ActionKey {
        static let idle = "idle_anim"
        static let tap  = "tap_anim"
    }

    // MARK: - Init

    /// Skapa nod med en enda stillbild (idle frame 1)
    convenience init(imageNamed name: String) {
        let texture = SKTexture(imageNamed: name)
        self.init(texture: texture, color: .clear, size: texture.size())
    }

    // MARK: - Ladda animationer

    /// Laddar idle-frames från Assets.
    /// Namnkonvention: "\(baseName)_01", "\(baseName)_02" … "\(baseName)_NN"
    func loadIdleAnimation(baseName: String, frameCount: Int) {
        idleFrames = SpriteLoader.loadFrames(baseName: baseName, count: frameCount)
    }

    /// Laddar tap-frames från Assets.
    /// Namnkonvention: "\(baseName)_01", "\(baseName)_02" … "\(baseName)_NN"
    func loadTapAnimation(baseName: String, frameCount: Int) {
        tapFrames = SpriteLoader.loadFrames(baseName: baseName, count: frameCount)
    }

    // MARK: - Spela animationer

    /// Startar idle-loopen. Anropas i setupScene efter loadIdleAnimation.
    func playIdleAnimation(timePerFrame: TimeInterval = 0.1) {
        guard !idleFrames.isEmpty else { return }
        removeAction(forKey: ActionKey.idle)
        let anim = SKAction.repeatForever(
            SKAction.animate(with: idleFrames, timePerFrame: timePerFrame)
        )
        run(anim, withKey: ActionKey.idle)
    }

    /// Pausar idle-loopen utan att nollställa frame.
    func pauseIdleAnimation() {
        removeAction(forKey: ActionKey.idle)
    }

    /// Spelas när användaren tappar på noden.
    /// Stoppar idle → kör tap-animation → återupptar idle.
    func playTapAnimation(timePerFrame: TimeInterval = 0.08) {
        guard !isPlayingTap else { return }

        // Om inga tap-frames laddats: ge en enkel skalningseffekt istället
        if tapFrames.isEmpty {
            let bounce = SKAction.sequence([
                SKAction.scale(to: 1.15, duration: 0.08),
                SKAction.scale(to: 1.0,  duration: 0.12)
            ])
            run(bounce)
            return
        }

        isPlayingTap = true
        pauseIdleAnimation()

        let tapAnim = SKAction.animate(with: tapFrames, timePerFrame: timePerFrame)
        let restore = SKAction.run { [weak self] in
            guard let self else { return }
            self.isPlayingTap = false
            if !self.idleFrames.isEmpty {
                self.playIdleAnimation(timePerFrame: timePerFrame)
            }
        }
        run(SKAction.sequence([tapAnim, restore]), withKey: ActionKey.tap)
    }

    // MARK: - Tap-hantering

    func onTap() {
        onTapHandler?()
    }
}
