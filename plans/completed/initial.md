# Compact Cross-Platform Flutter Starter

**Status:** Audited architecture baseline

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
- ExUI as optional syntax sugar for basic Flutter layout only, installed with its first adopted caller.
- Dartx approved for selective, non-UI Dart ergonomics when a concrete caller is clearer than the Dart SDK equivalent.
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
| Framework | Flutter stable `3.44.7`; package floor Flutter `>=3.44.0 <3.45.0` with Dart `^3.12.0`; pin the exact Flutter patch in CI |
| Design system | ForUI |
| Layout ergonomics | ExUI core extensions, used selectively |
| Dart ergonomics | Dart SDK first; Dartx approved on first use for a demonstrably clearer non-UI operation |
| Custom motion | Flutter animation primitives first; Simple Animations for coordinated motion |
| State and dependency injection | Riverpod |
| Routing | `go_router` |
| Forms | Flutter `Form`/`FormField` with ForUI form widgets |
| Localization | Slang + `slang_flutter` with JSON source files |
| Small persisted settings | `SharedPreferencesAsync` |
| Local diagnostics | Application logger backed by Talker |
| Unit and widget tests | Flutter Test; add Mocktail only when a mock is genuinely clearer than a fake or provider override |
| Integration smoke tests | Flutter SDK `integration_test`; add it with the first smoke-test file |
| Static analysis | `very_good_analysis`, strict analyzer language settings, and the native `riverpod_lint` analysis-server plugin |

### 3.2 Approved on first use

| Capability | Preferred package | Add when |
| --- | --- | --- |
| Advanced model-driven forms | Re-evaluate `reactive_forms` in a focused ForUI adapter spike | A real workflow needs dynamic arrays, nested/multi-step form graphs, coordinated async validation, or shared dirty/reset/server-error orchestration that native forms cannot express cleanly. |
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
| Riverpod code generation | `riverpod_annotation` + `riverpod_generator` | Repeated manual provider declarations make generation measurably clearer; the compact baseline starts with handwritten providers. |
| Dart collection ergonomics | Dartx | A concrete non-UI collection/string operation is clearer than the Dart SDK equivalent. Do not add it only to demonstrate an extension. |
| Test mocks | Mocktail | A collaboration is awkward to cover with a small fake, in-memory implementation, or provider override. |

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

These are the dependencies reached by the compact baseline. Add each package in the phase that introduces its first real caller and test:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # UI
  forui: ^0.24.1
  exui: ^1.0.11
  simple_animations: ^5.3.0

  # State and routing
  flutter_riverpod: ^3.3.2
  go_router: ^17.3.0

  # Localization
  intl: ^0.20.2
  slang: ^4.18.0
  slang_flutter: ^4.18.0

  # Settings and diagnostics
  shared_preferences: ^2.5.5
  talker_flutter: ^5.1.19
  package_info_plus: ^10.2.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter

  build_runner: ^2.15.1
  slang_build_runner: ^4.18.0
  very_good_analysis: ^10.3.0
```

Add packages through `flutter pub add`, review the generated constraints, and commit `pubspec.lock` because this is an application.

The baseline deliberately selects Flutter Riverpod 3.3.x. Dependency resolution must not silently fall back to Riverpod 2.x while `riverpod_lint` 3.1.x is configured; inspect `flutter pub deps` after the initial add and after every major dependency upgrade.

```bash
flutter pub add \
  "flutter_localizations@{sdk: flutter}" \
  forui@^0.24.1 exui@^1.0.11 simple_animations@^5.3.0 \
  flutter_riverpod@^3.3.2 go_router@^17.3.0 \
  intl@^0.20.2 slang@^4.18.0 slang_flutter@^4.18.0 \
  shared_preferences@^2.5.5 talker_flutter@^5.1.19 \
  package_info_plus@^10.2.1

