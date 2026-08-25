# Architecture

`starter` is a compact cross-platform Flutter starter (Android, iOS, macOS, Windows, Linux; web optional) on Flutter 3.44.x / Dart 3.12.x. This file is a quick INDEX — like the index at the back of a book — pointing to where each concern lives, optimized for AI agents. Read the subsystem, then jump to the `Start here` file.

## Decision records

The architecture decisions live in [`plans/completed/initial.md`](../plans/completed/initial.md), the static UI contract in [`plans/completed/initial_ui.md`](../plans/completed/initial_ui.md), and the execution sequence in [`plans/completed/implementation_workflow.md`](../plans/completed/implementation_workflow.md). The frozen feature API boundaries — public typed values and per-page callback signatures such as `LoginPage.onSubmit(LoginFormValue)` — are in [`plans/feature_roadmap/contracts.md`](../plans/feature_roadmap/contracts.md); consult it before extending or renaming any feature's public surface. Proposed ten-foot UI, remote focus, Android TV, and tvOS support is specified in [`plans/tv_platform_support.md`](../plans/tv_platform_support.md). Post-implementation abstraction rationale (kept/rejected decisions) is in [`docs/baseline_architecture_report.md`](baseline_architecture_report.md); deferred release blockers are tracked in [`docs/release_readiness.md`](release_readiness.md).

## How to read this

- **Feature-first ownership.** Each feature owns its pages, view-data, and tests. There is no `core/` or `utils/` layer.
- **Composition has explicit seams.** `lib/app/dependencies.dart` + `lib/app/dependencies/**` build
  domain aggregates, `lib/bootstrap.dart` owns startup, `lib/app/routing/**` composes routing, and
  feature `*_routes.dart` modules own route registration. Wire providers here, not globally.
- **Generated code is committed.** slang `*.g.dart`, Freezed `*.freezed.dart`, and ForUI theme
  tokens are checked in; edit only their sources and regenerate (`just gen` / `forui_cli`).
- **Config is compile-time only.** `--dart-define-from-file=config/<env>.json` feeds `AppConfig.fromEnvironment()`; no runtime env-var fallback, no secrets.
- **Settings are handwritten Riverpod (no codegen).** Override `settingsRepositoryProvider` + `initialSettingsProvider` at the `ProviderScope`; mutate only via `SettingsController`.

## Quick index

| Subsystem | What it is | Start here |
|---|---|---|
| bootstrap-startup | Zone guard, error handlers, dependency graph, root App | `lib/bootstrap.dart` |
| configuration-environments | Compile-time defines select env, gate logging/dev routes | `lib/app/config/app_config.dart` |
| routing | App shell composition, one redirect chain, feature-owned route lists | `lib/app/routing/app_router.dart` + `lib/features/*/*_routes.dart` |
| state-settings | Handwritten Riverpod accent/fontScale/themeMode/locale | `lib/features/settings/settings_controller.dart` |
| internationalization | slang v4 codegen: en + ar + zh-Hans via context.t | `lib/i18n/en.i18n.json` |
| shell-adaptive-layout | AppShell picks compact/expanded nav by width | `lib/app/shell/app_shell.dart` |
| tv-platform-support | Injected TV capability, ten-foot presentation, remote focus, and native targets | `lib/shared/adaptive/app_presentation_policy.dart` |
| keyboard-shortcuts | One root hardware listener, shortcut registry, and chord preview | `lib/app/keyboard/app_keyboard_host.dart` |
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
- `createApplication` is the shared seam: `integration_test/*` reuse it to build the real tree without `runApp`; inject `ApplicationRunner` (default `runApp`), never call `runApp` directly. `AppDependencies.production` resolves immutable platform capabilities before composition; tests inject a complete `PlatformCapabilities` value through `AppDependencies.inMemory`.
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

**go_router tree mapping `AppRoutes` constants to screens behind one adaptive StatefulShellRoute.**

