# Compact Cross-Platform Flutter Starter

**Status:** Architecture baseline

**Scope:** A compact, reusable Flutter application starter with no product-specific features

**Baseline date:** 21 July 2026

**Primary targets:** Android, iOS, macOS, Windows, and Linux

**Optional target:** Web

---

## 1. Purpose

This document defines a small but durable starting point for a Flutter application that runs well on touch and desktop devices.

The baseline must provide:

- A feature-first project structure that can grow without creating a `core/` junk drawer.
- One application entrypoint with explicit development, staging, and production configuration.
- ForUI as the sole application design system.
- ExUI as optional syntax sugar for basic Flutter layout only.
- Dartx for selective, non-UI Dart ergonomics.
- Simple Animations for purposeful custom and multi-property motion.
- Riverpod for state composition and dependency injection.
- Declarative routing with `go_router`.
- Adaptive compact, medium, and expanded layouts.
- Runtime theme, accent, text-scale, and locale settings.
- Type-safe English, Arabic, and Simplified Chinese localization with Slang.
- A small preferences and logging foundation used by the starter itself.
- Strict analysis, focused tests, and multi-platform CI.

The starter must make the first product feature easy to add. It must not pre-build infrastructure for hypothetical features.

The companion [initial UI plan](initial_ui.md) defines the first static screens used to exercise these architecture decisions.

---

## 2. Guiding principles

### 2.1 Start concrete and extract at real boundaries

Use a plain class, function, widget, or Riverpod provider first. Introduce an interface only when at least one of these is true:

- Two real implementations exist.
- Platforms require materially different implementations.
- A vendor type would otherwise leak into application or feature code.
- Tests need a substitute that cannot be provided cleanly through a provider override.
- The abstraction expresses meaningful application behavior rather than merely renaming a package API.

Do not create `BaseRepository`, `BaseService`, `Manager`, or generic CRUD layers.

### 2.2 Keep features together

A feature owns its UI, state, validation, models, and feature-specific data access. Files that change for the same product requirement should usually live near each other.

### 2.3 Add packages when code uses them

An approved package is not automatically an installed package. Install a dependency in the same change that introduces its first real caller and test.

### 2.4 Adapt to available space, not device labels

Layout decisions use the current window or parent constraints. A narrow desktop window may use the compact layout, while a large tablet may use an expanded layout.

Platform checks are reserved for capabilities, native policy, and plugin support.

### 2.5 Optimize for readability before line count

Compact code is useful when intent remains obvious. Avoid clever extension chains, giant widgets, and abstractions that hide Flutter's layout model.

---

## 3. Technical decisions

### 3.1 Baseline decisions

| Concern | Decision |
| --- | --- |
| Framework | Flutter stable `3.44.0+` with Dart `3.12.0+` |
| Design system | ForUI |
| Layout ergonomics | ExUI core extensions, used selectively |
| Dart ergonomics | Dartx extensions, used selectively |
| Custom motion | Flutter animation primitives first; Simple Animations for coordinated motion |
| State and dependency injection | Riverpod |
| Routing | `go_router` |
| Localization | Slang + `slang_flutter` with JSON source files |
| Small persisted settings | `SharedPreferencesAsync` |
| Local diagnostics | Application logger backed by Talker |
| Unit and widget tests | Flutter Test + Mocktail where a mock is genuinely useful |
| Static analysis | `very_good_analysis`, `custom_lint`, and `riverpod_lint` |

### 3.2 Approved on first use

| Capability | Preferred package | Add when |
| --- | --- | --- |
| Multi-field forms | `flutter_form_builder` | A real feature has a form whose state or validation benefits from it. |
| Structured persistence | Drift + SQLite | A feature has durable records or queries. Do not create an empty database. |
| Sensitive storage | `flutter_secure_storage` | Credentials, encryption keys, or other sensitive values exist. |
| Networking | Dio | The first remote endpoint is implemented. |
| HTTP caching | `dio_cache_interceptor` | An endpoint has explicit cache semantics. |
| Generated immutable models | Freezed + JSON Serializable | Model volume makes generation cheaper than handwritten types. |
| Analytics | Firebase Analytics behind an application contract | Production telemetry requirements and consent behavior are defined. |
| Crash reporting | Firebase Crashlytics behind an application contract | A supported release target needs remote crash reporting. |
| Performance telemetry | Firebase Performance behind an application contract | Meaningful operations have been selected for tracing. |
| Audio | `just_audio`, `audio_session`, optionally `audio_service` | A concrete playback workflow exists. |
| Background downloads | `background_downloader` | A concrete downloadable resource exists. |
| Local notifications | `flutter_local_notifications` + `timezone` | A user-facing notification workflow exists. |
| Native end-to-end tests | Patrol | The first permission, notification, background, or native integration workflow exists. |

