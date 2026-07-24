# Architecture

`starter` is a compact cross-platform Flutter starter (Android, iOS, macOS, Windows, Linux; web optional) on Flutter 3.44.x / Dart 3.12.x. This file is a quick INDEX — like the index at the back of a book — pointing to where each concern lives, optimized for AI agents. Read the subsystem, then jump to the `Start here` file.

## Decision records

The architecture decisions live in [`plans/initial.md`](plans/initial.md), the static UI contract in [`plans/initial_ui.md`](plans/initial_ui.md), and the execution sequence in [`plans/implementation_workflow.md`](plans/implementation_workflow.md). The frozen feature API boundaries — public typed values and per-page callback signatures such as `LoginPage.onSubmit(LoginFormValue)` — are in [`plans/feature_contracts.md`](plans/feature_contracts.md); consult it before extending or renaming any feature's public surface. Post-implementation abstraction rationale (kept/rejected decisions) is in [`docs/baseline_architecture_report.md`](docs/baseline_architecture_report.md); deferred release blockers are tracked in [`docs/release_readiness.md`](docs/release_readiness.md).

## How to read this

- **Feature-first ownership.** Each feature owns its pages, view-data, and tests. There is no `core/` or `utils/` layer.
- **Root composition lives in only 3 files:** `lib/app/dependencies.dart`, `lib/app/routing/app_router.dart`, `lib/bootstrap.dart`. Wire providers here, not globally.
- **Generated code is committed.** slang `*.g.dart` and ForUI theme tokens are checked in; edit only the JSON/CLI sources and regenerate (`just gen` / `forui_cli`).
- **Config is compile-time only.** `--dart-define-from-file=config/<env>.json` feeds `AppConfig.fromEnvironment()`; no runtime env-var fallback, no secrets.
- **Settings are handwritten Riverpod (no codegen).** Override `settingsRepositoryProvider` + `initialSettingsProvider` at the `ProviderScope`; mutate only via `SettingsController`.

## Quick index

| Subsystem | What it is | Start here |
|---|---|---|
| bootstrap-startup | Zone guard, error handlers, dependency graph, root App | `lib/bootstrap.dart` |
| configuration-environments | Compile-time defines select env, gate logging/dev routes | `lib/app/config/app_config.dart` |
| routing | go_router tree mapping AppRoutes to screens, one ShellRoute | `lib/app/routing/app_router.dart` |
| state-settings | Handwritten Riverpod accent/fontScale/themeMode/locale | `lib/features/settings/settings_controller.dart` |
| internationalization | slang v4 codegen: en + ar + zh-Hans via context.t | `lib/i18n/en.i18n.json` |
| shell-adaptive-layout | AppShell picks compact/expanded nav by width | `lib/app/shell/app_shell.dart` |
| theme-system | ForuiThemeFactory composes FThemeData from tokens | `lib/shared/theme/forui_theme_factory.dart` |
| motion-and-page-transitions | Duration/curve tokens + per-platform transitions | `lib/shared/motion/app_motion.dart` |
| features-product-screens | Callback-driven backend-free product screens | `lib/features/auth/login_page.dart` |
| shared-widgets | Cross-feature widget abstractions (Escape dismiss) | `lib/shared/widgets/escape_dismissible_overlay.dart` |
| dev-gallery-diagnostics | Dev-only gallery + diagnostics, gated by config | `lib/features/dev_gallery/gallery_case.dart` |
| infrastructure | Redacting logger, platform info, sole production prefs store | `lib/infrastructure/logging/app_logger.dart` |
| testing-analysis-ci | Linted suite, macOS goldens, integration, 5-job CI | `justfile` |

## Subsystems

### Foundation

#### bootstrap-startup

**Process entry: installs zone guard + error handlers, builds production dependency graph, runs root App.**

Files:
- `lib/main.dart` — runZonedGuarded + AppConfig load
- `lib/bootstrap.dart` — bootstrap, createApplication, error handlers
- `lib/app/app.dart` — ProviderScope overrides + MaterialApp.router
- `lib/app/dependencies.dart` — production dependency graph
- `lib/app/startup/startup_error_view.dart` — startup fallback UI

