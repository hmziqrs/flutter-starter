# Readability & Architecture Refactor Plan

## Outcome (executed on `refactor/readability-cleanup`)

Baseline at start: 1155 tests green. Final: **1161 green, 14/14 goldens unchanged,
`gen-check` clean.** `settings_page.dart` went 1247 → 978 lines.

| Commit | Step | Result |
|---|---|---|
| `44746be` | 1 | Deleted `auth_form_support.dart` (42 lines, 6 pass-through symbols) + the 2 docs that told the next agent to keep it |
| `49320fd` | 6 | `SettingsSection.tryParse` derived from `values`; added round-trip coverage for all 6 sections |
| `a55d51e` | 2 | Settings save failures now logged; duplicate `feedbackLoggerProvider` removed; 3 tests added for a path that had none |
| `c0bf877` | 4a | `SettingsSection` moved to its own file — `route_guards.dart` no longer imports a 1200-line widget file for an enum |
| `843ca8b` | 4b | Six preference tiles + toggle card + save-failure mixin moved to `widgets/` |

**Dropped as planned:** Step 3 (auth submit mixin) and Step 5 (enum consolidation).

**Found during execution, not in any audit:** making the tiles public triggers
`use_key_in_widget_constructors`, so each needs `super.key`. Minor, but it means "make it
public" is never free in this repo.

**Investigated, deliberately not changed:** `login_page.dart:314-317` keeps a non-null
no-op `onPress` while submitting on *every* platform, whereas `register`, `forgot_password`,
and `reset_password` only do so on ten-foot (`retainBusySubmitFocus` /
`isTenFoot`) and otherwise pass `null`. Login never computes ten-foot in `build` at all.
**No functional bug** — `_submit()` guards with `if (_submitting) return`, so duplicate
submits are suppressed either way. The difference is affordance only: login's submit button
does not render its disabled state while in flight. `login_page_test.dart:106` pins the
current behavior with `isNotNull`, so aligning it is a product decision plus a test change,
not a refactor.

---

Status: **audited and revised.** Four independent audits (fact-check, conventions,
test-safety, red-team) ran against the draft. Two of the draft's six steps are dropped,
one is trimmed, and three of its factual claims were refuted. Open questions A1–A9 are
closed below.

Goal: reduce duplication and file size in the highest-traffic parts of `lib/` without
changing behavior.

Non-goals: reorganizing feature boundaries, changing state management, touching routing
contracts, introducing generic `core/`/`utils/` buckets, or adding generics that make call
sites harder to read than the duplication they replace.

---

## BLOCKER — the working tree does not compile

`just test` at HEAD: **`+1150: All tests passed!` in 38s, zero failures.** The plan starts
from green.

`just test` on the current working tree: **~34 test files fail to compile.** An in-flight
`runGuarded` / `AppLogger` migration is mid-edit — `AppLogger.warning` is gaining
`error:`/`stackTrace:` parameters and callers have not all been updated
(`lib/app/dependencies.dart`, `session_controller.dart`, `experiments_controller.dart`,
`feature_flags_controller.dart`, `device_permission_service.dart`,
`share_plus_share_service.dart`, `android_app_update_service.dart`,
`firebase_performance_*`, and the untracked `lib/shared/async/run_guarded.dart:24`).

Scope of the dirty tree: **13 modified files, +181/-58**, plus untracked
`lib/shared/async/` and `test/shared/async/`.

**Nothing in this plan starts until that migration is finished and committed.** Two
consequences:

- `appLoggerProvider` **does not exist at HEAD** — it is part of the uncommitted work.
  Step 2 depends on it, so Step 2 is downstream of that commit landing, not independent of it.
- While the tree is red, the verification gate cannot distinguish plan-caused breakage from
  in-flight breakage.

Good news: `git diff --stat -- lib/features/settings lib/features/auth` is **empty**. Zero
file-level overlap between the in-flight work and any surviving plan step.

---

## Verification gate (runs after every step)

```
just format-check && just analyze && just gen-check && just test
```

Corrections to the draft's gate:

- **`just gen-check` was missing.** CI runs it (`.github/workflows/ci.yml:45-59`) and fails
  on any uncommitted change *including untracked files*.
