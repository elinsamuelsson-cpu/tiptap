import SpriteKit

class OwlNode: SKSpriteNode {

    // MARK: - State

    enum State {
        case sleeping, wakingUp, awake, blowing, goingToSleep
    }

    private(set) var state: State = .sleeping
    private var sleepFrames: [SKTexture] = []
    private var awakeFrames: [SKTexture] = []
    private var lastTapTime: CFTimeInterval = 0
    private let debounce: CFTimeInterval = 0.3
    private var restPosition: CGPoint = .zero

    // Callbacks
    var onAwake: (() -> Void)?       // Tap 1 → vaken, redo för bubbla
    var onTap2: (() -> Void)?        // Tap 2 → starta bubbla
    var onSleeping: (() -> Void)?    // Sleep-transition klar → redo för ny runda

    // MARK: - Init

    convenience init() {
        let texture = SKTexture(imageNamed: "owl_sleep_01")
        // Canvas 1200×1200, scale 0.75
        self.init(texture: texture, color: .clear, size: CGSize(width: 1200, height: 1200))
        setScale(0.75)
        loadFrames()
        startSleeping()
    }

    private func loadFrames() {
        sleepFrames = SpriteLoader.loadFrames(baseName: "owl_sleep", count: 5)
        awakeFrames = SpriteLoader.loadFrames(baseName: "owl_awake", count: 5)
    }

    // MARK: - Idle loops

    func startSleeping() {
        state = .sleeping
        removeAllActions()
        alpha = 1.0
        // Ping-pong: 01→02→03→04→05→04→03→02 (8 frames, 0.5s/frame = 4s)
        // Fade: 0.1s ut till 0.9, 0.1s in, hold 0.3s, Linear
        run(pingPong(frames: sleepFrames, timePerFrame: 0.5,
                     fadeAlpha: 0.9, fadeDuration: 0.1, timingMode: .linear), withKey: "idle")
    }

    func startAwake() {
        state = .awake
        removeAllActions()
        alpha = 1.0
        // Ping-pong: 01→02→03→04→05→04→03→02 (8 frames, 0.3s/frame = 3s)
        // Fade: 0.08s ut till 0.92, 0.08s in, hold 0.14s, EaseInEaseOut
        run(pingPong(frames: awakeFrames, timePerFrame: 0.3,
                     fadeAlpha: 0.92, fadeDuration: 0.08, timingMode: .easeInEaseOut), withKey: "idle")
    }

    func startBlowing() {
        state = .blowing
        removeAllActions()
        alpha = 1.0
        // Bara awake_01 ↔ awake_02 med långsam mjuk övergång
        let frames = [awakeFrames[0], awakeFrames[1]]
        run(pingPong(frames: frames, timePerFrame: 1.0,
                     fadeAlpha: 0.95, fadeDuration: 0.15, timingMode: .easeInEaseOut), withKey: "idle")
    }

    // MARK: - Transitions

    /// Tap 1: Sover → Vaken (1.5s)
    func wakeUp() {
        guard state == .sleeping else { return }
        state = .wakingUp
        removeAllActions()
        alpha = 1.0

        // sleep_05→04→03→02→01 → awake_05→04→03→02→01 (10 frames, 0.15s/frame)
        // Fade: 0.05s ut till 0.88, 0.05s in, hold 0.05s
        let frames: [SKTexture] = [
            sleepFrames[4], sleepFrames[3], sleepFrames[2], sleepFrames[1], sleepFrames[0],
            awakeFrames[4], awakeFrames[3], awakeFrames[2], awakeFrames[1], awakeFrames[0]
        ]
        let transition = crossFadeSequence(frames: frames, timePerFrame: 0.15,
                                           fadeAlpha: 0.88, fadeDuration: 0.05, timingMode: .easeOut)
        let done = SKAction.run { [weak self] in
            self?.startAwake()
            self?.onAwake?()
        }
        run(SKAction.sequence([transition, done]), withKey: "transition")
    }

