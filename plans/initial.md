# Flutter Application Boilerplate

**Status:** Architecture baseline  
**Scope:** Infrastructure-only Flutter application with no product-specific features  
**Baseline date:** 21 July 2026  
**Primary targets:** Android, iOS, macOS, Windows, and Linux  
**Optional target:** Web

---

## 1. Purpose

This document defines a reusable Flutter boilerplate before any application-specific feature is implemented.

The boilerplate must provide:

- A maintainable application architecture.
- ForUI as the UI kit.
- Riverpod for dependency injection and state orchestration.
- Declarative routing.
- Dynamic light/dark themes, selectable accents, configurable colors, and adjustable font scaling.
- Type-safe English, Arabic, and Simplified Chinese localization with Slang.
- Reusable form handling with `flutter_form_builder`.
- Domain-neutral UI search, audio, background-download, and notification foundations.
- A vendor-neutral analytics abstraction backed by Firebase Analytics initially.
- A vendor-neutral crash-reporting abstraction backed by Firebase Crashlytics initially.
- Structured local persistence, preferences, secure storage, networking, and caching foundations.
- Strict logging, privacy, testing, and platform-boundary rules.

The boilerplate should make later feature work easy without turning the initial project into a dependency dump.

---

## 2. Non-goals

The boilerplate must **not** initially implement:

- Product-specific content or data.
- Product-specific permission prompts or background behavior during startup.
- Authentication or cloud synchronization.
- Remote content APIs.
- Product-specific media queues, download catalogs, notification schedules, or search indexes.
- A production backend.

Infrastructure interfaces may exist for future features, but they must remain domain-neutral and side-effect-free until used.

---

## 3. Core technical decisions

| Concern                        | Decision                                                                    |
| ------------------------------ | --------------------------------------------------------------------------- |
| Framework                      | Flutter                                                                     |
| UI kit                         | ForUI                                                                       |
| State and dependency injection | Riverpod                                                                    |
| Routing                        | `go_router`                                                                 |
| Localization                   | Slang + `slang_flutter` with JSON translation files                         |
| Forms                          | `flutter_form_builder` behind app-styled reusable fields                    |
| Small preferences              | `SharedPreferencesAsync`                                                    |
| Durable structured storage     | Drift + SQLite                                                              |
| Sensitive key-value storage    | `flutter_secure_storage`                                                    |
| HTTP client                    | Dio                                                                         |
| HTTP response cache            | `dio_cache_interceptor`, used only when an endpoint defines cache semantics |
| Audio engine                   | `just_audio` + `audio_session`                                              |
| Background audio               | `audio_service`                                                             |
| Background downloads           | `background_downloader`                                                     |
| Local notifications            | `flutter_local_notifications` + `timezone`                                  |
| Analytics                      | Application wrapper, Firebase adapter initially                             |
| Crash reporting                | Application wrapper, Firebase Crashlytics adapter initially                 |
| Performance telemetry          | Application wrapper, Firebase Performance adapter where supported           |
| Local logging                  | Application wrapper backed by Talker                                        |
| Unit/widget tests              | Flutter Test + Mocktail                                                     |
| Native/E2E tests               | Patrol when first platform workflow is added                                |
| Static analysis                | `very_good_analysis`, `custom_lint`, and `riverpod_lint`                    |

### Minimum Flutter baseline

ForUI `0.22.0+` requires Flutter `3.44.0+`. Use the latest stable Flutter version compatible with the current ForUI release. Do not build this boilerplate on an older Flutter channel.

Do not manually guess dependency versions in this document. Add the latest compatible stable packages with `flutter pub add`, review the resulting constraints, and commit `pubspec.lock` for the application.

---

## 4. Dependency policy

Dependencies are divided into three groups:

1. **Install and wire now** — foundational and exercised by the boilerplate.
2. **Install now, initialize lazily** — commonly reused platform foundations kept dormant until invoked.
3. **Approved later** — intentionally excluded until a concrete feature needs them.

This prevents multiple libraries from competing for the same responsibility.

---

## 5. Dependencies

### 5.1 Install and wire now

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # UI
  forui:
  flutter_form_builder:

  # State, dependency injection, and routing
  flutter_riverpod:
  riverpod_annotation:
  go_router:

  # Localization
  intl:
  slang:
  slang_flutter:

  # Preferences and persistence
  shared_preferences:
  flutter_secure_storage:
  drift:
  drift_flutter:
  path_provider:

  # Networking and standards-based HTTP caching
  dio:
  dio_cache_interceptor:

  # Reusable platform capabilities
  just_audio:
  audio_session:
  audio_service:
  background_downloader:
  flutter_local_notifications:
  timezone:

  # Firebase observability
  firebase_core:
  firebase_analytics:
  firebase_crashlytics:
  firebase_performance:

  # Diagnostics
  talker_flutter:
  package_info_plus:

  # Model/code-generation support
  freezed_annotation:
  json_annotation:

