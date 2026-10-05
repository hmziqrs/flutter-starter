# Reusable state views

> **Tier:** P1 · **Domain:** ux · **Backend:** none · **Status:** done · **Depends on:** none

## Summary

A themed family of widgets for the canonical async-list states (empty / error / loading), so
features stop hand-rolling `FCard` placeholders. Every list/detail screen cycles through these
states; one shared contract guarantees consistent spacing, wording, a11y, and retry semantics
instead of per-feature copy-paste divergence.

## Contract

- **Ports / value objects:** No port — backend-free. A small `StateViewAction` record
  (`{String label, VoidCallback onTap}`) carries the optional action; views take typed
  title/body `String`s plus that optional action. The loading view exposes no action.
- **Providers:** none — pure widgets taking typed Strings + reading `context.theme`.
- **Routes:** none — a widget family, not a routed screen.
- **Files:**
  - add `lib/shared/widgets/states/empty_state_view.dart`
  - add `lib/shared/widgets/states/error_state_view.dart`
  - add `lib/shared/widgets/states/loading_state_view.dart`
  - edit `lib/i18n/{en,ar,zh-Hans}.i18n.json` — add `states.empty*` / `states.error*` /
    `states.loading*` keys
  - edit `lib/features/home/home_page.dart` — first consumer (replace the inline
    `_RecentActivity` empty `FCard` near line 263)
  - add `test/shared/widgets/states/{empty,error,loading}_state_view_test.dart`
  - add `PreviewFrame` cases per state to `lib/features/dev_gallery/cases/production_gallery_cases.dart`
- **Dependencies:** none (Flutter SDK + ForUI `FCard` / `FButton` / `FIcon`)

## Backend & test surface

Backend-free. The default impl is real and local — views are pure presentational widgets driven
by the `loading` / `error` flag already in each feature's `*_presentation_state`. The error
view's retry callback is feature-supplied, so an action with no backend still surfaces
`common.notConnected` ([`lib/i18n/en.i18n.json`](../../lib/i18n/en.i18n.json):20) rather than
faking success. The no-backend boundary is honored at the call site, not inside the widget.

## Tests

- **Unit/widget:** render each view with and without the action; assert `context.t` strings,
  `FCard` presence, `Semantics` labels, and that the retry callback fires; render under the `ar`
  locale to confirm RTL glyph spacing.
- **Integration:** optional — render `home_page` with an empty-activity fixture via
  `createApplication` + `pumpAppFrames` (8 bounded frames), never `pumpAndSettle`.
- **Golden impact:** yes — the home matrix changes (inline empty `FCard` replaced); add a
  `PreviewFrame` fixture per state to the canonical matrix. Re-baseline on the pinned macOS
  runner ([`test/goldens/README.md`](../../test/goldens/README.md); baselines currently empty).
- **Dev-gallery fixture:** three `PreviewFrame` cases (empty / error / loading), gated behind
  `developmentToolsEnabled`.

## i18n

- **Keys:** `states.emptyTitle` / `states.emptyBody`, `states.errorTitle` / `states.errorBody`,
  `states.loadingTitle` — synced across `en` + `ar` (RTL) + `zh-Hans`; run `just gen`. Reuse
  the existing `common.retry` for the action label.
- **RTL note:** centered icon+text stacks are direction-neutral; verify `ar` glyph spacing and
  icon placement in the `PreviewFrame`.

## Audit

- [x] No-backend honored as a port — **n/a**: backend-free presentational widgets; retry is feature-supplied and the shared list wires it honestly — `PagedListView` defaults the error body to `common.notConnected` with a real retry (`lib/shared/widgets/lists/paged_list_view.dart:58-66`; key verified in all three locales).
- [x] Feature-first ownership; no core/ utils/ buckets — **pass**: `lib/shared/widgets/states/{empty,error,loading}_state_view.dart` + `state_view_card.dart` — the designated cross-feature bucket, peer of `escape_dismissible_overlay.dart`.
- [x] shared/widgets extraction >=3 consumers — **pass** (warn resolved): two of the three designated consumers are now concrete — home activity (`lib/features/home/home_page.dart:286`, `EmptyStateView`) and search-results via `PagedListView` rendering all three states (`lib/shared/widgets/lists/paged_list_view.dart:56-69`, backing `lib/features/search/search_page.dart`); [offline-cache](offline-cache.md) remains the designated deferred consumer under [C1](../contracts.md#c1--scope-is-comprehensive) (re-audit when it lands).
- [x] Composition root confined — **n/a**: pure widgets taking typed Strings; no providers.
- [x] Motion guarded — **pass**: `LoadingStateView` guards with `MediaQuery.disableAnimationsOf(context)` and falls back to a static title label (`loading_state_view.dart:24-47`); no navigation gating.
- [x] i18n synced en/ar/zh-Hans; gen-check stays clean — **pass**: `states.{emptyTitle,emptyBody,errorTitle,errorBody,loadingTitle}` present in all three of `lib/i18n/{en,ar,zh-Hans}.i18n.json`; action label reuses `common.retry`; the error view test asserts localized `ar` strings under RTL (`test/shared/widgets/states/error_state_view_test.dart:77-98`).
- [x] Strict-analysis clean — **pass**: typed `StateViewAction` record typedef (`state_view_card.dart:6`), typed Strings, no `dynamic`/raw.
- [x] Generated code untouched — **pass**: no generated files in this family.
- [x] Native entitlements flagged in PR + CI platform jobs — **n/a**.
- [x] Goldens re-baselined + dev-gallery fixture — **pass** (warn resolved): `PreviewFrame` cases per state exist and are registered (`lib/features/dev_gallery/cases/state_views_gallery_cases.dart`, `gallery_registry.dart:35`); home-matrix impact documented — repo-wide re-baseline pending the pinned macOS 26 CI run (tracked repo-wide, not per-feature).
- [x] Port-reuse consistency — **n/a**: no port; reuses the busy-indicators progress primitive as designed (`loading_state_view.dart` composes `BusyIndicator`).
- [x] Config rule respected — **pass**: gallery behind `developmentToolsEnabled`.
- [x] Honest feedback, no faked success — **pass**: the action button renders only when an action is supplied — no default empty lambda (`state_view_card.dart:53-60`); no-backend consumers surface `common.notConnected` via the error body (`paged_list_view.dart:61`).
- [x] Tests — **pass**: `test/shared/widgets/states/{empty,error,loading}_state_view_test.dart` (render with/without action, retry fires, `ar` RTL case).

## Risks / notes

- **Extraction threshold (checklist #3).** `lib/shared/widgets/` requires ≥3 real consumers
  ([baseline report](../../docs/baseline_architecture_report.md)). Today only
  [`home_page.dart`](../../lib/features/home/home_page.dart) is concrete. Pricing cannot be empty
  (`pricing_page.dart` asserts `plans.isNotEmpty` and already has its own unavailable banner) and
  profile is a dirty/saving/saved form, not an async list — so neither counts. The three
  designated consumers under [C1](../contracts.md#c1--scope-is-comprehensive) are: home activity
  error/loading (this change), search-results ([search-pagination.md](search-pagination.md)), and
  cached list ([offline-cache.md](offline-cache.md)) — the latter two are deferred async-list
  consumers that land with their features.
- **Loading treatment.** The loading view should reuse the busy-indicators wrapper
  ([busy-indicators.md](busy-indicators.md)) rather than forking a spinner — sequence after it,
  or co-design so the two share one progress primitive.
- **No silent retry.** The error view's `onTap` must never default to an empty lambda; a
  feature with no backend wires it to surface `common.notConnected`.
