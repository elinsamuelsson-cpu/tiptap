import SpriteKit

class GrassNode: SKSpriteNode {

    // MARK: - Properties

    private var grassFrames: [SKTexture] = []
    private let grassSize = CGSize(width: 2440, height: 877)

    // MARK: - Init

    convenience init() {
        let texture = SKTexture(imageNamed: "grass_01")
        self.init(texture: texture, color: .clear, size: CGSize(width: 2440, height: 877))
        alpha = 0
        loadFrames()
    }

    private func loadFrames() {
        grassFrames = SpriteLoader.loadFrames(baseName: "grass", count: 5)
    }

    // MARK: - Grow (simultant med dans, 2.0s)
    // grass_01→04, 0.5s/frame

    func startGrow() {
        removeAllActions()
        texture = grassFrames[0]
        alpha = 1.0

        var frameActions: [SKAction] = []
        for i in 1...3 {  // grass_01 already showing → 02, 03, 04
            let fadeOut = SKAction.fadeAlpha(to: 0.9, duration: 0.08)
            let swap = SKAction.setTexture(grassFrames[i], resize: false)
            let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.08)
            let hold = SKAction.wait(forDuration: 0.5 - 0.16)
            frameActions.append(SKAction.sequence([fadeOut, swap, fadeIn, hold]))
        }

        let done = SKAction.run { [weak self] in
            self?.startLoop()
        }

        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.5),  // hold grass_01
        ] + frameActions + [done]), withKey: "grow")
    }

    // MARK: - Loop (grass_04 ↔ grass_05, 2.0s/frame, EaseInEaseOut)

    private func startLoop() {
        removeAction(forKey: "grow")

        let toFrame5 = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.92, duration: 0.3),
            SKAction.setTexture(grassFrames[4], resize: false),
            SKAction.fadeAlpha(to: 1.0, duration: 0.3),
            SKAction.wait(forDuration: 2.0 - 0.6)
        ])

        let toFrame4 = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.92, duration: 0.3),
            SKAction.setTexture(grassFrames[3], resize: false),
            SKAction.fadeAlpha(to: 1.0, duration: 0.3),
            SKAction.wait(forDuration: 2.0 - 0.6)
        ])

        run(SKAction.repeatForever(SKAction.sequence([toFrame5, toFrame4])), withKey: "loop")
    }

    // MARK: - Fade Out (1.0s fade, 0.3s delay)

    func fadeOutGrass(completion: (() -> Void)? = nil) {
        removeAction(forKey: "loop")

        let done = SKAction.run {
            completion?()
        }

        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.3),
            SKAction.fadeOut(withDuration: 1.0),
            done
        ]), withKey: "fadeOut")
    }

    // MARK: - Reset

    func reset() {
        removeAllActions()
        alpha = 0
        texture = grassFrames.first
    }
}