dev_dependencies:
  flutter_test:
    sdk: flutter

  build_runner:
  riverpod_generator:
  drift_dev:
  freezed:
  json_serializable:
  slang_build_runner:

  mocktail:
  very_good_analysis:
  custom_lint:
  riverpod_lint:
```

### 5.2 Install now, initialize lazily

Audio, downloads, and notifications are standard boilerplate capabilities. Their packages and application-owned interfaces are included, but real platform services must not start or request permissions during application bootstrap.

### 5.3 Approved later, not part of the initial boilerplate

| Package/capability                   | Add when                                                                                               |
| ------------------------------------ | ------------------------------------------------------------------------------------------------------ |
| `workmanager`                        | A best-effort mobile maintenance job is required. It must not be used for exact-time scheduling.      |
| `cached_network_image`               | The application displays meaningful remote imagery.                                                    |
| `flutter_cache_manager`              | Disposable remote files require a dedicated temporary file cache.                                      |
| `firebase_remote_config`             | The project has a real remote feature flag or remotely controlled configuration.                       |
| `firebase_messaging`                 | Push notifications are implemented.                                                                    |
| `sentry_flutter` or another provider | Windows/Linux crash reporting becomes a production requirement.                                        |
| Location/sensor packages             | A concrete location, compass, or sensor feature is implemented.                                        |
| Search/tokenizer packages            | Search requirements and verified corpus tests are defined.                                             |
| `patrol`                             | The first native permission, audio, notification, or background workflow is implemented.               |

### 5.4 Explicitly excluded

Do not add these to the baseline without a written architectural reason:

- Hive or Hive CE alongside Drift.
- GetIt alongside Riverpod.
- Provider, Bloc, GetX, MobX, or another competing state framework.
- `gen_l10n`, Easy Localization, or another localization framework alongside Slang.
- A second HTTP client.
- A generic React Query clone before the app has substantial remote server state.
- `sqlite3_flutter_libs`; current Drift/sqlite3 setups bundle SQLite for Flutter native platforms.
- Connectivity checks that block network requests. A reported Wi-Fi/mobile connection does not prove internet reachability.

---

## 6. Package installation commands

Run from a newly created Flutter application:

```bash
flutter pub add \
  forui flutter_form_builder \
  flutter_riverpod riverpod_annotation go_router \
  intl slang slang_flutter \
  shared_preferences flutter_secure_storage \
  drift drift_flutter path_provider \
  dio dio_cache_interceptor \
  firebase_core firebase_analytics firebase_crashlytics firebase_performance \
  talker_flutter package_info_plus \
  freezed_annotation json_annotation \
  just_audio audio_session audio_service \
  background_downloader \
  flutter_local_notifications timezone

flutter pub add --dev \
  build_runner riverpod_generator drift_dev \
  freezed json_serializable slang_build_runner \
  mocktail very_good_analysis custom_lint riverpod_lint