- **`just format-check` covers only `lib test integration_test`; CI formats the whole repo.**
  A file added outside those three directories passes locally and fails CI.
- **`just test` excludes `test/goldens/`** (`justfile:112`). Golden drift is invisible to the
  gate until `just test-goldens` runs explicitly.

**No step below should shift a single pixel.** All 13 baselines render non-submitting states
(`invalid`, `focused`, `idle`, `default`), and no golden renders a settings save-failure. So a
golden diff during this work is **a caught regression, not a baseline to refresh** — and
AGENTS.md's pinned-macOS constraint means "just regenerate it" is not available as an escape
hatch mid-refactor.

---

## Step 1 — Delete `auth_form_support.dart` (KEEP)

All four audits agree this is the one unambiguous win.

**Verified:** the file is 43 lines and 6 public symbols, every one a single-expression
forward with no added defaults, reordering, or wrapping. Importers are **exactly 5, all in
`lib/features/auth/`**: `login_page.dart:7`, `register_page.dart:7`,
`reset_password_page.dart:7`, `forgot_password_page.dart:7`, `otp_page.dart:8` (which uses
`revealFirstAuthInvalid` only).

**A1 closed: nothing in `test/` or `integration_test/` imports it or names any of its
symbols.** Zero test blast radius; the compiler catches every rename. The draft's stated risk
("tests referencing the auth-prefixed names must be updated") does not exist.

**Bonus:** `AuthInvalidFieldTarget` (`:7`) has **zero users** — every call site writes the
record type inline. Delete it outright.

**Required doc edits in the same commit** — without these the change reverts itself:

- `plans/feature_roadmap/features/form-scaffolding.md:79-83` says under Risks: *"Keep the
  facade. Leave `auth_form_support.dart` as an aliasing facade."* That doc anticipated removal
  as a separate PR, so this is that PR — but the instruction must be struck, or the next agent
  restores the file.
- `docs/architecture.md:242` documents `auth_form_support.dart` as the shared-validators
  location. Repoint at `lib/shared/forms/`.
- `form-scaffolding.md`'s status in `plans/feature_roadmap/README.md` is stale — its `## Files`
  list is already fully implemented on disk while the table still says `planned`.

Commit: `refactor(auth): drop auth_form_support facade`

---

## Step 2 — Log settings save failures (KEEP, but tests first)

**Verified:** `settings_page.dart:634-644` (`mixin _SaveFailureState`) catches `on Object` and
only flips `_saveFailed` — no logging. It drives six tiles (`:654, 678, 711, 745, 771, 809`)
and three failure surfaces (`ValueKey('settings-toggle-save-error')` `:872`,
`settings-save-error` `:993`, `locale-save-error` `:1042`). `SettingsController._replace`
(`settings_controller.dart:92-102`) correctly rethrows, so the tile is exactly where the
signal dies.

**A2 closed:** `appLoggerProvider` exists (post-migration) and all six `_SaveFailureState`
users are already `ConsumerState`, so narrowing the mixin to `on ConsumerState<T>` and calling
`ref.read(appLoggerProvider)` needs no plumbing.

**A3 closed — the draft's approach was unimplementable.** `runGuarded<void>` returns `null` on
both success *and* failure, so `null` cannot drive `_saveFailed`. **Do not route `_run` through
`runGuarded`.** `_run` is 8 lines; add the `logger.warning(...)` call directly to its existing
`on Object` catch at `:640-642`.

**Prerequisite — this is the only step gated on new tests.** Grep across `test/` and
`integration_test/` for `settings-toggle-save-error`, `settings-save-error`, or
`locale-save-error` returns **nothing**. No test ever taps a settings toggle tile. Write a
`failWrites: true` tile test first, mirroring the working pattern at
`accessibility_settings_page_test.dart:59-72` (which covers `accessibility_settings_page.dart`'s
*own separate copy* of this flag — a different file Step 2 does not touch).

Note the new log line is **unverifiable in both directions**: `AppLogger` writes to `Talker`,
no test captures log output, and there is no spy logger anywhere in the suite. So the test
must pin the `_saveFailed` UI, not the logging.

