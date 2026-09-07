import Flutter
import UIKit

final class SceneDelegate: FlutterSceneDelegate {
  private let flutterEngine = FlutterEngine(name: "chants-main")

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let windowScene = scene as? UIWindowScene else { return }
    guard flutterEngine.run() else { return }

    GeneratedPluginRegistrant.register(with: flutterEngine)
    registerSceneLifeCycle(with: flutterEngine)

    let flutterViewController = FlutterViewController(
      engine: flutterEngine,
      nibName: nil,
      bundle: nil
    )
    let flutterWindow = UIWindow(windowScene: windowScene)
    flutterWindow.rootViewController = flutterViewController
    window = flutterWindow
    flutterWindow.makeKeyAndVisible()

    super.scene(scene, willConnectTo: session, options: connectionOptions)
  }
}
