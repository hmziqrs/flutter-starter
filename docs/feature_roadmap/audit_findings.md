# Feature roadmap — audit findings

The adversarial pass over every spec in [`features/`](features/) against the
[audit checklist](audit_checklist.md) + the locked [decisions](decisions.md). Each feature doc already
carries its own inline `Audit` block; this file is the independent verifier pass — it re-checks those
self-audits, logs every edit applied during the pass, and records the judgment calls left to the
implementer.

**Totals (at audit):** 35 features — **26 pass · 5 fixed · 4 warn · 0 fail.**
**After post-audit resolutions:** **31 pass · 4 designated (rule-compliant) · 0 warn · 0 fail** —
see [Resolutions](#resolutions-post-audit).

The spec set is unusually disciplined: every backend feature ships the full D2 four-part contract
(port + Noop/InMemory default + optional override + `tools/test_server/` route), no widget calls a
plugin directly, no `core/`/`utils/` buckets are proposed, and no generated file is hand-edited. The
fixes below are narrow consistency/defect corrections, not architectural rework. The four `warn` rows
are genuine judgment calls (the shared-extraction ≥3-consumer threshold vs. [D1](decisions.md#d1--scope-is-comprehensive))
that the docs already flag honestly — they are left to the implementer, not auto-fixed.

## Summary table

| Feature | Verdict | One-line note |
|---|:---:|---|
| [lifecycle-observer](features/lifecycle-observer.md) | pass | Backend-free foundation; typed `AppLifecyclePhase`, exhaustive switch, no UI. |
| [secure-store](features/secure-store.md) | **fixed** | Corrected `encruptedSharedPreferences` typo (→ `encryptedSharedPreferences`, ×2). |
| [crash-reporting](features/crash-reporting.md) | pass | Noop + test-server `/v1/crashes` + existing `_installErrorHandlers` seam; honest. |
| [connectivity](features/connectivity.md) | pass | Owns the shared `ConnectivityService`; banner mounted in `app.dart` builder; motion guarded. |
| [onboarding-gate](features/onboarding-gate.md) | pass | Reuses `SettingsStore`; candidate to establish the D5 redirect; no new port. |
| [native-splash](features/native-splash.md) | pass | Pure codegen, correctly bypasses `lib/`; brand assets tracked as release blocker. |
| [state-views](features/state-views.md) | **warn** | Shared `lib/shared/widgets/states/` with only 1 concrete consumer today (D1 vs checklist #3). |
| [busy-indicators](features/busy-indicators.md) | pass | ≥3 real consumers (auth `isSubmitting` ×5 + profile); ForUI primitive adoption. |
| [form-scaffolding](features/form-scaffolding.md) | pass | 5 existing auth consumers; byte-for-byte move behind a re-export facade. |
| [biometric](features/biometric.md) | pass | Port + Noop-unavailable default; entitlements flagged; third D5 redirect reader. |
| [session](features/session.md) | **fixed** | Corrected "establishes the first redirect" → reuses D5 helper (per sequencing + D5). |
| [log-redaction](features/log-redaction.md) | pass | Deepens the existing single choke point; conservative PAN pattern + negative test. |
| [analytics](features/analytics.md) | **fixed** | Moved `analyticsOptIn` off `SettingsState` to a SecureStore-backed controller. |
| [feature-flags](features/feature-flags.md) | **fixed** | Reconciled Audit/Files inconsistency on the remote-config port location. |
| [announcements](features/announcements.md) | pass | Backend-free fixtures; banner feature-local (correctly declined `shared/`). |
| [in-app-splash](features/in-app-splash.md) | pass | Motion guard + no-nav-on-animation are load-bearing; reuses `createApplication` init. |
| [update-blocker](features/update-blocker.md) | pass | Full D2 contract; candidate D5 redirect owner; shares remote-config backend. |
| [skeleton](features/skeleton.md) | **warn** | Shared skeleton primitives with no concrete consumer today (D1 vs checklist #3). |
| [pull-refresh](features/pull-refresh.md) | **warn** | Shared refresh/list primitives with only `home` as concrete consumer today. |
| [mfa-otp](features/mfa-otp.md) | pass | Deepens existing OTP screen; port + InMemory + `/otp/*` contract; `FakeAsync` determinism. |
| [auth-ratelimit](features/auth-ratelimit.md) | pass | 3 consumers (login/OTP/PIN); honestly documented as UX-only, not a security control. |
| [push-notifications](features/push-notifications.md) | pass | Noop denies honestly; entitlement-heavy (flagged); test-server covers token path only (D3). |
| [system-ui](features/system-ui.md) | pass | `SystemChrome` config; API-35 `values-v35` flagged; exhaustive `AppAccent` switch. |
| [haptics](features/haptics.md) | pass | Port + disableMotion parity; `hapticsEnabled` correctly on `SettingsState`/`SettingsStore`. |
| [a11y-presets](features/a11y-presets.md) | pass | Extends `SettingsState` correctly; `labeled_control.dart` self-gated behind ≥3 consumers. |
| [deep-linking](features/deep-linking.md) | pass | Host allowlist from compile-time config; associated-domains/autoVerify flagged. |
| [permissions-media](features/permissions-media.md) | pass | Two ports, Noop defaults surface denied/unavailable honestly; rationale sheet ≥4 kinds. |
| [license-share-update](features/license-share-update.md) | pass | Bundle of 3; Noops honest; single update-gate reused (not duplicated). |
| [state-restoration](features/state-restoration.md) | pass | Framework mechanism; last-route defers to redirect chain precedence. |
| [search-pagination](features/search-pagination.md) | **warn** | Shared search/paged primitives with one concrete consumer today; rejects `infinite_scroll_pagination`. |
| [toast-dialogs](features/toast-dialogs.md) | pass | ≥3 consumers (`_showInformationDialog` ×10+); wraps, does not fork, `FToaster`/`FDialog`. |
| [pin-autolock](features/pin-autolock.md) | pass | Salted hash via SecureStore; reuses `AttemptTracker`; 4th D5 redirect reader. |
| [feedback](features/feedback.md) | pass | Noop returns `unavailable`; shake detector correctly kept feature-local. |
| [ab-experiments](features/ab-experiments.md) | pass | Shares remote-config family; deterministic default is honest local assignment (not faked remote). |
| [offline-cache](features/offline-cache.md) | **fixed** | Removed duplicate `connectivityStatusProvider`; now reuses connectivity's. |

## Fixed during audit

Five narrow edits (docs only — no `lib/`, `pubspec.yaml`, or codegen touched):

1. **[features/secure-store.md](features/secure-store.md)** — corrected the misspelling
   `encruptedSharedPreferences` → `encryptedSharedPreferences` in two places (Audit native-entitlements
   bullet + Risks native-config bullet). The Android `encryptedSharedPreferences` Gradle option is the
   real name; the typo would mislead an implementer copying it into `android/` config.
2. **[features/session.md](features/session.md)** — the Summary, Routes, and Risks each claimed session
   *establishes the first* `go_router` redirect / "the D5 redirect pattern". This contradicts
   [D5](decisions.md#d5--one-go_router-redirect-pattern-reused) and the [sequencing](README.md#sequencing),
   which name [update-blocker](features/update-blocker.md) / [onboarding-gate](features/onboarding-gate.md)
   as the redirect-helper owner and list *session* among the "subsequent gates" that **reuse** it. All
   three claims rewritten to "reuses the D5 helper; installs its auth-required predicate into it."
3. **[features/analytics.md](features/analytics.md)** — the doc added `analyticsOptIn` to `SettingsState`
   *while persisting it via `SecureStore``. `SettingsState` fields are 1:1 with `SettingsStore` keys via
   `SettingsRepository` (the settings boundary in [`architecture.md`](../../architecture.md)); a
   `SecureStore`-persisted value must not live on it. Replaced the `SettingsState` edit with a small
   handwritten `analyticsOptInControllerProvider` (`Notifier<bool>`) backed by a thin `SecureStore`
   wrapper, surfaced in the settings page via its own watch. Consistent with
   [D4](decisions.md#d4--port-reuse-do-not-multiply-backends) (opt-in is a SecureStore key).
4. **[features/feature-flags.md](features/feature-flags.md)** — internal inconsistency: the Audit block
   claimed "the remote-config port family under `lib/infrastructure/feature_flags/`" while the Files
   list placed the `FeatureFlagsSource` port under `lib/features/feature_flags/`. Reconciled to match
   the Files (and the two sibling remote-config docs, [update-blocker](features/update-blocker.md) and
   [ab-experiments](features/ab-experiments.md), which place their typed ports with their features per
   the [`SettingsStore`](../../lib/features/settings/settings_store.dart) exemplar); only the optional
   shared real-impl adapter lives under `lib/infrastructure/feature_flags/`.
5. **[features/offline-cache.md](features/offline-cache.md)** — the doc redeclared
   `connectivityStatusProvider` (and proposed `lib/shared/state/connectivity_status_provider.dart`) even
   though [connectivity](features/connectivity.md) already owns that provider. Removed the duplicate
   file + provider declaration; offline-cache now `ref.watch`es connectivity's existing
   `connectivityStatusProvider` (port-reuse, [D4](decisions.md#d4--port-reuse-do-not-multiply-backends)).

## Resolutions (post-audit)

The five open questions below were resolved after the audit pass to make the plan internally
consistent. Each is recorded here for traceability; the referenced docs were updated.

1. **Shared-extraction threshold (#1)** — amended [checklist #3](audit_checklist.md#3--shared-extraction-threshold)
   to accept **designated** consumers under [D1](decisions.md#d1--scope-is-comprehensive) (≥3
   intended consumers listed in the doc, re-audited when they land), and to set a lower bar
   (≥1 + reuse intent) for pure-Dart `lib/shared/state/` primitives. The four `warn` rows
   ([state-views](features/state-views.md), [skeleton](features/skeleton.md),
   [pull-refresh](features/pull-refresh.md), [search-pagination](features/search-pagination.md))
   are now **rule-compliant designated shared buckets**; their inline `warn` is an honest
   pre-resolution snapshot, superseded by this rule. *This is the one stance to sanity-check —
   it relaxes the baseline's "current-callers-only" discipline for comprehensive scope.*
2. **Remote-config test-server endpoint (#2)** — standardized to **one combined**
   `GET /v1/remote-config?deviceId=&platform=&version=` returning
   `{flags, versionPolicy, experiments, revision}` (one round-trip, one cache; `304` on
   unchanged). New [D9](decisions.md#d9--test-server-route-conventions) records the full route
   table with a uniform `/v1/` prefix; [feature-flags](features/feature-flags.md),
   [update-blocker](features/update-blocker.md), and [ab-experiments](features/ab-experiments.md)
   now read their slice from this one endpoint.
3. **Remote-config port location (#3)** — corrected [D4](decisions.md#d4--port-reuse-do-not-multiply-backends)
   and the [README port map](README.md#cross-cutting-port-map): typed ports
   (`FeatureFlagsSource` / `VersionGateStore` / `ExperimentSource`) live **with their features**
   (port-with-feature, matching the [`SettingsStore`](../../lib/features/settings/settings_store.dart)
   exemplar); only the optional shared real-impl adapter lives under
   `lib/infrastructure/remote_config/`.
4. **ab-experiments default (#4)** — confirmed deliberate: its zero-backend default is a
   **real-local** `DeterministicExperimentSource` (stable assignments, never claims a remote
   source), which [D2](decisions.md#d2--backend-stance-port--noop-production-default--optional-real-impl--test-server)
   explicitly permits. No change.
5. **biometric stray reference (#5)** — [biometric](features/biometric.md) Dependencies line
   fixed: dropped the stale `fake_secure_storage_factory`; tests reuse `InMemorySecureStore`
   from [secure-store](features/secure-store.md).

## Open questions / judgment calls (original audit list — all resolved above)

Retained for traceability. All five were resolved in [Resolutions](#resolutions-post-audit)
above; the original audit notes follow.

### 1. Shared-extraction threshold (≥3 consumers) vs. D1 — the four `warn` rows

Checklist [#3](audit_checklist.md#3--shared-extraction-threshold) says anything under
`lib/shared/widgets/` or `lib/shared/forms/` needs **≥3 real consumers**. [D1](decisions.md#d1--scope-is-comprehensive)
says the roadmap deliberately introduces capabilities with no caller yet, gated structurally instead.
Four features propose shared buckets with **fewer than three concrete consumers today**:

- **[state-views](features/state-views.md)** — `lib/shared/widgets/states/`; only `home_page._RecentActivity`
  is concrete. The doc says: migrate pricing + profile empty states in the same change, or accept as
  the designated states bucket under D1.
- **[skeleton](features/skeleton.md)** — `lib/shared/widgets/states/`; no concrete consumer today. Doc
  says adopt on home + pricing + profile load states together, else defer.
- **[pull-refresh](features/pull-refresh.md)** — `lib/shared/widgets/refresh/` + `lib/shared/widgets/lists/`;
  only `home` is concrete. Doc says adopt on pricing/search lists, or document deferred consumers.
- **[search-pagination](features/search-pagination.md)** — `lib/shared/widgets/search/` +
  `lib/shared/state/`; one concrete consumer (the new search route).

**Decide once and apply uniformly:** either (a) enforce checklist #3 strictly — keep each helper
feature-local until ≥3 callers materialize, or (b) amend checklist #3 to bless "designated shared
buckets" under D1 with an explicit "deferred consumers" note. The four docs all self-flag this; pick a
rule so the set is consistent. Note `lib/shared/state/` (offline-cache's `cachedFutureProvider`,
search-pagination's `PagedStateNotifier`) is **not** literally covered by checklist #3 (widgets/forms
only) — decide whether the threshold extends to shared state primitives.

### 2. Remote-config test-server endpoint shape is inconsistent across three docs

The remote-config family is shared ([D4](decisions.md#d4--port-reuse-do-not-multiply-backends)), but the
three readers describe **different** test-server surfaces:

- [feature-flags](features/feature-flags.md): `GET /v1/flags` (flags only).
- [update-blocker](features/update-blocker.md): `GET /version-policy` (version policy only).
- [ab-experiments](features/ab-experiments.md): `GET /remote-config/assignments` returning a **single
  combined** `{experiments, flags, versionPolicy}` payload.

Pick one shape for the shared backend: either (a) one combined remote-config endpoint (ab-experiments'
view — one cacheable response), or (b) three sibling routes under a shared `/remote-config/` or `/v1/`
prefix (feature-flags + update-blocker's view). Right now the contract the test server must implement
is ambiguous. (Also: route prefixes drift — `/v1/auth`, `/v1/flags`, `/v1/events`, `/v1/crashes` vs.
un-prefixed `/otp/*`, `/feedback`, `/cache/{key}`, `/version-policy`, `/remote-config/*`. Standardize.)

### 3. Where does the *shared* remote-config port family physically live?

[D4](decisions.md#d4--port-reuse-do-not-multiply-backends) + the [README](README.md#cross-cutting-port-map)
name `lib/infrastructure/feature_flags/` as the family home; the three feature docs place their typed
ports *with their features* (`lib/features/{feature_flags,force_update,experiments}/`), following the
[`SettingsStore`](../../lib/features/settings/settings_store.dart) exemplar (port-with-feature) rather
than the [`SecureStore`](features/secure-store.md)/[`ConnectivityService`](features/connectivity.md)
sibling pattern (shared port under `lib/infrastructure/`). Both are defensible; the audit pass left the
typed ports with their features (minority deviation from D4's literal text) because (i) the optional
real-impl adapter correctly lives under `lib/infrastructure/feature_flags/` already, and (ii)
D4 itself says "three readers, one optional backend, **three** InMemory defaults" — implying three
distinct typed ports, not one. Confirm the family's canonical home so D4, the README port map, and the
three docs agree.

### 4. `ab-experiments` default is "Deterministic" (real local), not Noop

Unlike the other server features whose default is a Noop surfacing `notConnected`,
[ab-experiments](features/ab-experiments.md) ships a `DeterministicExperimentSource` that produces
**real, stable variant assignments** with no backend. This is deliberate (experiments must let UI
branch meaningfully pre-backend) and honest (it never claims the data came from a remote source). It is
consistent with D2's "Noop/InMemory **or** real-local default" case (cf. `SecureStore`,
`FileCacheStore`). Flagging only so the implementer consciously confirms this is the intended stance for
experiment data specifically — it is the one server feature whose zero-backend default is not an
"unavailable" surface.

### 5. Minor / bundle-discipline nits (self-flagged, no action required)

- [license-share-update](features/license-share-update.md) bundles three concerns behind one doc
  (self-warned "bundle discipline"); each concern's files stay under its owner.
- [biometric](features/biometric.md) Dependencies line references an undefined
  `fake_secure_storage_factory` (likely a stale research artifact); the real test fake is
  `InMemorySecureStore` from [secure-store](features/secure-store.md) — drop the stray reference on
  adoption.
- Several "warn" items on Motion / Strict-analysis / i18n across docs are **reminders the implementer
  must honor** (e.g. biometric/mfa-otp/auth-ratelimit/pin-autolock motion guards; analytics/session/
  feature-flags strict-analysis), not defects. They are correctly left as `warn` until the feature is
  `done`.

## Port-reuse map

Confirms each shared port is built once and read by N features (no parallel ports found). The one
duplicate proposed (`connectivityStatusProvider` in offline-cache) was removed during this pass.

| Shared surface | Owner (builds it) | Readers (consume it) | Notes |
|---|---|---|---|
| `ConnectivityService` | [connectivity](features/connectivity.md) → `lib/infrastructure/connectivity/` | connectivity banner; [offline-cache](features/offline-cache.md) (`cachedFutureProvider`); ab-experiments remote-source offline-degrade | `connectivityStatusProvider` lives with connectivity; offline-cache was re-pointed at it (see Fixed #5). |
| Remote-config backend family | [feature-flags](features/feature-flags.md) → `lib/infrastructure/feature_flags/` (optional real impl) | [feature-flags](features/feature-flags.md) (`FeatureFlagsSource`); [update-blocker](features/update-blocker.md) (`VersionGateStore`); [ab-experiments](features/ab-experiments.md) (`ExperimentSource`) | Three typed ports + three InMemory defaults over **one** optional backend (D4). Test-server endpoint shape still inconsistent — see Open question #2. |
| `SecureStore` | [secure-store](features/secure-store.md) → `lib/infrastructure/secure_storage/` | [session](features/session.md) (refresh token); [pin-autolock](features/pin-autolock.md) (PIN salt+hash); [biometric](features/biometric.md) (enable flag if tamper-resistant); [analytics](features/analytics.md) (opt-in); [mfa-otp](features/mfa-otp.md) (recovery codes, optional TOTP) | Single secrets port; no per-feature secure stores. `analyticsOptIn` moved here off `SettingsState` (see Fixed #3). |
| `CrashReporter` | [crash-reporting](features/crash-reporting.md) → `lib/infrastructure/error_reporting/` | [`_installErrorHandlers`](../../lib/bootstrap.dart) (alongside `AppLogger.error`) | Plugs into the existing bootstrap seam; Noop default. |
| `AnalyticsClient` | [analytics](features/analytics.md) → `lib/infrastructure/analytics/` | `GoRouter` `observers:` (screen views) + a handful of CTA call sites | Plugs into the existing router-observer seam; Noop default. |
| `go_router` redirect helper ([D5](decisions.md#d5--one-go_router-redirect-pattern-reused)) | [update-blocker](features/update-blocker.md) or [onboarding-gate](features/onboarding-gate.md) establishes it | update-blocker → onboarding-gate → [session](features/session.md) → [biometric](features/biometric.md) → [pin-autolock](features/pin-autolock.md) (documented precedence) | One helper, composed predicates. session's "establishes" claim corrected (see Fixed #2). |
| `AttemptTracker` | [auth-ratelimit](features/auth-ratelimit.md) → `lib/features/auth/` | login; [mfa-otp](features/mfa-otp.md) OTP; [pin-autolock](features/pin-autolock.md) | 3 consumers; pure-Dart, feature-local (no `shared/` bucket needed). |
| `AppLinkHandler` | [deep-linking](features/deep-linking.md) → `lib/app/routing/` | [mfa-otp](features/mfa-otp.md) magic-link; [push-notifications](features/push-notifications.md) tap; future referral | Inbound-routing primitive; host allowlist from compile-time config. |
| `SettingsStore` (existing) | settings → `lib/features/settings/` | onboarding-gate, announcements, auth-ratelimit, haptics, a11y-presets, pin-autolock (config only), push-notifications (token/perm), state-restoration (last-route), feedback (draft), ab-experiments (stable id) | Pre-existing port; new features extend `SettingsState` + `persistedKeys` correctly. |

### Re-verification of the twelve guardrails (whole-set view)

1. **No-backend-as-port** — all 10 `server` features ship port + Noop/InMemory default + optional
   override + test-server contract; none fake success; no widget calls a plugin directly. **Pass.**
2. **Feature-first ownership** — no `core/`/`utils/`/base-repository/use-case/service-locator proposed.
   **Pass.**
3. **Shared extraction ≥3** — 4 judgment calls (see Open question #1); otherwise met. **Warn (4).**
4. **Composition root** — all provider wiring via `AppDependencies` + `ProviderScope`; concrete adapters
   only in `dependencies.dart` / `app_router.dart` / `bootstrap.dart`. **Pass.**
5. **Motion guard** — every custom animation (splash, connectivity sonar, banner, skeleton shimmer,
   pull-refresh, OTP countdown, passcode shake) is either guarded or explicitly self-warned for the
   implementer; none gate navigation on animation completion. **Pass.**
6. **i18n** — all user-facing copy via `context.t`; keys synced en+ar+zh-Hans; no hardcoded strings.
   **Pass.**
7. **Strict analysis** — typed value objects, exhaustive switches, handwritten Riverpod only. **Pass.**
8. **Generated code** — no doc proposes hand-editing slang `*.g.dart` or ForUI tokens. **Pass.**
9. **Native entitlements** — every native-dependent feature (secure-store, biometric, push, deep-link,
   permissions-media, system-ui, native-splash, offline-cache macOS container) flags them in Risks.
   **Pass.**
10. **Goldens** — every visual feature notes macOS re-baseline + a `PreviewFrame` fixture; timing-
    sensitive surfaces (auth-ratelimit, pin-autolock dots) deliberately exclude from the matrix.
    **Pass.**
11. **Port-reuse** — one `ConnectivityService`, one remote-config family, one `SecureStore`, crash →
    bootstrap, analytics → router observer; one duplicate removed. **Pass (after fix).**
12. **Config rule** — no runtime env switcher; all gates via `verboseLoggingEnabled` /
    `developmentToolsEnabled`; deep-link host allowlist from compile-time config. **Pass.**