**Related, verified, worth folding in:** `feedback_controller.dart:36` declares a second
`Provider<AppLogger>` alongside `app_logger.dart:81`. Two logger identities — override one at
the root and the other silently keeps bootstrapping. Delete it; use `appLoggerProvider`.

Commits: `test(settings): cover tile save-failure state` → `fix(settings): log settings save
failures` → `refactor(feedback): drop duplicate logger provider`

---

## Step 3 — Extract the auth submit mixin (**DROPPED**)

The draft's justification does not survive audit.

**A4 closed — the premise holds but the payoff does not.** All four `_submit()` bodies are
byte-for-byte identical in statement order: guard → `validateGranularly` → reveal + return →
`form.save()` → build value → ten-foot focus → `setState(true)` → `finishAutofillContext` →
`await` → `finally setState(false)`. `finishAutofillContext` is after `setState` in all four;
the ten-foot focus request is present in all four.

**The "suspected drift" accessibility bug is FALSE.** `reset_password_page.dart:326-341` and
`forgot_password_page.dart:286-296` both reveal the first invalid field — they inline
`revealFirstAuthInvalid` instead of wrapping it in a private helper. Cosmetic only. **Step 3
fixes no bug.**

**A5 closed — restoration does not generalize.** Four pages, three shapes: register has two
drafts, login and forgot have one, and `reset_password_page.dart:78-81` mixes in
`RestorationMixin` with an **empty `restoreState` and zero restorables**. Generalizing needs a
list-of-drafts abstraction, which the plan's own non-goals forbid.

**A6 closed — `update_profile_page.dart` cannot adopt it.** No `finishAutofillContext` at all,
a six-value `ProfilePresentationPhase` instead of a bool, `rethrow` instead of swallow, three
controllers mutated on success (`:341-343`). Four escape hatches for one caller.

**The decisive argument:** the two parts that actually differ between pages — the ordered
reveal targets and the form-value constructor — stay in the page, and the plan itself keeps the
presentation-status half of `_submitting` in the page too. So the mixin extracts ~12 boilerplate
lines per page while adding ~10 lines of overrides, netting roughly **40 lines saved across
2,281 lines of auth pages (1.7%)** — and in exchange it splits ownership of the single most
bug-prone piece of state in these pages across a file boundary. A developer debugging a stuck
submit button goes from three hops in one file to four hops across two, one of them a dynamic
dispatch through `on State<W>` that jump-to-definition does not resolve usefully.

**Two real findings surfaced while investigating this, both worth keeping:**

1. **Genuine drift, opposite to what the draft guessed.** `login_page.dart:314-317` computes
   `onPress` as `_locked ? null : _submitting ? () {} : ...` — login's submit button is **never
   disabled**, and `login_page_test.dart:106` pins that with `isNotNull`. The other three use
   `_submitting ? (retainBusySubmitFocus ? () {} : null) : ...` and their tests assert `isNull`.
   **`login_page.dart` never computes `retainBusySubmitFocus` at all.** Investigate separately —
   this is either a real bug or a deliberate TV-focus carve-out that deserves a comment.
2. **`reset_password_page.dart:62` mixes in `RestorationMixin` with an empty `restoreState` and
   no restorables.** Dead weight; delete it (see Test debt below first).

---

## Step 4 — Split `settings_page.dart` (KEEP, trimmed)

**A7 closed: public classes in `widgets/`. `part`/`part of` is forbidden.** Hand-written `part`
appears **nowhere** in this repo — the only uses are generated Freezed output and the generated
ForUI theme (`lib/shared/theme/generated_forui_theme.dart:7-10`, `lib/i18n/translations.g.dart:21`),
all files AGENTS.md forbids editing. Using `part` would make hand-written code visually
indistinguishable from codegen. The established pattern is one public type per file in
`<feature>/widgets/` — `lib/features/pricing/widgets/` contains `PlanCard`, `PlanComparison`,
`BillingSelector` and **zero** private classes. `public_member_api_docs` is explicitly disabled
in `analysis_options.yaml`, so going public costs nothing in lint terms.

**Two corrections to the draft's layout:**

