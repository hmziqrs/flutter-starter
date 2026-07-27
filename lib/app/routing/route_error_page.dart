import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/theme/app_sizes.dart';
import 'package:starter/shared/theme/app_spacing.dart';

class RouteErrorPage extends StatelessWidget {
  const RouteErrorPage({
    required this.location,
    required this.onHome,
    this.message,
    this.onBack,
    super.key,
  });

  final String location;
  final VoidCallback onHome;
  final String? message;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final translations = context.t;
    return FScaffold(
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSizes.formContentMaxWidth),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    FLucideIcons.circleAlert,
                    size: 40,
                    color: context.theme.colors.error,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    translations.routeError.title,
                    style: context.theme.typography.display.xl,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    message ?? translations.routeError.body,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SelectableText(
                    translations.routeError.path(path: location),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  FButton(
                    key: const ValueKey('route-error-home'),
                    onPress: onHome,
                    child: Text(translations.common.home),
                  ),
                  if (onBack case final onBack? when Navigator.canPop(context)) ...[
                    const SizedBox(height: AppSpacing.sm),
                    FButton(
                      key: const ValueKey('route-error-back'),
                      variant: .outline,
                      onPress: onBack,
                      child: Text(translations.common.back),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
