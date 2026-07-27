# In-app announcements

> **Tier:** P1 · **Domain:** engagement · **Backend:** none · **Status:** planned · **Depends on:** settings

## Summary

Dismissible, dismiss-tracked banners rendered above the shell to broadcast outages, ToS
changes, version notes, or promos without an app update. The standard low-friction channel
for time-sensitive user communication that bypasses store review cycles. Fully backend-free:
the default impl serves static fixtures, and a remote variant would plug through the same
controller later without touching call sites.

## Contract

- **Ports / value objects:** no transport port is required for the default — this is a
  backend-free feature (see [D2](../decisions.md#d2--backend-stance-port--noop-production-default--optional-real-impl--test-server);
  the "Noop is the real default" case). Typed value objects:
  `Announcement` (`id`, `severity` enum `info|warning|critical|success`, `titleKey`/`messageKey`
  i18n keys or inline `LocalizedString`, `actionRoute`?, `dismissible`, `activeFrom`/`activeUntil`
  epochs, `minAppVersion`/`maxAppVersion` for version gating via
  [`AppBuildInfo`](../../../lib/infrastructure/platform/app_build_info.dart)). Dismissed IDs
  persist as a single JSON-encoded list under one
  [`SettingsStore`](../../../lib/features/settings/settings_store.dart) key
  (`announcements.dismissedIds`) — per-key discipline, **no** `clearAll`.
- **Providers:** handwritten Riverpod — `announcementsFixturesProvider` (static list, like
  [`PricingFixtures`](../../../lib/features/pricing/)), `announcementsControllerProvider`
  (`Notifier` exposing `active` filtered by dismissed-set + version + date window + layout).
  Follow the [`SettingsController`](../../../lib/features/settings/settings_controller.dart)
  shape; **no** codegen.
- **Routes:** none of its own. Optional `actionRoute` on an `Announcement` resolves to an
  **existing** named route via `context.goNamed`.
- **Files:** feature-first —
  - `lib/features/announcements/announcement_view_data.dart`
  - `lib/features/announcements/announcement_fixtures.dart`
  - `lib/features/announcements/announcements_controller.dart`
  - `lib/features/announcements/announcement_banner.dart` (see Audit §3 — keep feature-local)
  - `test/features/announcements/announcements_controller_test.dart`
  - **root-composition edits (flagged):** mount the banner **once** above the router child in
    the `MaterialApp.router` `builder:` at
    [`lib/app/app.dart:101`](../../../lib/app/app.dart) (so auth/onboarding top-level routes
    also see it — do **not** mount inside `AppShell` only), reading from
    `announcementsControllerProvider`.
- **Dependencies:** none (Flutter SDK + ForUI only).

## Backend & test surface

**Backend-free** ([D2](../decisions.md#d2--backend-stance-port--noop-production-default--optional-real-impl--test-server),
backend=none case): `AnnouncementFixtures` is a static, compile-time list — the default impl is
real and local, not a Noop. There is no backend to surface `notConnected` against.

If a remote variant is added later, it does **not** get a new surface: introduce an
`AnnouncementsSource` port with an `InMemoryAnnouncementsSource` (serving the fixtures) as the
default and an optional HTTP source as an override at the `ProviderScope`; the controller and
banner stay unchanged. Keep that extraction deferred until a remote source is actually wired —
do not add an empty port now (per the
[baseline report](../../baseline_architecture_report.md): "deferred product capabilities remain
decisions, not empty interfaces").

## Tests

- **Unit/widget:** `announcements_controller_test.dart` — dismissal persists to
  `SettingsStore` under the single JSON key and round-trips; version/date windows filter
  correctly; restoring dismissed-set on cold start hides the banner. Banner widget test:
  enter/exit reachable, action CTA fires `goNamed`, Escape/dismiss button removes the active
  announcement.
- **Integration:** reuse `createApplication`; `pumpAppFrames` (8 bounded frames), **never**
  `pumpAndSettle`. Verify the banner renders above auth/onboarding (top-level routes), not only
  inside the shell.
- **Golden impact:** **yes** — the banner sits in the `MaterialApp.router` builder above every
  route, so it enters the shell matrix. Add a `PreviewFrame` case for each severity and
  re-baseline on the pinned macOS runner ([`test/goldens/README.md`](../../../test/goldens/README.md));
  baselines are currently empty, so the first run needs `--update-goldens`.
- **Dev-gallery fixture:** one `TypedGalleryCase` per severity behind
  `developmentToolsEnabled`, via
  [`PreviewFrame`](../../../lib/features/dev_gallery/preview_frame.dart), registered through
  [`production_gallery_cases.dart`](../../../lib/features/dev_gallery/cases/production_gallery_cases.dart).

## i18n

- **Keys:** `announcements.dismiss`, `announcements.actionLearnMore`, plus per-announcement
  `title`/`message` pairs (or inline `LocalizedString` on the fixture — pick one and stay
  consistent). Sync across `en` + `ar` + `zh-Hans`, then `just gen`.
- **RTL note:** the banner uses `FAlert`/`FBadge` which honor `Directionality`; an action CTA
  on the trailing edge must flip in RTL — verify via the Arabic gallery fixture, no manual
  mirroring.

## Audit

- [x] **n/a-pass** — No-backend honored: backend-free; the default (static fixtures) is real and
  local, not a Noop. No success to fake.
- [x] **pass** — Feature-first ownership: value object + fixtures + controller live under
  `lib/features/announcements/`.
- [ ] **warn** — Shared extraction threshold: research proposed
  `lib/shared/widgets/announcement_banner.dart`, but there is a **single** mount site (the
  `app.dart` builder). Keep it feature-local at `lib/features/announcements/announcement_banner.dart`
  until a second consumer appears (per
  [baseline report](../../baseline_architecture_report.md) ≥3-consumer rule). This doc pins it
  feature-local.
- [x] **pass** — Motion guarded: enter/exit sourced from
  [`AppMotion`](../../../lib/shared/motion/app_motion.dart) (`standard`/`standardCurve`) and
  guarded with `MediaQuery.disableAnimationsOf(context)`; the non-animated branch still renders
  the banner immediately so the message is never gated on the animation.
- [x] **pass** — Tests use `pumpAppFrames`, never `pumpAndSettle`.
- [x] **pass** — i18n synced en/ar/zh-Hans; `gen-check` stays clean.
- [x] **pass** — Strict-analysis clean: typed `AnnouncementSeverity` enum with exhaustive
  switch into `FAlertStyle`; no `dynamic`.
- [x] **n/a-pass** — Native entitlements: none.
- [ ] **warn** — Golden re-baseline required on the pinned macOS runner; the banner is above
  every route, so multiple matrix cases shift.

## Risks / notes

- **Mount location is load-bearing.** Mount in the `app.dart:101` `builder:` above the
  `FToaster`/router child, **not** inside `AppShell`. Auth and onboarding are top-level routes;
  mounting inside the shell would hide outage/ToS banners exactly where usersetup happens.
- **Dismissal is per-device, not per-user.** Dismissed IDs live in `SettingsStore` (no account,
  no backend). If accounts land later, re-scope dismissal to the session — do not silently keep
  a dismissed critical banner hidden across an account switch.
- **Version + date windowing.** Gate fixtures by `minAppVersion`/`maxAppVersion`
  ([`AppBuildInfo`](../../../lib/infrastructure/platform/app_build_info.dart)) and
  `activeFrom`/`activeUntil` so stale promos never render after a release; cover these branches
  in the controller test.
- **No port-reuse relationship.** Announcements does not read
  [`ConnectivityService`](connectivity.md) or the remote-config family — keep it standalone. If
  a future "outage" announcement wants to auto-derive from connectivity, read the
  [`connectivity`](connectivity.md) provider inside the controller rather than duplicating the
  sensor.
- **Sequencing.** No upstream dependency beyond [`settings`](../README.md); ship in a later
  pure-UI wave. It forces its own golden re-baseline.