### 3.3 Explicit exclusions

Do not add these without a written architectural reason:

- A second state-management or dependency-injection framework.
- A second localization framework.
- A second HTTP client.
- Hive alongside Drift for the same structured data.
- A generic React Query clone before substantial remote server state exists.
- Connectivity checks that block network requests.
- Empty platform-service interfaces with no caller.
- No-op implementations created only to satisfy a folder diagram.

---

## 4. Initial dependencies

Install and exercise only the compact baseline:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # UI
  forui:
  exui:
  simple_animations:

  # Dart ergonomics
  dartx:

  # State and routing
  flutter_riverpod:
  riverpod_annotation:
  go_router:

  # Localization
  intl:
  slang:
  slang_flutter:

  # Settings and diagnostics
  shared_preferences:
  talker_flutter:
  package_info_plus:

dev_dependencies:
  flutter_test:
    sdk: flutter

  build_runner:
  riverpod_generator:
  slang_build_runner:
  mocktail:
  very_good_analysis:
  custom_lint:
  riverpod_lint:
```

Add packages through `flutter pub add`, review the generated constraints, and commit `pubspec.lock` because this is an application.

```bash
flutter pub add \
  forui exui simple_animations dartx \
  flutter_riverpod riverpod_annotation go_router \
  intl slang slang_flutter \
  shared_preferences talker_flutter package_info_plus

flutter pub add --dev \
  build_runner riverpod_generator slang_build_runner \
  mocktail very_good_analysis custom_lint riverpod_lint
```

Generate ForUI theme files without allowing the CLI to define the application architecture:

```bash
dart run forui theme create
```

Run code generation with:

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## 5. Project structure

Create directories when they contain real code. The intended shape is:

```text
config/
├── development.json
├── staging.json
└── production.json

lib/
├── main.dart
├── bootstrap.dart
│
├── app/
│   ├── app.dart
│   ├── dependencies.dart
│   ├── config/
│   │   ├── app_config.dart
│   │   └── app_environment.dart
│   ├── routing/
│   │   ├── app_router.dart
│   │   └── app_routes.dart
│   └── shell/
│       ├── app_shell.dart
│       ├── compact_app_shell.dart
│       └── expanded_app_shell.dart
│
├── features/
│   ├── home/
│   │   └── home_page.dart
│   └── settings/
│       ├── settings_controller.dart
│       ├── settings_state.dart
│       ├── settings_repository.dart
│       ├── settings_page.dart
│       ├── layouts/
│       │   ├── settings_compact_layout.dart
│       │   └── settings_expanded_layout.dart
│
├── shared/
│   ├── adaptive/
│   │   ├── app_layout_class.dart
│   │   └── app_interaction_policy.dart
│   ├── theme/
│   │   ├── app_spacing.dart
│   │   ├── app_sizes.dart
│   │   ├── app_theme.dart
│   │   └── forui_theme_factory.dart
│   └── motion/
│       └── app_motion.dart
│
├── infrastructure/
│   ├── logging/
│   │   ├── app_logger.dart
│   │   └── log_redactor.dart
│   └── platform/
│       └── platform_capabilities.dart
│
└── i18n/
    ├── strings.i18n.json
    ├── strings_ar.i18n.json
    ├── strings_zh.i18n.json
    └── translations.g.dart

