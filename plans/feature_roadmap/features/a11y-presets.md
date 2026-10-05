# Accessibility presets

> **Tier:** P2 · **Domain:** platform · **Backend:** none · **Status:** done · **Depends on:** none

## Summary
Surface the already-clamped `fontScale` as named presets (comfortable / large) plus an optional
dyslexia-friendly font, exposed through the settings UI. Accessibility is a baseline store/app-store
requirement; the repo already guards reduce-motion and carries focus `debugLabels`, so this closes
the visible-a11y story. Backend-free — persists via the existing `SettingsStore` port.

## Contract
- **Ports / value objects:** `AppTextPreset` enum (`comfortable`, `large`, `dyslexia`) owned by the
  settings feature, with a pure mapping to `(fontScale, fontFamily)`. `fontScale` is already clamped
  to `[0.85, 1.6]` in [`SettingsState`](../../lib/features/settings/settings_state.dart); the `large`
  preset must stay inside that range. Adds a `textPreset` field (and optional `fontFamily` override)
  to `SettingsState`.
- **Providers:** extend [`settingsControllerProvider`](../../lib/features/settings/settings_controller.dart)
  with `setTextPreset(AppTextPreset)` — optimistic-update-with-rollback, persisted via the per-key
  `SettingsStore` (no `clearAll`).
- **Routes:** add `accessibilitySettings` / `/settings/accessibility` (paired name+path constants,
  sibling of `appearanceSettings`/`languageSettings`). In-shell GoRoute under the existing
  ShellRoute.
- **Files:**
  - `lib/features/settings/text_preset.dart` — **add**; enum + `toSettings()` mapping
    (fontScale + fontFamily).
  - `lib/features/settings/accessibility_settings_page.dart` — **add**; preset selector UI.
  - `lib/features/settings/settings_state.dart` — **edit**; `textPreset` field + `==`/`hashCode`/
    `copyWith`.
  - `lib/features/settings/settings_repository.dart` — **edit**; `textPresetKey` in `persistedKeys`,
    load/save.
  - `lib/features/settings/settings_controller.dart` — **edit**; `setTextPreset`.
  - `lib/app/routing/app_routes.dart` — **edit**; paired `accessibilitySettings`/`Path` constants.
  - `lib/app/routing/app_router.dart` — **edit**; in-shell GoRoute.
  - `lib/shared/theme/forui_theme_factory.dart` — **edit**; apply the dyslexia `fontFamily` through
    `_buildTypography` (fontScale already flows here).
  - `lib/shared/widgets/labeled_control.dart` — **add only when >=3 screens use it** (see Audit).
  - `test/hardening/semantics_focus_order_test.dart` — **add**; assert preset UI focus order.
- **Dependencies:** none (Noto Sans / Noto Sans Arabic / Noto Sans SC already bundled in
  `assets/fonts/`). A dyslexia font is optional — if added, bundle it as an asset and regenerates
  goldens (see Risks).

## Backend & test surface
Backend-free. Default = local settings persisted through the existing `SettingsStore` port. No
test-server contract. Tests use `InMemorySettingsStore` (with `failReads`/`failWrites` toggles) —
no Mocktail.

## Tests
- **Unit/widget:** preset → `(fontScale, fontFamily)` mapping (exhaustive over `AppTextPreset`),
  clamping invariant, load/save round-trip via `InMemorySettingsStore`. Widget: selecting a preset
  applies `fontScale` live through `ForuiThemeFactory`.
- **Integration:** light — preset change persists across a `createApplication` reload
  (`pumpAppFrames`).
- **Golden impact:** **yes** — `fontScale`/font changes are visual and hit the
  [`canonical_matrix_golden_test.dart`](../../test/goldens/canonical_matrix_golden_test.dart). Add a
  `PreviewFrame` case per preset and re-baseline on the pinned macOS runner.
- **Dev-gallery fixture:** `PreviewFrame` case per preset (comfortable/large/dyslexia) behind
  `developmentToolsEnabled`.

## i18n
- **Keys:** `settings.accessibility.title`, `settings.accessibility.preset.comfortable`,
  `settings.accessibility.preset.large`, `settings.accessibility.preset.dyslexia`, plus a one-line
  description per preset. Sync `en` + `ar` + `zh-Hans`, run `just gen`.