Notes:
- `createApplication` is the shared seam: `integration_test/*` reuse it to build the real tree without `runApp`; inject `ApplicationRunner` (default `runApp`), never call `runApp` directly.
- Error handlers log then swallow (PlatformDispatcher returns true, neither rethrows); `_AppView` is keyed by `(environment, developmentToolsEnabled, initialLocation)` so the router rebuilds on config change.
- `main.dart` stays minimal (config load + zone guard); add providers via `AppDependencies` + ProviderScope overrides in `App.build`.

#### configuration-environments

**Compile-time config via `--dart-define-from-file` selects env, gates verbose logging and dev-only routes.**

Files:
- `lib/app/config/app_config.dart` — reads defines into AppConfig
- `lib/app/config/app_environment.dart` — enum + parse/exception
- `config/development.json` — dev defines, flags true
- `config/staging.json` / `config/production.json` — flags false
- `test/app/config/app_config_test.dart` — parsing invariant tests

Notes:
- Compile-time only, no runtime fallback; all JSON values are strings, booleans must be exactly `"true"`/`"false"`. Never secrets here — files compile into the binary.
- `verboseLoggingEnabled` and `developmentToolsEnabled` AND-gate on `AppEnvironment.development`; staging/prod return false even if raw flags are true. `enable*=true` under production throws `AppConfigException`.
- Tests use `AppConfig.fromValues({...})`; `fromEnvironment()` is compile-time pinned — missing APP_ENV throws `AppEnvironmentException`.

#### routing

**go_router tree mapping `AppRoutes` constants to screens behind one adaptive ShellRoute.**

Files:
- `lib/app/routing/app_router.dart` — buildAppRouter wires GoRoutes
- `lib/app/routing/app_routes.dart` — name/path constants + otpLocation
- `lib/app/routing/otp_purpose.dart` — OtpPurpose enum disambiguates OTP
- `lib/app/routing/route_error_page.dart` — unknown-route fallback
- `lib/app/shell/app_shell.dart` — adaptive shell dispatch

Notes:
- Declare every route as paired name+path constants; navigate by name via `context.goNamed`/`pushNamed`; build parameterized paths via helpers like `AppRoutes.otpLocation(purpose)`.
- Chrome-bearing destinations inside the ShellRoute; full-screen flows (auth, onboarding) top-level; gate dev routes behind `if (config.developmentToolsEnabled)` with `/dev/*` paths.
- One ShellRoute builds `AppShell`, which switches compact/expanded internally (not separate branches); router is rebuilt, not reactive. `ProductionPageFactory<TState>` is a typedef in `lib/app/presentation/production_page_factory.dart`, not a class.

#### state-settings

**Handwritten Riverpod settings owning accent, fontScale, themeMode, locale; persisted via a SettingsStore port.**

Files:
- `lib/features/settings/settings_controller.dart` — notifier + 3 providers
- `lib/features/settings/settings_state.dart` — SettingsState, enums, defaults
- `lib/features/settings/settings_repository.dart` — serialize to/from store keys
- `lib/features/settings/settings_store.dart` — SettingsStore port + exception
- `lib/features/settings/in_memory_settings_store.dart` — test SettingsStore with `failReads`/`failWrites` toggles
- `lib/infrastructure/preferences/shared_preferences_settings_store.dart` — sole production prefs adapter

Notes:
- Override `settingsRepositoryProvider` at the ProviderScope — it throws `StateError` if unoverridden. `initialSettingsProvider` is optional and falls back to `SettingsState.defaults()`; never instantiate the repo inside a provider.
- Mutate only via controller setters; keep optimistic-update-with-rollback; `fontScale` clamped to `[0.85, 1.6]`; locale applied live via `LocaleSettings.setLocale`.
- Add a field: extend `SettingsState`, add a `persistedKeys` entry + load/save, add a controller setter. In tests construct `InMemorySettingsStore()..failReads/failWrites = true`, wrap it in `SettingsRepository`, and override `settingsRepositoryProvider` (`AppDependencies.inMemory` exposes no store handle).

#### internationalization

**slang v4 codegen: `en` base + `ar` (RTL) + `zh-Hans`, accessed via `context.t`.**