```

Initialize ForUI theme generation without allowing the CLI to own the whole application architecture:

```bash
dart run forui theme create
```

Configure Firebase after creating separate Firebase projects for each environment:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Run code generation with:

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## 7. Proposed project structure

```text
lib/
├── main.dart
├── main_development.dart
├── main_staging.dart
├── main_production.dart
├── bootstrap.dart
│
├── app/
│   ├── app.dart
│   ├── app_router.dart
│   ├── app_shell.dart
│   └── startup/
│       ├── app_startup.dart
│       └── startup_failure_view.dart
│
├── core/
│   ├── analytics/
│   │   ├── analytics.dart
│   │   ├── analytics_event.dart
│   │   ├── analytics_navigator_observer.dart
│   │   ├── composite_analytics.dart
│   │   ├── debug_analytics.dart
│   │   ├── firebase_analytics_adapter.dart
│   │   └── noop_analytics.dart
│   │
│   ├── crash_reporting/
│   │   ├── crash_reporter.dart
│   │   ├── firebase_crash_reporter.dart
│   │   └── noop_crash_reporter.dart
│   │
│   ├── performance/
│   │   ├── performance_monitor.dart
│   │   ├── firebase_performance_monitor.dart
│   │   └── noop_performance_monitor.dart
│   │
│   ├── logging/
│   │   ├── app_logger.dart
│   │   ├── log_redactor.dart
│   │   └── talker_logger_adapter.dart
│   │
│   ├── config/
│   │   ├── app_config.dart
│   │   ├── app_environment.dart
│   │   └── firebase_options_resolver.dart
│   │
│   ├── localization/
│   │   ├── locale_controller.dart
│   │   ├── locale_preferences.dart
│   │   └── supported_locales.dart
│   │
│   ├── theme/
│   │   ├── app_accent.dart
│   │   ├── app_theme_controller.dart
│   │   ├── app_theme_preferences.dart
│   │   ├── app_theme_settings.dart
│   │   ├── forui_theme_factory.dart
│   │   └── text_scale_policy.dart
│   │
│   ├── storage/
│   │   ├── database/
│   │   │   ├── app_database.dart
│   │   │   ├── migrations.dart
│   │   │   └── tables/
│   │   ├── preferences/
│   │   │   ├── preferences_store.dart
│   │   │   └── shared_preferences_store.dart
│   │   └── secure/
│   │       ├── secure_store.dart
│   │       └── flutter_secure_store.dart
│   │
│   ├── network/
│   │   ├── api_client.dart
│   │   ├── dio_factory.dart
│   │   ├── network_failure.dart
│   │   └── interceptors/
│   │       ├── cache_interceptor.dart
│   │       ├── request_id_interceptor.dart
│   │       └── safe_logging_interceptor.dart
│   │
│   ├── audio/
│   │   ├── app_audio_service.dart
│   │   ├── audio_session_manager.dart
│   │   └── noop_audio_service.dart
│   │
│   ├── downloads/
│   │   ├── download_service.dart
│   │   ├── background_download_service.dart
│   │   └── noop_download_service.dart
│   │
│   ├── notifications/
│   │   ├── notification_service.dart
│   │   └── noop_notification_service.dart
│   │
│   ├── forms/
│   │   ├── app_form.dart
│   │   ├── app_form_field.dart
│   │   └── form_error_mapper.dart
│   │
│   ├── search/
│   │   ├── app_search_field.dart
│   │   ├── search_query_controller.dart
│   │   └── search_state.dart
│   │
│   └── platform/
│       ├── app_platform.dart
│       └── platform_capabilities.dart
│
├── features/
│   └── README.md
│
└── i18n/
    ├── strings.i18n.json
    ├── strings_ar.i18n.json
    ├── strings_zh.i18n.json
    └── translations.g.dart

test/
├── app/
├── core/
│   ├── analytics/
│   ├── localization/
│   ├── theme/
│   └── storage/
└── helpers/

integration_test/
└── app_smoke_test.dart
```

### Structural rules

- `core/` must not import from `features/`.
- Feature packages may depend on public core interfaces, not concrete Firebase/Dio/Drift implementations.
- UI widgets must not call Firebase, Dio, Drift, Shared Preferences, or secure storage directly.
- Platform checks belong in `platform_capabilities.dart` or adapter factories, not scattered through widgets.
- Every external service must have a fake or no-op implementation.

---

## 8. Application bootstrap

Bootstrap order should be deterministic:

1. Call `WidgetsFlutterBinding.ensureInitialized()`.
2. Read compile-time application environment.
3. Initialize the local logger.
4. Load package/build metadata.
5. Initialize Firebase only on supported/configured platforms.
6. Create analytics, crash-reporting, and performance adapters.
7. Register global Flutter, platform, and zoned error handlers.
8. Open preferences and the Drift database.
9. Load persisted locale and theme settings.
10. Configure the audio abstraction without starting playback.
11. Register lazy download and notification adapters without requesting permissions.
12. Create the Riverpod `ProviderContainer` or `ProviderScope` overrides.
13. Run the application inside Slang's `TranslationProvider`.

Use `runZonedGuarded`, `FlutterError.onError`, and `PlatformDispatcher.instance.onError` so framework, asynchronous, and platform errors reach the `CrashReporter` abstraction.

A startup failure must show a minimal localized recovery screen rather than a permanent blank splash screen.

---

## 9. Environment strategy

Support three environments:

```text
development
staging
production
```

Each environment should define:

- Application display name suffix.
- Bundle/application identifier.
- Firebase project/configuration.
- API base URL placeholder.
- Analytics default state.
- Verbose logging state.
- Debug diagnostics availability.

Prefer compile-time values through `--dart-define` or `--dart-define-from-file`. Do not use `.env` files as a security mechanism; values compiled into a client application are discoverable.

Recommended entry points:

```text
lib/main_development.dart
lib/main_staging.dart
lib/main_production.dart
```

Production must never accidentally use the development Firebase project.

---

## 10. ForUI integration

ForUI must be the primary design system. Material widgets may still be used where Flutter or plugins require them, but their theme must be derived from the active ForUI theme so the application remains visually coherent.

ForUI does not automatically select light or dark brightness. The application theme controller must explicitly choose the correct `FThemeData`.

ForUI provides separate touch and desktop theme variants. The theme factory should select a density profile based on platform and input mode rather than screen width alone.

Suggested root composition:

```text
ProviderScope
└── MaterialApp.router
    └── Builder
        └── FTheme
            └── AppShell
