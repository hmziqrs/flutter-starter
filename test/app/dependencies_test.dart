import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tvos/flutter_tvos.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:starter/app/dependencies.dart';
import 'package:starter/app/routing/app_link_handler.dart';
import 'package:starter/features/search/search_corpus.dart';
import 'package:starter/features/settings/settings_repository.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/features/settings/text_preset.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/cache/cache_diagnostics.dart';
import 'package:starter/infrastructure/error_reporting/composite_crash_reporter.dart';
import 'package:starter/infrastructure/error_reporting/crash_reporter.dart';
import 'package:starter/infrastructure/error_reporting/http_crash_reporter.dart';
import 'package:starter/infrastructure/error_reporting/noop_crash_reporter.dart';
import 'package:starter/infrastructure/logging/app_logger.dart';
import 'package:starter/infrastructure/media/image_picker_media_picker.dart';
import 'package:starter/infrastructure/media/media_picker.dart';
import 'package:starter/infrastructure/media/noop_media_picker.dart';
import 'package:starter/infrastructure/permissions/device_permission_service.dart';
import 'package:starter/infrastructure/permissions/noop_permission_service.dart';
import 'package:starter/infrastructure/permissions/permission_service.dart';
import 'package:starter/infrastructure/platform/platform_capabilities.dart';
import 'package:starter/infrastructure/updates/android_app_update_service.dart';
import 'package:starter/infrastructure/updates/app_update_service.dart';
import 'package:starter/infrastructure/updates/ios_app_update_service.dart';
import 'package:starter/infrastructure/updates/noop_app_update_service.dart';