- **Drop the proposed `sections/` directory.** The only feature subdirectory convention in this
  repo is `widgets/`. `accessibility_settings_page.dart` and `license_page.dart` already sit as
  flat siblings in `lib/features/settings/`.
- **`widgets/settings_tiles.dart` holding eight tiles** violates one-public-type-per-file.

**Trimmed scope.** The draft's 11-file split trades one file with zero internal imports for
eleven files with ~25 new intra-feature import edges, because five layout primitives are
consumed by nearly everything (`_DirectionalChevron` 14 refs, `_SettingsScrollFrame` 9,
`_SaveFailureState` 9, `_ToggleCard` 8, `_SettingsCard` 7, `_SpacedSettingsTiles` 6). This is a
densely woven mesh, not 33 independent classes. Do the 80/20 instead:

```
lib/features/settings/settings_section.dart   # SettingsSection enum — has a real external consumer
lib/features/settings/widgets/<one file per tile>   # 8 tiles + the save-failure mixin
```

~350 lines moved, ~10 new public symbols instead of ~20. Leave the layout primitives and the six
section contents in `settings_page.dart` — they are the mesh, and separating them is what makes
navigation worse.

**A8 closed:** `SettingsSection` is in no routing contract. `contracts.md` never names it; the
only production consumers are `settings_routes.dart` and `route_guards.dart:43,51`, both by
symbol. Moving it changes 5 import lines. **Do not add a re-export barrel** —
`docs/baseline_architecture_report.md:45-47` explicitly rejects feature-barrel layers.

**Test impact: one line.** No test imports a private settings class or depends on the file path,
beyond `production_gallery_cases_test.dart:23` needing an import update when `SettingsSection`
moves. Everything else is black-box over `ValueKey`s or `find.byType(SettingsPage)`.

**Invariant:** extracted widgets keep receiving `onOpen*` callbacks. None may import `go_router`
or route constants (`contracts.md:271`).

**Run `just test-goldens` on this step specifically**, not batched — `settings_800x1000_zh_light_language`
is a live baseline over the exact surface being moved.

---

## Step 5 — Consolidate the presentation-status enums (**DROPPED**)

**A9 closed: drop it.** All four audits concur.

**Verified:** the three enums are byte-for-byte identical and the freezed classes differ only in
type-name prefix. **Blast radius: ~58 edit sites across 4 files** —
`production_gallery_cases.dart` (24 construction sites), and 11/12/11 in the three auth page
tests — to delete ~120 lines of no-logic data classes.

Three independent reasons to drop:

1. **It destroys type safety.** Today you cannot hand a reset-password fixture to
   `ForgotPasswordPage.presentation`. Unify them and the compiler shrugs — for pages whose whole
   job is rendering a status-driven alert.
2. **Contract violation.** `contracts.md:283-286` freezes the state vocabulary, and these enums
   already deviate by carrying `focused` and `invalid`. Consolidating hardens that deviation into
   a *shared* type. Worse, `contracts.md:169-173` puts `*_presentation_state` firmly under
   `lib/features/<feature>/` — **there is no sanctioned home for a shared one.**
3. **Zero testable value.** All 58 sites are construction sites, not behavior.

---

## Step 6 — `SettingsSection.tryParse` (KEEP, standalone)

`settings_page.dart:34-44` hand-writes a switch duplicating the `parameter` field. Replace with a
lookup over `values`. **Unblock it from Step 4** — it is 8 lines of pure win.

**Hard requirement:** `SettingsSection.parameter` strings are load-bearing for deep-link
normalization (`route_guards.dart:43,51`, `settings_routes.dart:76,96`). Every string must survive
byte-identical. Well covered end-to-end via `/settings?section=...` in `settings_page_test.dart:49,69`,
so a broken lookup fails loudly — but note `production_gallery_cases_test.dart:144-147` covers
`privacyAbout` only.

---

## Revised sequence

0. **Finish and commit the in-flight `runGuarded`/`AppLogger` migration.** (blocker)
1. **Step 1** — delete the facade + doc edits.
2. **Step 6** — `tryParse`, standalone, 5 minutes.
3. **Step 2** — settings tile test → logging → duplicate-logger deletion.
4. **Step 4** — trimmed settings split, with per-step goldens.