```

Use ForUI's generated theme files as source-controlled design tokens. Do not edit package source in `.pub-cache`.

---

## 11. Dynamic theme system

### 11.1 Required settings

```dart
enum AppThemeMode {
  system,
  light,
  dark,
}

enum AppAccent {
  neutral,
  green,
  blue,
  amber,
  rose,
  violet,
}

class AppThemeSettings {
  final AppThemeMode mode;
  final AppAccent accent;
  final double fontScale;
  final bool useSystemAccent;
}
```

The final implementation may use Freezed, but these concepts must remain framework-independent.

### 11.2 Behavior

The theme controller must support:

- `system`, `light`, and `dark` modes.
- Runtime accent switching without restarting the application.
- A configurable application font multiplier.
- Separate light and dark palettes for every supported accent.
- Optional system accent adoption when a future platform implementation is added.
- Touch and desktop ForUI density variants.
- Immediate persistence through `SharedPreferencesAsync`.
- Reset-to-default behavior.

### 11.3 Font scaling

Recommended initial range:

```text
Minimum: 0.85×
Default: 1.00×
Maximum: 1.60×
Step:    0.05×
```

Application font scaling must not erase the operating system's accessibility text scaling. Combine the app multiplier with the system text scaler and apply a defensive upper bound only where layout safety requires it.

Do not globally force one font family for every script. The theme should permit script-specific font families when additional locales are introduced. ForUI's recent theme system supports multiple typefaces, which fits this requirement.

### 11.4 Persistence keys

Centralize keys and never use raw strings outside the preferences adapter:

```text
appearance.theme_mode
appearance.accent
appearance.font_scale
appearance.use_system_accent
privacy.analytics_enabled
privacy.crash_reporting_enabled
localization.locale
```

---

## 12. Localization

### 12.1 Initial locales

| Language           | Locale | Direction |
| ------------------ | ------ | --------- |
| English            | `en`   | LTR       |
| Arabic             | `ar`   | RTL       |
| Simplified Chinese | `zh`   | LTR       |

### 12.2 Tooling

Use Slang with its Flutter integration and `build_runner`. Keep translations in JSON and generate a type-safe API.

```yaml
targets:
  $default:
    builders:
      slang_build_runner:
        options:
          base_locale: en
          fallback_strategy: base_locale
          input_directory: lib/i18n
          input_file_pattern: .i18n.json
          output_directory: lib/i18n
          output_file_name: translations.g.dart
          locale_handling: true
          flutter_integration: true
```

Generate with:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Initialize the saved or device locale before rendering the app and wrap the root widget with `TranslationProvider`. UI code uses the generated `t` API rather than raw string keys.

### 12.3 Locale controller

The language settings must support system default, English, Arabic, and Simplified Chinese. Persist explicit selections with `SharedPreferencesAsync`; selecting system default removes the override and delegates to Slang's device-locale handling.

### 12.4 Translation rules

- Never concatenate translated fragments to form a sentence.
- Use placeholders for values.
- Use plural/select messages where required.
- Keep keys semantic, for example `settingsAppearanceTitle`, not `text17`.
- Keep every locale structurally aligned with the base locale and fail CI on missing translations.
- Test RTL layout independently; successful translation does not guarantee correct directionality.
- Do not hardcode alignment as left/right when start/end is appropriate.
- Validate typography and line height for every supported script.

### 12.5 Localization smoke tests

For every supported locale, verify:

- App starts successfully.
- No missing localization exception occurs.
- Theme controls remain usable.
- Navigation remains usable.
- Directionality matches the locale.
- Long translated strings do not overflow the boilerplate screen.

---

## 13. Analytics abstraction

Firebase must not be referenced outside its adapter.

### 13.1 Interface

```dart
abstract interface class Analytics {
  Future<void> setEnabled(bool enabled);

  Future<void> track(
    String name, {
    Map<String, Object?> parameters = const {},
  });

  Future<void> trackScreen({
    required String screenName,
    String? screenClass,
  });

  Future<void> setUserId(String? anonymousUserId);

  Future<void> setUserProperty({
    required String name,
    required String? value,
  });

