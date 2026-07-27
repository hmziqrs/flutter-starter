# In-app feedback

> **Tier:** P3 · **Domain:** engagement · **Backend:** test-server · **Status:** planned · **Depends on:** settings, platform-capabilities

## Summary

Free-form feedback (text, optional screenshot) submitted from anywhere via a shake gesture or a
menu entry. Low-friction qualitative signal and bug reports that catch issues before they become
negative store reviews. Ships behind a Noop transport so the starter runs green with zero
backend; the optional real impl is an override.

## Contract

- **Ports / value objects:** `FeedbackTransport` abstract interface
  (`submit(FeedbackSubmission) -> Future<FeedbackResult>`) mirroring
  [`SettingsStore`](../../../lib/features/settings/settings_store.dart) (exceptions wrapped,
  never silent). Typed trio copied from
  [`lib/features/auth/`](../../../lib/features/auth/): `FeedbackFormValue`
  (`message`, `email?`, `includeScreenshot`, `appMetadata`), `FeedbackPresentationState`
  (`idle | drafting | validating | submitting | success | failed` enum + named constructors),
  `FeedbackSubmission` (the transport payload), `FeedbackResult` (`accepted` with id, or
  `rejected`/`unavailable`).
- **Providers:** handwritten Riverpod — `feedbackTransportProvider` (overridden at the
  [`ProviderScope`](../../../lib/app/app.dart), Noop by default), `feedbackControllerProvider`
  (`Notifier` owning the draft + presentation state, persisting the draft to `SettingsStore`).
  No `riverpod_generator`.
- **Routes:** no dedicated `AppRoutes` constant for the surface — the sheet is modal
  (`FSheet`/`FDialog`) opened imperatively from a menu entry + the shake listener. If a
  full-screen variant is wanted later, add it as a top-level GoRoute (full-screen flows live
  top-level), wrapped in
  [`EscapeDismissibleOverlay`](../../../lib/shared/widgets/escape_dismissible_overlay.dart).
- **Files:** feature-first —
  - `lib/features/feedback/feedback_form_value.dart`
  - `lib/features/feedback/feedback_presentation_state.dart`
  - `lib/features/feedback/feedback_transport.dart` (port)
  - `lib/features/feedback/noop_feedback_transport.dart` (production default)
  - `lib/features/feedback/feedback_controller.dart`
  - `lib/features/feedback/feedback_sheet.dart`
  - `lib/features/feedback/shake_feedback_trigger.dart` (see Audit §3 — keep feature-local)
  - `test/features/feedback/feedback_controller_test.dart`
  - **root-composition edits (flagged):** [`lib/app/dependencies.dart`](../../../lib/app/dependencies.dart)
    (`AppDependencies.production` constructs `NoopFeedbackTransport`),
    [`lib/app/app.dart`](../../../lib/app/app.dart) (mount the shake listener in `_AppViewState`
    gated by the opt-in setting + `PlatformCapabilities`; `ProviderScope` override).
- **Dependencies:** `sensors_plus` (shake detection). The HTTP client for the real impl reuses
  the shared `dart:io`/`http` stack already transitively available — do not add a second HTTP
  package.

## Backend & test surface

