import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  /// A widget tap that launched the app arrives here.
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    for context in connectionOptions.urlContexts {
      NativeSurfaces.shared.open(context.url)
    }
  }

  /// A widget tap while the app is running arrives here. Surface URLs stop here, because Flutter's
  /// own deep linking would otherwise try to route them too.
  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    let others = URLContexts.filter { !NativeSurfaces.shared.open($0.url) }
    if !others.isEmpty {
      super.scene(scene, openURLContexts: others)
    }
  }
}