flutter pub add \
  "dev:integration_test@{sdk: flutter}" \
  dev:build_runner@^2.15.1 dev:slang_build_runner@^4.18.0 \
  dev:very_good_analysis@^10.3.0
```

Generate ForUI theme files without allowing the CLI to define the application architecture:

```bash
dart run forui theme create
```

Run code generation with:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Configure analysis explicitly. `riverpod_lint` 3.1.x uses Dart's native analysis-server plugin and is versioned in `analysis_options.yaml`; it is not a `custom_lint` dependency and does not require a separate CI command.

```yaml
include: package:very_good_analysis/analysis_options.yaml

plugins:
  riverpod_lint: 3.1.4

analyzer:
  exclude:
    - "**/*.g.dart"
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true

formatter:
  page_width: 100
  trailing_commas: preserve
```

Document every project-wide lint override beside the override with its architectural reason. Prefer a narrow line or file suppression for generated/vendor constraints over disabling a rule globally.

---

## 5. Project structure

Create directories when they contain real code. The intended shape is:

```text
config/
├── development.json
├── staging.json
└── production.json

slang.yaml

assets/
└── fonts/                  # reviewed Noto subsets/weights + license files

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
│       ├── settings_store.dart
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
│   ├── preferences/
│   │   └── shared_preferences_settings_store.dart
│   └── platform/
│       └── platform_capabilities.dart
│
└── i18n/
    ├── en.i18n.json
    ├── ar.i18n.json
    ├── zh-Hans.i18n.json
    └── translations.g.dart

test/
├── app/
├── features/
├── shared/
├── infrastructure/
└── goldens/

integration_test/
├── development_smoke_test.dart
└── production_routes_test.dart
```

This is a destination, not a request to create every listed folder on day one.

### 5.1 Folder responsibilities

- `app/` is the composition root. It may import features, shared code, and infrastructure.
- `features/` contains user-visible behavior grouped by product capability.
- `shared/` contains cross-feature application code reused by at least two features or by the app shell. It may use Flutter and the approved UI-layer dependencies under section 8; third-party service/plugin adapters remain in `infrastructure/`.
- `infrastructure/` contains plugin setup, operating-system integration, shared clients, and concrete vendor adapters. An infrastructure adapter may implement an app- or feature-owned port, but it must not contain product decisions or UI.
- Feature-specific repositories, ports, serialization, and mapping remain with their feature. For example, settings owns `SettingsStore`, `SettingsRepository`, persisted keys, and invalid-value fallback; infrastructure supplies the `SharedPreferencesAsync` implementation.
- `i18n/` owns translation sources and generated localization output.
- Native implementation code remains in `android/`, `ios/`, `macos/`, `windows/`, and `linux/`.

### 5.2 Dependency direction

```text
app ───────────────► features ───────────► shared
 │                       ▲
 └───────────────► infrastructure ───────► shared
                         │
                         └── implements feature-owned ports
```

Rules:

- `shared/` must not import from `features/` or `infrastructure/`.
- Feature UI, controllers, repositories, and public feature APIs must not expose Firebase, Dio, Drift, Shared Preferences, or other vendor types. Only concrete adapter files import the corresponding plugin.
- `app/dependencies.dart` constructs concrete adapters and feature repositories, then binds them to Riverpod providers. For settings it creates `SharedPreferencesSettingsStore`, injects it into `SettingsRepository`, and never exposes `SharedPreferencesAsync` above that adapter.
- One feature must not import another feature's internal files. Promote a genuinely shared concept or expose a narrow public contract.
- Infrastructure may depend on the narrow port it implements; feature code must not import the concrete infrastructure implementation.
- Infrastructure must not contain product UI or product validation/mapping rules.
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

`main()` is the production entrypoint and the normal owner of compile-time environment reads. `bootstrap`, `App`, router construction, and dependency construction receive an explicit validated `AppConfig`. Unit and widget tests construct `AppConfig` fixtures directly and therefore do not depend on ambient `--dart-define` values. Integration tests call the production bootstrap/composition path with `AppConfig.fromEnvironment()` and always pass a configuration file to the test command.

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
- Development integration tests must explicitly pass `config/development.json`; no test may rely on a default environment.
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
8. Place Slang's translation provider at the required root boundary and wire the selected locale, supported locales, Flutter delegates, and ForUI delegates into `MaterialApp.router`.

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
        └── builder
            └── FTheme
                └── FToaster
                    └── FTooltipGroup
                        └── router child (including AppShell)
```