test/
├── app/
├── features/
├── shared/
└── infrastructure/
```

This is a destination, not a request to create every listed folder on day one.

### 5.1 Folder responsibilities

- `app/` is the composition root. It may import features, shared code, and infrastructure.
- `features/` contains user-visible behavior grouped by product capability.
- `shared/` contains vendor-independent code reused by at least two features or by the app shell.
- `infrastructure/` contains cross-feature plugin setup, operating-system integration, shared clients, and vendor adapters.
- Feature-specific data adapters remain with their feature; for example, the settings preferences repository stays under `features/settings/`.
- `i18n/` owns translation sources and generated localization output.
- Native implementation code remains in `android/`, `ios/`, `macos/`, `windows/`, and `linux/`.

### 5.2 Dependency direction

```text
app ───────────────► features
 │                     │
 ├───────────────► shared ◄──────────────┐
 │                                       │
 └───────────────► infrastructure ───────┘
```

Rules:

- `shared/` must not import from `features/` or `infrastructure/`.
- Feature UI and controllers must not call Firebase, Dio, Drift, Shared Preferences, or platform plugins directly.
- `app/dependencies.dart` constructs app-wide infrastructure and feature dependencies, then binds them to Riverpod providers.
- One feature must not import another feature's internal files. Promote a genuinely shared concept or expose a narrow public contract.
- Infrastructure must not contain product UI.
- Avoid barrel files until a directory has a stable public API worth protecting.

### 5.3 Keeping features compact

Start a feature flat. Add `presentation/`, `application/`, `domain/`, or `data/` subdirectories only when the flat directory becomes difficult to navigate or the boundaries are real.

Keep related small types together:

- A state class and its small enums may share one file.
- Private one-use widgets may remain beside the page.
- Extract a widget when it is reused, independently testable, or makes the parent build method difficult to scan.
- Split a file when it contains unrelated reasons to change, not merely because it crossed an arbitrary line count.

Avoid vague files such as `utils.dart`, `helpers.dart`, `common.dart`, and `constants.dart`. Name files after their responsibility.

---

## 6. Environment and entrypoint strategy

Support three independent application environments:

```text
development
staging
production
```

Use one Dart entrypoint:

```text
lib/main.dart
```

```dart
Future<void> main() async {
  final config = AppConfig.fromEnvironment();
  await bootstrap(config);
}
```

Read non-secret compile-time values through `--dart-define-from-file`:

```bash
flutter run \
  --dart-define-from-file=config/development.json

flutter build windows \
  --dart-define-from-file=config/production.json
```

Each configuration defines at least:

```text
APP_ENV
ENABLE_VERBOSE_LOGGING
ENABLE_DEV_TOOLS
```

Add API, Firebase, telemetry, or other capability-specific keys only when that capability is implemented.

Rules:

- Missing or unknown `APP_ENV` must fail with an actionable startup error.
- Production CI must explicitly pass `config/production.json`.
- Compile-time client configuration is discoverable and must not contain secrets.
- Use native Android/iOS/macOS flavors when the environment changes the app name, identifier, icon, Firebase files, signing, or entitlements.
- Keep native flavor names aligned with `development`, `staging`, and `production`.
- Mobile and desktop are platforms, not environments, and must not have separate `main` files.
- Build mode (`debug`, `profile`, `release`) must not select the backend environment implicitly.

The production build must never fall back to development configuration.

---

## 7. Application bootstrap

Bootstrap only what is required to render the application safely:

1. Call `WidgetsFlutterBinding.ensureInitialized()`.
2. Validate `AppConfig` and the environment.
3. Create the redacted application logger.
4. Register Flutter, platform, and zoned error handlers.
5. Create the preferences dependency used by settings.
6. Load only the settings needed to avoid an incorrect first frame.
7. Create Riverpod overrides and run the application.
8. Place Slang's translation provider at the required root boundary.

Do not initialize Firebase, a database, audio, downloads, notifications, or permissions in the baseline bootstrap.

When future capabilities are added:

- Initialize only required, startup-critical services before `runApp`.
- Initialize optional services lazily from their first use.
- Never request permissions during generic startup.
- Show a small recoverable startup failure view instead of a permanent blank screen.

---

## 8. UI ergonomics and motion policy

### 8.1 ForUI owns the design system

Use ForUI for:

- Themes and design tokens.
- Buttons, inputs, cards, tiles, dialogs, sheets, and feedback.
- Bottom navigation, headers, sidebars, and other navigation surfaces.
- Focus, hover, disabled, error, and interaction states supplied by the kit.

Material widgets may be used when Flutter or a plugin requires them, but they must visually align with the active ForUI theme.

Suggested root composition:

```text
ProviderScope
└── TranslationProvider
    └── MaterialApp.router
        └── FTheme
            └── AppShell