Files:
- `lib/i18n/en.i18n.json` — base English, canonical keys
- `lib/i18n/ar.i18n.json` — Arabic translation
- `lib/i18n/zh-Hans.i18n.json` — Simplified Chinese translation
- `lib/i18n/translations.g.dart` + `translations_{en,ar,zh_Hans}.g.dart` — generated AppLocale/`context.t` + per-locale tables; regenerate and commit all four together
- `slang.yaml` (CLI) / `build.yaml` (build_runner) — slang codegen options
- `lib/bootstrap.dart` — createApplication applies localeOverride

Notes:
- Edit only `*.i18n.json` sources, never `*.g.dart`; add keys to en/ar/zh-Hans in sync, regenerate, commit all generated files.
- Regenerate via `dart run build_runner build` (or `just gen`); locale entry point is `createApplication` in `bootstrap.dart`.
- File is `zh-Hans.i18n.json` but enum is `AppLocale.zhHans`; `localeOverride == null` means follow device; use `context.t` in widgets (rebuilds on locale change).
- Bundled fonts (Noto Sans / Arabic / SC) live in `assets/fonts/` with pinned SHA-256s (see `assets/fonts/README.md`); they underpin RTL/CJK glyph coverage and golden pixel determinism — never swap or delete without regenerating baselines.

### Presentation

#### shell-adaptive-layout

**Adaptive nav chrome: AppShell picks a compact bottom-bar or expanded sidebar shell from width.**

Files:
- `lib/app/shell/app_shell.dart` — layout-dispatching ShellRoute builder
- `lib/app/shell/compact_app_shell.dart` — compact bottom-nav shell
- `lib/app/shell/expanded_app_shell.dart` — sidebar shell (reused for medium); uses `exui` `.paddingOnly` (sole exui call site)
- `lib/shared/adaptive/app_layout_class.dart` — compact/medium/expanded enum + fromWidth
- `lib/shared/adaptive/app_layout_provider.dart` — AppLayoutScope + provider
- `lib/shared/adaptive/app_interaction_policy.dart` — AppInteractionPolicy enum + monotonic resolver
- `lib/app/interaction_policy_controller.dart` — Riverpod policy providers

Notes:
- Derive layout only from width inside AppLayoutScope; never branch on platform. Read breakpoints from `context.theme.breakpoints` (`.sm` compactMax, `.lg` expandedMin).
- `medium` reuses `ExpandedAppShell` with `compactSidebar:true`; new tabs need both shells + the `_selectedIndex` prefix map (0=home,1=pricing,2=settings).
- Interaction policy is input-only and monotonic; `interactionPolicyOverrideProvider` is the deterministic test/dev hook; reading `appLayoutClassProvider` outside AppLayoutScope throws.

#### theme-system

**ForUI theming: ForuiThemeFactory composes FThemeData from generated tokens, accent, fontScale, and policy.**

Files:
- `lib/shared/theme/forui_theme_factory.dart` — builds FThemeData, applies accent/scale/touch
- `lib/shared/theme/generated_forui_theme.dart` — ForUI CLI output (committed)
- `lib/shared/theme/colors.dart` / `typography.dart` / `style.dart` / `icons.dart` — generated (do not edit)
- `lib/shared/theme/app_spacing.dart` — AppSpacing xs..xl3 constants
- `lib/shared/theme/app_sizes.dart` — AppSizes sidebar/content width constants
- `lib/features/settings/settings_state.dart` — AppAccent enum owner

Notes:
- Never hand-edit generated files (`colors`/`typography`/`style`/`icons`/`generated_forui_theme`); regenerate via `forui_cli`. No lint fixes to them either.
- Change accents in `ForuiThemeFactory._accentColors`; feed FThemeData to MaterialApp via `toApproximateMaterialTheme()` (a ForUI SDK method), not Material duplicates.
- `touch` derives from `AppInteractionPolicy` (precisionPointer => desktop); dark error foreground overridden in factory; `AppAccent` is owned by `settings_state.dart`.

#### motion-and-page-transitions

**Duration/curve tokens plus a per-platform PageTransitionsTheme for native route transitions.**

Files:
- `lib/shared/motion/app_motion.dart` — duration/curve tokens
- `lib/shared/motion/app_page_transitions.dart` — nativePageTransitionsTheme (const)
- `lib/app/app.dart` — applies transitions theme + FThemeMotion
- `lib/features/onboarding/onboarding_page.dart` — consumer with reduce-motion guard

