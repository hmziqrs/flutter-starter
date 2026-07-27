# Feature audit checklist

The guardrails every feature doc — and every feature implementation — must satisfy. The
[audit pass](audit_findings.md) scores each feature against this list; implementers re-run it
before marking a feature `done` in the [README](README.md) status table.

Each item: verify the condition, then mark the feature's in-doc checklist `pass` / `warn` /
`n/a` with a one-line reason. A feature is not `done` while any non-`n/a` item is `warn` or
unverified.

## 1. No-backend honored as a port

Backend-dependent features ship **all four** parts of [D2](decisions.md#d2--backend-stance-port--noop-production-default--optional-real-impl--test-server):
port, Noop/InMemory production default (runs green, surfaces `common.notConnected`, never fakes
success), optional real override, and a `tools/test_server/` contract. Verify no widget calls a
plugin directly — every side effect goes through a port. Verify the Noop default does **not**
return success for an action that has no backend.

## 2. Feature-first ownership

Pages and typed `*_view_data` (+ `*_form_value` / `*_presentation_state` for forms) live under
`lib/features/<feature>/`. No `core/`, `utils/`, base-repository, use-case, or service-locator
layers. Cross-feature primitives go under `lib/shared/` only when a concern genuinely repeats.

## 3. Shared extraction threshold

Anything under `lib/shared/widgets/` or `lib/shared/forms/` needs **≥3 consumers** — concrete
today, or **designated** under [D1](decisions.md#d1--scope-is-comprehensive): the feature doc
lists the ≥3 intended consumer features as deferred consumers and re-audits when they land
(demote to feature-local if they never materialize). This relaxes the baseline's strict
"current callers only" rule ([baseline report](../baseline_architecture_report.md)) for the
foundational UX primitives the comprehensive roadmap deliberately introduces. Pure-Dart
primitives under `lib/shared/state/` (e.g. `PagedStateNotifier`) need only **≥1 consumer + a
documented reuse intent** — the ≥3 bar is for widget/form extraction, not state helpers. Verify
proposed shared helpers meet the bar (concrete or designated); flag premature extraction with
no designated consumers.

## 4. Composition root confined

Providers wired only via `AppDependencies` + `ProviderScope` overrides in
[`lib/app/app.dart`](../../lib/app/app.dart). Concrete adapters constructed only in
[`lib/app/dependencies.dart`](../../lib/app/dependencies.dart),
[`lib/app/routing/app_router.dart`](../../lib/app/routing/app_router.dart), or
[`lib/bootstrap.dart`](../../lib/bootstrap.dart). No globals, no singletons, no plugin init
outside these three files (plus `main.dart`'s zone guard).

## 5. Motion guarded

Custom animations source durations/curves from [`AppMotion`](../../lib/shared/motion/app_motion.dart)
and guard with `MediaQuery.disableAnimationsOf(context)` **plus** a non-animated fallback that
still completes the action (e.g. `jumpToPage`/`goNamed`). Critical for splash, connectivity
sonar, banner enter/exit, pull-refresh, skeleton shimmer. Navigation must **never** gate on
animation completion — tests use [`pumpAppFrames`](../../integration_test/integration_test_support.dart)
(8 bounded frames), never `pumpAndSettle`.

## 6. i18n synced

All user-facing copy via `context.t`. New keys added to `en` + `ar` (RTL) + `zh-Hans`
**together**, then `just gen`; `just gen-check` stays clean. Verify RTL for any
direction-sensitive UI (banners, toasts, progress, chevrons). No hardcoded strings.

## 7. Strict analysis clean

Typed value objects, exhaustive `switch`, no `dynamic`/raw types. Handwritten Riverpod only —
**no** `riverpod_generator` / provider codegen introduced. `flutter analyze --fatal-infos`
passes (very_good_analysis + strict-casts/inference/raw-types + riverpod_lint).

## 8. Generated code untouched

Never hand-edit slang `*.g.dart` or ForUI `colors`/`typography`/`style`/`icons`/
`generated_forui_theme`. Change JSON/CLI sources and regenerate (`just gen` / `forui_cli`).
Accent colors via [`ForuiThemeFactory._accentColors`](../../lib/shared/theme/forui_theme_factory.dart).

## 9. Native entitlements flagged

Secure storage (Keychain/Keystore), biometric, deep links (associated-domains / `autoVerify` +
`assetlinks.json`), and push require per-platform native config **outside** `lib/`. The feature
doc's Risks section must call these out, and PRs + the CI platform jobs must cover them.

## 10. Goldens re-baselined

Visual features note golden re-baseline on the **pinned macOS runner**
([`test/goldens/README.md`](../../test/goldens/README.md); baselines are currently empty — first
run needs `--update-goldens`) **and** add a `dev_gallery` `PreviewFrame` fixture so the state is
deterministically previewable. Note which matrix cases change.

## 11. Port-reuse consistency

Confirm shared ports are shared, not duplicated: one `ConnectivityService` (banner + cache);
one remote-config family (flags + `VersionGateStore` + experiments); one `SecureStore` (all
secrets); crash into `_installErrorHandlers`; analytics into `GoRouter` `observers:`. Flag any
feature proposing a parallel port for a concern that already has one.

## 12. Config rule respected

No runtime environment switching (incompatible with compile-time
[`AppConfig`](../../lib/app/config/app_config.dart)). Behavior gated through
`verboseLoggingEnabled` / `developmentToolsEnabled`, never raw `enable*` flags. Dev-only
surfaces behind `if (config.developmentToolsEnabled)` at `/dev/*`.

## 13. Honest feedback, no faked success

Actions without a backend surface `common.notConnected` / `globalError` / `*Unavailable` via
the shared dialog helper and **never** claim success. No Mocktail fakes of backend success in
production code paths (in-memory fakes are for tests only and must surface the unavailable
state where the contract demands it).
