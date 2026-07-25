# System UI overlay & edge-to-edge

> **Tier:** P2 · **Domain:** platform · **Backend:** none · **Status:** planned · **Depends on:** none

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
    existing `build(brightness, accent, touch)` (accent color is already resolved here).
  - `android/app/src/main/res/values-v35/styles.xml` — **add (native, outside `lib/`)**; opt into
    edge-to-edge window posturings for API 35+.
- **Dependencies:** none (Flutter SDK `SystemChrome`).

## Backend & test surface
Backend-free. The default and only impl is the real device (`SystemChrome`). No test-server
contract, no `tools/test_server/` route. Tests assert the pure style construction and the
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
- [x] No-backend honored as a port — **n/a**: backend-free config command, not a side-effecting
  service; correct to skip the port here.
- [x] Feature-first ownership; no `core/` `utils/` buckets — **pass**: lives in
  `lib/infrastructure/platform/` (peer of `platform_capabilities.dart`), edits to root composition
  files are explicit and minimal.
- [x] shared/widgets extraction only if >=3 consumers — **n/a**: no new shared widget.
- [x] Motion guarded — **n/a**: no animation.
- [x] Tests use pumpAppFrames, never pumpAndSettle — **pass**.
- [x] i18n synced en/ar/zh-Hans; gen-check stays clean — **n/a**: no keys.
- [x] Strict-analysis clean — **pass**: exhaustive switch over `AppAccent`/`Brightness`, no `dynamic`.
- [ ] Native entitlements flagged in PR + CI platform jobs — **warn**: `values-v35/styles.xml` +
  Android `windowSoftInputMode="adjustResize"` must be covered by the Android release-build CI job.
- [ ] Golden re-baseline noted on pinned macOS runner — **warn**: macOS matrix unaffected, but call
  out that mobile-only golden coverage (if added) requires fresh baselines.

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
- See [../decisions.md](../decisions.md) D2 (backend stance — this feature is explicitly exempt: no
  port needed) and [../audit_checklist.md](../audit_checklist.md) §9 (native entitlements).