Keep generated ForUI theme files in source control. The `MaterialApp.router` builder must preserve and return its router child. Never edit package source under `.pub-cache`.

`MaterialApp.router` must also receive:

- The Slang-selected Flutter locale, with `null`/system behavior resolved before construction.
- Only the application-supported locales: English, Arabic, and Simplified Chinese.
- Flutter's Material, Widgets, and Cupertino localization delegates.
- ForUI's `FLocalizations` delegates so built-in ForUI controls and accessibility copy are localized.

Do not advertise every locale supported internally by ForUI when the application ships only three. Add a root widget test that renders one ForUI control with built-in localized copy in each application locale.

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

Do not lock application orientation. Compact, medium, and expanded layouts must remain usable in portrait, landscape, split-screen, foldable, and resizable-window modes.

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

Use a deterministic, injectable resolver:

| Signal | Initial policy |
| --- | --- |
| Touch-first platform with no observed precision pointer | Touch |
| Desktop-first platform with no observed touch input | Precision pointer |
| Both touch and mouse/stylus/trackpad input observed | Hybrid |
| Test or development gallery override | Explicit injected policy |

Platform supplies only the safe initial default. Observed pointer kinds may promote the session to hybrid, but transient pointer attachment must not destroy feature state or change the width-based layout class. Keep the resolver behind a provider so widget tests and the gallery can select every policy deterministically. Allow a future persisted user override only if a real product need emerges.

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
  final AppLocale? localeOverride;
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

Apply the application multiplier to the base typography tokens used to build the ForUI and approximate Material themes. Leave the ambient `MediaQuery` `TextScaler` intact so the operating system's nonlinear accessibility scaling is applied afterward. Do not replace it with `TextScaler.linear`, derive behavior from the deprecated `textScaleFactor`, or clamp system scaling globally.

Before accepting the first locale goldens, choose and bundle source-controlled, license-reviewed font assets that cover the required Latin, Arabic, and Simplified Chinese glyphs and weights. The baseline choice is the relevant Noto Sans families. System fonts may still be reviewed manually, but committed goldens must not depend on whichever fallback fonts happen to be installed on a CI runner.

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
| Simplified Chinese | `zh-Hans` | LTR |

Use Slang with JSON translation sources and committed generated output.

Add a committed `slang.yaml`:

```yaml
base_locale: en
fallback_strategy: base_locale
input_directory: lib/i18n
input_file_pattern: .i18n.json
output_directory: lib/i18n
output_file_name: translations.g.dart
```

Rules:

- English is the base locale.
- Source files are `en.i18n.json`, `ar.i18n.json`, and `zh-Hans.i18n.json`; every file name identifies its locale explicitly.
- Feature UI never embeds user-facing strings directly.
- Keys describe meaning, not English wording.
- Interpolation and pluralization remain type-safe.
- Layout uses directional APIs such as `EdgeInsetsDirectional` and `AlignmentDirectional`.
- Generated files are never edited manually.
- Locale selection uses Slang's generated `AppLocale` type. A null `localeOverride` means follow the operating system; persistence serializes the locale tag only at the repository boundary and rejects unknown saved values safely.
- Locale selection and persistence belong to the settings feature.

Smoke-test every locale for startup, navigation, settings, fallback, and text direction.

---

## 12. State and dependency flow

Use Riverpod as the composition seam:

