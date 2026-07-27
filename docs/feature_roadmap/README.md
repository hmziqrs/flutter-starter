# Feature roadmap

A tracked, auditable plan for growing `starter` from its compact baseline into a
fully-featured cross-platform product. This directory is the **intake + tracking** layer;
[`plans/feature_contracts.md`](../../plans/feature_contracts.md) remains the freeze layer for
public APIs once a feature is implemented.

- **Decisions:** [decisions.md](decisions.md) — scope, backend stance, the minimal test server,
  port reuse, redirect pattern.
- **Audit checklist:** [audit_checklist.md](audit_checklist.md) — the guardrails every feature
  must pass.
- **Audit findings:** [audit_findings.md](audit_findings.md) — the adversarial pass results and
  fixes applied.
- **Feature specs:** [features/](features/) — one doc per feature.

## How to use it

- **Track:** each feature doc has a `Status:` header (`planned` → `in-progress` → `done` /
  `blocked`). The status table below mirrors it; update both together.
- **Audit:** before marking a feature `done`, re-run the [checklist](audit_checklist.md) and
  resolve every non-`n/a` `warn`. Log results in [audit_findings.md](audit_findings.md).
- **Scope a change:** amend [decisions.md](decisions.md) first, then the affected feature docs,
  then this table.

## Scope

