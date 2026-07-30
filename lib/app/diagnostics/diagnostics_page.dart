import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:starter/app/app_lifecycle_controller.dart';
import 'package:starter/app/config/app_config.dart';
import 'package:starter/app/interaction_policy_controller.dart';
import 'package:starter/app/platform_capabilities_provider.dart';
import 'package:starter/app/presentation_policy_controller.dart';
import 'package:starter/features/experiments/experiments_controller.dart';
import 'package:starter/features/feature_flags/feature_flags.dart';
import 'package:starter/features/feature_flags/feature_flags_controller.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/analytics/analytics_client.dart';
import 'package:starter/infrastructure/cache/cache_diagnostics.dart';
import 'package:starter/infrastructure/cache/cache_store.dart';
import 'package:starter/infrastructure/error_reporting/crash_reporter.dart';
import 'package:starter/infrastructure/platform/app_build_info.dart';
import 'package:starter/infrastructure/secure_storage/secure_store_backend.dart';
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
    final lifecyclePhase = ref.watch(appLifecyclePhaseProvider);
    final presentationPolicy = ref.watch(presentationPolicyProvider);
    final capabilities = ref.watch(platformCapabilitiesProvider);
    final locale = TranslationProvider.of(context).locale;
    final analyticsBackend = ref.watch(analyticsClientBackendProvider);
    final flags = ref.watch(featureFlagsControllerProvider);

    return FScaffold(
      child: SafeArea(
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
                            label: translations.diagnostics.lifecycle,
                            value: lifecyclePhase.kind.name,
                          ),
                          _DiagnosticTile(
                            label: translations.diagnostics.viewingEnvironment,
                            value: presentationPolicy.viewingEnvironment.name,
                          ),
                          _DiagnosticTile(
                            label: translations.diagnostics.locale,
                            value: locale.languageTag,
                          ),
                          _DiagnosticTile(
                            label: translations.diagnostics.capabilities,
                            value: capabilities.redactedSummary,
                          ),
                          _DiagnosticTile(
                            label: translations.diagnostics.secureStorage,
                            value: resolveSecureStoreBackend().name,
                          ),
                          _DiagnosticTile(
                            label: translations.diagnostics.crashReporting,
                            value: switch (ref.watch(crashReporterBackendProvider)) {
                              NoopCrashReporterBackend() =>
                                translations.diagnostics.crashReportingNone,
                              RemoteCrashReporterBackend(:final host) => host,
                            },
                          ),
                          _DiagnosticTile(
                            label: translations.diagnostics.analytics,
                            value: switch (analyticsBackend) {
                              NoopAnalyticsBackend() => translations.diagnostics.analyticsNone,
                              RemoteAnalyticsBackend(:final host) => host,
                            },
                          ),
                          if (config.developmentToolsEnabled)
                            for (final flag in FeatureFlag.values)
                              _DiagnosticTile(
                                label: '${translations.diagnostics.featureFlags}.${flag.wireKey}',
                                value: flags.isEnabled(flag).toString(),
                              ),
                          if (config.developmentToolsEnabled)
                            for (final assignment in ref.watch(experimentAssignmentsProvider))
                              _DiagnosticTile(
                                label:
                                    '${translations.diagnostics.experiments.title}.${assignment.key.wireKey}',
                                value: '${assignment.variant.wireName} (${assignment.source.name})',
                              ),
                          if (config.developmentToolsEnabled)
                            FutureBuilder<List<CacheDiagnosticRow>>(
                              future: cacheDiagnosticsSnapshot(ref.read(cacheStoreProvider)),
                              builder: (context, snapshot) {
                                final rows = snapshot.data ?? const <CacheDiagnosticRow>[];
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (final row in rows)
                                      _DiagnosticTile(
                                        label: row.key,
                                        value: row.present
                                            ? 'age: ${row.age?.inSeconds ?? 0}s'
                                            : 'absent',
                                      ),
                                  ],
                                );
                              },
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
