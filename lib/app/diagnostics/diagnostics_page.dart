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
import 'package:starter/infrastructure/sharing/share_service.dart';
import 'package:starter/infrastructure/updates/app_update_service.dart';
import 'package:starter/shared/adaptive/app_layout_class.dart';
import 'package:starter/shared/theme/app_sizes.dart';
import 'package:starter/shared/theme/app_spacing.dart';

class DiagnosticsPage extends ConsumerStatefulWidget {
  const DiagnosticsPage({required this.config, super.key});

  final AppConfig config;

  @override
  ConsumerState<DiagnosticsPage> createState() => _DiagnosticsPageState();
}

class _DiagnosticsPageState extends ConsumerState<DiagnosticsPage> {
  late final Future<List<CacheDiagnosticRow>> _cacheDiagnostics = cacheDiagnosticsSnapshot(
    ref.read(cacheStoreProvider),
    keys: knownCacheKeys,
  );

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    final translations = context.t;
    final breakpoints = context.theme.breakpoints;
    final layoutClass = AppLayoutClass.fromWidth(
      MediaQuery.sizeOf(context).width,
      compactMax: breakpoints.sm,
      expandedMin: breakpoints.lg,
    );
    final locale = TranslationProvider.of(context).locale;

    return FScaffold(
      child: SafeArea(
        child: ListView(
          padding: context.screenPadding,
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
                    SizedBox(height: context.spacing.xl),
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
                          _WatchedTile(
                            label: translations.diagnostics.interaction,
                            watchValue: (ref) => ref.watch(
                              interactionPolicyProvider.select((policy) => policy.name),
                            ),
                          ),
                          _WatchedTile(
                            label: translations.diagnostics.lifecycle,
                            watchValue: (ref) => ref.watch(
                              appLifecyclePhaseProvider.select((phase) => phase.kind.name),
                            ),
                          ),
                          _WatchedTile(
                            label: translations.diagnostics.viewingEnvironment,
                            watchValue: (ref) => ref.watch(
                              presentationPolicyProvider.select(
                                (policy) => policy.viewingEnvironment.name,
                              ),
                            ),
                          ),
                          _DiagnosticTile(
                            label: translations.diagnostics.locale,
                            value: locale.languageTag,
                          ),
                          _WatchedTile(
                            label: translations.diagnostics.capabilities,
                            watchValue: (ref) => ref.watch(
                              platformCapabilitiesProvider.select(
                                (capabilities) => capabilities.redactedSummary,
                              ),
                            ),
                          ),
                          _DiagnosticTile(
                            label: translations.diagnostics.secureStorage,
                            value: resolveSecureStoreBackend().name,
                          ),
                          _WatchedTile(
                            label: translations.diagnostics.crashReporting,
                            watchValue: (ref) => ref.watch(
                              crashReporterBackendProvider.select(
                                (backend) => switch (backend) {
                                  NoopCrashReporterBackend() =>
                                    translations.diagnostics.crashReportingNone,
                                  RemoteCrashReporterBackend(:final host) => host,
                                },
                              ),
                            ),
                          ),
                          _WatchedTile(
                            label: translations.diagnostics.analytics,
                            watchValue: (ref) => ref.watch(
                              analyticsClientBackendProvider.select(
                                (backend) => switch (backend) {
                                  NoopAnalyticsBackend() => translations.diagnostics.analyticsNone,
                                  RemoteAnalyticsBackend(:final host) => host,
                                },
                              ),
                            ),
                          ),
                          if (config.developmentToolsEnabled)
                            for (final flag in FeatureFlag.values)
                              _WatchedTile(
                                label: '${translations.diagnostics.featureFlags}.${flag.wireKey}',
                                watchValue: (ref) => ref.watch(
                                  featureFlagsControllerProvider.select(
                                    (flags) => flags.isEnabled(flag).toString(),
                                  ),
                                ),
                              ),
                          if (config.developmentToolsEnabled)
                            Consumer(
                              builder: (context, ref, _) {
                                final assignments = ref.watch(experimentAssignmentsProvider);
                                return Column(
                                  children: [
                                    for (final assignment in assignments)
                                      _DiagnosticTile(
                                        label:
                                            '${translations.diagnostics.experiments.title}.${assignment.key.wireKey}',
                                        value:
                                            '${assignment.variant.wireName} (${assignment.source.name})',
                                      ),
                                  ],
                                );
                              },
                            ),
                          if (config.developmentToolsEnabled)
                            FutureBuilder<List<CacheDiagnosticRow>>(
                              future: _cacheDiagnostics,
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
                          if (config.developmentToolsEnabled) ...[
                            _DevTriggerTile(
                              key: const ValueKey('diagnostics-share-trigger'),
                              title: translations.share.trigger,
                              idleLabel: translations.diagnostics.triggerIdle,
                              runningLabel: translations.diagnostics.triggerRunning,
                              run: (ref) async => _shareOutcomeLabel(
                                translations,
                                await ref
                                    .read(shareServiceProvider)
                                    .shareText('starter · ${config.environment.name}'),
                              ),
                            ),
                            _DevTriggerTile(
                              key: const ValueKey('diagnostics-update-check'),
                              title: translations.update.checkForUpdates,
                              idleLabel: translations.diagnostics.triggerIdle,
                              runningLabel: translations.diagnostics.triggerRunning,
                              run: (ref) async => _updateOutcomeLabel(
                                translations,
                                await ref.read(appUpdateServiceProvider).checkForUpdate(),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: context.spacing.lg),
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

class _WatchedTile extends ConsumerWidget {
  const _WatchedTile({required this.label, required this.watchValue});

  final String label;
  final String Function(WidgetRef ref) watchValue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _DiagnosticTile(label: label, value: watchValue(ref));
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

/// A dev-only action tile on `/dev/diagnostics` that runs a platform port on
/// tap and surfaces the honest outcome as its detail value. The provider is
/// only read inside [run] (never during build) so harnesses that do not
/// override the port still render the page.
class _DevTriggerTile extends ConsumerStatefulWidget {
  const _DevTriggerTile({
    required this.title,
    required this.idleLabel,
    required this.runningLabel,
    required this.run,
    super.key,
  });

  final String title;
  final String idleLabel;
  final String runningLabel;
  final Future<String> Function(WidgetRef ref) run;

  @override
  ConsumerState<_DevTriggerTile> createState() => _DevTriggerTileState();
}

class _DevTriggerTileState extends ConsumerState<_DevTriggerTile> {
  bool _running = false;
  String? _outcome;

  Future<void> _run() async {
    if (_running) return;
    setState(() => _running = true);
    String? outcome;
    try {
      outcome = await widget.run(ref);
    } on Object {
      // Adapters are total, but a stray throw must never wedge the tile on
      // "running" — keep the last reported outcome instead.
    }
    if (!mounted) return;
    setState(() {
      _running = false;
      if (outcome != null) _outcome = outcome;
    });
  }

  @override
  Widget build(BuildContext context) {
    final outcome = _outcome;
    return FTile(
      onPress: _run,
      title: Text(widget.title),
      details: Text(outcome ?? (_running ? widget.runningLabel : widget.idleLabel)),
    );
  }
}

String _shareOutcomeLabel(Translations translations, ShareResult result) {
  return switch (result) {
    ShareResult.success => translations.share.success,
    ShareResult.unavailable => translations.share.unavailable,
    ShareResult.cancelled => translations.share.cancelled,
  };
}

String _updateOutcomeLabel(Translations translations, UpdateAvailability availability) {
  return switch (availability) {
    UpdateAvailability.noUpdate => translations.update.notAvailable,
    UpdateAvailability.available => translations.update.available,
    UpdateAvailability.required => translations.update.required,
  };
}

class _BuildValue extends StatefulWidget {
  const _BuildValue();

  @override
  State<_BuildValue> createState() => _BuildValueState();
}

class _BuildValueState extends State<_BuildValue> {
  late final Future<AppBuildInfo> _buildInfo = AppBuildInfo.load();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppBuildInfo>(
      future: _buildInfo,
      builder: (context, snapshot) {
        return SelectableText(snapshot.data?.displayValue ?? '—');
      },
    );
  }
}
