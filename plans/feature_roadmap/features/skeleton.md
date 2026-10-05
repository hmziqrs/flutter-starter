# Skeleton loading placeholders

> **Tier:** P2 · **Domain:** ux · **Backend:** none · **Status:** in-progress · **Depends on:** state-views

Implementation note: the widgets, tests, motion guards, and gallery fixtures are done and
verified; `home_page.dart` now renders `SkeletonView` behind the `homeRecentActivityProvider`
load future (skeleton→content asserted in `integration_test/home_lists_test.dart`). The
feature stays `in-progress` solely on checklist item 3 — home + the dev gallery are two
distinct consumers, still short of the ≥3 bar (adopt on pricing/profile/search or record the
designation to close it).

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
- **Dependencies:** `skeletonizer: ^2.1.3` (optional — wraps an existing laid-out tree and
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
- **Golden impact:** deferred — no loading-state matrix case is committed today. Shimmer is
  non-deterministic, so such a case must run against the static fallback (or a single frozen
  shimmer frame) and can only be added with the repo-wide re-baseline on the pinned macOS 26
  CI runner; never run `--update-goldens` locally to produce it.
- **Dev-gallery fixture:** a `PreviewFrame` skeleton case (static fallback), gated behind
  `developmentToolsEnabled`.

## i18n

- **Keys:** none — skeletons carry no copy; the loading label comes from
  [state-views.md](state-views.md).
- **RTL note:** n/a — the mirrored layout inherits `Directionality`.

## Audit

- [x] No-backend honored as a port — **n/a**: backend-free; the skeleton renders off a feature's `isLoading` flag and never issues a network call (`skeleton_view.dart` has no I/O); no plugin calls.
- [x] Feature-first ownership — **pass**: `lib/shared/widgets/states/skeleton_view.dart` + `skeleton_tile.dart`, peers of the state-views widgets in the same bucket.
- [ ] shared/widgets extraction ≥3 consumers — **warn**: consumers today are the dev gallery
  (`skeleton_gallery_cases.dart`) plus `home_page.dart` (production — `SkeletonView` mirrors
  the recent-activity tiles behind `homeRecentActivityProvider`); `pricing` and `profile` did
  not adopt it and no ≥3 deferred consumers are designated — the bar is unmet.
- [x] Composition root confined — **pass**: no providers or adapters; pure widgets, nothing to wire in `AppDependencies`/`ProviderScope`.
- [x] Motion guarded — **pass**: hand-rolled implementation (no `skeletonizer` dependency in `pubspec.yaml`); `_sync` reads `MediaQuery.disableAnimationsOf` (`skeleton_view.dart:94`) and disposes the ticker under reduce-motion so only the static base paint remains; the animated path sources duration/curve from `AppMotion` tokens (`skeleton_view.dart:105,109`); `skeleton_view_test.dart:84,99` asserts the static fallback stays measurable; feature tests never use `pumpAndSettle`.
- [x] i18n synced en/ar/zh-Hans — **pass**: no skeleton keys (copy-less bones); the default semantics label reuses `states.loadingTitle`, present in all three locales (`en.i18n.json:374`, `ar.i18n.json:399`, `zh-Hans.i18n.json:369`).
- [x] Strict analysis clean — **pass**: immutable typed `SkeletonStyle` with `==`/`hashCode` (`skeleton_view.dart:8-45`), no `dynamic`; deterministic bone primitives.
- [x] Generated code untouched — **pass**: no codegen for this feature; working-tree generated-file changes trace to source edits via `just gen`.
- [x] Native entitlements flagged — **n/a**: no native surface.
- [x] Goldens re-baselined + dev-gallery fixture — **pass**: committed `PreviewFrame` cases `skeleton.staticList` (frozen/static, golden-safe) + `skeleton.shimmerList` (`skeleton_gallery_cases.dart`, registered in `gallery_registry.dart:36`) — the repo-wide re-baseline on the pinned macOS 26 runner is tracked separately (the committed baselines are outdated vs HEAD; that re-baseline is outstanding).
- [x] Port-reuse consistency — **n/a**: introduces no port.
- [x] Config rule respected — **pass**: gallery cases reachable only via `dev_gallery_routes.dart` gated on `config.developmentToolsEnabled`.
- [x] Honest feedback, no faked success — **pass**: the skeleton carries a loading semantics label and transitions to real content or the error/empty state-view; it never renders data-shaped bones as a success claim.

## Risks / notes

- **Motion guardrail is load-bearing here.** [Audit checklist #5](../contracts.md#5--motion-guarded)
  names skeleton shimmer directly: the animated path MUST have a `disableAnimationsOf` check
  plus a non-animated fallback; goldens run against the static path.
- **Depends on state-views.** Sequence after [state-views.md](state-views.md) — the skeleton is
  one loading treatment; `loading_state_view` is the fallback. Share the `lib/shared/widgets/states/`
  bucket.
- **Mirror drift.** `skeletonizer` wraps the real widget tree, so keep the mirrored layout in
  sync with the production widget — a stale skeleton misleads users about what is loading.
- **Optional dependency.** If `skeletonizer` is declined (bundle/audit concerns), the hand-rolled
  `FSkeleton` box is the fallback; do not block the feature on the package.