Comprehensive (~35 features) per [D1](decisions.md#d1--scope-is-comprehensive). Backend-dependent
features are real but optional — port + Noop production default + a [`tools/test_server/`](decisions.md#d3--minimal-in-repo-test-server-tools-test_server)
contract — so the starter runs green with zero backend.

## Status table

Legend — Tier: P0 foundation · P1 expected · P2 polish · P3 opt-in. Backend: `none` (backend-free)
or `server` (port + Noop default + test server per [D2](decisions.md#d2--backend-stance-port--noop-production-default--optional-real-impl--test-server)).

| Feature | Tier | Domain | Backend | Status | Doc |
|---|---|---|---|---|---|
| App lifecycle observer | P0 | startup | none | planned | [lifecycle-observer](features/lifecycle-observer.md) |
| SecureStore port | P0 | security | none | planned | [secure-store](features/secure-store.md) |
| Crash & error reporting | P0 | infra | server | planned | [crash-reporting](features/crash-reporting.md) |
| Real-time connectivity indicator | P1 | startup | none | planned | [connectivity](features/connectivity.md) |
| First-launch onboarding gate | P1 | startup | none | planned | [onboarding-gate](features/onboarding-gate.md) |
| Native splash | P1 | startup | none | planned | [native-splash](features/native-splash.md) |
| Reusable state views | P1 | ux | none | planned | [state-views](features/state-views.md) |
| Progress / busy indicators | P1 | ux | none | planned | [busy-indicators](features/busy-indicators.md) |
| Reusable form scaffolding | P1 | ux | none | planned | [form-scaffolding](features/form-scaffolding.md) |
| Biometric unlock | P1 | security | none | planned | [biometric](features/biometric.md) |
| Session / token management | P1 | security | server | planned | [session](features/session.md) |
| Log PII redaction | P1 | security | none | planned | [log-redaction](features/log-redaction.md) |
| Product analytics | P1 | infra | server | planned | [analytics](features/analytics.md) |
| Feature flags / remote-config | P1 | infra | server | planned | [feature-flags](features/feature-flags.md) |
| In-app announcements | P1 | engagement | none | planned | [announcements](features/announcements.md) |
| Animated in-app splash | P2 | startup | none | planned | [in-app-splash](features/in-app-splash.md) |
| Update blocker (hard + soft) | P2 | startup | server | planned | [update-blocker](features/update-blocker.md) |
| Skeleton loading | P2 | ux | none | planned | [skeleton](features/skeleton.md) |
| Pull-to-refresh + virtualization | P2 | ux | none | planned | [pull-refresh](features/pull-refresh.md) |
| MFA / OTP completion | P2 | security | server | planned | [mfa-otp](features/mfa-otp.md) |
| Auth rate-limit / lockout | P2 | security | none | planned | [auth-ratelimit](features/auth-ratelimit.md) |
| Push notifications | P2 | engagement | server | planned | [push-notifications](features/push-notifications.md) |
| System UI / edge-to-edge | P2 | platform | none | planned | [system-ui](features/system-ui.md) |
| Haptic feedback | P2 | platform | none | planned | [haptics](features/haptics.md) |
| Accessibility presets | P2 | platform | none | planned | [a11y-presets](features/a11y-presets.md) |
| Deep linking | P2 | platform | none | planned | [deep-linking](features/deep-linking.md) |
| Runtime permissions + media picker | P2 | platform | none | planned | [permissions-media](features/permissions-media.md) |
| License / share / in-app updates | P2 | platform | none | planned | [license-share-update](features/license-share-update.md) |
| State restoration + last-screen | P3 | startup | none | planned | [state-restoration](features/state-restoration.md) |
| In-app search + pagination | P3 | ux | none | planned | [search-pagination](features/search-pagination.md) |
| Toast + confirmation wrappers | P3 | ux | none | planned | [toast-dialogs](features/toast-dialogs.md) |
| PIN / passcode + auto-lock | P3 | security | none | planned | [pin-autolock](features/pin-autolock.md) |
| In-app feedback / shake | P3 | engagement | server | planned | [feedback](features/feedback.md) |
| A/B experiment hooks | P3 | engagement | server | planned | [ab-experiments](features/ab-experiments.md) |
| Offline-first caching layer | P3 | infra | server | planned | [offline-cache](features/offline-cache.md) |

## Sequencing

Build order respects dependencies; each backend feature delivers port + Noop default +
test-server contract together, with the real impl as the final optional step.

1. **P0 foundation** — [`lifecycle-observer`](features/lifecycle-observer.md),
   [`secure-store`](features/secure-store.md), [`crash-reporting`](features/crash-reporting.md).
   No UI, no golden impact. Stand up [`tools/test_server/`](decisions.md#d3--minimal-in-repo-test-server-tools-test_server)
   here so every later `server` feature has a target.
2. **The headline three + their ports** — [`connectivity`](features/connectivity.md)
   (`ConnectivityService`), [`update-blocker`](features/update-blocker.md) (`VersionGateStore`
   + the first [`go_router` redirect](decisions.md#d5--one-go_router-redirect-pattern-reused)),
   [`native-splash`](features/native-splash.md) + [`in-app-splash`](features/in-app-splash.md)
   (`AppStartupResult` from `createApplication`).
3. **Pure-UI P1** — [`onboarding-gate`](features/onboarding-gate.md),
   [`state-views`](features/state-views.md), [`busy-indicators`](features/busy-indicators.md),
   [`log-redaction`](features/log-redaction.md). Forces the first golden re-baseline.
4. **One port per pattern** — [`session`](features/session.md) (reuses the redirect),
   [`analytics`](features/analytics.md) (`GoRouter` observer),
   [`feature-flags`](features/feature-flags.md) (remote-config family),
   [`biometric`](features/biometric.md).
5. **P2 polish** — engagement + platform bundles; depends on P0/P1 ports where marked.
6. **P3 + the rest** — opt-in and lower-leverage features.

## Cross-cutting port map

| Port | Owner | Readers |
|---|---|---|
| `ConnectivityService` | `lib/infrastructure/connectivity/` | connectivity banner, offline-cache |
| Remote-config family | feature-owned typed ports (`lib/features/{feature_flags,force_update,experiments}/`) + shared adapter `lib/infrastructure/remote_config/` | feature-flags (`FeatureFlagsSource`), update-blocker (`VersionGateStore`), ab-experiments (`ExperimentSource`) |
| `SecureStore` | `lib/infrastructure/secure_storage/` | session (refresh token), pin-autolock, biometric, analytics opt-in |
| `CrashReporter` | `lib/infrastructure/error_reporting/` | bootstrap `_installErrorHandlers` |
| `AnalyticsClient` | `lib/infrastructure/analytics/` | `GoRouter` `observers:` |
| `go_router` redirect helper | `lib/app/routing/app_router.dart` | update-blocker, onboarding-gate, session, biometric, pin-autolock |
