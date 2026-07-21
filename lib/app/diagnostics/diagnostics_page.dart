import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/interaction_policy_controller.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/platform/app_build_info.dart';
import 'package:starter/infrastructure/platform/platform_capabilities.dart';
import 'package:starter/shared/adaptive/app_layout_class.dart';
import 'package:starter/shared/theme/app_sizes.dart';
import 'package:starter/shared/theme/app_spacing.dart';

class DiagnosticsPage extends ConsumerWidget {
  const DiagnosticsPage({required this.config, super.key});

  final AppConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translations = context.t;
    final breakpoints = context.theme.breakpoints;
    final layoutClass = AppLayoutClass.fromWidth(
      MediaQuery.sizeOf(context).width,
      compactMax: breakpoints.sm,
      expandedMin: breakpoints.lg,
    );
    final interactionPolicy = ref.watch(interactionPolicyProvider);
    final capabilities = PlatformCapabilities.current();
    final locale = TranslationProvider.of(context).locale;

    return FScaffold(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppSizes.readingContentMaxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    translations.diagnostics.title,
                    style: context.theme.typography.display.xl2,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  FCard(
                    child: Column(
                      children: [
                        _DiagnosticTile(
                          label: translations.diagnostics.environment,
                          value: config.environment.name,
                        ),
                        _DiagnosticTile(
                          label: translations.diagnostics.build,
                          value: '',
                          valueBuilder: _BuildValue.new,
                        ),
                        _DiagnosticTile(
                          label: translations.diagnostics.layout,
                          value: layoutClass.name,
                        ),
                        _DiagnosticTile(
                          label: translations.diagnostics.interaction,
                          value: interactionPolicy.name,
                        ),
                        _DiagnosticTile(
                          label: translations.diagnostics.locale,
                          value: locale.languageTag,
                        ),
                        _DiagnosticTile(
                          label: translations.diagnostics.capabilities,
                          value: capabilities.redactedSummary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(translations.diagnostics.redactedNotice),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiagnosticTile extends StatelessWidget {
  const _DiagnosticTile({
    required this.label,
    required this.value,
    this.valueBuilder,
  });

  final String label;
  final String value;
  final Widget Function()? valueBuilder;

  @override
  Widget build(BuildContext context) {
    return FTile(
      title: Text(label),
      details: valueBuilder?.call() ?? SelectableText(value),
    );
  }
}

class _BuildValue extends StatelessWidget {
  const _BuildValue();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppBuildInfo>(
      future: AppBuildInfo.load(),
      builder: (context, snapshot) {
        return SelectableText(snapshot.data?.displayValue ?? '—');
      },
    );
  }
}
