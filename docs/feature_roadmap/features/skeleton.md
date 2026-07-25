# Skeleton loading placeholders

> **Tier:** P2 · **Domain:** ux · **Backend:** none · **Status:** planned · **Depends on:** state-views

## Summary

Animated shimmer placeholders that mirror a screen's real layout (cards, tiles, text lines) so
users see structure while data loads, not a bare spinner. ForUI has no skeleton primitive in
0.24.1, so this adopts `skeletonizer` (or a hand-rolled `FSkeleton` box) under the shared
states bucket.

## Contract

- **Ports / value objects:** No port — backend-free. No value object beyond an optional
  `SkeletonStyle` exposing brightness-derived colors from `context.theme`. The skeleton wraps an
  existing laid-out widget subtree and shimmers it.
- **Providers:** none.
- **Routes:** none.
- **Files:**
  - add `lib/shared/widgets/states/skeleton_view.dart` — wraps a real subtree; shimmer on/off
    via `MediaQuery.disableAnimationsOf(context)`
  - add `lib/shared/widgets/states/skeleton_tile.dart` — card/tile bone for grids
  - edit [`lib/features/home/home_page.dart`](../../lib/features/home/home_page.dart) — optional
    first consumer (skeleton for `_RecentActivity` during load)
  - add `test/shared/widgets/states/skeleton_view_test.dart`
  - add a skeleton `PreviewFrame` case to the dev gallery
- **Dependencies:** `skeletonizer ^5.0.0` (optional — wraps an existing laid-out tree and
  auto-shimmers it, ideal for mirroring `FCard`/`FTile` grids). A hand-rolled `FSkeleton` painted
  from `context.theme` colors needs no dependency; prefer `skeletonizer` for the mirror property.

## Backend & test surface

Backend-free. The default impl is real and local — the skeleton renders whenever a feature's
`*_presentation_state.isLoading` is true; no network call is involved. No faked success: the
skeleton never claims data loaded; it transitions to the real content or to the
empty/error state-view ([state-views.md](state-views.md)).

## Tests

- **Unit/widget:** skeleton renders the mirrored subtree; under `disableAnimationsOf` the static
  (non-shimmering) fallback paints and the subtree is still measurable; colors derive from
  `context.theme`.
- **Integration:** `home_page` load path via `createApplication` + `pumpAppFrames` asserts the
  skeleton→content transition — never `pumpAndSettle`.
- **Golden impact:** yes — adds a loading-state matrix case. Shimmer is non-deterministic, so
  goldens run against the static fallback (or a single frozen shimmer frame). Re-baseline on the
  pinned macOS runner.
- **Dev-gallery fixture:** a `PreviewFrame` skeleton case (static fallback), gated behind
  `developmentToolsEnabled`.

## i18n

- **Keys:** none — skeletons carry no copy; the loading label comes from
  [state-views.md](state-views.md).
- **RTL note:** n/a — the mirrored layout inherits `Directionality`.

## Audit

- [x] No-backend honored as a port — **n/a** (backend-free; driven by the `isLoading` flag)
- [x] Feature-first ownership — **pass** (`lib/shared/widgets/states/`, peer of state-views)
- [ ] shared/widgets extraction ≥3 consumers — **warn** (no concrete consumer today; reach the threshold by adopting on home + pricing + profile load states together, else defer)
- [x] Motion guarded — **pass** (shimmer guarded by `disableAnimationsOf` + a static fallback that still lays out; critical — [checklist #5](../audit_checklist.md#5--motion-guarded) names skeleton shimmer explicitly)
- [x] Tests use pumpAppFrames, never pumpAndSettle — **pass**
- [x] i18n synced en/ar/zh-Hans; gen-check stays clean — **pass** (no new keys)
- [x] Strict-analysis clean — **pass** (typed style, no `dynamic`)
- [x] Native entitlements flagged — **n/a**
- [ ] Golden re-baseline noted on pinned macOS runner — **warn** (new loading matrix case; must freeze shimmer for determinism)

## Risks / notes

- **Motion guardrail is load-bearing here.** [Audit checklist #5](../audit_checklist.md#5--motion-guarded)
  names skeleton shimmer directly: the animated path MUST have a `disableAnimationsOf` check
  plus a non-animated fallback; goldens run against the static path.
- **Depends on state-views.** Sequence after [state-views.md](state-views.md) — the skeleton is
  one loading treatment; `loading_state_view` is the fallback. Share the `lib/shared/widgets/states/`
  bucket.
- **Mirror drift.** `skeletonizer` wraps the real widget tree, so keep the mirrored layout in
  sync with the production widget — a stale skeleton misleads users about what is loading.
- **Optional dependency.** If `skeletonizer` is declined (bundle/audit concerns), the hand-rolled
  `FSkeleton` box is the fallback; do not block the feature on the package.