  Future<void> reset();
}
```

### 13.2 Implementations

```text
FirebaseAnalyticsAdapter
DebugAnalyticsAdapter
NoopAnalytics
CompositeAnalytics
```

`CompositeAnalytics` allows a later provider to be added without changing feature code.

### 13.3 Navigation analytics

Do not directly attach `FirebaseAnalyticsObserver` to the router. Implement an `AnalyticsNavigatorObserver` that depends only on `Analytics`.

This keeps screen tracking vendor-neutral and testable.

### 13.4 Event conventions

- Use lowercase `snake_case` event names.
- Define events centrally as typed constants or sealed event objects.
- Avoid arbitrary event names generated inside widgets.
- Include a schema version for complex events.
- Keep parameter types simple and predictable.
- Add tests that fail when event names or required parameters change unexpectedly.

### 13.5 Privacy rules

Never send:

- Raw user-entered text.
- Search terms by default.
- Product content or user-generated content.
- Email addresses, names, phone numbers, precise location, or device identifiers.
- Access tokens, URLs containing tokens, headers, or request bodies.

Analytics should be disabled in tests and normally disabled in debug builds. Provide a user-facing opt-out setting before production release.

---

## 14. Crash-reporting abstraction

### 14.1 Interface

```dart
abstract interface class CrashReporter {
  Future<void> setEnabled(bool enabled);
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
    String? reason,
    Map<String, Object?> context = const {},
  });
  Future<void> log(String message);
  Future<void> setUserId(String? anonymousUserId);
  Future<void> setKey(String key, Object value);
}
```

### 14.2 Implementations

```text
FirebaseCrashReporter
DebugCrashReporter
NoopCrashReporter
```

### 14.3 Platform behavior

Firebase Crashlytics currently covers Android, iOS, and macOS through the Flutter plugin. Windows and Linux must receive `NoopCrashReporter` initially.

Do not scatter checks such as `if (Platform.isWindows)` throughout the application. Resolve the proper adapter once during bootstrap.

When production-grade Windows/Linux crash reporting is required, add a second adapter, likely through `CompositeCrashReporter`, without changing application features.

### 14.4 Required crash context

Safe diagnostic keys may include:

```text
app_version
build_number
environment
platform
locale
theme_mode
accent
route_name
database_schema_version
```

Do not attach raw product content, user input, search queries, authorization headers, or full local file paths.

---

## 15. Performance monitoring

Use a provider-neutral interface:

```dart
abstract interface class PerformanceMonitor {
  Future<T> trace<T>(
    String name,
    Future<T> Function() operation,
  );
}
```

Initial implementations:

```text
FirebasePerformanceMonitor
DebugPerformanceMonitor
NoopPerformanceMonitor
```

Firebase Performance is primarily useful on Android and iOS. Unsupported desktop targets must use a no-op implementation.

Instrument only meaningful operations. Do not wrap every function call.

Initial generic traces may include:

```text
app_bootstrap
open_database
load_preferences
first_route_ready
```

---

## 16. Logging

Use `AppLogger`, not Talker directly outside the adapter.

Suggested interface:

```dart
abstract interface class AppLogger {
  void debug(String message, {Map<String, Object?> context = const {}});
  void info(String message, {Map<String, Object?> context = const {}});
  void warning(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  });
  void error(
    String message, {
    required Object error,
    required StackTrace stackTrace,
    Map<String, Object?> context = const {},
  });
}
```

Rules:

- Use structured context rather than string interpolation where possible.
- Apply a central redactor before logs reach Talker or Crashlytics.
- Never log tokens, request bodies, user content, secure-storage values, or full database rows.
- Verbose network logs must be development-only.
- Production logs should be sparse and actionable.
- A developer-only log viewer may be added later, but it must not be routable in production.

---

## 17. Storage and caching model

“Cache” is intentionally split into distinct layers.

### 17.1 L1: Riverpod runtime state

Use Riverpod for:

- In-memory state.
- Async loading/error/data state.
- Request deduplication at the provider level.
- Automatic disposal where appropriate.
- Refresh/invalidation orchestration.

Riverpod is not the durable database.

### 17.2 L2: Shared preferences

Use `SharedPreferencesAsync` only for small, non-critical settings:

- Theme mode.
- Accent.
- Font scale.
- Locale override.
- Analytics/crash-reporting consent.

Do not store collections, user-generated content, transfer records, or tokens here.

### 17.3 L3: Drift database

Drift is the durable structured source of truth.

The boilerplate database may initially contain only infrastructure tables such as:

```text
schema_metadata
app_migrations
```

Do not invent domain tables before features are designed.

Every migration must have a migration test. Keep schema snapshots under version control.

### 17.4 L4: Secure storage

Use secure storage for future credentials, refresh tokens, and encryption keys. The boilerplate should expose the interface and adapter but should not write placeholder secrets.

### 17.5 L5: HTTP cache

Use `dio_cache_interceptor` only for cacheable HTTP requests.

Rules:

- Respect `Cache-Control`, `ETag`, and `Last-Modified` where possible.
- Default authenticated requests to no-store unless explicitly designed otherwise.
- Do not cache error responses by default.
- Do not cache sensitive response bodies in a generic shared cache.
- Prefer a memory cache initially; add a persistent store only after actual endpoint requirements exist.
- Durable business data should be normalized into Drift rather than hidden indefinitely in an HTTP cache.

### 17.6 L6: File storage

Permanent application-managed files belong in an application support/documents location and should be tracked by Drift when a feature requires durable file metadata.

Disposable files belong in the cache directory and may be removed by the operating system.

Do not use temporary cache storage for anything the user expects to remain available offline.

### 17.7 Image caching

Flutter already has an in-memory `ImageCache`. Do not add `cached_network_image` until the application actually displays remote images requiring disk caching and placeholders.

---

## 18. Networking

Expose a narrow `ApiClient` or endpoint-specific repositories instead of passing `Dio` into widgets or controllers.

Dio configuration should include:

- Sensible connection, send, and receive timeouts.
- Request IDs.
- Safe retry policy for idempotent requests only.
- Cache interceptor where explicitly enabled.
- Development-only sanitized request logging.
- Central error mapping into `NetworkFailure` types.
- Cancellation support for user-abandoned operations.

Do not use `connectivity_plus` as a gate before every request. Attempt the request and handle failure. Connectivity state may later improve messaging, but it is not proof of internet access.

---

## 19. Reusable capability foundations

### 19.1 Audio

Expose `just_audio`, `audio_session`, and `audio_service` through an application-owned `AppAudioService`. Include a no-op implementation for tests and unsupported configurations. Initialization must be lazy, and the boilerplate must not start playback, create a media notification, or bundle sample audio.

The interface should support local files, remote streams, playlists, playback speed, and background controls without leaking package types into features.

### 19.2 Background downloads

Wrap `background_downloader` behind `DownloadService` with watch, enqueue, pause, resume, cancel, and reconcile operations. Downloads should use partial files, verify expected size/checksum when supplied, move completed files atomically, and persist authoritative task metadata in Drift.

The real adapter initializes lazily. The boilerplate UI may expose a generic development-only transfer demo, but it must not ship a product-specific download catalog.

### 19.3 Notifications

Keep `flutter_local_notifications` behind `NotificationService`. Support immediate and scheduled local notifications, cancellation, timezone-aware scheduling, and test/no-op adapters.

Do not request notification permission at startup. Request it in context when the user enables a notification workflow. `workmanager` remains excluded because background workers are best-effort and are not a replacement for operating-system notification scheduling.

### 19.4 Forms

Use `flutter_form_builder` for reusable form state, validation, initial values, dirty-state tracking, and submission. Wrap common fields in app-owned components so ForUI styling, accessibility, localization, and server-error mapping remain consistent.

Feature code owns its form schema and submission behavior. Do not introduce a global form singleton, pass raw untyped maps beyond the form boundary, or place API calls inside field validators.

### 19.5 UI search

Provide an app-styled `AppSearchField` and a reusable Riverpod search-query controller. The UI foundation must support clear, submit, debounce, loading, empty, error, and keyboard-focus states without defining a product-specific index or result model.

Search cancellation must discard stale results. Query normalization and tokenizer behavior belong to the feature or data source because requirements vary by corpus and locale.

---

## 20. Routing

Use `go_router` with named routes.

The initial route tree should remain minimal:

```text
/
/settings/appearance
/settings/language
/settings/privacy
/dev/diagnostics   # development builds only
/dev/components    # development builds only
```

The settings screens are infrastructure controls, not application-specific features.

Rules:

- Route names and paths are centralized.
- Navigation analytics observes route changes through the analytics abstraction.
- Redirect logic does not access Firebase or storage directly.
- Development routes are completely unavailable in production builds.
- Deep links must be accepted only for explicitly registered routes.

---

## 21. Initial boilerplate UI

The application may contain a minimal ForUI-based shell demonstrating only infrastructure:

- A home screen that confirms successful startup.
- Appearance settings:
  - system/light/dark mode
  - accent selector
  - font-size slider
  - reset button
- Language settings:
  - system default
  - English
  - Arabic
  - Simplified Chinese
- Privacy settings:
  - analytics toggle
  - crash-reporting toggle
- Development-only diagnostics:
  - environment
  - app/build version
  - platform capability matrix
  - reusable form and UI-search examples
  - audio/download/notification adapter status
  - test analytics event
  - test non-fatal error

Do not include product-specific placeholder content. Generic UI labels are sufficient.

---

## 22. Firebase platform boundary

Use adapter factories selected during bootstrap.

Indicative initial matrix:

| Capability           | Android |  iOS |           macOS | Windows | Linux |                    Web |
| -------------------- | ------: | ---: | --------------: | ------: | ----: | ---------------------: |
| Firebase Analytics   |     Yes |  Yes |             Yes |   No-op | No-op |                    Yes |
| Firebase Crashlytics |     Yes |  Yes |             Yes |   No-op | No-op |                  No-op |
| Firebase Performance |     Yes |  Yes | No-op initially |   No-op | No-op | Verify before enabling |

The build must still compile and run when Firebase is unavailable or intentionally disabled.

Do not make Firebase a requirement for opening the local app shell.

---

## 23. Consent and privacy defaults

Recommended initial policy:

| Environment | Analytics                                                  | Crash reporting                                            |
| ----------- | ---------------------------------------------------------- | ---------------------------------------------------------- |
| Development | Off; debug logger adapter                                  | Off; debug logger adapter                                  |
| Test/CI     | Off                                                        | Off                                                        |
| Staging     | Explicit configuration                                     | Explicit configuration                                     |
| Production  | Controlled by persisted user preference and release policy | Controlled by persisted user preference and release policy |

Before public release, provide a clear privacy explanation and allow collection to be changed later from settings.

The app must work normally with all telemetry disabled.

---

## 24. Testing strategy

### Unit tests

Cover:

- Theme mode/accent/font-scale transitions.
- Preference serialization and invalid-value fallback.
- Slang generation, locale selection, and base-locale fallback.
- Form validation, value transformation, reset, and server-error mapping.
- Search debouncing, cancellation, and stale-result rejection.
- Audio, download, and notification no-op adapters.
- Analytics event validation.
- Analytics, crash, and performance no-op adapters.
- Log redaction.
- Platform adapter selection.
- Bootstrap failure mapping.

### Widget tests

Cover:

- Light and dark theme rendering.
- Every accent palette.
- Minimum/default/maximum font scaling.
- English, Arabic RTL, and Simplified Chinese localization.
- App-styled form fields and validation messages.
- Search loading, empty, error, clear, and keyboard-focus states.
- Settings persistence behavior using fakes.
- No overflow at common compact dimensions.

### Golden tests

At minimum:

```text
English / light / default scale
English / dark / maximum scale
Arabic / light / default scale
Arabic / dark / maximum scale
Chinese / light / default scale
Desktop-density shell
Touch-density shell
```

### Integration tests

Initial smoke test:

1. Launch the app.
2. Change theme mode.
3. Change accent.
4. Change font scale.
5. Change language to Arabic and verify RTL.
6. Restart and verify settings persisted.
7. Exercise the generic form and search examples.
8. Verify telemetry and capability adapters do not crash unsupported platforms.

Use Patrol for native notification, download, and background-audio workflows.

---

## 25. CI requirements

Every pull request should run:

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

Add code-generation drift detection:

```bash
dart run build_runner build --delete-conflicting-outputs
git diff --exit-code
```

Recommended build matrix:

| Runner  | Checks                                                     |
| ------- | ---------------------------------------------------------- |
| Ubuntu  | Dart checks, unit/widget tests, Android build, Linux build |
| macOS   | iOS build, macOS build                                     |
| Windows | Windows build                                              |

Web compilation can be added if web remains a supported target.

Firebase-dependent integration tests must use staging configuration and must never write analytics/crash data from normal unit tests.

---

## 26. Dependency maintenance

Because ForUI is still pre-1.0, minor version changes may contain breaking changes and Dart's normal caret behavior does not automatically cross every pre-1.0 minor line.

Maintenance routine:

```bash
flutter pub outdated
flutter pub upgrade
flutter pub upgrade forui --major-versions
dart fix --apply
flutter analyze
flutter test
```

Review changelogs before upgrading:

- Flutter stable.
- ForUI.
- Riverpod.
- Drift/sqlite3.
- FlutterFire.
- Slang.
- `flutter_form_builder`.
- `background_downloader`.
- `just_audio` / `audio_service`.
- `flutter_local_notifications`.

Never merge an automated dependency upgrade without running the platform build matrix.

---

## 27. Implementation sequence

### Phase 1 — Project baseline

- Create Flutter project with all required native targets.
- Enable strict analysis.
- Add build flavors/environments.
- Add CI formatting, analysis, tests, and platform builds.

### Phase 2 — UI and routing

- Install ForUI.
- Generate source-controlled theme tokens.
- Add `go_router` and the minimal app shell.
- Add touch/desktop density selection.

### Phase 3 — Theme and localization

- Implement persisted theme settings.
- Add accent palettes and app font scaling.
- Configure Slang and add English, Arabic, and Simplified Chinese JSON translations.
- Add locale switching, RTL, generation, and large-text tests.

### Phase 4 — Observability

- Add logger, analytics, crash-reporting, and performance interfaces.
- Add Firebase adapters and unsupported-platform no-op adapters.
- Register global error handlers.
- Add consent toggles.

### Phase 5 — Storage and network foundations

- Add SharedPreferencesAsync wrapper.
- Add secure-storage wrapper.
- Add empty Drift database with migration tests.
- Add configured Dio client and explicit cache policy.

### Phase 6 — Reusable app capabilities

- Add `flutter_form_builder` wrappers and a development-only form example.
- Add the reusable UI search field and Riverpod query controller.
- Add audio, download, and notification interfaces with lazy/no-op adapters.
- Confirm no capability starts work or requests permission during launch.

### Phase 7 — Hardening

- Add unit, widget, golden, and smoke tests.
- Verify all native targets compile.
- Verify app startup with Firebase unavailable.
- Verify app startup with all telemetry disabled.

---

## 28. Definition of done

The boilerplate is complete when:

- [ ] Android, iOS, macOS, Windows, and Linux builds are green.
- [ ] The app uses ForUI and has no competing UI kit architecture.
- [ ] Theme mode changes among system/light/dark at runtime.
- [ ] Accent changes at runtime.
- [ ] Font scaling changes at runtime while respecting accessibility scaling.
- [ ] Theme settings survive restart.
- [ ] Slang generates type-safe English, Arabic, and Simplified Chinese translations.
- [ ] Locale selection, persistence, fallback, and RTL behavior work at runtime.
- [ ] Reusable Form Builder fields are app-styled, localized, and tested.
- [ ] Generic UI search handles debounce, cancellation, focus, and all result states.
- [ ] Analytics is accessed only through the wrapper.
- [ ] Crash reporting is accessed only through the wrapper.
- [ ] Performance traces are accessed only through the wrapper.
- [ ] Firebase is absent from features and UI code.
- [ ] Windows/Linux run with safe no-op Firebase adapters.
- [ ] Shared Preferences, secure storage, Drift, and Dio are accessed only through core abstractions.
- [ ] Audio, downloads, and notifications are available through application-owned interfaces.
- [ ] Audio, downloads, and notifications initialize lazily and request no permissions on startup.
- [ ] Telemetry can be disabled without reducing core app functionality.
- [ ] Logs redact sensitive data.
- [ ] Unit, widget, localization, theme, and smoke tests pass.
- [ ] Generated code is committed and CI detects stale generation.
- [ ] No product-specific feature exists yet.

---

## 29. Final baseline summary

```text
Flutter + ForUI
├── Riverpod + go_router
├── Slang: type-safe en, ar, zh localization
├── flutter_form_builder + app-styled field wrappers
├── Reusable UI search field + Riverpod query state
├── Dynamic ForUI themes
│   ├── system/light/dark
│   ├── accent palettes
│   ├── touch/desktop density
│   └── accessible app font scaling
├── SharedPreferencesAsync
├── Drift + SQLite
├── flutter_secure_storage
├── Dio + explicit HTTP caching
├── Analytics wrapper -> Firebase Analytics / debug / no-op
├── Crash wrapper -> Firebase Crashlytics / debug / no-op
├── Performance wrapper -> Firebase Performance / debug / no-op
├── Talker-backed redacted logging
├── Lazy audio foundation
├── Lazy background-download foundation
├── Lazy local-notification foundation
└── Strict tests and multi-platform CI
```

This architecture keeps the boilerplate completely domain-neutral while creating stable seams for future application capabilities.

---

## 30. Primary references

- ForUI getting started: https://forui.dev/docs/getting-started
- ForUI themes: https://forui.dev/docs/concepts/themes
- ForUI CLI: https://forui.dev/docs/reference/cli
- ForUI localization: https://forui.dev/docs/concepts/localization
- Flutter internationalization: https://docs.flutter.dev/ui/internationalization
- Slang: https://pub.dev/packages/slang
- `slang_flutter`: https://pub.dev/packages/slang_flutter
- `flutter_form_builder`: https://pub.dev/packages/flutter_form_builder
- Firebase Flutter setup: https://firebase.google.com/docs/flutter/setup
- Firebase Analytics for Flutter: https://firebase.google.com/docs/analytics/flutter/get-started
- Firebase Crashlytics for Flutter: https://firebase.google.com/docs/crashlytics/flutter/get-started
- Drift Flutter setup: https://drift.simonbinder.eu/setup/
- Riverpod: https://riverpod.dev/
- `go_router`: https://pub.dev/packages/go_router
- `background_downloader`: https://pub.dev/packages/background_downloader
- `just_audio`: https://pub.dev/packages/just_audio
- `audio_service`: https://pub.dev/packages/audio_service
- `flutter_local_notifications`: https://pub.dev/packages/flutter_local_notifications
- `shared_preferences`: https://pub.dev/packages/shared_preferences