    /// Automatisk: Vaken → Sover (2.0s, efter bubbel-explosion)
    func goToSleep() {
        guard state == .awake else { return }
        state = .goingToSleep
        removeAllActions()
        alpha = 1.0

        // awake_01→02→03→04→05 → sleep_05→04→03→02→01 (10 frames, 0.2s/frame)
        // Fade: 0.08s ut till 0.92, ease-in
        let frames: [SKTexture] = [
            awakeFrames[0], awakeFrames[1], awakeFrames[2], awakeFrames[3], awakeFrames[4],
            sleepFrames[4], sleepFrames[3], sleepFrames[2], sleepFrames[1], sleepFrames[0]
        ]
        let transition = crossFadeSequence(frames: frames, timePerFrame: 0.2,
                                           fadeAlpha: 0.92, fadeDuration: 0.08, timingMode: .easeIn)
        let done = SKAction.run { [weak self] in
            self?.startSleeping()
            self?.onSleeping?()
        }
        run(SKAction.sequence([transition, done]), withKey: "transition")
    }

    // MARK: - Trembling (simultant med bubbel-växt)

    func startTrembling() {
        let breatheIn = SKAction.scale(to: 0.76, duration: 1.0)
        breatheIn.timingMode = .easeInEaseOut
        let breatheOut = SKAction.scale(to: 0.74, duration: 1.2)
        breatheOut.timingMode = .easeInEaseOut
        let pulse = SKAction.repeatForever(SKAction.sequence([breatheIn, breatheOut]))
        run(pulse, withKey: "tremble")
    }

    func stopTrembling() {
        removeAction(forKey: "tremble")
        run(SKAction.scale(to: 0.75, duration: 0.2), withKey: "snapBack")
    }

    // MARK: - Freeze / Unfreeze

    func freeze() {
        removeAction(forKey: "idle")
        removeAction(forKey: "transition")
        texture = awakeFrames[0]
    }

    func unfreeze() {
        if state == .awake {
            startAwake()
        }
    }

    // MARK: - Tap

    func onTap() {
        let now = CACurrentMediaTime()
        guard now - lastTapTime > debounce else { return }
        lastTapTime = now

        switch state {
        case .sleeping:
            wakeUp()
        case .awake:
            onTap2?()
        case .wakingUp, .goingToSleep, .blowing:
            break
        }
    }

    // MARK: - Helpers

    private func pingPong(frames: [SKTexture], timePerFrame: TimeInterval,
                          fadeAlpha: CGFloat, fadeDuration: TimeInterval,
                          timingMode: SKActionTimingMode) -> SKAction {
        let forward = frames
        let backward = Array(frames.dropFirst().dropLast().reversed())
        let anim = crossFadeSequence(frames: forward + backward, timePerFrame: timePerFrame,
                                     fadeAlpha: fadeAlpha, fadeDuration: fadeDuration,
                                     timingMode: timingMode)
        return SKAction.repeatForever(anim)
    }

    private func crossFadeSequence(frames: [SKTexture], timePerFrame: TimeInterval,
                                   fadeAlpha: CGFloat, fadeDuration: TimeInterval,
                                   timingMode: SKActionTimingMode) -> SKAction {
        let holdDuration = max(0, timePerFrame - fadeDuration * 2)
        let frameActions = frames.map { texture -> SKAction in
            let fadeOut = SKAction.fadeAlpha(to: fadeAlpha, duration: fadeDuration)
            fadeOut.timingMode = timingMode
            let swap = SKAction.setTexture(texture, resize: false)
            let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: fadeDuration)
            fadeIn.timingMode = timingMode
            let wait = SKAction.wait(forDuration: holdDuration)
            return SKAction.sequence([fadeOut, swap, fadeIn, wait])
        }
        return SKAction.sequence(frameActions)
    }
}
