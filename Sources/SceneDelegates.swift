import UIKit

/// Phone window. Sign-in happens here.
@objc(PhoneSceneDelegate)
final class PhoneSceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = BrowserViewController()
        window.makeKeyAndVisible()
        self.window = window
    }
}

/// Car window. A plain UIWindowScene under `UIWindowSceneSessionRoleCarPlay`.
/// iOS only creates it for a build signed with Apple's `carplay-video`
/// entitlement; without it this class is never instantiated.
@objc(CarSceneDelegate)
final class CarSceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = BrowserViewController()
        window.makeKeyAndVisible()
        self.window = window
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        window = nil
    }
}
