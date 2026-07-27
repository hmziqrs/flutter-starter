# Structured-log PII redaction

> **Tier:** P1 · **Domain:** security · **Backend:** none · **Status:** planned · **Depends on:** none

## Summary

Extends the existing regex-based [`LogRedactor`](../../../lib/infrastructure/logging/log_redactor.dart) to scrub additional PII patterns — email addresses, phone numbers (E.164), PAN / card numbers, JWT bodies, and token-bearing query strings — from both free-text messages and structured `Map` context before they reach Talker. PII leaking into logs, crash reports, or analytics is a GDPR / HIPAA / PCI liability, and the redactor is already the documented single choke point and the **only** infra file with tests today, so this is cheap and high-signal.

## Contract

- **Ports / value objects:** no new port — this deepens the existing `LogRedactor` class. Adds static `RegExp` fields to [`log_redactor.dart`](../../../lib/infrastructure/logging/log_redactor.dart): `_email`, `_phoneE164`, `_pan`, `_jwtPayload`, plus a query-string-token pass (`?…token=…` / `&access_token=…`). Reuses the existing `LogRedactor.replacement` (`'[REDACTED]'`). Keeps the `_sensitiveKey` regex covering context map keys; adds new key fragments (`email`, `phone`, `pan`, `card`) to it. All patterns stay `static final RegExp` (compiled once), deterministic, and side-effect-free.
- **Providers:** none — `LogRedactor` is a `const` class consumed directly by [`AppLogger`](../../../lib/infrastructure/logging/app_logger.dart). No Riverpod wiring, no ProviderScope override.
- **Routes:** none — pure infra.
- **Files:**
  - **edit** `lib/infrastructure/logging/log_redactor.dart` (add regexes + wire into `redactText`; extend `_sensitiveKey`).
  - **edit** `test/infrastructure/logging/log_redactor_test.dart` (extend with the new pattern cases).
- **Dependencies:** none (pure Dart, no package, no Flutter SDK surface).

## Backend & test surface

**Backend-free.** Pure-Dart regex transforms; no I/O, no plugin, no network. The default (and only) impl is real. No test-server contract, no `common.notConnected` path, no optional override.

## Tests

- **Unit/widget:** extend [`log_redactor_test.dart`](../../../test/infrastructure/logging/log_redactor_test.dart) with cases for each new pattern — an email in free text, an E.164 phone, a 16-digit PAN (with and without spaces), a `xxx.yyy.zzz` JWT body, a `?token=…` query string — asserting each is replaced by `LogRedactor.replacement` while surrounding text is preserved. Add a **negative** case proving a diagnostic-style run of digits (e.g. `STARTUP-CONFIG-12345`, an order ID) is **not** redacted (the redactor is intentionally conservative).
- **Integration:** none beyond the unit suite — `LogRedactor` has no widget surface.
- **Golden impact:** **yes (indirect)** — if any golden fixture logs a string that now matches a new pattern (e.g. a fake email in a startup banner), its golden-rendered diagnostic text changes. Requires a **re-baseline on the pinned macOS runner** via `--update-goldens`; inspect every changed baseline.
- **Dev-gallery fixture:** none — not a UI feature.

## i18n

- **Keys:** none — the redactor operates on values, not localized copy. No `*.i18n.json` changes, no `just gen`.
- **RTL note:** n/a.

## Audit

- [x] No-backend honored as a port — **n/a**: backend-free pure-Dart transform; no port/default/override split applies.
- [x] Feature-first ownership; no `core/` / `utils/` — **pass**: stays under `lib/infrastructure/logging/` (the existing redactor home).
- [x] Shared/widgets extraction only if ≥3 consumers — **n/a**: no widget; the redactor is already the single shared choke point consumed by `AppLogger`.
- [x] Motion guarded — **n/a**: no animation surface.
- [x] Tests use `pumpAppFrames`, never `pumpAndSettle` — **n/a**: pure-Dart unit tests, no pumping.
- [x] i18n synced en/ar/zh-Hans; `gen-check` stays clean — **n/a**: no string changes.
- [x] Strict-analysis clean — **pass**: keep `static final RegExp` typed, raw string literals for patterns, no `dynamic`; verify `dart analyze --fatal-infos` is clean.
- [x] Native entitlements flagged in PR + CI platform jobs — **n/a**.
- [x] Golden re-baseline noted — **warn**: indirect impact — audit golden fixtures for strings that newly match; re-baseline on the pinned macOS runner if any change.

## Risks / notes

- **Do not redact generic digit-runs.** A greedy `\d{13,19}` PAN regex will eat diagnostic IDs, order numbers, and `STARTUP-CONFIG-12345`-style codes, breaking debugging and golden stability. Use Luhn-check or a contextual pattern (`\b(?:\d[ -]*?){13,19}\b` gated by surrounding card-like tokens), and keep the negative test case above as a regression guard.
- **Determinism is load-bearing.** Redaction output must be identical across runs for the same input (golden/test stability). Avoid time-based or random replacements; reuse the single `replacement` token.
- **Order matters.** Run `_bearerToken` and `_sensitiveAssignment` before `_jwtPayload` so a `Bearer <jwt>` header is fully redacted in one pass; document the pipeline order in a comment.
- **Context-key coverage.** Adding `email`/`phone`/`pan`/`card` to `_sensitiveKey` means any structured-log key matching those fragments redacts its **whole value** — verify this does not over-redact legitimate non-PII keys (e.g. `emailEnabled` flag). Prefer exact-key matches over fragments if collisions appear.
- **Partly present.** This is a deepening of an existing, tested file — not a new subsystem. The infrastructure subsystem in [`architecture.md`](../../../architecture.md) establishes `AppLogger` (which consumes `LogRedactor`) as the single logging choke point; every future backend feature ([session](session.md), [analytics](analytics.md), [mfa-otp](mfa-otp.md)) flows events through `AppLogger`, so these regexes automatically protect every later feature.
