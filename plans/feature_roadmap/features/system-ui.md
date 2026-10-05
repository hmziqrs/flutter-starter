# System UI overlay & edge-to-edge

> **Tier:** P2 · **Domain:** platform · **Backend:** none · **Status:** done · **Depends on:** none

## Summary
Configure transparent/branded status and navigation bars and draw app content behind system chrome
(Android edge-to-edge, iOS safe-area handling). Android 15 (API 35) **enforces** edge-to-edge for
apps targeting a modern `targetSdk`, so a starter that ignores it ships visually broken on current
devices. Pure presentation/config — no backend, no new dependency (built-in `SystemChrome`).

## Contract
- **Ports / value objects:** No port — this is a one-shot config command plus a reactive overlay-style
  side effect, both backed by the device (the "default impl" is real and local). Value object is the
  `SystemUiOverlayStyle` derived from `Brightness` + `AppAccent`; derive it inside
  [`ForuiThemeFactory`](../../lib/shared/theme/forui_theme_factory.dart) so the overlay color stays in
  lockstep with the accent tokens (`_accentColors`).
- **Providers:** No new Riverpod provider required. Reactivity comes from the existing
  [`settingsControllerProvider`](../../lib/features/settings/settings_controller.dart) (themeMode +
  accent already drive `_AppView.build`); apply the overlay style as a side effect there.
- **Routes:** None.
- **Files:**
  - `lib/infrastructure/platform/system_ui_controller.dart` — **add**; `applyEdgeToEdge()` (sets
    `SystemUiMode.edgeToEdge` with transparent bars) + `applyOverlayStyle(brightness, accent)`.
  - `lib/bootstrap.dart` — **edit (root composition)**; invoke `SystemUiController.applyEdgeToEdge()`
    once inside `createApplication` after `WidgetsFlutterBinding.ensureInitialized()`.
  - `lib/app/app.dart` — **edit (root composition)**; in `_AppView.build` (where light/dark themes
    are already computed) call `SystemUiController.applyOverlayStyle(...)` so the style tracks theme
    + accent changes. Gate desktop/web to no-ops via `PlatformCapabilities`.
  - `lib/shared/theme/forui_theme_factory.dart` — **edit**; expose the overlay style alongside the
    existing `build({brightness, accent, fontScale, interactionPolicy, responsiveFontScale})`
    (accent color is already resolved here; `touch` is derived internally from `interactionPolicy`).
  - `android/app/src/main/res/values-v35/styles.xml` — **add (native, outside `lib/`)**; opt into
    edge-to-edge window posturings for API 35+.
- **Dependencies:** none (Flutter SDK `SystemChrome`).

## Backend & test surface
Backend-free. The default and only impl is the real device (`SystemChrome`). No test-server
contract, no `tools/hono_server/` route. Tests assert the pure style construction and the
PlatformCapabilities gating; they do not touch real chrome (hermetic).

## Tests
- **Unit/widget:** `SystemUiController` overlay-style mapping for every `(brightness, accent)` pair
  (exhaustive over `AppAccent`); confirm desktop/web short-circuit. Pure value test, no plugin.
- **Integration:** `createApplication` invokes `applyEdgeToEdge()` without throwing (reuse the
  `createApplication` seam; `pumpAppFrames`, never `pumpAndSettle`).
- **Golden impact:** none on the pinned macOS runner (system chrome is not captured and macOS has no
  status bar in goldens). **Warn:** any future Android/iOS golden set would need its own baselines.
- **Dev-gallery fixture:** n/a — system chrome does not render inside `PreviewFrame`.

## i18n
- **Keys:** none.
- **RTL note:** n/a (overlay is symmetric; safe-area insets already handled by existing `SafeArea`
  usage).