```text
Widget
  └── Controller/provider
        └── Feature repository or gateway, when needed
              └── Feature-owned port
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
- Plugin-specific types must stop inside their concrete adapter. Feature ports, repositories, controller state, and provider signatures use application-owned types only.
- Avoid global mutable singletons. Dependencies are created in `app/dependencies.dart`.

For the initial settings feature, `SettingsRepository` owns keys, serialization, fallback, and settings behavior. It depends on one narrow `SettingsStore` port. `SharedPreferencesSettingsStore` is the sole production implementation and is the only file that imports `SharedPreferencesAsync`; an in-memory implementation is used by repository, controller, widget, and restart-policy tests. Do not create a no-op implementation or a generic CRUD repository hierarchy.

This port is earned immediately by two concrete boundaries from section 2.1: it prevents a vendor type from leaking inward and provides a deterministic substitute for persistence tests. Keep it settings-specific instead of turning it into a project-wide storage abstraction.

---

## 13. Infrastructure activation rules

### 13.1 Preferences

Use `SharedPreferencesAsync` only for small, non-sensitive settings such as theme, locale, and telemetry consent.

The adapter exposes only the small read/write/remove operations required by `SettingsRepository`. It does not expose a `SharedPreferencesAsync` instance, preferences-specific options, or raw plugin exceptions to the feature. Map read/write failures to a small application-owned settings failure with actionable logging and a safe UI fallback.

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

Use Flutter `Form`/`FormField` with ForUI's native form widgets by default. `FTextFormField`, `FOtpField`, selects, date/time fields, sliders, and related ForUI controls already expose native validation/save/reset/error behavior; wrap plain checkbox/switch controls in a small `FormField<T>` composition only where needed.

Follow ForUI control ownership: managed/internal first, managed/external for programmatic control with explicit lifecycle ownership, and lifted only when an existing state owner requires bidirectional synchronization. Never maintain a second value copy merely to satisfy a form library.

The feature owns field order, focus, localized validation, typed submission values, dirty state, and service-error mapping. Use Flutter's granular validation to reveal the first invalid field. API calls do not belong inside field validators, and passwords/OTP values are never persisted or logged.

Do not add `reactive_forms`, Formz, or a schema renderer for the initial static screens. The compatibility and activation criteria are documented in [initial_ui.md](initial_ui.md). If advanced requirements emerge, spike the smallest representative ForUI adapter before changing the baseline.

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
- Router locations are accepted only for registered routes. Unknown or malformed locations render the localized recovery page; Back is shown only when `GoRouter.canPop()` is true, otherwise Home is the sole navigation recovery action.

Initial UI:

- A small home page that confirms startup.
- Appearance settings for theme mode, accent, and text scale.
- Language selection for system, English, Arabic, and Simplified Chinese.
- Development diagnostics showing environment, build version, layout class, interaction policy, locale, and platform capabilities.

The settings screens are a real feature because users interact with them. They are not infrastructure controls.

The expanded static screen route tree, shell ownership, typed OTP route, development gallery, and route-error policy live in [initial_ui.md](initial_ui.md). That companion plan is additive to this baseline and must retain the same environment gating and dependency direction.

### 15.1 Link and restoration scope

The baseline guarantees route parsing, direct initial-location navigation, browser/OS Back behavior inside the app, and unknown-location recovery. Tests may inject locations such as `/auth/otp/registration` directly into `GoRouter` without claiming that the operating system is registered to open an external URL.

Universal links, Android App Links, iOS associated domains, custom desktop URL schemes, and a production web path-URL strategy are deferred until a product owns a domain, application identifiers, signing identities, and hosting configuration. When activated:

- Android requires an intent filter, verified `assetlinks.json`, package ID, and signing-certificate fingerprints.
- iOS requires associated-domain entitlements, an AASA document, team ID, and bundle ID.
- Web must explicitly choose hash URLs or path URLs; path URLs require host rewrite/fallback rules.
- macOS, Windows, and Linux require an explicit OS protocol/launch-argument registration design and are not implied by the mobile route table.
- Platform link validation must run on every activated platform before its external-link support is claimed.

Flutter restoration of non-sensitive route or draft state is also deferred in this baseline. If activated later, add `restorationScopeId`, stable page restoration IDs, restart-and-restore tests, and an allowlist proving that passwords, OTP values, and tokens never enter restoration data.

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
- The `SettingsStore` contract, in-memory implementation, plugin-error mapping, and repository behavior without a platform channel.
- Log redaction.

### 16.2 Widget tests

Cover:

- Compact shell at representative phone dimensions.
- Medium shell at tablet or narrow-window dimensions.
- Expanded shell at desktop dimensions.
- Live resizing across breakpoints without losing settings state.
- Light and dark themes.
- Application multipliers `0.85×`, `1.00×`, and `1.60×` composed with normal and maximum nonlinear system text scaling without overflow or lost actions.
- English, Arabic RTL, and Simplified Chinese (`zh-Hans`).
- Keyboard focus traversal and visible focus state.
- Settings persistence through provider overrides and the in-memory `SettingsStore` implementation.
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

Golden-test harness rules:

- Commit reviewed baselines under `test/goldens/` and update them only through an explicit review command/change.
- Run comparison on one pinned OS, Flutter patch, renderer, device-pixel ratio, color space, and bundled application font set. Other platforms receive widget and manual visual checks rather than sharing the same pixels blindly.
- Every helper sets and restores logical size, device-pixel ratio, locale, brightness, text scaler, safe-area/inset fixtures, and animation state with `addTearDown`.
- Settle finite animations at a documented timestamp. Do not hide real diffs behind a broad pixel tolerance; any narrow tolerance must be justified beside the comparator.
- Keep focused/hovered goldens deterministic by controlling focus and pointer state explicitly.

### 16.4 Integration smoke test

Add `integration_test/development_smoke_test.dart` using `IntegrationTestWidgetsFlutterBinding.ensureInitialized()` and stable `ValueKey`s on workflow-critical controls. After resetting test-owned preferences, the test reads `AppConfig.fromEnvironment()` and calls the same public bootstrap/composition path used by `main()`; it does not enable the legacy Flutter Driver extension.

1. Reset the test-owned preference keys to a known baseline.
2. Launch with explicit development configuration.
3. Navigate using compact and expanded shells.
4. Change theme, accent, text scale, and locale.
5. Verify Arabic directionality.
6. Reconstruct the root application and production dependencies and verify persistence. This is a settings persistence check, not Flutter restoration.
7. Resize across compact, medium, and expanded widths while preserving navigation and settings state.

Add a separate `integration_test/production_routes_test.dart` that launches with production configuration and proves `/dev/screens` and `/dev/diagnostics` are unregistered. Keep production route-gating assertions separate from the longer development flow so failures identify the violated policy directly.

Desktop/local commands:

```bash
flutter test integration_test/development_smoke_test.dart \
  -d linux \
  --dart-define-from-file=config/development.json

