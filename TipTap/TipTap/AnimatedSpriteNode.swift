import SpriteKit

class AnimatedSpriteNode: SKSpriteNode {

    var onTapHandler: (() -> Void)?

    private var idleFrames: [SKTexture] = []
    private var tapFrames: [SKTexture] = []
    private var isPlayingTap = false

    private enum ActionKey {
        static let idle = "idle_anim"
        static let tap  = "tap_anim"
    }

    convenience init(imageNamed name: String) {
        let texture = SKTexture(imageNamed: name)
        self.init(texture: texture, color: .clear, size: texture.size())
    }

    func loadIdleAnimation(baseName: String, frameCount: Int) {
        idleFrames = SpriteLoader.loadFrames(baseName: baseName, count: frameCount)
    }

    func loadTapAnimation(baseName: String, frameCount: Int) {
        tapFrames = SpriteLoader.loadFrames(baseName: baseName, count: frameCount)
    }

    func playIdleAnimation(timePerFrame: TimeInterval = 0.1) {
        guard !idleFrames.isEmpty else { return }
        removeAction(forKey: ActionKey.idle)
        let anim = SKAction.repeatForever(
            SKAction.animate(with: idleFrames, timePerFrame: timePerFrame)
        )
        run(anim, withKey: ActionKey.idle)
    }

    func pauseIdleAnimation() {
        removeAction(forKey: ActionKey.idle)
    }

    func playTapAnimation(timePerFrame: TimeInterval = 0.08) {
        guard !isPlayingTap else { return }

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

    func onTap() {
        onTapHandler?()
    }
}