## Audit
- [x] No-backend honored as a port — **n/a**: backend-free one-shot config command, not a side-effecting data service; correct to skip the port here (explicit C2 exemption). `SystemChrome` is touched only from `SystemUiController` (`system_ui_controller.dart:15,26`) — no widget calls the platform channel directly.
- [x] Feature-first ownership — **pass**: `lib/infrastructure/platform/system_ui_controller.dart` (peer of `platform_capabilities.dart`); root composition edits are exactly the two planned seams — `bootstrap.dart:105` (`applyEdgeToEdge` inside `createApplication`) and `app.dart:358` (`applyOverlayStyle` in the theme builder). (Deviation from the Files list: the `(brightness, accent)` mapping lives in `SystemUiController.overlayStyleFor` rather than `ForuiThemeFactory`; `ForuiThemeFactory.overlayStyle` (`forui_theme_factory.dart:283`) also exists but is currently unused by the controller — harmless duplication, same transparent-bar contract.)
- [x] shared/widgets extraction ≥3 consumers — **n/a**: no new shared widget.
- [x] Composition root confined — **pass**: `SystemChrome.*` appears nowhere else in `lib/` (grep-verified); invocation is confined to `bootstrap.dart` + `app.dart`'s theme builder, both sanctioned composition seams.
- [x] Motion guarded — **n/a**: no animation.
- [x] i18n synced en/ar/zh-Hans — **n/a**: no user-facing keys.
- [x] Strict analysis clean — **pass**: exhaustive switch over `(Brightness, AppAccent)` using `||` patterns covering all six accents (`system_ui_controller.dart:35-64`); `system_ui_controller_test.dart:48-51` pins the 2×6 cardinality so the switch cannot go non-exhaustive silently; no `dynamic`.
- [x] Generated code untouched — **pass**: no codegen involved.
- [x] Native entitlements flagged — **pass** (resolves the prior warn): `values-v35/styles.xml` + `values-night-v35/styles.xml` are committed with rationale comments (`windowDrawsSystemBarBackgrounds`, `*Contrast=false`, `shortEdges` cutout); `android:windowSoftInputMode="adjustResize"` is set on both activities (`AndroidManifest.xml:37,61`); the Android release-build CI job exists (`.github/workflows/release.yml:251`, per-ABI APKs + AAB).
- [x] Goldens re-baselined + dev-gallery fixture — **pass**: macOS golden matrix unaffected (system chrome is not captured; no status bar on macOS goldens) and the fixture is correctly n/a (chrome does not render inside `PreviewFrame`); the doc notes any future mobile golden set needs its own baselines. The repo-wide re-baseline on the pinned macOS 26 runner is tracked separately (currently pending) and does not interact with this feature.
- [x] Port-reuse consistency — **n/a**: introduces no port; reads the existing `PlatformCapabilities` seam for gating.
- [x] Config rule respected — **pass**: no runtime env switching; desktop/web short-circuit via `PlatformCapabilities` (`system_ui_controller.dart:84-89`), not scattered `Platform.is*` checks or config flags; platform gating asserted in `system_ui_controller_test.dart:81-104`.
- [x] Honest feedback, no faked success — **n/a**: pure config command with no user-visible action to fake; tests assert style construction and gating hermetically without touching real chrome.

## Risks / notes
- **Android 15 enforcement is the whole reason this is P2, not P3.** Skipping it ships a broken
  layout on API 35+; the `values-v35` styles + `adjustResize` are mandatory, not cosmetic.
- **Safe-area discipline.** Edge-to-edge draws behind the bars; every existing screen must already
  be wrapped in `SafeArea` (verify the in-shell pages and auth scaffold before merge — the auth
  `AuthPageScaffold` and `AppShell` are the risk surfaces).
- **No call-site platform branching.** Branch on `PlatformCapabilities` / width inside the controller,
  never scatter `Platform.is*` checks — matches the existing guardrail.
- **Sequencing:** foundational platform config; lands before [haptics](./haptics.md) and
  [a11y-presets](./a11y-presets.md) since both also touch bootstrap/settings. No upstream dependency.
- See [../contracts.md](../contracts.md) C2 (backend stance — this feature is explicitly exempt: no
  port needed) and [../contracts.md](../contracts.md) §9 (native entitlements).