Files:
- `lib/app/routing/app_router.dart` — buildAppRouter wires GoRoutes
- `lib/app/routing/route_guards.dart` — the single app-level redirect chain and live gate reads
- `lib/app/routing/route_support.dart` — cross-feature tab, dialog, and route-error helpers
- `lib/app/routing/app_routes.dart` — name/path constants + otpLocation
- `lib/app/routing/otp_purpose.dart` — OtpPurpose enum disambiguates OTP
- `lib/app/routing/route_error_page.dart` — unknown-route fallback
- `lib/app/shell/app_shell.dart` — adaptive shell dispatch
- `lib/app/shell/cross_fading_branch_container.dart` — `StatefulShellRoute` navigator container builder (tab cross-fade)

Notes:
- Declare every route as paired name+path constants; navigate by name via `context.goNamed`/`pushNamed`; build parameterized paths via helpers like `AppRoutes.otpLocation(purpose)`.
- Each routed feature owns a `<feature>_routes.dart` module exporting its `RouteBase` list and
  route-page wrappers. Pages remain callback-driven and never import `go_router` or route
  constants. Feature route modules never declare redirects; `appRedirect` is composed exactly
  once by `buildAppRouter`.
- Chrome-bearing destinations live inside one `StatefulShellRoute` with three branches (home, pricing, settings) and a cross-fading navigator container builder (`crossFadingBranchContainer`); full-screen flows (auth, onboarding) are top-level; gate dev routes behind `if (config.developmentToolsEnabled)` with `/dev/*` paths.
- Branch GoRoutes keep absolute paths (a `StatefulShellBranch` is not a `ShellRouteBase`); `settings` must precede its detail routes so reset-on-retap lands on `/settings`. In-shell tab switches go through `goBranch` with reset-on-retap (`initialLocation: index == shell.currentIndex`). Top-level flows (onboarding, paywall, auth, profile, route-error) stay siblings of the shell: a `go` to one unmounts the shell and resets every branch stack, while a `pushNamed` overlay preserves branch stacks. Router is rebuilt, not reactive. `ProductionPageFactory<TState>` is a typedef in `lib/app/presentation/production_page_factory.dart`, not a class.
- Password reset is a stack-preserving, typed-result flow: Forgot, reset OTP, and Reset Password
  are pushed above the caller and unwind to the original Login. A directly opened reset URL has
  no caller, so completion explicitly falls back to a root Login. This distinction keeps Home
  available to Back only when Login was originally pushed from Home.

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
- `lib/app/shell/app_shell.dart` — adaptive shell; takes a `StatefulNavigationShell` (or `AppShell.preview` for the dev gallery)
- `lib/app/shell/cross_fading_branch_container.dart` — owns the `StatefulShellRoute` tab cross-fade
- `lib/app/shell/compact_app_shell.dart` — compact bottom-nav shell (go_router-agnostic)
- `lib/app/shell/expanded_app_shell.dart` — sidebar shell (reused for medium); uses `exui` `.paddingOnly` (sole exui call site)
- `lib/shared/adaptive/app_layout_class.dart` — compact/medium/expanded enum + fromWidth
- `lib/shared/adaptive/app_layout_provider.dart` — AppLayoutScope + provider
- `lib/shared/adaptive/app_unit.dart` — bounded logical-width spacing/type scale + physical-pixel helpers
- `lib/shared/adaptive/app_interaction_policy.dart` — AppInteractionPolicy enum + monotonic resolver
- `lib/app/interaction_policy_controller.dart` — Riverpod policy providers

