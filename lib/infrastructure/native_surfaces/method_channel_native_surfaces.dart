import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/native_surfaces/native_surfaces_port.dart';
import 'package:starter/features/native_surfaces/surface_snapshot.dart';
import 'package:starter/infrastructure/logging/app_logger.dart';

final nativeSurfacesProvider = Provider<NativeSurfacesPort>((ref) {
  final surfaces = MethodChannelNativeSurfaces(logger: AppLogger.bootstrap());
  ref.onDispose(surfaces.dispose);
  return surfaces;
});

/// Talks to the native side over one channel, which each platform implements
/// as docs/native_surfaces.md describes. A platform without an implementation is
/// normal, so a missing one is a quiet no-op rather than an error.
final class MethodChannelNativeSurfaces implements NativeSurfacesPort {
  MethodChannelNativeSurfaces({
    required this._logger,
    this._channel = const MethodChannel(channelName),
  }) {
    _channel.setMethodCallHandler(_handleCall);
  }

  static const channelName = 'starter/native_surfaces';

  final AppLogger _logger;
  final MethodChannel _channel;
  final StreamController<String> _routes = StreamController<String>.broadcast();

  Future<void> _handleCall(MethodCall call) async {
    if (call.method == 'openRoute' && call.arguments is String) {
      _routes.add(call.arguments as String);
    }
  }

  @override
  Future<void> publish(SurfaceSnapshot snapshot) async {
    await _invoke<void>('publish', jsonEncode(snapshot.toJson()));
  }

  @override
  Future<bool> startLive(SurfaceSnapshot snapshot) async {
    return await _invoke<bool>('startLive', jsonEncode(snapshot.toJson())) ?? false;
  }

  @override
  Future<void> updateLive(SurfaceSnapshot snapshot) async {
    await _invoke<void>('updateLive', jsonEncode(snapshot.toJson()));
  }

  @override
  Future<void> endLive() async {
    await _invoke<void>('endLive');
  }

  @override
  Stream<String> get routeRequests => _routes.stream;

  @override
  Future<String?> takeLaunchRoute() => _invoke<String>('takeLaunchRoute');

  Future<T?> _invoke<T>(String method, [Object? arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      return null;
    } on PlatformException catch (error, stackTrace) {
      _logger.warning('native_surfaces.$method', error: error, stackTrace: stackTrace);
      return null;
    }
  }

  void dispose() {
    _channel.setMethodCallHandler(null);
    unawaited(_routes.close());
  }
}