```

Keep generated ForUI theme files in source control. Never edit package source under `.pub-cache`.

### 8.2 ExUI owns only layout ergonomics

Import only the universal core library:

```dart
import 'package:exui/exui.dart';
```

Do not import ExUI's Material or Cupertino libraries. They construct competing styled controls.

Good ExUI uses include:

- Padding and safe-area wrappers.
- Alignment and centering.
- Width and height constraints.
- `Expanded` and `Flexible` wrappers.
- Small, obvious row or column compositions.

Rules:

- Use application spacing and size tokens rather than scattered numbers.
- Keep chains short; three wrapper operations is the normal maximum.
- Import ExUI directly in files that use it; do not re-export its broad extension surface from a project-wide barrel.
- Use explicit Flutter widgets when wrapper order or constraints are important to understanding the layout.
- Do not use ExUI styling helpers to bypass ForUI colors, borders, radii, typography, or interaction states.
- Do not add gesture wrappers around an already interactive ForUI control.
- ExUI reduces source boilerplate only; it does not replace adaptive layout or improve runtime performance.

Example:

```dart
return content
    .maxWidth(AppSizes.readableContent)
    .paddingHorizontal(AppSpacing.lg)
    .center();
```

### 8.3 Dartx owns only non-UI ergonomics

Import Dartx directly where a specific extension makes the code clearer:

```dart
import 'package:dartx/dartx.dart';
```

Good uses include readable collection sorting, grouping, distinct selection, safe slicing, and small null/string helpers.

Rules:

- Prefer the Dart SDK when its API is equally clear.
- Do not re-export Dartx from a project-wide barrel; its broad extensions can collide with SDK or package APIs.
- Do not use locale-insensitive helpers such as `capitalize()` for translated UI copy.
- Do not use convenience hashes such as MD5 for passwords, signatures, or other security decisions.
- Keep timezone, calendar, and business-date rules explicit; duration helpers do not replace domain-aware time handling.
- When a newer Dart SDK subsumes an extension, migrate to the SDK API during dependency maintenance.

### 8.4 Simple Animations owns coordinated custom motion

Use Flutter's built-in implicit animation widgets first for a single straightforward transition. Use Simple Animations when a UI needs coordinated properties, staggered scenes, a managed controller, or a reusable custom timeline.

Rules:

- ForUI owns animation inside ForUI components. Do not wrap controls merely to override their native interaction motion.
- Centralize shared durations and curves in `shared/motion/app_motion.dart`; feature-specific tweens remain with their feature.
- Prefer typed `MovieTweenProperty<T>` values over string keys for maintained timelines.
- Pass static content through animation-builder `child` parameters so it does not rebuild every frame.
- Respect `MediaQuery.disableAnimationsOf(context)` and provide an immediate or reduced-motion result.
- Motion must not be the only way to communicate state or meaning.
- Avoid infinite looping animations unless the workflow requires them; pause off-screen work and honor `TickerMode`.
- Do not animate expensive full-screen layout changes during live window resizing by default.
- Keep animation state local to the presentation layer unless another part of the application genuinely consumes it.

The baseline should exercise Simple Animations with one small, purposeful multi-property transition, such as an appearance-preview change. Do not add decorative motion merely to prove the dependency is installed.

---

## 9. Adaptive mobile and desktop layout

### 9.1 Separate layout, interaction, and capability

Use three independent concepts:

| Concept | Examples | Source |
| --- | --- | --- |
| Layout class | compact, medium, expanded | Available logical width |
| Interaction policy | touch, precision pointer, hybrid | Input capabilities and app policy |
| Platform capability | notifications, background audio, filesystem behavior | Runtime/plugin support |

Do not infer all three from `Platform.isAndroid` or `Platform.isWindows`.

### 9.2 Initial window classes

Use ForUI's theme breakpoints as the canonical numeric source and map them into the application-owned layout class:

```dart
enum AppLayoutClass {
  compact,
  medium,
  expanded;

