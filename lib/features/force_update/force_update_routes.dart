import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:starter/app/routing/app_routes.dart';
import 'package:starter/app/routing/route_guards.dart';
import 'package:starter/features/force_update/force_update_page.dart';
import 'package:starter/features/force_update/force_update_state.dart';
import 'package:starter/features/force_update/update_requirement.dart';
import 'package:starter/features/force_update/version_gate_providers.dart';
import 'package:starter/infrastructure/logging/app_logger.dart';

List<RouteBase> buildForceUpdateRoutes() => [
  GoRoute(
    name: AppRoutes.forceUpdate,
    path: AppRoutes.forceUpdatePath,
    builder: (context, state) {
      final container = ProviderScope.containerOf(context, listen: false);
      final requirement = container.read(versionCheckProvider).value;
      final hard = requirement is UpdateRequirementHard
          ? requirement
          : const UpdateRequirementHard(
              minVersion: '',
              latestVersion: '',
              storeUrl: '',
            );
      return ForceUpdatePage(
        state: ForceUpdateState.from(hard),
        onUpdateNow: () => unawaited(
          launchStoreUrl(hard.storeUrl, logger: container.read(appLoggerProvider)),
        ),
      );
    },
  ),
];