flutter test integration_test/production_routes_test.dart \
  -d linux \
  --dart-define-from-file=config/production.json
```

Linux CI runs these commands under Xvfb. Select one deterministic desktop target for every pull request; add Android/iOS device runs when a real platform workflow exists. Web uses `flutter drive` plus ChromeDriver only if web becomes supported.

Add Patrol only when a native workflow justifies it.

---

## 17. CI requirements

Pin Flutter `3.44.7` in CI rather than following a floating `stable` channel. Record the runner images and minimum supported OS/toolchain versions in `README.md`; changing any of them is a reviewed maintenance decision.

Every pull request runs:

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test test
```

Detect stale generated code:

```bash
dart run build_runner build --delete-conflicting-outputs
git diff --exit-code
```

Recommended platform matrix:

| Runner | Checks |
| --- | --- |
| Ubuntu | Format, analysis, generated-code drift, unit/widget/golden tests, Xvfb Linux integration smoke tests, Android release build, Linux release build |
| macOS | iOS release build with `--no-codesign`, macOS release build, optional simulator smoke test |
| Windows | Windows release build |

Release-build commands always pass production configuration explicitly:

```bash
flutter build apk --release \
  --dart-define-from-file=config/production.json
flutter build linux --release \
  --dart-define-from-file=config/production.json
flutter build ios --release --no-codesign \
  --dart-define-from-file=config/production.json
flutter build macos --release \
  --dart-define-from-file=config/production.json
flutter build windows --release \
  --dart-define-from-file=config/production.json
```