Notes:
- Source durations/curves from `AppMotion` only (quick/standard/deliberate, standardCurve/emphasizedCurve); never hardcode. `nativePageTransitionsTheme` is a top-level const applied via `pageTransitionsTheme` copyWith on both themes.
- iOS uses `CupertinoPageTransitionsBuilder` (preserves swipe-back); desktop (macOS/windows/linux) cross-fades via `CrossFadePageTransitionsBuilder`.
- Guard every custom animation with `MediaQuery.disableAnimationsOf(context)` + a non-animated fallback that still completes the action (e.g. `jumpToPage` for navigation); reduce-motion is enforced per call site, not centralized.

#### shared-widgets

**Cross-feature widget abstractions, extracted only after a concern repeats across features; currently just the Escape-dismissal wrapper.**

Files:
- `lib/shared/widgets/escape_dismissible_overlay.dart` — `EscapeDismissibleOverlay`: binds Escape to `Navigator.maybePop` for modal content

Notes:
- Wrap modal/overlay/recovery content so the Escape key pops it. Callers span routing (`app_router.dart`), auth (`register_page.dart`), profile (`update_profile_page.dart`), and dev-gallery fixtures (`system_overlay_fixture.dart`, `production_gallery_cases.dart`).
- Reuse this for new Escape-dismissable surfaces; do not re-implement per feature. Extraction is deliberately bounded per `docs/baseline_architecture_report.md` — add a `shared/widgets/` entry only when a concern genuinely repeats, never for one-off helpers.

### Features

#### features-product-screens

**Callback-driven, backend-free product screens (auth, home, onboarding, pricing, profile, settings), each with typed view-data/state.**

Files:
- `lib/features/auth/login_page.dart` — canonical page+form_value+presentation_state trio (replicated per routed screen below)
- `lib/features/auth/{register,forgot_password,reset_password,otp}_page.dart` — sibling routed auth screens, each with its own `*_form_value` + `*_presentation_state` trio
- `lib/features/auth/auth_page_scaffold.dart` — adaptive auth shell (compact/medium/expanded layout only)
- `lib/features/auth/auth_form_support.dart` — shared email/password validators, password-toggle, first-invalid-field reveal (used by all auth pages)
- `lib/features/home/home_page.dart` — dashboard + fixtures
- `lib/features/onboarding/onboarding_page.dart` — slide PageView to paywall
- `lib/features/pricing/pricing_page.dart` / `paywall_page.dart` — plan grid + paywall
- `lib/features/profile/update_profile_page.dart` — dirty/saving/saved state machine
- `lib/features/settings/settings_page.dart` — settings UI (appearance/language/account); sole consumer of `simple_animations`
- `lib/app/routing/app_routes.dart` — route constants per feature

Notes:
- Each feature owns page(s) + typed `*_view_data` (and `*_form_value`/`*_presentation_state` for forms); router wires static callbacks to `goNamed`/`pushNamed`.
- No backend: surface `common.notConnected` / `globalError` for actions needing one, never fake success. Pull all strings from `context.t`.
- Add-a-feature pattern: create `lib/features/<name>/` with page + view_data, add route constant in `app_routes.dart` + GoRoute in `app_router.dart` injecting callbacks, mirror under `test/features/<name>/` using the `auth_test_harness.dart`-style localized app.

### Infra & Tooling

#### dev-gallery-diagnostics

**Dev-only UI gallery + diagnostics pages, gated by `developmentToolsEnabled`, rendering production screens in a deterministic preview env.**

