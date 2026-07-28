import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'routes/auth.dart' as auth;
import 'routes/crashes.dart' as crashes;
import 'routes/events.dart' as events;
import 'routes/notifications.dart' as notifications;
import 'routes/otp.dart' as otp;
import 'routes/remote_config.dart' as remote_config;

/// A function that mounts one route group onto the server [Router].
///
/// Every `routes/*.dart` module exposes a top-level `registerRoutes(Router)`
/// matching this type. To add a new endpoint group, create a module, import it
/// here with a prefix, and append `yourModule.registerRoutes` to [_registrars].
typedef RouteRegistrar = void Function(Router router);

/// Append-only list of route groups the test server exposes.
///
/// Order matters only when two groups share a path (they must not). Add new
/// backend contract groups here — one import + one line is the whole wiring
/// surface for a new endpoint group.
final List<RouteRegistrar> _registrars = <RouteRegistrar>[
  auth.registerRoutes,
  crashes.registerRoutes,
  events.registerRoutes,
  notifications.registerRoutes,
  otp.registerRoutes,
  remote_config.registerRoutes,
];

/// Assembles the full shelf [Handler] for the test server.
///
/// Pipeline: optional request logging -> router (`/healthz` + every registered
/// group). [enableLogging] defaults to `true` for the running server; tests
/// pass `false` to keep output quiet.
Handler buildHandler({bool enableLogging = true}) {
  final router = Router()..get('/healthz', _health);

  for (final register in _registrars) {
    register(router);
  }

  var pipeline = const Pipeline();
  if (enableLogging) {
    pipeline = pipeline.addMiddleware(logRequests());
  }
  return pipeline.addHandler(router.call);
}

Response _health(Request request) => Response.ok('ok');
