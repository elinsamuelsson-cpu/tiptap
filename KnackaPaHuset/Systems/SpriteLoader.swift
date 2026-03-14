import SpriteKit

/// Hjälpfunktioner för att ladda sprites och animationssekvenser från Assets.xcassets
enum SpriteLoader {

    // MARK: - Ladda frame-sekvenser

    /// Returnerar en array av SKTexture för en PNG-sekvens.
    ///
    /// Namnkonvention i Assets: "\(baseName)_01", "\(baseName)_02" … "\(baseName)_NN"
    /// Exempel: baseName="hus_idle", count=8 → laddar "hus_idle_01" … "hus_idle_08"
    static func loadFrames(baseName: String, count: Int) -> [SKTexture] {
        return (1...count).map { i in
            let name = String(format: "%@_%02d", baseName, i)
            let texture = SKTexture(imageNamed: name)
            texture.filteringMode = .nearest // bra för pixelart / handritad stil
            return texture
        }
    }

    /// Laddar frames från en SKTextureAtlas (om du använder .atlas-mappar).
    /// Sorterar automatiskt efter namn så ordningen alltid stämmer.
    static func loadFramesFromAtlas(named atlasName: String) -> [SKTexture] {
        let atlas = SKTextureAtlas(named: atlasName)
        return atlas.textureNames
            .sorted()
            .map { atlas.textureNamed($0) }
    }

    // MARK: - Preload (valfritt, för snabb laddning)

    /// Förladdar alla texturer i en atlas i bakgrunden.
    /// Anropa från AppDelegate eller en laddningsskärm.
    static func preloadAtlases(named names: [String], completion: @escaping () -> Void) {
        let atlases = names.map { SKTextureAtlas(named: $0) }
        SKTextureAtlas.preloadTextureAtlases(atlases, withCompletionHandler: completion)
    }
}
