import SpriteKit

class TransitionManager {

    enum ObjectID: CaseIterable {
        case owl, hat, toolbox
    }

    private var objects: [ObjectID: SKNode] = [:]

    // MARK: - Register

    func registerObject(id: ObjectID, sprite: SKNode) {
        objects[id] = sprite
    }

    // MARK: - Activate (focus on one object)

    func activateObject(id: ObjectID) {
        for (objectID, sprite) in objects {
            if objectID == id {
                let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.4)
                fadeIn.timingMode = .easeInEaseOut
                sprite.run(fadeIn, withKey: "focus")
            } else {
                let fadeOut = SKAction.fadeAlpha(to: 0.0, duration: 0.4)
                fadeOut.timingMode = .easeInEaseOut
                sprite.run(fadeOut, withKey: "focus")
            }
        }
    }

    // MARK: - Deactivate all (restore)

    func deactivateAll() {
        for (_, sprite) in objects {
            let restore = SKAction.sequence([
                SKAction.wait(forDuration: 0.3),
                SKAction.fadeAlpha(to: 1.0, duration: 0.6)
            ])
            restore.timingMode = .easeInEaseOut
            sprite.run(restore, withKey: "focus")
        }
    }

    // MARK: - Force Reset

    func forceReset() {
        for (_, sprite) in objects {
            sprite.removeAction(forKey: "focus")
            sprite.alpha = 1.0
        }
    }
}