Jobs run only commands supported by their host OS. CI must fail if production configuration is missing, malformed, identifies itself as another environment, or if the production router registers development routes. When remote services are added, also validate that production configuration cannot reference development endpoints or projects.

Web compilation is added only if web remains a supported target.

### 17.1 Dependency maintenance

Review dependency upgrades deliberately, especially while ForUI remains pre-1.0:

```bash
flutter pub outdated
flutter pub upgrade
flutter pub upgrade forui --major-versions
dart fix --dry-run
flutter analyze
flutter test
```

Review the dry-run output before running `dart fix --apply`; never apply automated fixes blindly across an upgrade.

Read Flutter, ForUI, ExUI, Dartx, Simple Animations, Riverpod, and Slang changelogs before accepting major or pre-1.0 minor upgrades. Run the platform build matrix before merging automated dependency changes.

---

## 18. Implementation sequence

### Phase 1 — Compact baseline

- Pin Flutter `3.44.7` in local tooling and CI and declare the supported Flutter/Dart range in `pubspec.yaml`.
- Replace the counter template with the one-entrypoint bootstrap.
- Add explicit development, staging, and production configuration files.
- Enable `very_good_analysis`, strict analyzer language settings, and the native `riverpod_lint` plugin.
- Add `slang.yaml`, locale-qualified source files, and generated-code drift detection.
- Install each baseline dependency from section 4 with its first caller.

### Phase 2 — App shell and adaptive UI

- Generate and commit ForUI theme tokens.
- Add the ForUI root theme and minimal router.
- Add `AppLayoutClass`, breakpoints, and interaction policy.
- Implement compact and expanded app shells.
- Exercise ExUI in one short token-based shell/content composition; keep Dartx uninstalled until a clearer-than-SDK caller exists.
- Add shared motion tokens and one reduced-motion-aware Simple Animations transition.
- Verify resizing, keyboard focus, pointer behavior, and constrained desktop content.

### Phase 3 — Settings and localization

- Add the settings feature, feature-owned `SettingsStore` port and repository, infrastructure `SharedPreferencesSettingsStore`, and in-memory test implementation.
- Implement theme mode, accent, and accessible text scaling.
- Configure Slang and the Flutter/ForUI delegates for English, Arabic, and Simplified Chinese (`zh-Hans`).
- Implement locale switching, persistence, fallback, and RTL behavior.

### Phase 4 — Diagnostics, tests, and CI