Files:
- `lib/features/dev_gallery/gallery_case.dart` — GalleryCase + TypedGalleryCase
- `lib/features/dev_gallery/gallery_registry.dart` — registry, rejects dup/empty IDs
- `lib/features/dev_gallery/gallery_environment.dart` — GalleryEnvironment model + viewport/text-scale/display presets
- `lib/features/dev_gallery/preview_frame.dart` — isolated MediaQuery/theme/Navigator wrapper
- `lib/features/dev_gallery/screen_gallery_page.dart` — gallery page controls
- `lib/features/dev_gallery/cases/production_gallery_cases.dart` — production cases
- `lib/features/dev_gallery/system/system_gallery_cases.dart` — system-surface cases (startup failure, unknown route, OTP) + ForUI overlay cases
- `lib/features/dev_gallery/system/system_overlay_fixture.dart` — `SystemOverlayFixtureKind` (dialog/sheet/toast/popover/tooltip)
- `lib/app/presentation/production_page_factory.dart` — `ProductionPageFactory<TState>` typedef (builds gallery cases)
- `lib/app/diagnostics/diagnostics_page.dart` — runtime env/build/capabilities

Notes:
- Register cases only via `TypedGalleryCase` with a unique non-empty id; build from static fixtures via `ProductionPageFactory<TState>`, never live services/navigation.
- Routes `/dev/screens` and `/dev/diagnostics` mounted inside `if (config.developmentToolsEnabled)`; absent in staging/prod.
- `PreviewFrame` installs its own Navigator + MediaQuery + ProviderScope + FTheme + Directionality (fully isolated); `ScreenGalleryPage` mutates and restores global locale while mounted.

#### infrastructure

**Cross-cutting adapters: a redacting talker-backed logger, read-only platform/build info, and the sole production per-key prefs store.**

Files:
- `lib/infrastructure/logging/app_logger.dart` — talker logger, verbose-gated, redacts context
- `lib/infrastructure/logging/log_redactor.dart` — regex scrubber for tokens/passwords
- `lib/infrastructure/platform/app_build_info.dart` — version/buildNumber
- `lib/infrastructure/platform/platform_capabilities.dart` — read-only platform flags
- `lib/infrastructure/preferences/shared_preferences_settings_store.dart` — sole production SettingsStore impl

Notes:
- Route all logging through `AppLogger`; pass structured `Map<String,Object?>` context (redacted automatically, never pre-redact); debug/stacks gated behind verbose, info/warn/error always on.
- SettingsStore is per-key only (`readString`/`writeString`/`remove`), never `clearAll`; uses `SharedPreferencesAsync`; wrap adapters in try/on Object -> `SettingsStoreException`.
- No network/db/secure-storage adapters exist by design — do not add without escalating. Only `log_redactor` has tests.

#### testing-analysis-ci

**very_good_analysis-linted suite with macOS-only canonical goldens, integration smoke/route tests, and a 5-job CI gate.**

Files:
- `justfile` — test, test-goldens, smoke, watch, analyze, gen recipes
- `.github/workflows/ci.yml` — 5 jobs: ubuntu-quality, linux-integration, ubuntu/macos/windows release builds, macOS goldens
- `analysis_options.yaml` — very_good_analysis + strict-casts/inference/raw-types + riverpod_lint
- `integration_test/development_smoke_test.dart` — full-flow smoke across layouts
- `integration_test/production_routes_test.dart` — dev routes absent in prod
- `test/goldens/canonical_matrix_golden_test.dart` — 13-case pairwise matrix (macOS)
- `test/goldens/README.md` — pinned baseline env (macOS 26.5, Flutter 3.44.7)

Notes:
- `just test` excludes goldens; goldens compare ONLY on macOS via `just test-goldens`; regenerate baselines with `--update-goldens` on the pinned runner. `test/goldens/baselines/` is currently empty — needs `--update-goldens` before first compare.
- Integration tests reuse `createApplication`; use `pumpAppFrames` (8 bounded frames), never `pumpAndSettle`; pass `--dart-define-from-file`. `resetTestSettings()` wipes settings keys before each run.
- Keep analysis clean at `flutter analyze --fatal-infos`; keep generated code in sync (`just gen` + `just gen-check`); Flutter pinned to 3.44.7 in CI.

## Where do I...