Notes:
- Derive layout only from width inside AppLayoutScope; never branch on platform. Read breakpoints from `context.theme.breakpoints` (`.sm` compactMax, `.lg` expandedMin).
- `AppShell` is built two ways: the default `AppShell(navigationShell: shell)` from `StatefulShellRoute.builder`, and `AppShell.preview(child:)` for the dev gallery (which has no shell). It wraps `AppLayoutScope` and passes `selectedIndex`, `child`, and an `onSelectTab(int)` callback down; `onSelectTab` is wired to `goBranch` with reset-on-retap. Ten-foot policy dispatches to `TelevisionAppShell` before the width switch; near-field keeps the compact/medium/expanded behavior. The 0/1/2 index contract (0=home,1=pricing,2=settings) is unchanged.
- `CompactAppShell`/`ExpandedAppShell` are go_router-agnostic: they switch tabs only through `onSelectTab(int)` and no longer import `go_router`/`app_routes`. `cross_fading_branch_container.dart` owns the tab cross-fade — it keeps every branch proxy mounted in stable order, fades both branches, and leaves only the current branch interactive/focusable/semantic/ticking; it honors `MediaQuery.disableAnimationsOf` (`Duration.zero`).
- `AppUnit` uses a 390 logical-pixel reference width and bounded interpolation from 320 through 1200; density never changes layout scale and is used only by `pixel`/`snap` for physical-pixel rendering.
- `medium` reuses `ExpandedAppShell` with `compactSidebar:true`; new tabs need both shells, a new ordered `StatefulShellBranch` in `app_router.dart` (branches are indexed home=0/pricing=1/settings=2), and an `onSelectTab` entry in each shell. `selectedIndex` is derived from `navigationShell.currentIndex`, not a location prefix.
- Interaction policy is input-only and monotonic, including `remote -> hybridRemote` after precision-pointer observation. Viewing distance remains orthogonal through `AppPresentationPolicy`; `interactionPolicyOverrideProvider` and `presentationPolicyOverrideProvider` are deterministic test/dev hooks. Reading `appLayoutClassProvider` outside AppLayoutScope throws.

#### keyboard-shortcuts

**One focus-independent keyboard host owns app-wide shortcuts and the bottom-center chord preview.**

Files:
- `lib/app/keyboard/app_keyboard_host.dart` — root hardware handler, typed bindings, modifier-aware preview
- `lib/app/app.dart` — sole host mount and root-owned shortcut registry

Notes:
- Mount `AppKeyboardHost` once below `FTheme`; feature screens must not add global hardware handlers.
- In remote/hybrid-remote mode the host consumes activation `KeyRepeatEvent`s (Enter, numpad Enter, Space, Select, game Button A) but leaves first-down activation and directional repeats to Flutter's normal Shortcuts/Actions/focus system.
- Ordinary keys never surface by themselves. Meta, Control, Alt/Option, Shift, and Fn start the
  preview; ordinary keys held with them join the displayed chord.
- A binding consumes the event only when its callback reports that it performed an action. The
  initial `Meta+Backspace` binding pops the root router only when it can pop, preserving normal
  control behavior otherwise.

#### theme-system

**ForUI theming: ForuiThemeFactory composes FThemeData from generated tokens, accent, fontScale, and policy.**

Files:
- `lib/shared/theme/forui_theme_factory.dart` — builds FThemeData, applies accent/scale/touch
- `lib/shared/theme/generated_forui_theme.dart` — ForUI CLI output (committed)
- `lib/shared/theme/colors.dart` / `typography.dart` / `style.dart` / `icons.dart` — generated (do not edit)
- `lib/shared/theme/app_spacing.dart` — AppSpacing xs..xl3 base tokens + `context.spacing` responsive values
- `lib/shared/theme/app_sizes.dart` — AppSizes sidebar/content width constants
- `lib/features/settings/settings_state.dart` — AppAccent enum owner

Notes:
- Never hand-edit generated files (`colors`/`typography`/`style`/`icons`/`generated_forui_theme`); regenerate via `forui_cli`. No lint fixes to them either.
- Change accents in `ForuiThemeFactory._accentColors`; feed FThemeData to MaterialApp via `toApproximateMaterialTheme()` (a ForUI SDK method), not Material duplicates.
- `touch` derives from `AppInteractionPolicy` (precisionPointer => desktop). The app factory
  replaces the generated type sizes and excessive leading with explicit body/display tokens,
  composes responsive and user font scales, and distributes leading evenly. Button vertical
  padding is derived from the resolved label size while preserving ForUI's 44-pixel touch and
  36-pixel pointer targets. Dark error foreground is overridden in the factory; `AppAccent` is
  owned by `settings_state.dart`.
- `AppPresentationTokens` is a handwritten ForUI theme extension. Ten-foot policy raises readable
  widths, spacing/type scale, minimum focus/control bounds, navigation width, and focus outline
  metrics without editing generated theme sources. `AppPresentationViewport` is the sole TV safe
  frame owner and preserves IME/display-feature data.

#### motion-and-page-transitions

**Duration/curve tokens plus a per-platform PageTransitionsTheme for native route transitions.**