- **RTL note:** n/a for font/scale, but the optional dyslexia font **must cover Arabic glyphs** —
  OpenDyslexic does not; fall back to Noto Sans Arabic for `ar` (see Risks).

## Audit

Implementation audit (2026-10-04) against the 13-item checklist in
[contracts.md](../contracts.md):

- [x] No-backend honored as a port — **n/a**: backend-free settings persisted through the existing
  `SettingsStore` per-key port (`textPresetKey` = `appearance.text_preset`,
  `settings_repository.dart:13,27,47,87`).
- [x] Feature-first ownership — **pass**: `AppTextPreset` + `toSettings()` mapping
  (`text_preset.dart`), selector page (`accessibility_settings_page.dart`), and route
  (`settings_routes.dart:37-39`) all owned by the settings feature; no `core/`/`utils/`. Focus
  order asserted in `test/hardening/accessibility/a11y_presets_focus_order_test.dart` (LTR + RTL).
- [x] Shared extraction ≥3 consumers — **pass**: `labeled_control.dart` was never promoted; the
  selector composes the feature-local `LabeledSectionCard`
  (`settings/widgets/labeled_section_card.dart`) — nothing landed under `lib/shared/widgets/`.
- [x] Composition root confined — **pass**: presets flow through the existing
  `settingsControllerProvider`; route declared in the feature-owned `settings_routes.dart` (not
  app_router); the theme reads `settings.fontFamily`/`fontScale` at the composition seam
  (`app.dart:290-300`, `forui_theme_factory.dart:249-266`).
- [x] Motion guarded — **n/a**: introduces no new animation.
- [x] i18n synced en/ar/zh-Hans — **pass**: `settings.accessibility.*` (title + all three presets
  + per-preset descriptions) verified present in all three `lib/i18n/*.i18n.json`; RTL rendering
  tested (`accessibility_settings_page_test.dart:75`).
- [x] Strict analysis clean — **pass**: exhaustive switch over `AppTextPreset` in `toSettings()`
  (`text_preset.dart:10-17`); clamp invariant asserted (`text_preset_test.dart:22-30`: large=1.3
  inside `[0.85, 1.6]`).
- [x] Generated code untouched — **pass**: `text_preset.freezed.dart` +
  `settings_state.freezed.dart` committed alongside their `part` sources.
- [x] Native entitlements flagged — **n/a**: none. The optional dyslexia font asset is a
  documented placeholder — honest "where available" copy in all three locales, asserted by
  `text_preset_test.dart:40` ("asset optional"); fallback flows through Noto script families
  (`forui_theme_factory.dart:251-266`), never a wholesale font swap.
- [x] Goldens re-baselined + dev-gallery fixture — **pass**: one `PreviewFrame` case per preset
  (`a11y_presets_gallery_cases.dart`, registered `gallery_registry.dart:44`); fontScale/font is
  matrix-visible per this doc — repo-wide re-baseline still pending the pinned macOS 26 CI run
  (tracked repo-wide).
- [x] Port-reuse consistency — **pass**: no new port; reuses `SettingsStore` + theme factory seam.
- [x] Config rule respected — **pass**: no config surface.
- [x] Honest feedback, no faked success — **pass**: save failure surfaces `common.notConnected`
  with rollback (`accessibility_settings_page_test.dart:60-73`); the dyslexia preset never claims
  a font it cannot render.

## Risks / notes
- **Dyslexia font + RTL/CJK.** OpenDyslexic has no Arabic/CJK coverage; shipping it would break `ar`
  glyph rendering and golden determinism. Default the dyslexia preset to swap only the Latin family
  and keep Noto Sans Arabic / Noto Sans SC for those locales — do **not** swap fonts wholesale.
- **`fontScale` clamp is load-bearing.** The `large` preset must resolve to a value within
  `[0.85, 1.6]`; never bypass `_parseFontScale`'s clamp.
- **Font asset changes force a golden re-baseline** and a `pubspec.yaml` asset entry — flag in the PR.
- **Sequencing:** extend `SettingsState` in the same pass as [haptics](./haptics.md). Builds on the
  existing reduce-motion guards in
  [`settings_page.dart`](../../lib/features/settings/settings_page.dart) and
  [`onboarding_page.dart`](../../lib/features/onboarding/onboarding_page.dart) — do not duplicate
  them.
- The hardening suite under `test/hardening/` already covers a11y/responsive cases; extend it rather
  than starting a parallel harness.
