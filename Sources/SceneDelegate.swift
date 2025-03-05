import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
        
        if #available(iOS 17.0, *) {
            window.rootViewController = UIHostingController(rootView: ContentView())
        } else {
            let fallbackView = Text("This app requires iOS 17.0 or later")
                .foregroundColor(.white)
                .preferredColorScheme(.dark)
            window.rootViewController = UIHostingController(rootView: fallbackView)
        }
        
        self.window = window
        window.makeKeyAndVisible()
    }
}