  static AppLayoutClass fromWidth(
    double width, {
    required double compactMax,
    required double expandedMin,
  }) {
    if (width < compactMax) return compact;
    if (width < expandedMin) return medium;
    return expanded;
  }
}
```

Initially pass `context.theme.breakpoints.sm` (`640`) as `compactMax` and `context.theme.breakpoints.lg` (`1024`) as `expandedMin`. Do not scatter those numbers or mix a second breakpoint scale into feature code. Adjust the ForUI theme tokens if real screens demonstrate better transition points.

Use:

- `MediaQuery.sizeOf(context)` for decisions about the whole application window.
- `LayoutBuilder` for decisions based on the space allocated to a particular widget.

Never use orientation or hardware labels as the primary layout switch.

### 9.3 Shell behavior

| Layout | Navigation | Typical content |
| --- | --- | --- |
| Compact | Bottom navigation or a compact header | One primary pane |
| Medium | Navigation rail or narrow sidebar | One primary pane with more breathing room |
| Expanded | Persistent ForUI sidebar | Constrained content or list/detail panes |

The app shell owns global navigation adaptation. A feature owns its internal layout adaptation.

Do not create global `mobile/` and `desktop/` source trees. When a feature needs structurally different layouts, use descriptive files such as:

```text
settings_compact_layout.dart
settings_expanded_layout.dart
```

Both layouts must share the same controller, state, validation, and small content widgets.

Changing window size must preserve feature state. Responsive rebuilding must not recreate repositories, providers, or navigation state unnecessarily.

Branch at the highest practical layout boundary. Do not scatter width checks through every leaf widget, and do not create a generic `ResponsiveWidget` abstraction until repeated use demonstrates a stable API.

### 9.4 Desktop requirements

Desktop readiness means more than rendering a wider mobile screen. Verify:

- Arbitrary window resizing, including a narrow desktop window.
- Keyboard focus traversal and visible focus states.
- Shortcuts for common actions where useful.
- Mouse, trackpad, scroll-wheel, and hover behavior.
- Selectable text where users reasonably expect it.
- Scrollbars for long desktop content.
- Context menus, tooltips, and drag/drop only when the feature benefits from them.
- Readable maximum widths for text, forms, and settings panels.
- List/detail or multi-pane layouts only where simultaneous context is valuable.

Touch layouts must preserve accessible target sizes and must not depend on hover.

### 9.5 Density policy

ForUI touch and desktop density must be selected through `AppInteractionPolicy`, not screen width alone. A tablet may have a mouse, and a desktop device may have a touchscreen.

Default safely when input capability is ambiguous, and allow future user override if the product needs it.

---

## 10. Theme and design tokens

The settings state supports:

```dart
enum AppThemeMode { system, light, dark }

enum AppAccent { neutral, green, blue, amber, rose, violet }

class SettingsState {
  final AppThemeMode themeMode;
  final AppAccent accent;
  final double fontScale;
  final String? locale;
}
```

Keep this handwritten until code generation provides a measurable benefit.

The theme system must provide:

- System, light, and dark modes.
- Separate light and dark palettes for every supported accent.
- Runtime accent changes without restart.
- Touch and precision-input density variants.
- Shared spacing, radius, and content-width tokens.
- Script-appropriate typography.
- Application text scaling that preserves operating-system accessibility scaling.

Initial application font multiplier:

```text
Minimum: 0.85×
Default: 1.00×
Maximum: 1.60×
Step:    0.05×
```

Centralize persisted keys inside `settings_repository.dart`:

```text
appearance.theme_mode
appearance.accent
appearance.font_scale
localization.locale
```

No other file may use these storage strings directly.

---

## 11. Localization

Initial locales:

| Language | Locale | Direction |
| --- | --- | --- |
| English | `en` | LTR |
| Arabic | `ar` | RTL |
| Simplified Chinese | `zh` | LTR |

Use Slang with JSON translation sources and committed generated output.

Rules:

- English is the base locale.
- Feature UI never embeds user-facing strings directly.
- Keys describe meaning, not English wording.
- Interpolation and pluralization remain type-safe.
- Layout uses directional APIs such as `EdgeInsetsDirectional` and `AlignmentDirectional`.
- Generated files are never edited manually.
- Locale selection and persistence belong to the settings feature.

Smoke-test every locale for startup, navigation, settings, fallback, and text direction.

---

## 12. State and dependency flow

Use Riverpod as the composition seam:

```text
Widget
  └── Controller/provider
        └── Feature repository or gateway, when needed
              └── Infrastructure adapter
