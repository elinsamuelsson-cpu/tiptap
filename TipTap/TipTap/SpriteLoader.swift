import SpriteKit

enum SpriteLoader {

    static func loadFrames(baseName: String, count: Int) -> [SKTexture] {
        return (1...count).map { i in
            let name = String(format: "%@_%02d", baseName, i)
            let texture = SKTexture(imageNamed: name)
            texture.filteringMode = .nearest
            return texture
        }
    }
}