Per [C2](../contracts.md#c2--backend-stance-port--noop-production-default--optional-real-impl--test-server):
the starter runs green with **zero backend**, surfaces `common.notConnected` honestly, never
fakes success.

- **Noop production default** — `NoopFeedbackTransport.submit` returns `FeedbackResult.unavailable`
  and the controller surfaces `context.t.common.notConnected` with the `failed` presentation
  state; it never returns `accepted`. Constructed in `AppDependencies.production`.
- **Optional real override** — `HttpFeedbackTransport` posts to the backend; a consumer
  constructs it (with endpoint + auth headers) and overrides `feedbackTransportProvider`. Never
  constructed by default.
- **Test-server contract** — [`tools/test_server/`](../contracts.md#c3--minimal-in-repo-test-server-tools-test_server)
  implements the feedback ingest route group:
  - `POST /v1/feedback` `{message, email?, screenshotMime?, screenshotBase64?, appMetadata:{version,platform,locale}}`
    -> `201 {id}` or `422` (validation) or `413` (payload too large)
  - `GET /v1/feedback/{id}/status` -> `{state: queued|triaged}` (optional, for a future status view)
  Integration tests start the server on a random port and point `HttpFeedbackTransport` at it;
  the screenshot path is covered with a tiny in-repo fixture.
- **Fakes** — `InMemoryFeedbackTransport` (configurable `result` + recorded submissions list)
  for controller/widget tests, mirroring
  [`InMemorySettingsStore`](../../../lib/features/settings/in_memory_settings_store.dart)
  toggle style. No Mocktail.

## Tests

- **Unit/widget:** `feedback_controller_test.dart` — draft persists across controller rebuild;
  validation rejects empty message; Noop surfaces `failed` + `notConnected` and never `success`;
  `InMemoryFeedbackTransport` returning `accepted` flips state to `success` and clears the draft.
  Widget test: `FSheet` opens/closes, Escape dismisses without submitting, screenshot toggle
  reachable, motion guard renders the static fallback.
- **Integration:** reuse `createApplication`; start `tools/test_server` on a random port and
  override `feedbackTransportProvider` with `HttpFeedbackTransport` pointed at it. Submit a real
  payload with `pumpAppFrames` (8 bounded frames), **never** `pumpAndSettle`; assert the server
  received the POST and the UI reached `success`.
- **Golden impact:** minimal — the sheet is modal and transient; add one `PreviewFrame` case for
  the `drafting` + `failed` states if the sheet is visually distinctive, otherwise none.
- **Dev-gallery fixture:** `TypedGalleryCase` behind `developmentToolsEnabled` previewing
  `drafting`/`submitting`/`failed` states via
  [`PreviewFrame`](../../../lib/features/dev_gallery/preview_frame.dart).

## i18n

- **Keys:** `feedback.title`, `feedback.messageLabel`, `feedback.messageHint`,
  `feedback.includeScreenshot`, `feedback.emailOptional`, `feedback.submit`, `feedback.cancel`,
  `feedback.successTitle`, `feedback.successBody`, `feedback.failedTitle` (maps to the honest
  `common.notConnected` path), `feedback.shakeEnabled` (settings label). Sync `en` + `ar` +
  `zh-Hans`, then `just gen`.
- **RTL note:** the sheet is `Directionality`-aware via ForUI; the screenshot toggle + email
  field are direction-neutral. Arabic string lengths may wrap the title — verify in the gallery.

## Audit

- [x] **pass** — No-backend honored as a port: `NoopFeedbackTransport` is the prod default,
  returns `unavailable`, surfaces `notConnected`, never returns `accepted`.
- [x] **pass** — Feature-first ownership: form trio + transport + controller under
  `lib/features/feedback/`.
- [ ] **warn** — Shared extraction threshold: research proposed
  `lib/shared/widgets/shake_detector.dart`, but shake has a **single** consumer (feedback).
  Keep it feature-local at `lib/features/feedback/shake_feedback_trigger.dart` until a second
  caller appears. This doc pins it feature-local.
- [x] **pass** — Motion guarded: sheet open/close from
  [`AppMotion`](../../../lib/shared/motion/app_motion.dart), guarded by
  `MediaQuery.disableAnimationsOf(context)`; the non-animated branch still calls
  `Navigator.maybePop`/submits.
- [x] **pass** — Tests use `pumpAppFrames`, never `pumpAndSettle`.
- [x] **pass** — i18n synced en/ar/zh-Hans; `gen-check` stays clean.
- [x] **pass** — Strict-analysis clean: typed `FeedbackPresentationState` enum with exhaustive
  switch; no `dynamic`.
- [x] **n/a-pass** — Native entitlements: none (no keychain/biometric/push). `sensors_plus`
  needs no entitlement.
- [x] **n/a-pass** — Golden re-baseline: none required (modal/transient); add a gallery fixture
  only if visually distinctive.

## Risks / notes

- **Shake is platform-gated.** Build the detector on `sensors_plus` and gate it behind
  [`PlatformCapabilities`](../../../lib/infrastructure/platform/platform_capabilities.dart)
  (`isWeb`/desktop accelerometer absent) **plus** a `SettingsStore` opt-in
  (`feedback.shakeEnabled`, default off — shake-to-feedback is divisive). Do not register the
  listener unless both are true; unlisten on dispose.
- **Screenshot capture needs a real backend to be useful.** Without a backend the screenshot
  toggle is inert (the Noop path returns `unavailable`); never fake "screenshot attached
  successfully" in the UI.
- **Draft persistence scope.** Draft persists in `SettingsStore` under `feedback.draft` so a
  user does not lose a half-written report across backgrounding; clear it only on confirmed
  `accepted` (not on `failed` — a failed submit should retain the text for retry).
- **PII in metadata.** `appMetadata` (version/platform/locale) is fine to send; never auto-attach
  account identifiers. Route any log line about a submission through
  [`AppLogger`](../../../lib/infrastructure/logging/app_logger.dart) with structured context and
  let the [`LogRedactor`](../../../lib/infrastructure/logging/log_redactor.dart) scrub the message
  body — never log the message verbatim in plaintext.
- **Sequencing.** P3 — depends only on [`settings`](../README.md) and
  [`PlatformCapabilities`](../../../lib/infrastructure/platform/platform_capabilities.dart)
  (already present). Ships after the engagement ports
  ([`analytics`](analytics.md)/[`feature-flags`](feature-flags.md)) so feedback metadata can
  optionally carry experiment assignments, but does not block on them.
- **No port-reuse relationship.** Feedback has its own transport; do not fold it into
  [`analytics`](analytics.md) event ingest — feedback is a distinct, human-triaged channel.
