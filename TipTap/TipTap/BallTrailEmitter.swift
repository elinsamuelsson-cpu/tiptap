import SpriteKit

class BallTrailEmitter {

    // MARK: - Emitter Nodes

    private var smokeEmitter: SKEmitterNode?
    private var glitterEmitter: SKEmitterNode?
    private var auraEmitter: SKEmitterNode?

    // MARK: - Textures (generated in code)

    /// Stor oval rökblob — mjuk, asymmetrisk, magisk
    private static let smokeTexture: SKTexture = {
        let w: CGFloat = 80    // bredd — stor och fluffig
        let h: CGFloat = 56    // höjd — oval form
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: w, height: h))
        let image = renderer.image { ctx in
            let center = CGPoint(x: w / 2, y: h / 2)
            let colors = [
                UIColor.white.withAlphaComponent(1.0).cgColor,
                UIColor.white.withAlphaComponent(0.6).cgColor,
                UIColor.white.withAlphaComponent(0.2).cgColor,
                UIColor.white.withAlphaComponent(0.0).cgColor,
            ] as CFArray
            let locations: [CGFloat] = [0.0, 0.3, 0.7, 1.0]
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                         colors: colors,
                                         locations: locations) {
                ctx.cgContext.drawRadialGradient(
                    gradient,
                    startCenter: center, startRadius: 0,
                    endCenter: center, endRadius: w / 2,
                    options: .drawsAfterEndLocation
                )
            }
        }
        return SKTexture(image: image)
    }()

    /// Stor mjuk cirkelglöd — magisk aura
    private static let auraTexture: SKTexture = {
        let size: CGFloat = 120   // stor glöd
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let image = renderer.image { ctx in
            let center = CGPoint(x: size / 2, y: size / 2)
            let colors = [
                UIColor.white.withAlphaComponent(0.8).cgColor,
                UIColor.white.withAlphaComponent(0.3).cgColor,
                UIColor.white.withAlphaComponent(0.0).cgColor,
            ] as CFArray
            let locations: [CGFloat] = [0.0, 0.4, 1.0]
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                         colors: colors,
                                         locations: locations) {
                ctx.cgContext.drawRadialGradient(
                    gradient,
                    startCenter: center, startRadius: 0,
                    endCenter: center, endRadius: size / 2,
                    options: .drawsAfterEndLocation
                )
            }
        }
        return SKTexture(image: image)
    }()

    /// 4-uddig stjärna — glitter/gnist
    private static let starTexture: SKTexture = {
        let size: CGFloat = 32   // större stjärna
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let image = renderer.image { ctx in
            let c = ctx.cgContext
            let center = CGPoint(x: size / 2, y: size / 2)
            let outerRadius: CGFloat = size / 2
            let innerRadius: CGFloat = size / 7   // smal midja

            c.setFillColor(UIColor.white.cgColor)
            let path = UIBezierPath()
            for i in 0..<8 {
                let angle = CGFloat(i) * .pi / 4 - .pi / 2
                let r: CGFloat = (i % 2 == 0) ? outerRadius : innerRadius
                let p = CGPoint(x: center.x + cos(angle) * r,
                                y: center.y + sin(angle) * r)
                if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
            }
            path.close()
            path.fill()
        }
        return SKTexture(image: image)
    }()

    // MARK: - Create Emitters

    private func makeSmokeEmitter() -> SKEmitterNode {
        let e = SKEmitterNode()
        e.particleTexture = Self.smokeTexture

        // --- Livslängd: lång, hängande rök ---
        e.particleLifetime = 2.5             // länge kvar — justerbar
        e.particleLifetimeRange = 1.0

        // --- Startmängd ---
        e.particleBirthRate = 20             // justeras dynamiskt

        // --- Storlek: STOR, växer ---
        e.particleScale = 1.2               // stor start — justerbar
        e.particleScaleRange = 0.5
        e.particleScaleSpeed = 0.8          // växer medan den tonar — justerbar

        // --- Alpha ---
        e.particleAlpha = 0.5
        e.particleAlphaRange = 0.15
        e.particleAlphaSpeed = -0.2

        // --- Rörelse: flyter uppåt och ut ---
        e.emissionAngle = .pi / 2
        e.emissionAngleRange = .pi * 0.6
        e.particleSpeed = 25                // drift — justerbar
        e.particleSpeedRange = 18

        // --- Rotation ---
        e.particleRotation = 0
        e.particleRotationRange = .pi
        e.particleRotationSpeed = 0.2

        // --- Färgsekvens: vit → pärlemor-lavendel → ljusgrå → transparent ---
        let colorSeq = SKKeyframeSequence(keyframeValues: [
            UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
            UIColor(red: 0.93, green: 0.88, blue: 1.0, alpha: 1.0),   // lavendel
            UIColor(red: 0.90, green: 0.93, blue: 1.0, alpha: 1.0),   // ljusblå
            UIColor(red: 0.92, green: 0.92, blue: 0.92, alpha: 1.0),  // ljusgrå
        ], times: [0.0, 0.3, 0.6, 1.0])
        colorSeq.interpolationMode = .linear
        e.particleColorSequence = colorSeq
        e.particleColorBlendFactor = 1.0

        // Alpha-sekvens
        let alphaSeq = SKKeyframeSequence(keyframeValues: [
            NSNumber(value: 0.5),    // start
            NSNumber(value: 0.45),
            NSNumber(value: 0.2),
            NSNumber(value: 0.0),
        ], times: [0.0, 0.3, 0.7, 1.0])
        alphaSeq.interpolationMode = .linear
        e.particleAlphaSequence = alphaSeq

        e.particleBlendMode = .alpha
        e.zPosition = 12
        e.targetNode = nil

        return e
    }

    private func makeAuraEmitter() -> SKEmitterNode {
        let e = SKEmitterNode()
        e.particleTexture = Self.auraTexture

        // --- Livslängd ---
        e.particleLifetime = 1.8             // justerbar
        e.particleLifetimeRange = 0.6

        // --- Startmängd ---
        e.particleBirthRate = 8

        // --- Storlek: stor glöd ---
        e.particleScale = 1.5               // justerbar
        e.particleScaleRange = 0.6
        e.particleScaleSpeed = 1.2          // expanderar

        // --- Alpha ---
        e.particleAlpha = 0.25
        e.particleAlphaRange = 0.1
        e.particleAlphaSpeed = -0.12

        // --- Rörelse: långsam drift ---
        e.emissionAngle = .pi / 2
        e.emissionAngleRange = .pi
        e.particleSpeed = 12
        e.particleSpeedRange = 8

        // --- Rotation ---
        e.particleRotation = 0
        e.particleRotationRange = .pi * 2
        e.particleRotationSpeed = 0.15

        // --- Färgsekvens: pastell-magi ---
        let colorSeq = SKKeyframeSequence(keyframeValues: [
            UIColor(red: 1.0, green: 0.88, blue: 0.95, alpha: 1.0),   // rosa
            UIColor(red: 0.88, green: 0.92, blue: 1.0, alpha: 1.0),   // ljusblå
            UIColor(red: 0.93, green: 0.88, blue: 1.0, alpha: 1.0),   // lavendel
            UIColor(red: 0.88, green: 1.0, blue: 0.93, alpha: 1.0),   // mint
        ], times: [0.0, 0.3, 0.6, 1.0])
        colorSeq.interpolationMode = .linear
        e.particleColorSequence = colorSeq
        e.particleColorBlendFactor = 1.0

        // Alpha-sekvens
        let alphaSeq = SKKeyframeSequence(keyframeValues: [
            NSNumber(value: 0.25),
            NSNumber(value: 0.2),
            NSNumber(value: 0.08),
            NSNumber(value: 0.0),
        ], times: [0.0, 0.2, 0.6, 1.0])
        alphaSeq.interpolationMode = .linear
        e.particleAlphaSequence = alphaSeq

        e.particleBlendMode = .add          // glödande
        e.zPosition = 11
        e.targetNode = nil

        return e
    }

    private func makeGlitterEmitter() -> SKEmitterNode {
        let e = SKEmitterNode()
        e.particleTexture = Self.starTexture

        // --- Livslängd ---
        e.particleLifetime = 0.8             // lite längre — justerbar
        e.particleLifetimeRange = 0.3

        // --- Startmängd ---
        e.particleBirthRate = 20

        // --- Storlek: krymper ---
        e.particleScale = 0.5               // större start — justerbar
        e.particleScaleRange = 0.25
        e.particleScaleSpeed = -0.4         // krymper — justerbar

        // --- Alpha ---
        e.particleAlpha = 1.0
        e.particleAlphaRange = 0.2

        // --- Rörelse: spretar ut 360° ---
        e.emissionAngle = 0
        e.emissionAngleRange = .pi * 2
        e.particleSpeed = 90                // snabbare utkastning — justerbar
        e.particleSpeedRange = 60

        // --- Rotation: snabb spin ---
        e.particleRotation = 0
        e.particleRotationRange = .pi
        e.particleRotationSpeed = 10        // snabb — justerbar

        // --- Färgsekvens: guld → vit → ljusblå → lavendel → transparent ---
        let colorSeq = SKKeyframeSequence(keyframeValues: [
            UIColor(red: 1.0, green: 0.85, blue: 0.4, alpha: 1.0),    // guld
            UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),     // vit
            UIColor(red: 0.8, green: 0.88, blue: 1.0, alpha: 1.0),    // ljusblå
            UIColor(red: 0.92, green: 0.85, blue: 1.0, alpha: 1.0),   // lavendel
            UIColor(red: 0.92, green: 0.85, blue: 1.0, alpha: 0.0),   // transparent
        ], times: [0.0, 0.2, 0.5, 0.8, 1.0])
        colorSeq.interpolationMode = .linear
        e.particleColorSequence = colorSeq
        e.particleColorBlendFactor = 1.0

        // Alpha-sekvens
        let alphaSeq = SKKeyframeSequence(keyframeValues: [
            NSNumber(value: 1.0),
            NSNumber(value: 0.9),
            NSNumber(value: 0.3),
            NSNumber(value: 0.0),
        ], times: [0.0, 0.2, 0.6, 1.0])
        alphaSeq.interpolationMode = .linear
        e.particleAlphaSequence = alphaSeq

        e.particleBlendMode = .add          // glödande
        e.zPosition = 14
        e.targetNode = nil

        return e
    }

    // MARK: - API

    /// Fäst emitters på bollen.
    /// `trailTarget`: noden partiklar lämnas i (parent) så de inte följer bollen.
    func attach(to ball: SKNode, trailTarget: SKNode) {
        let smoke = makeSmokeEmitter()
        smoke.targetNode = trailTarget
        smoke.position = .zero
        ball.addChild(smoke)
        smokeEmitter = smoke

        let aura = makeAuraEmitter()
        aura.targetNode = trailTarget
        aura.position = .zero
        ball.addChild(aura)
        auraEmitter = aura

        let glitter = makeGlitterEmitter()
        glitter.targetNode = trailTarget
        glitter.position = .zero
        ball.addChild(glitter)
        glitterEmitter = glitter
    }

    /// Anropas varje frame — justerar intensitet efter bollens hastighet.
    /// `speed`: 0–1500+ px/s
    func updateIntensity(speed: CGFloat) {
        let t = min(max(speed / 1200, 0), 1.0)

        // Rök: 6 stilla → 35 full fart — justerbar
        smokeEmitter?.particleBirthRate = CGFloat(6.0 + t * 29.0)
        smokeEmitter?.particleScale = 1.0 + t * 0.8

        // Aura: 3 stilla → 14 full fart — justerbar
        auraEmitter?.particleBirthRate = CGFloat(3.0 + t * 11.0)
        auraEmitter?.particleScale = 1.2 + t * 1.0

        // Glitter: 5 stilla → 40 full fart — justerbar
        glitterEmitter?.particleBirthRate = CGFloat(5.0 + t * 35.0)
        glitterEmitter?.particleSpeed = 50 + t * 120
        glitterEmitter?.particleScale = 0.4 + t * 0.3
    }

    /// Stoppa emitters mjukt.
    func stop(fadeOut duration: TimeInterval = 0.5) {
        smokeEmitter?.particleBirthRate = 0
        glitterEmitter?.particleBirthRate = 0
        auraEmitter?.particleBirthRate = 0

        // Ta bort efter att partiklarna dött ut
        let removeDelay = duration + 3.0
        for emitter in [smokeEmitter, glitterEmitter, auraEmitter] {
            emitter?.run(SKAction.sequence([
                SKAction.wait(forDuration: removeDelay),
                SKAction.removeFromParent()
            ]))
        }

        smokeEmitter = nil
        glitterEmitter = nil
        auraEmitter = nil
    }
}