Files:
- `lib/shared/motion/app_motion.dart` — duration/curve tokens
- `lib/shared/motion/app_page_transitions.dart` — nativePageTransitionsTheme (const)
- `lib/app/app.dart` — applies transitions theme + FThemeMotion
- `lib/features/onboarding/onboarding_page.dart` — consumer with reduce-motion guard

Notes:
- Source durations/curves from `AppMotion` only (quick/standard/deliberate, standardCurve/emphasizedCurve); never hardcode. `nativePageTransitionsTheme` is a top-level const applied via `pageTransitionsTheme` copyWith on both themes.
- Every platform transition is wrapped by `OpaquePageTransitionsBuilder`, which paints the active Material theme's scaffold background behind every routed page. This keeps route surfaces opaque without feature-level background declarations. iOS delegates to `CupertinoPageTransitionsBuilder` (preserves swipe-back); desktop (macOS/windows/linux) delegates to `CrossFadePageTransitionsBuilder`.
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
- `lib/shared/forms/{form_validators,password_field_toggle,form_field_reveal}.dart` — shared email/password validators, password-toggle, first-invalid-field reveal (imported directly by all auth pages)
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
- `lib/infrastructure/platform/platform_capabilities_resolver.dart` — startup tvOS/Android TV detection
- `lib/infrastructure/preferences/shared_preferences_settings_store.dart` — sole production SettingsStore impl

Notes:
- Route all logging through `AppLogger`; pass structured `Map<String,Object?>` context (redacted automatically, never pre-redact); debug/stacks gated behind verbose, info/warn/error always on. Diagnostics reads the injected capability provider and never performs a second native query.
- SettingsStore is per-key only (`readString`/`writeString`/`remove`), never `clearAll`; uses `SharedPreferencesAsync`; wrap adapters in try/on Object -> `SettingsStoreException`.
- No network/db/secure-storage adapters exist by design — do not add without escalating. Only `log_redactor` has tests.

#### testing-analysis-ci

**very_good_analysis-linted suite with macOS-only canonical goldens and integration smoke/route tests, all run locally; GitHub Actions builds release artifacts only.**

Files:
- `justfile` — test, test-goldens, smoke, watch, analyze, gen recipes
- `.github/workflows/release.yml` — release artifacts for macOS/iOS/Windows/Linux/Android on pushes to `master`
- `analysis_options.yaml` — very_good_analysis + strict-casts/inference/raw-types + riverpod_lint
- `integration_test/development_smoke_test.dart` — full-flow smoke across layouts
- `integration_test/production_routes_test.dart` — dev routes absent in prod
- `test/goldens/canonical_matrix_golden_test.dart` — 13-case pairwise matrix (macOS)
- `test/goldens/README.md` — pinned baseline env (macOS 26.5, Flutter 3.44.7)

Notes:
- `just test` excludes goldens; goldens compare ONLY on macOS via `just test-goldens`; regenerate the 13 committed baselines with `--update-goldens` on the pinned runner and inspect every changed image.
- Integration tests reuse `createApplication`; use `pumpAppFrames` (8 bounded frames), never `pumpAndSettle`; pass `--dart-define-from-file`. `resetTestSettings()` wipes settings keys before each run.
- Android release CI validates TV source/merged manifests, launcher/resource ownership, ARM ABIs,
  and 16 KB zip alignment. tvOS uses the separately pinned `flutter-tvos` toolchain documented in
  `docs/tvos_toolchain.md`; it never replaces the stock Flutter SDK.
- Keep analysis clean at `flutter analyze --fatal-infos`; keep generated code in sync (`just gen` + `just gen-check`); Flutter pinned to 3.44.7 in CI.

## Where do I...