void main() {
  test('settings persistence keys are explicit and unique', () {
    expect(SettingsRepository.persistedKeys.toSet(), {
      'appearance.theme_mode',
      'appearance.accent',
      'appearance.font_scale',
      'appearance.text_preset',
      'appearance.spacing',
      'appearance.radius',
      'localization.locale',
      'onboarding.completed',
      'security.biometric_unlock_enabled',
      'appearance.haptics_enabled',
      'security.passcode_enabled',
      'security.auto_lock_delay_seconds',
      'security.lock_on_background',
    });
    expect(
      SettingsRepository.persistedKeys,
      hasLength(SettingsRepository.persistedKeys.toSet().length),
    );
  });

  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferencesAsyncPlatform? previousPlatform;

  setUp(() {
    previousPlatform = SharedPreferencesAsyncPlatform.instance;
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() => SharedPreferencesAsyncPlatform.instance = previousPlatform);

  test('reconstructed production dependencies load persisted settings', () async {
    final first = await AppDependencies.production(
      AppLogger.bootstrap(),
      iosAppleId: '',
      allowedDeepLinkHosts: AllowedDeepLinkHosts.empty,
    );
    const expected = SettingsState(
      themeMode: AppThemeMode.dark,
      accent: AppAccent.violet,
      fontScale: 1.35,
      textPreset: AppTextPreset.comfortable,
      spacingVariant: AppSpacingVariant.standard,
      radiusVariant: AppRadiusVariant.rounded,
      localeOverride: AppLocale.zhHans,
    );

    await first.settings.settingsRepository.save(expected);
    final reconstructed = await AppDependencies.production(
      AppLogger.bootstrap(),
      iosAppleId: '',
      allowedDeepLinkHosts: AllowedDeepLinkHosts.empty,
    );

    expect(reconstructed.settings.initialSettings, expected);
  });

  test('production wires the search corpus source only behind a backend base url', () async {
    final offline = await AppDependencies.production(
      AppLogger.bootstrap(),
      iosAppleId: '',
      allowedDeepLinkHosts: AllowedDeepLinkHosts.empty,
    );
    expect(offline.searchCorpusSource, isNull);

    final wired = await AppDependencies.production(
      AppLogger.bootstrap(),
      iosAppleId: '',
      allowedDeepLinkHosts: AllowedDeepLinkHosts.empty,
      backendBaseUrl: Uri.parse('http://127.0.0.1:8123'),
    );
    expect(wired.searchCorpusSource, isNotNull);
  });

  test('production composes the crash reporter with HTTP only behind a backend base url', () async {
    final offline = await AppDependencies.production(
      AppLogger.bootstrap(),
      iosAppleId: '',
      allowedDeepLinkHosts: AllowedDeepLinkHosts.empty,
    );
    final offlineComposite = offline.telemetry.crashReporter as CompositeCrashReporter;
    expect(offlineComposite.reporters.whereType<HttpCrashReporter>(), isEmpty);

    final wired = await AppDependencies.production(
      AppLogger.bootstrap(),
      iosAppleId: '',
      allowedDeepLinkHosts: AllowedDeepLinkHosts.empty,
      backendBaseUrl: Uri.parse('http://127.0.0.1:8123'),
    );
    final wiredComposite = wired.telemetry.crashReporter as CompositeCrashReporter;
    expect(wiredComposite.reporters.whereType<HttpCrashReporter>(), hasLength(1));
    expect(wiredComposite.reporters.first, isA<NoopCrashReporter>());
    expect(wired.telemetry.crashReporterBackend, isA<RemoteCrashReporterBackend>());
  });

  test('known cache keys cover the search corpus cache key', () {
    expect(knownCacheKeys, contains(searchCorpusCacheKey));
  });

  test('update adapter selection matches both iOS platform spellings', () {
    AppUpdateService selectFor(String platform, {bool isWeb = false}) {
      return AppDependencies.selectAppUpdateService(
        PlatformCapabilities(platform: platform, isWeb: isWeb),
        iosAppleId: '123456789',
        logger: AppLogger.bootstrap(),
      );
    }

    // The resolver yields TargetPlatform.iOS.name ('iOS'); the lowercase
    // spelling is matched too so real devices never fall to the noop.
    final enumNamed = selectFor('iOS');
    expect(enumNamed, isA<IosAppUpdateService>());
    expect((enumNamed as IosAppUpdateService).appleId, '123456789');

    expect(selectFor('ios'), isA<IosAppUpdateService>());
    expect(selectFor('android'), isA<AndroidAppUpdateService>());
    expect(selectFor('macos'), isA<NoopAppUpdateService>());
    expect(selectFor('iOS', isWeb: true), isA<NoopAppUpdateService>());
  });

  test('production routes a resolved iOS device to the iOS update adapter', () async {
    final previousTargetPlatform = debugDefaultTargetPlatformOverride;
    TvOSInfo.bindingsOverride = _FakeTvOsBindings(isTvOS: false);
    try {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      final deps = await AppDependencies.production(
        AppLogger.bootstrap(),
        iosAppleId: '123456789',
        allowedDeepLinkHosts: AllowedDeepLinkHosts.empty,
      );

      expect(deps.platform.platformCapabilities.platform, 'iOS');
      expect(deps.platform.appUpdateService, isA<IosAppUpdateService>());
      expect(deps.platform.permissionService, isA<DevicePermissionService>());
      expect(deps.platform.mediaPicker, isA<ImagePickerMediaPicker>());
    } finally {
      debugDefaultTargetPlatformOverride = previousTargetPlatform;
      TvOSInfo.bindingsOverride = null;
    }
  });

  test('permission and media picker selection match both iOS platform spellings', () {
    PermissionService permissionFor(String platform, {bool isWeb = false}) {
      return AppDependencies.selectPermissionService(
        PlatformCapabilities(platform: platform, isWeb: isWeb),
        logger: AppLogger.bootstrap(),
      );
    }

    MediaPicker pickerFor(String platform, {bool isWeb = false}) {
      return AppDependencies.selectMediaPicker(
        PlatformCapabilities(platform: platform, isWeb: isWeb),
        logger: AppLogger.bootstrap(),
      );
    }

    // The resolver yields TargetPlatform.iOS.name ('iOS'); both spellings must
    // keep real devices off the noop adapters.
    expect(permissionFor('iOS'), isA<DevicePermissionService>());
    expect(permissionFor('ios'), isA<DevicePermissionService>());
    expect(permissionFor('android'), isA<DevicePermissionService>());
    expect(permissionFor('macos'), isA<NoopPermissionService>());
    expect(permissionFor('iOS', isWeb: true), isA<NoopPermissionService>());

    expect(pickerFor('iOS'), isA<ImagePickerMediaPicker>());
    expect(pickerFor('ios'), isA<ImagePickerMediaPicker>());
    expect(pickerFor('android'), isA<ImagePickerMediaPicker>());
    expect(pickerFor('macos'), isA<NoopMediaPicker>());
    expect(pickerFor('iOS', isWeb: true), isA<NoopMediaPicker>());
  });
}

final class _FakeTvOsBindings extends TvOSNativeBindings {
  _FakeTvOsBindings({required this.isTvOS}) : super.forTesting();

  @override
  final bool isTvOS;
}
