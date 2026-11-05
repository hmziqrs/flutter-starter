import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/features/native_surfaces/surface_snapshot.dart';

/// The app's side of the native surfaces. Each call is safe on every platform:
/// where a surface does not exist, the call does nothing.
abstract interface class NativeSurfacesPort {
  /// Stores [snapshot] where the native surfaces read it, and asks them to redraw.
  Future<void> publish(SurfaceSnapshot snapshot);

  /// Starts an ongoing lock screen presence: a Live Activity on iOS, a live
  /// update on Android. Returns false where the platform has none, or the user
  /// has turned them off.
  Future<bool> startLive(SurfaceSnapshot snapshot);

  Future<void> updateLive(SurfaceSnapshot snapshot);

  Future<void> endLive();

  /// Routes requested by a surface while the app is running.
  Stream<String> get routeRequests;

  /// The route that launched the app from a surface, once. Null otherwise.
  Future<String?> takeLaunchRoute();
}

/// Whether a surface may open [route]. A widget's data sits in shared storage
/// outside the app, so its routes are checked before anything navigates.
bool isOpenableSurfaceRoute(String route) => AppRoutes.isShellLocation(route);
