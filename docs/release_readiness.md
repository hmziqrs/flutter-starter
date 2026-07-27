# Release readiness

Use this checklist for a candidate built from a clean commit with Flutter
3.44.7 and `config/production.json`. Automated CI proves compilation and the
deterministic test contracts; this document records the human and product work
that CI cannot prove.

## Candidate record

- [ ] Commit/tag: `____________________`
- [ ] Version/build number: `____________________`
- [ ] Reviewer(s): `____________________`
- [ ] Review date: `____________________`
- [ ] All required jobs in `.github/workflows/ci.yml` passed from this commit.
- [ ] The candidate was rebuilt with an explicit production configuration and
      no uncommitted/generated drift.
- [ ] Production diagnostics contain no secrets, credentials, personal data,
      OTP/password values, or development endpoints.

## Device and window review

Record the exact hardware/emulator and OS beside each completed item.

- [ ] Small phone, portrait: all screens, safe areas, dialogs, sheets, and
      primary actions remain reachable.
- [ ] Small phone, landscape: no clipped forms, hidden actions, or unusable
      keyboard layout.
- [ ] Large phone or foldable-sized emulator: hinge/display-feature avoidance
      and posture changes preserve state.
- [ ] Tablet-sized window: medium layout and navigation behave correctly.
- [ ] Resizable macOS window: compact/medium/expanded and short-height
      transitions preserve navigation and draft form state.
- [ ] Resizable Windows window: compact/medium/expanded and short-height
      transitions preserve navigation and draft form state.
- [ ] Split-screen or narrow desktop window: content scrolls instead of
      overflowing and every required action remains reachable.
- [ ] Software keyboard shown: focused fields are revealed, keyboard insets are
      honored, and the submit action is reachable.
- [ ] Software keyboard dismissed/reattached: focus and typed content follow
      the documented policy.
- [ ] Browser/OS Back works where supported; direct router locations recover
      correctly without claiming universal-link or desktop-protocol support.
- [ ] Android TV at 720p, 1080p, and 4K: the app launches from TV Home, every
      action is reachable by D-pad, focus remains inside the safe frame, and
      Back follows overlay -> keyboard/form -> route -> system priority.
- [ ] Apple TV at 1080p and 4K: Siri Remote Select/Menu, directional focus,
      suspend/resume, controller reconnect, and full-screen text entry follow
      the documented policy without duplicate actions.

## Touch, keyboard, and pointer input

- [ ] Touch targets meet the required size and spacing at phone and tablet
      dimensions.
- [ ] Keyboard-only traversal follows a logical localized order on every form,
      the shell, settings, gallery overlays, and recovery surfaces.
- [ ] Focus is always visible in light, dark, and high-contrast modes.
- [ ] Enter/submit, Space activation, Tab/Shift+Tab, arrow-key controls, and
      Escape/dismiss behavior are correct where those conventions apply.
- [ ] The first invalid form field receives focus and is scrolled into view.
- [ ] Mouse and trackpad hover, cursor, click, wheel/trackpad scroll, tooltip,
      popover, and outside-dismiss behavior are correct.
- [ ] Touch, precision-pointer, and hybrid policies do not expose hover-only
      information or make an enabled control unreachable.
- [ ] Resize or input-policy changes do not duplicate a submit, navigation, or
      overlay action.
- [ ] Remote, game-controller, and keyboard activation aliases trigger exactly
      once; held Select/Enter/Button A never repeats submit, navigation,
      resend, restore, or destructive actions.

## Localization, scaling, and motion

- [ ] English renders without missing or fallback-only glyphs.
- [ ] Simplified Chinese (`zh-Hans`) renders with the bundled Noto Sans SC
      coverage and localized ForUI copy.
- [ ] Arabic uses RTL layout, correct reading/focus order, directional icons,
      number handling, and bundled Noto Sans Arabic coverage.
- [ ] Long localized labels wrap or scroll without hiding required actions.
- [ ] Application multiplier `1.60x` composed with the maximum nonlinear system
      text scaler remains usable; the system scaler is neither replaced nor
      globally clamped.
- [ ] High contrast preserves meaning, state, selection, borders, focus, and
      error visibility.
- [ ] Bold text preserves layout and action availability.
- [ ] Disabled animations/reduced motion settle immediately without removing
      information or trapping interaction.
- [ ] Light and dark themes meet contrast expectations for body text, controls,
      errors, selected states, disabled states, and focus indicators.

## Screen-reader review

- [ ] VoiceOver on iOS: Login -> Register -> registration OTP -> Home is
      understandable and operable without sight.
- [ ] TalkBack on Android: Login -> Register -> registration OTP -> Home is
      understandable and operable without sight.
- [ ] TalkBack on Android TV and VoiceOver/Switch Control on Apple TV preserve
      remote navigation, range-control adjustment, overlay focus trapping, and
      private text-entry semantics.
- [ ] Fields expose localized labels, required/invalid state, current value
      policy, and actionable error messages without duplicate announcements.
- [ ] OTP cells announce purpose, position/value policy, validation, expiry,
      resend state, and progress coherently.