- **Add a screen/route:** Add name+path constants in `lib/app/routing/app_routes.dart`; add the `GoRoute` and wrapper to the owning feature's `<feature>_routes.dart`; compose a new feature list in `app_router.dart`. Branch routes stay absolute and settings keeps `/settings` before detail routes. Switch tabs through `goAppTab`/`goBranch`, not `goNamed`. Gate dev routes in `dev_gallery_routes.dart` with `developmentToolsEnabled`. Add gates only to `appRedirect`.
- **Add a translation:** Add the key to `lib/i18n/en.i18n.json`, `ar.i18n.json`, and `zh-Hans.i18n.json` in sync; run `just gen` (`dart run build_runner build`); commit all `*.g.dart`. Use `context.t` in widgets.
- **Change a color/theme token:** Accent colors live in `lib/shared/theme/forui_theme_factory.dart` (`_accentColors`). Do NOT edit generated `colors.dart`/`typography.dart`/`style.dart`/`icons.dart`/`generated_forui_theme.dart` — regenerate via `forui_cli`. Use `AppSpacing`/`AppSizes` for layout numbers.
- **Add a setting:** Extend `SettingsState` in `lib/features/settings/settings_state.dart`; add a key to `persistedKeys` + load/save in `lib/features/settings/settings_repository.dart`; add a controller setter in `settings_controller.dart`; render it in `lib/features/settings/settings_page.dart`.
- **Add a feature:** Create `lib/features/<name>/` with `<name>_page.dart`, typed Freezed `<name>_view_data.dart`, and (when routed) `<name>_routes.dart`. Add route constants in `app_routes.dart`; the route module injects callbacks into a page that has no routing imports. Mirror under `test/features/<name>/`. For an auth form, use the page + `*_form_value` + `*_presentation_state` pattern and regenerate `*.freezed.dart` with `just gen`.
- **Change page transitions/motion:** Source durations/curves from `lib/shared/motion/app_motion.dart`; native transitions live in `lib/shared/motion/app_page_transitions.dart` (`nativePageTransitionsTheme`, applied via `pageTransitionsTheme` copyWith in `app.dart`). Guard custom animations with `MediaQuery.disableAnimationsOf(context)`.
- **Run tests (unit vs golden vs integration):** Unit/widget: `just test`. Goldens: `just test-goldens` (macOS only; regenerate with `--update-goldens`). Integration smoke: `just smoke` (adds `--dart-define-from-file=config/development.json`). Prod routes: `flutter test integration_test/production_routes_test.dart --dart-define-from-file=config/production.json`. Analyze: `just analyze`.
- **Build for release:** `flutter build <apk|ios|macos|linux|windows|web> --dart-define-from-file=config/production.json`. iOS uses `--no-codesign` in CI. Never set `ENABLE_*` flags true when `APP_ENV=production`.

## Conventions & guardrails

- No `core/`, `utils/`, service-locator, use-case, base-repository/base-page/feature-barrel layers. Feature-first ownership only.
- Construct adapters through the domain aggregates in `lib/app/dependencies.dart` and `lib/app/dependencies/**`; add providers via `AppDependencies` + `ProviderScope` overrides. Compose routing in `lib/app/routing/**` plus feature `*_routes.dart`, never in pages.
- Settings boundary is handwritten Riverpod (no codegen): override `settingsRepositoryProvider` + `initialSettingsProvider` at the ProviderScope; mutate only via `SettingsController` setters.
- ForUI owns controls + the committed generated theme; never hand-edit slang `*.g.dart` or theme `colors`/`typography`/`style`/`icons`/`generated_forui_theme`. Regenerate, don't patch.
- No backend: static callbacks give honest navigation or unavailable feedback (`common.notConnected` / `globalError`); never fake success. No fake backend services, Mocktail, or Riverpod provider codegen. Freezed data-class codegen is allowed and committed.
- Config via `--dart-define-from-file=config/<env>.json` only — compile-time, string values, no secrets. Gate behavior through `verboseLoggingEnabled`/`developmentToolsEnabled`, not raw `enable*` flags.
- Goldens separate from the default suite (`just test` excludes them); compare ONLY on the macOS pinned runner (`just test-goldens`); regenerate with `--update-goldens`.
- Logging through `AppLogger` only (auto-redacts structured context); no pre-redaction, no direct Talker calls. `debug`/stacks gated behind verbose.
- Tests mirror `lib/` (`app/`, `features/`, `shared/`, `infrastructure/`) plus `hardening/` (a11y + responsive) and `goldens/`. Use `pumpAppFrames`, never `pumpAndSettle`; drive widget/a11y/responsive tests via dev_gallery fixtures + `PreviewFrame`.
- Keep analysis clean at `flutter analyze --fatal-infos` (very_good_analysis + strict-casts/strict-inference/strict-raw-types + riverpod_lint). Keep generated code in sync: `just gen` then `just gen-check`.