```

Not every feature needs every level.

Rules:

- Local ephemeral UI state stays in the widget when no other consumer needs it.
- Riverpod owns shared, asynchronous, persisted, or cross-widget state.
- Controllers expose intent-based operations rather than package calls.
- Widgets render state and send user intent; they do not perform storage or network work.
- Provider overrides are the first testing seam.
- Extract an interface only when provider replacement alone is insufficient or a real boundary requires it.
- Plugin-specific types must stop at the infrastructure boundary.
- Avoid global mutable singletons. Dependencies are created in `app/dependencies.dart`.

For the initial settings feature, one `SettingsRepository` backed by `SharedPreferencesAsync` is sufficient. It does not need a separate interface and no-op implementation on day one.

---

## 13. Infrastructure activation rules

### 13.1 Preferences

Use `SharedPreferencesAsync` only for small, non-sensitive settings such as theme, locale, and telemetry consent.

Do not store collections, durable records, user content, transfer metadata, or credentials there.

### 13.2 Structured storage

Add Drift when the first durable domain table exists. Feature-specific tables and mapping code stay close to the owning feature; the shared database connection and migration runner live in `infrastructure/persistence/`.

Every schema change requires a migration test and a committed schema snapshot. Do not create infrastructure-only placeholder tables.

### 13.3 Secure storage

Add secure storage when sensitive values exist. Never write placeholder secrets simply to exercise the adapter.

### 13.4 Networking

Add Dio with the first endpoint. Prefer feature-specific repositories over a generic `ApiClient` that only forwards Dio methods.

Central infrastructure may own:

- Base configuration and timeouts.
- Request IDs and sanitized development logging.
- Authentication attachment when authentication exists.
- Cancellation and safe retry policy for idempotent requests.
- Shared error primitives that are meaningful across features.

Endpoint paths, DTOs, and response mapping belong to the owning feature.

Add HTTP caching only when an endpoint defines freshness and invalidation behavior. Do not use connectivity state as proof that a request will succeed.

### 13.5 Forms

Use native ForUI form controls for small settings interactions. Add `flutter_form_builder` when a real multi-field form needs coordinated validation, dirty state, reset behavior, or server-error mapping.

The feature owns the form schema and submission. API calls do not belong inside field validators.

### 13.6 Audio, downloads, and notifications

Add each capability with its first user-facing workflow. Keep permission requests contextual and initialization lazy.

Create an application contract when the workflow needs testing, platform variants, or background behavior. Do not predefine playlists, transfer catalogs, notification schedules, or no-op services.

---

## 14. Logging, telemetry, and privacy

### 14.1 Baseline logging

Use one concrete `AppLogger` backed by Talker. It owns redaction and production verbosity policy. Application code must not access Talker directly.

Rules:

- Use structured context where practical.
- Never log tokens, headers, request bodies, user content, secure-storage values, or full database rows.
- Verbose logs are development-only.
- Production logs are sparse and actionable.
- Extract a logger interface only if another implementation or a stronger test seam becomes necessary.

### 14.2 Telemetry activation

Analytics, crash reporting, and performance monitoring are not baseline dependencies. Add them together with:

- A defined event or error taxonomy.
- Consent and opt-out behavior.
- Platform support rules.
- Redaction tests.
- Debug/test behavior.
- A meaningful application-level contract.

When Firebase is selected, bind it in `app/dependencies.dart`; features and UI must never import FlutterFire.

The app must continue to work normally when telemetry is unavailable or disabled.

---

## 15. Routing and initial UI

Use named `go_router` routes.

Initial route tree:

```text
/
/settings
/settings/appearance
/settings/language
/dev/diagnostics    # non-production only
```

Rules:

- Route names and paths live in `app_routes.dart`.
- Route construction lives in `app_router.dart`.
- Redirects read application state through providers, not storage or plugins.
- Development routes are absent from the production route table, not merely hidden in navigation.
- Deep links are accepted only for registered routes.

Initial UI:

- A small home page that confirms startup.
- Appearance settings for theme mode, accent, and text scale.
- Language selection for system, English, Arabic, and Simplified Chinese.
- Development diagnostics showing environment, build version, layout class, interaction policy, locale, and platform capabilities.

The settings screens are a real feature because users interact with them. They are not infrastructure controls.

---

## 16. Testing strategy

Test implemented behavior rather than hypothetical adapters.

### 16.1 Unit tests

Cover:

- Environment parsing, including missing and unknown values.
- Production configuration safety.
- Compact, medium, and expanded breakpoint classification.
- Interaction-policy selection.
- Theme, accent, text-scale, and locale transitions.
- Preference serialization and invalid-value fallback.
- Log redaction.

### 16.2 Widget tests

Cover:

- Compact shell at representative phone dimensions.
- Medium shell at tablet or narrow-window dimensions.
- Expanded shell at desktop dimensions.
- Live resizing across breakpoints without losing settings state.
- Light and dark themes.
- Minimum and maximum text scaling without overflow.
- English, Arabic RTL, and Simplified Chinese.
- Keyboard focus traversal and visible focus state.
- Settings persistence through provider overrides or a focused fake.
- Reduced-motion behavior for custom animations.
- Custom animation start, settled, and interruption states where applicable.

Suggested viewport matrix:

```text
390 × 844    compact phone
800 × 1000   medium tablet/window
1024 × 768   expanded lower bound
1440 × 900   desktop
700 × 700    narrow resized desktop window
```

### 16.3 Golden tests

Keep the matrix intentional rather than multiplying every setting combination:

```text
Compact / English / light / default scale
Compact / Arabic / dark / maximum scale
Expanded / English / dark / default scale
Expanded / Chinese / light / default scale
```

### 16.4 Integration smoke test

1. Launch with explicit development configuration.
2. Navigate using compact and expanded shells.
3. Change theme, accent, text scale, and locale.
4. Verify Arabic directionality.
5. Restart and verify persistence.
6. Verify development routes are absent under production configuration.

Add Patrol only when a native workflow justifies it.

---

## 17. CI requirements

Every pull request runs:

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

Detect stale generated code:

```bash
dart run build_runner build --delete-conflicting-outputs
git diff --exit-code
```

Recommended platform matrix:

| Runner | Checks |
| --- | --- |
| Ubuntu | Analysis, tests, Android build, Linux build |
| macOS | iOS build, macOS build |
| Windows | Windows build |

At least one release build must use `config/production.json`. CI must fail if production configuration is missing, malformed, or identifies itself as another environment. When remote services are added, also validate that production configuration cannot reference development endpoints or projects.

Web compilation is added only if web remains a supported target.

### 17.1 Dependency maintenance

Review dependency upgrades deliberately, especially while ForUI remains pre-1.0:

```bash
flutter pub outdated
flutter pub upgrade
flutter pub upgrade forui --major-versions
dart fix --apply
flutter analyze
flutter test
```

Read Flutter, ForUI, ExUI, Dartx, Simple Animations, Riverpod, and Slang changelogs before accepting major or pre-1.0 minor upgrades. Run the platform build matrix before merging automated dependency changes.

---

## 18. Implementation sequence

### Phase 1 — Compact baseline

- Confirm Flutter `3.44.0+` on stable.
- Replace the counter template with the one-entrypoint bootstrap.
- Add explicit development, staging, and production configuration files.
- Enable strict analysis and code generation.
- Install only the baseline dependencies in section 4.

### Phase 2 — App shell and adaptive UI

- Generate and commit ForUI theme tokens.
- Add the ForUI root theme and minimal router.
- Add `AppLayoutClass`, breakpoints, and interaction policy.
- Implement compact and expanded app shells.
- Use ExUI and Dartx only under the policies in section 8.
- Add shared motion tokens and one reduced-motion-aware Simple Animations transition.
- Verify resizing, keyboard focus, pointer behavior, and constrained desktop content.

### Phase 3 — Settings and localization

- Add the settings feature and `SharedPreferencesAsync` repository.
- Implement theme mode, accent, and accessible text scaling.
- Configure Slang for English, Arabic, and Simplified Chinese.
- Implement locale switching, persistence, fallback, and RTL behavior.

### Phase 4 — Diagnostics, tests, and CI

- Add the redacted logger and development diagnostics page.
- Add unit, widget, golden, and smoke tests.
- Add generated-code drift detection.
- Build Android, iOS, macOS, Windows, and Linux in CI.

### Phase 5 — First product feature

- Add the first feature in a flat feature directory.
- Introduce only the infrastructure it actually consumes.
- Extract contracts after a real vendor, platform, or test boundary appears.
- Update this document when an approved-later capability becomes part of the baseline.

### Release-readiness phase

Before public release, decide and implement as required:

- Analytics, crash reporting, and performance telemetry.
- Consent and privacy UX.
- Production signing, identifiers, icons, and environment-specific native configuration.
- Native integration tests for real platform workflows.

---

## 19. Definition of done

The compact baseline is complete when:

- [ ] Android, iOS, macOS, Windows, and Linux builds are green.
- [ ] The app has one `main.dart` and requires an explicit valid environment.
- [ ] Development, staging, and production configuration cannot silently fall back to one another.
- [ ] ForUI is the only styled application component system.
- [ ] ExUI is limited to short, token-based layout composition.
- [ ] Dartx is imported selectively and does not replace localization, security, or domain-aware date logic.
- [ ] Simple Animations uses shared motion tokens and respects reduced-motion settings.
- [ ] The project is feature-first and has no generic `core/`, `utils/`, or empty capability folders.
- [ ] Compact, medium, and expanded layouts are selected from available width.
- [ ] Layout state survives live window resizing.
- [ ] Touch, mouse, and keyboard interactions have been tested.
- [ ] Theme mode, accent, and text scale change at runtime and survive restart.
- [ ] System accessibility text scaling remains effective.
- [ ] English, Arabic, and Simplified Chinese localization works, including RTL.
- [ ] Feature UI does not access Shared Preferences or other plugins directly.
- [ ] Logging centrally redacts sensitive data.
- [ ] Unit, widget, golden, and smoke tests pass.
- [ ] Generated code is committed and CI detects stale output.
- [ ] No unused database, network, Firebase, audio, download, notification, form, or no-op service code exists.
- [ ] No product-specific placeholder infrastructure exists.

---

## 20. Baseline summary

```text
Flutter
├── One main.dart + explicit environment configuration
├── ForUI design system
├── ExUI layout ergonomics only
├── Dartx non-UI ergonomics only
├── Simple Animations for coordinated custom motion
├── Riverpod composition and state
├── go_router navigation
├── Adaptive compact / medium / expanded shells
├── Touch / pointer / keyboard interaction policy
├── Slang: type-safe en / ar / zh localization
├── Runtime theme, accent, and accessible text scaling
├── SharedPreferencesAsync for exercised settings
├── Redacted local logging
└── Focused tests and multi-platform CI

Added with first real use
├── Forms
├── Drift persistence
├── Secure storage
├── Dio networking and caching
├── Firebase telemetry
├── Audio
├── Downloads
└── Notifications
```

The result is deliberately smaller than a traditional “clean architecture” template. It preserves strong boundaries while allowing the codebase to reveal the abstractions it actually needs.

---

## 21. Primary references

- ForUI getting started: https://forui.dev/docs/getting-started
- ForUI themes: https://forui.dev/docs/concepts/themes
- ExUI package: https://pub.dev/packages/exui
- Dartx package: https://pub.dev/packages/dartx
- Simple Animations package: https://pub.dev/packages/simple_animations
- Flutter adaptive and responsive design: https://docs.flutter.dev/ui/adaptive-responsive
- Flutter adaptive layout approach: https://docs.flutter.dev/ui/adaptive-responsive/general
- Flutter adaptive best practices: https://docs.flutter.dev/ui/adaptive-responsive/best-practices
- Flutter flavors for Android: https://docs.flutter.dev/deployment/flavors
- Flutter flavors for iOS and macOS: https://docs.flutter.dev/deployment/flavors-ios
- Flutter internationalization: https://docs.flutter.dev/ui/internationalization