- [ ] Password visibility controls announce role, label, state, and action
      without reading the password.
- [ ] Headings, landmarks, selected navigation destinations, progress, dialogs,
      sheets, toasts, tooltips, and recovery actions expose correct semantics.
- [ ] Dynamic success/error feedback is announced once and does not steal focus
      from the next required action.
- [ ] Decorative visuals are excluded; meaningful visuals have concise
      localized descriptions.

## Static-flow and environment review

- [ ] Onboarding and paywall Skip actions reach Home at compact and expanded
      widths.
- [ ] Register -> registration OTP -> Home and Forgot Password -> reset OTP ->
      Reset Password -> Login follow the intended static destinations.
- [ ] Static pricing, restore, legal, authentication, OTP, and upload actions
      never imply that an external transaction or service succeeded.
- [ ] Theme, accent, locale, text scale, and motion settings persist across a
      real restart.
- [ ] Unknown routes, malformed OTP purposes, and startup failures provide
      localized accessible recovery; a cold-start unknown route never offers
      an invalid Back action.
- [ ] Development routes and verbose logging are absent from the production
      candidate.
- [ ] Sensitive fields are not restored, logged, copied into diagnostics, or
      retained after their owning flow ends.

## Artifact review

- [ ] Android APK installs and cold-starts on a supported physical device.
- [ ] Android release APK/AAB passes `tool/android_tv/validate_android_tv.py`,
      contains 32-bit and 64-bit ARM Flutter libraries, passes 16 KB
      `zipalign`, appears in the TV launcher, and remains phone-installable.
- [ ] tvOS Debug/Profile/Release simulator builds use the pinned fork and clean
      mixed SwiftPM/CocoaPods plugin integration; a signed archive installs and
      launches on a real Apple TV before distribution.
- [ ] Unsigned iOS compilation is green; signed archive/install validation is
      tracked below and must be completed before distribution.
- [ ] macOS bundle launches, resizes, accepts keyboard/pointer input, and passes
      Gatekeeper/notarization validation once signing is activated.
- [ ] Windows bundle launches on a clean Windows 10/11 machine with its required
      runtime files.
- [ ] Linux bundle launches on the intended distribution with GTK 3 and every
      library reported by `ldd` available.
- [ ] Version, build number, app name, copyright, licenses, privacy text, and
      store metadata match the release record.

## Deferred release blockers and product decisions

The starter intentionally does not pretend these capabilities exist. Assign an
owner, record the decision, and complete the relevant verification before a
public release.

| Area | Required decision/implementation | Evidence before release |
| --- | --- | --- |
| Signing | Replace Android debug-key release signing; configure Apple certificates/profiles and macOS hardened runtime/notarization; define Windows signing if distributed | Signed installable artifacts, protected CI credentials, rotation/ownership record |
| Identifiers | Replace `com.example.starter` and all placeholder bundle/application IDs consistently | Store-registered unique IDs and clean install/upgrade tests |
| Icons and brand | Replace template icons, launch visuals, app name, and neutral placeholder brand assets | Reviewed assets at every required platform size and light/dark context |
| Android TV store | Final localized TV banner/icon/screenshots, Tier 3/Tier 2 quality review, Play device catalogue, low-RAM/device and 16 KB validation | TV launcher/store discovery, release AAB inspection, device matrix and reviewer evidence |
| tvOS store | Final layered icon, Top Shelf artwork, screenshots, privacy manifest/report, App Privacy text, identifiers and signing | Signed Apple TV install, archive/privacy inspection, App Store Connect validation and reviewer evidence |
| Telemetry | Decide whether analytics, crash reporting, and performance tracing are needed; add only behind application contracts | Data inventory, environment separation, redaction tests, retention/access policy |
| Consent and privacy | Define consent, opt-out/deletion, regional behavior, privacy disclosures, and legal destinations before telemetry or personal data collection | Approved copy/UX, policy links, consent-state tests, store privacy declarations |
| Native workflows | Identify real permissions, notifications, background tasks, purchases, links, uploads, or other native boundaries | Device tests (and Patrol only if justified), denial/recovery cases, platform configuration |
| App links/protocols | Define owned domains and activation scope for Android App Links, iOS universal links, web paths, or desktop URL schemes | Association/protocol files and real external-launch validation per activated platform |
| Store delivery | Choose channels, packaging, supported architectures/OS versions, staged rollout, rollback, and update policy | Store validation, clean install/upgrade/rollback rehearsal, support ownership |
| Product backends | Define auth, OTP, recovery, profile, pricing, purchase, entitlement, restore, and upload contracts | Threat model, backend-aligned validation/error copy, end-to-end tests without fake success |
| Legal/accessibility support | Finalize terms/privacy content and the supported accessibility conformance/review process | Legal approval, accessibility review notes, issue escalation and remediation owner |

## Sign-off

- [ ] All checked evidence is attached to the release pull request or release
      record; incomplete items have explicit owners and blocking status.
- [ ] No deferred blocker that applies to this distribution channel remains
      unresolved.
- [ ] Engineering approval: `____________________`
- [ ] Product/privacy approval: `____________________`
- [ ] Release owner approval: `____________________`