- Add the redacted logger and development diagnostics page.
- Add unit, widget, golden, and smoke tests.
- Add `integration_test` with separate development-flow and production-route tests, and run it on one deterministic desktop CI target.
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
- [ ] CI and local tooling use the reviewed Flutter `3.44.7` patch; supported Flutter/Dart and platform/toolchain ranges are documented.
- [ ] The app has one `main.dart` and requires an explicit valid environment.
- [ ] Development, staging, and production configuration cannot silently fall back to one another.
- [ ] ForUI is the only styled application component system.
- [ ] Native Flutter forms use ForUI form fields; no additional form engine exists without a recorded unmet requirement and adapter spike.
- [ ] ExUI is limited to short, token-based layout composition.
- [ ] If Dartx has earned installation, every import has a concrete clearer-than-SDK caller and does not replace localization, security, or domain-aware date logic.
- [ ] Simple Animations uses shared motion tokens and respects reduced-motion settings.
- [ ] The project is feature-first and has no generic `core/`, `utils/`, or empty capability folders.
- [ ] Compact, medium, and expanded layouts are selected from available width.
- [ ] The application does not lock orientation and remains usable in portrait, landscape, split-screen, foldable, and short-window fixtures.
- [ ] Layout state survives live window resizing.
- [ ] Touch, precision-pointer, hybrid, and keyboard interactions use an injectable deterministic policy and have been tested.
- [ ] Theme mode, accent, and text scale change at runtime and survive restart.
- [ ] The application font multiplier composes with nonlinear system accessibility scaling; neither replaces nor globally clamps the system `TextScaler`.
- [ ] English, Arabic, and Simplified Chinese (`zh-Hans`) localization works, including RTL, fallback, and localized ForUI built-in copy.
- [ ] Feature UI does not access Shared Preferences or other plugins directly.
- [ ] `SharedPreferencesAsync` appears only in the concrete infrastructure adapter; settings repository and controller tests use the feature port and in-memory implementation.
- [ ] Logging centrally redacts sensitive data.
- [ ] Unit, widget, golden, and smoke tests pass.
- [ ] Goldens use a pinned runner/renderer/DPR/font harness and reviewed source-controlled baselines.
- [ ] Development and production integration-test commands run with explicit environment files; Linux CI uses Xvfb when Linux is the selected target.
- [ ] Generated code is committed and CI detects stale output.
- [ ] Route-location parsing and recovery are tested without claiming external OS link registration; any activated external-link platform has its association/protocol configuration and validation committed.
- [ ] No unused database, network, Firebase, audio, download, notification, form, or no-op service code exists.
- [ ] No product-specific placeholder infrastructure exists.

---

## 20. Baseline summary

```text
Flutter
├── One main.dart + explicit environment configuration
├── ForUI design system
├── ExUI layout ergonomics only
├── Simple Animations for coordinated custom motion
├── Riverpod composition and state
├── go_router navigation
├── Native Flutter forms with ForUI form fields
├── Adaptive compact / medium / expanded shells
├── Touch / pointer / keyboard interaction policy
├── Slang: type-safe en / ar / zh-Hans localization
├── Runtime theme, accent, and accessible text scaling
├── Feature-owned settings persistence port + SharedPreferencesAsync adapter
├── Redacted local logging
└── Focused unit/widget/golden/integration tests and multi-platform CI

Added with first real use
├── Dartx non-UI ergonomics
├── Riverpod code generation
├── Mocktail
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
- ForUI complete LLM reference: https://forui.dev/docs/llms-full.txt
- ForUI controls: https://forui.dev/docs/concepts/controls
- ForUI text form field: https://forui.dev/docs/widgets/form/text-form-field
- Flutter FormState: https://api.flutter.dev/flutter/widgets/FormState-class.html
- ExUI package: https://pub.dev/packages/exui
- Dartx package: https://pub.dev/packages/dartx
- Simple Animations package: https://pub.dev/packages/simple_animations
- Flutter adaptive and responsive design: https://docs.flutter.dev/ui/adaptive-responsive
- Flutter adaptive layout approach: https://docs.flutter.dev/ui/adaptive-responsive/general
- Flutter adaptive best practices: https://docs.flutter.dev/ui/adaptive-responsive/best-practices
- Flutter flavors for Android: https://docs.flutter.dev/deployment/flavors
- Flutter flavors for iOS and macOS: https://docs.flutter.dev/deployment/flavors-ios
- Flutter internationalization: https://docs.flutter.dev/ui/internationalization
- Flutter integration testing: https://docs.flutter.dev/testing/integration-tests
- Flutter deep linking: https://docs.flutter.dev/ui/navigation/deep-linking
- Flutter nonlinear text scaling: https://docs.flutter.dev/release/breaking-changes/deprecate-textscalefactor
- Riverpod lint: https://pub.dev/packages/riverpod_lint
- Slang: https://pub.dev/packages/slang
