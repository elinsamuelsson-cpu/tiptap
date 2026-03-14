import SwiftUI
import SpriteKit

struct ContentView: View {

    // Scenen skapas en gång och återanvänds
    private let scene: GameScene = {
        let s = GameScene(size: CGSize(width: 2732, height: 2048))
        s.scaleMode = .aspectFill
        return s
    }()

    var body: some View {
        GeometryReader { geo in
            SpriteView(scene: scene)
                .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
        .statusBarHidden(true)
    }
}


#Preview {
    ContentView()
}

