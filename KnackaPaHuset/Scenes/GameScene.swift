import SpriteKit

class GameScene: SKScene {

    // MARK: - Setup

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.53, green: 0.81, blue: 0.98, alpha: 1) // himmelsblå
        setupScene()
    }

    private func setupScene() {
        setupHall()
        setupOwl()
    }

    // MARK: - Bakgrund

    private func setupHall() {
        let hall = AnimatedSpriteNode(imageNamed: "hall_idle_01")
        hall.position = CGPoint(x: frame.midX, y: frame.midY)
        hall.zPosition = 0
        hall.name = "hall"
        addChild(hall)
    }

    // MARK: - Objekt

    private func setupOwl() {
        let owl = AnimatedSpriteNode(imageNamed: "owl-idle")
        owl.position = CGPoint(x: frame.midX, y: frame.midY)
        owl.zPosition = 10
        owl.name = "owl"

        // TODO: byt ut frameCount när du vet hur många frames owl-idle har
        // owl.loadIdleAnimation(baseName: "owl-idle", frameCount: 4)
        // owl.playIdleAnimation()

        // TODO: ladda tap-animation när du har sprites för den
        // owl.loadTapAnimation(baseName: "owl-tap", frameCount: 4)

        owl.onTapHandler = { [weak owl] in
            owl?.playTapAnimation()
        }

        addChild(owl)
    }

    // MARK: - Touch

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        // Hittar den översta tappbara noden
        for node in nodes(at: location) {
            if let sprite = node as? AnimatedSpriteNode {
                sprite.onTap()
                break
            }
        }
    }
}
