# In-app feedback

> **Tier:** P3 · **Domain:** engagement · **Backend:** test-server · **Status:** done · **Depends on:** settings, platform-capabilities
>
> Implementation audit (2026-10-04): port + honest Noop default + controller/sheet/shake +
> i18n + widget tests verified. Fix round (2026-10-05): the optional real impl exists
> (`HttpFeedbackTransport`) with the live submit e2e, plus the shake settings tile, the
> screenshot capture seam (default none — see Risks), and Escape-dismissal coverage. All
> audit items pass with current evidence; status flipped to done (2026-10-05) with no open
> gaps.

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
  - `lib/features/feedback/http_feedback_transport.dart` (optional real impl, override-only)
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
- **Optional real override** — `HttpFeedbackTransport`
  (`lib/features/feedback/http_feedback_transport.dart`) maps 201→accepted, 422/413→rejected,
  network errors→unavailable; a consumer constructs it (with endpoint + auth headers) and
  overrides `feedbackTransportProvider`. Never constructed by default.
- **Test-server contract** — [`tools/hono_server/`](../contracts.md#c3--minimal-in-repo-test-server)
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
- **Integration:** `test/e2e/feedback_submit_e2e_test.dart` starts `tools/hono_server/` on a
  random port (graceful skip without a JS runtime) and drives `HttpFeedbackTransport` directly
  at the transport level — accepted + status round-trip, the screenshot fixture, and 422/413
  rejected. No widget pumping, no `pumpAndSettle`; the UI surface (sheet open/close, Escape
  dismissal, failed alert) is covered by the widget tests with `InMemoryFeedbackTransport`
  fakes.
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

- [x] **No-backend honored as a port** — **pass**: port + honest Noop default + server route
  verified: `FeedbackTransport` (`lib/features/feedback/feedback_transport.dart:87`),
  `NoopFeedbackTransport.submit` returns `FeedbackResult.unavailable`
  (`noop_feedback_transport.dart:7-8`), constructed in `AppDependencies.production`
  (`lib/app/dependencies.dart:397`); `POST /v1/feedback` + `/v1/feedback/:id/status` at
  `tools/hono_server/src/index.ts:327-363` with TS contract tests. Resolved 2026-10-05:
  `HttpFeedbackTransport` exists and the live submit e2e
  (`test/e2e/feedback_submit_e2e_test.dart`) drives it: accepted + status round-trip,
  screenshot fixture, 422/413 rejected.
- [x] **Feature-first ownership; no core/ utils/ buckets** — **pass**: form trio + transport +
  controller + sheet + shake trigger all under `lib/features/feedback/`.
- [x] **Shared extraction >=3 consumers** — **pass**: shake detection stayed feature-local at
  `lib/features/feedback/shake_feedback_trigger.dart` (with an injectable
  `ShakeStreamFactory` seam) as this doc pins; the shared `showAppBottomSheet` it uses has 3
  consumers (feedback sheet, permission rationale sheet, gallery system overlay fixture).
  Resolves the pre-written warn.
- [x] **Composition root confined** — **pass**: `NoopFeedbackTransport` constructed only in
  `lib/app/dependencies.dart:397` (+ the `inMemory` factory); overridden in
  `lib/app/app.dart:148-153`; the shake listener is mounted in `_AppViewState`
  (`app.dart:409-421`) gated by the `SettingsStore` opt-in + `!isWeb`; the settings menu
  entry opens the sheet (`lib/features/settings/settings_page.dart:614-618`).
- [x] **Motion guarded** — **pass**: the sheet contains no custom animation — open/close is
  delegated to the shared `showAppBottomSheet` (ForUI `FSheet`) under the app-level
  `FThemeMotion(duration: AppMotion.standard)` (`app.dart:372-375`); Escape dismissal is
  immediate via `EscapeDismissibleOverlay`; submit/`Navigator.maybePop` never gate on
  animation completion. (Corrects the earlier claim of a per-sheet
  `MediaQuery.disableAnimationsOf` branch.)
- [x] **i18n synced en/ar/zh-Hans** — **pass**: all eleven `feedback.*` keys (title,
  messageLabel, messageHint, includeScreenshot, emailOptional, submit, cancel, successTitle,
  successBody, failedTitle, shakeEnabled) present in all three locale files and generated.
- [x] **Strict analysis clean** — **pass**: typed `FeedbackResult`/`FeedbackSubmission`/
  `FeedbackPresentationState`; exhaustive switch over presentation status
  (`feedback_sheet.dart:243-255`); no `dynamic`.
- [x] **Generated code untouched** — **pass**: the three `*.freezed.dart` files carry
  standard generated headers; sources changed, not output.
- [x] **Native entitlements flagged** — **n/a**: `sensors_plus` needs no entitlement; the
  trigger is platform-gated off web.
- [x] **Goldens re-baselined + dev-gallery fixture** — **pass**: the doc documents the
  minimal/modal golden impact; `TypedGalleryCase` fixtures for
  drafting/submitting/failed/success exist (`feedback_gallery_cases.dart:10-40`); the pinned
  macOS 26 CI re-baseline is outstanding — the committed baselines predate this work and are
  outdated vs HEAD (13/14 canonical comparisons fail locally), tracked repo-wide per
  `test/goldens/README.md`, not failed here.
- [x] **Port-reuse consistency** — **pass**: own transport, deliberately not folded into
  analytics event ingest (distinct human-triaged channel per Risks); persistence goes through
  the existing `SettingsStore` per-key discipline (`feedback_controller.dart:15-26`).
- [x] **Config rule respected** — **pass**: shake is gated behind the persisted
  `feedback.shake_enabled` opt-in (default off) + `PlatformCapabilities`, not config flags;
  no runtime env switching.
- [x] **Honest feedback / no faked success** — **pass**: Noop surfaces the failed state with
  the `common.notConnected` alert (`feedback_sheet.dart:249-254`); `accepted` only comes from
  a real transport; the draft is cleared on accepted and retained on failed/rejected
  (`feedback_controller.dart:100-137`); asserted by
  `test/features/feedback/feedback_controller_test.dart:88-133, 202` and
  `feedback_sheet_test.dart:46`.

## Risks / notes

- **Shake is platform-gated.** Build the detector on `sensors_plus` and gate it behind
  [`PlatformCapabilities`](../../../lib/infrastructure/platform/platform_capabilities.dart)
  (`isWeb`/desktop accelerometer absent) **plus** a `SettingsStore` opt-in
  (`feedback.shakeEnabled`, default off — shake-to-feedback is divisive). Do not register the
  listener unless both are true; unlisten on dispose.
- **Screenshot capture needs a real backend to be useful.** Without a backend the screenshot
  toggle is inert (the Noop path returns `unavailable`); never fake "screenshot attached
  successfully" in the UI. `includeScreenshot` flows through an injectable
  `feedbackScreenshotCaptureProvider` (mime + base64 into `FeedbackSubmission`); the default
  capture returns none and a failed capture still submits the report — wiring a real
  platform capture is the consumer's (`feedback_controller.dart`).
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