The draft's `1 → 2 → 3 → 4` had a real conflict: Step 1 renames the exact call sites Step 3 would
then delete, wasting work in 2 of 5 files. Dropping Step 3 dissolves it. Step 2 before Step 4 is
correct and preserved — do the semantic edit to `_SaveFailureState` before moving the file.

---

## Test debt found during the audit (not caused by this plan)

Worth fixing regardless of whether any step above runs:

- **`TextInput.finishAutofillContext` has zero test coverage** across all five call sites
  (`login:439`, `register:523`, `reset_password:354`, `forgot_password:306`, `otp:455`). Deleting
  the call everywhere leaves the suite green.
- **Restoration is untested on 3 of 4 auth pages.** Only login has
  `login_presentation_restoration_test.dart`. Register carries two drafts with no test; nothing
  pins that reset-password must *not* restore passwords.
- **Login's duplicate-submit suppression is untested** — `login_page.dart:418`'s
  `if (_submitting) return` has no `submitCount` assertion, unlike the other three pages.
- **`forgot_password` has no golden** and no busy-overlay assertion.
- **No spy/fake logger exists in the suite.** Every test constructs a real `AppLogger`, so no
  logging behavior anywhere is assertable.

---

## Candidate architecture work (out of scope here — needs its own plan)

The red-team audit's central point stands: every step above is local cleanup. These are
structural, verified, and larger:

- **Auth business logic lives in the router.** `auth_routes.dart:35-69` performs an HTTP call,
  branches on `AuthException`, and shows a dialog inside a `GoRoute.builder`;
  `profile_routes.dart:47-79` does the same. The repo has 14 `*_controller.dart` files —
  including `auth/otp_controller.dart` — so auth's OTP flow has a controller and its
  login/register/forgot/reset flows do not. This is the largest consistency gap in the codebase,
  and lifting the state machine into an `AuthController` is what makes Step 3's mixin
  unnecessary rather than merely unattractive.
- **16 `ProviderScope.containerOf(context, listen: false)` call sites** across 8 files —
  Riverpod's documented escape hatch used as the default DI accessor, including inside a plain
  `State` leaf widget at `update_profile_page.dart:652`.
- **`update_profile_page.dart` ignores shared primitives that exist.** Hand-rolled reveal at
  `:348-364` with a different `Scrollable.ensureVisible` duration than
  `shared/forms/form_field_reveal.dart`, plus private `_required`/`_username`/`_bio` validators
  paralleling `shared/forms/form_validators.dart`. `feedback_sheet.dart:9` imports the shared ones
  correctly, proving the pattern works. **This is the cheapest real win on the list.**
- **The composition root is procedural and untestable.** `AppDependencies.production`
  (`dependencies.dart:200-397`) is ~200 lines with six separate `try/catch` fallbacks, and
  `app.dart:81-152` then unpacks all eight aggregate groups field-by-field across 71 lines of
  `overrideWithValue`. Adding one dependency means editing four sites.

### Explicitly NOT a defect — do not "fix" this

The red-team audit flagged `InMemoryVersionGateStore` (`dependencies.dart:242`) and
`InMemoryFeatureFlagsSource` (`:361`) in `AppDependencies.production` as shipping broken stubs,
calling it the highest-value fix available. **This is wrong, and acting on it would tear out
working architecture.**

`plans/feature_roadmap/contracts.md:16` — *"C2 — Backend stance: port + Noop production default +
optional real impl + test server"* — states the starter is **zero-backend in production by
design**: *"The app runs green with zero backend; actions needing one surface
`common.notConnected` / `globalError` honestly and never fake success."* Clause 3 is explicit that
the real adapter *"is never constructed by default"*. `contracts.md:67-77` specifies this exact
three-port arrangement, and `RemoteConfigVersionGateStore` existing unused is the intended shape —
it is the override an adopter wires when they have credentials. Commit `f34ff42 test(integration):
cover honest no-backend auth routing` shows the stance is actively maintained.

Recorded here because an auditor reading `lib/` without reading `contracts.md` will reliably
mistake this deliberate design for decay.
