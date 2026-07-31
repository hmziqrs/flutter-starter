import 'package:go_router/go_router.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/diagnostics/diagnostics_page.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/features/dev_gallery/gallery_registry.dart';
import 'package:starter/features/dev_gallery/screen_gallery_page.dart';

List<RouteBase> buildDevGalleryRoutes({required AppConfig config}) => config.developmentToolsEnabled
    ? [
        GoRoute(
          name: AppRoutes.developmentScreens,
          path: AppRoutes.developmentScreensPath,
          builder: (context, state) => ScreenGalleryPage(
            cases: buildGalleryRegistry(config: config),
          ),
        ),
        GoRoute(
          name: AppRoutes.diagnostics,
          path: AppRoutes.diagnosticsPath,
          builder: (context, state) => DiagnosticsPage(config: config),
        ),
      ]
    : const [];
