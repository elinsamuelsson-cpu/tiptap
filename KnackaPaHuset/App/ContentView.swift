import SwiftUI
import SpriteKit

struct ContentView: View {

    // Scenen skapas en gång och återanvänds
    private let scene: GameScene = {
        let s = GameScene()
        s.scaleMode = .resizeFill
        return s
    }()

    var body: some View {
        SpriteView(scene: scene)
            .ignoresSafeArea()
            .statusBarHidden(true)
    }
}

#Preview {
    ContentView()
}