- **Add a screen/route:** Add name+path constants in `lib/app/routing/app_routes.dart`; add a GoRoute in `lib/app/routing/app_router.dart` (inside the ShellRoute for nav chrome, top-level for full-screen flows). For a dev route, add inside `if (config.developmentToolsEnabled)` with a `/dev/*` path.
- **Add a translation:** Add the key to `lib/i18n/en.i18n.json`, `ar.i18n.json`, and `zh-Hans.i18n.json` in sync; run `just gen` (`dart run build_runner build`); commit all `*.g.dart`. Use `context.t` in widgets.
- **Change a color/theme token:** Accent colors live in `lib/shared/theme/forui_theme_factory.dart` (`_accentColors`). Do NOT edit generated `colors.dart`/`typography.dart`/`style.dart`/`icons.dart`/`generated_forui_theme.dart` — regenerate via `forui_cli`. Use `AppSpacing`/`AppSizes` for layout numbers.
- **Add a setting:** Extend `SettingsState` in `lib/features/settings/settings_state.dart`; add a key to `persistedKeys` + load/save in `lib/features/settings/settings_repository.dart`; add a controller setter in `settings_controller.dart`; render it in `lib/features/settings/settings_page.dart`.
- **Add a feature:** Create `lib/features/<name>/` with `<name>_page.dart` + typed `<name>_view_data.dart`; add a route constant in `app_routes.dart` + a GoRoute in `app_router.dart` injecting static callbacks; mirror under `test/features/<name>/`. For an auth-style form, copy the page + `*_form_value` + `*_presentation_state` trio from `lib/features/auth/` (and reuse `auth_form_support.dart`). Before freezing its public API, check `plans/feature_contracts.md`.
- **Change page transitions/motion:** Source durations/curves from `lib/shared/motion/app_motion.dart`; native transitions live in `lib/shared/motion/app_page_transitions.dart` (`nativePageTransitionsTheme`, applied via `pageTransitionsTheme` copyWith in `app.dart`). Guard custom animations with `MediaQuery.disableAnimationsOf(context)`.
- **Run tests (unit vs golden vs integration):** Unit/widget: `just test`. Goldens: `just test-goldens` (macOS only; regenerate with `--update-goldens`). Integration smoke: `just smoke` (adds `--dart-define-from-file=config/development.json`). Prod routes: `flutter test integration_test/production_routes_test.dart --dart-define-from-file=config/production.json`. Analyze: `just analyze`.
- **Build for release:** `flutter build <apk|ios|macos|linux|windows|web> --dart-define-from-file=config/production.json`. iOS uses `--no-codesign` in CI. Never set `ENABLE_*` flags true when `APP_ENV=production`.

## Conventions & guardrails

- No `core/`, `utils/`, service-locator, use-case, base-repository/base-page/feature-barrel layers. Feature-first ownership only.
- Root composition lives ONLY in `lib/app/dependencies.dart`, `lib/app/routing/app_router.dart`, `lib/bootstrap.dart`. Add providers via `AppDependencies` + ProviderScope overrides, not globals/singletons.
- Settings boundary is handwritten Riverpod (no codegen): override `settingsRepositoryProvider` + `initialSettingsProvider` at the ProviderScope; mutate only via `SettingsController` setters.
- ForUI owns controls + the committed generated theme; never hand-edit slang `*.g.dart` or theme `colors`/`typography`/`style`/`icons`/`generated_forui_theme`. Regenerate, don't patch.
- No backend: static callbacks give honest navigation or unavailable feedback (`common.notConnected` / `globalError`); never fake success. No fake backend services, Mocktail, or Riverpod codegen.
- Config via `--dart-define-from-file=config/<env>.json` only — compile-time, string values, no secrets. Gate behavior through `verboseLoggingEnabled`/`developmentToolsEnabled`, not raw `enable*` flags.
- Goldens separate from the default suite (`just test` excludes them); compare ONLY on the macOS pinned runner (`just test-goldens`); regenerate with `--update-goldens`.
- Logging through `AppLogger` only (auto-redacts structured context); no pre-redaction, no direct Talker calls. `debug`/stacks gated behind verbose.
- Tests mirror `lib/` (`app/`, `features/`, `shared/`, `infrastructure/`) plus `hardening/` (a11y + responsive) and `goldens/`. Use `pumpAppFrames`, never `pumpAndSettle`; drive widget/a11y/responsive tests via dev_gallery fixtures + `PreviewFrame`.
- Keep analysis clean at `flutter analyze --fatal-infos` (very_good_analysis + strict-casts/strict-inference/strict-raw-types + riverpod_lint). Keep generated code in sync: `just gen` then `just gen-check`.
