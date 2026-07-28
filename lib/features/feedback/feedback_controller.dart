import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starter/features/feedback/feedback_form_value.dart';
import 'package:starter/features/feedback/feedback_presentation_state.dart';
import 'package:starter/features/feedback/feedback_transport.dart';
import 'package:starter/features/settings/settings_store.dart';
import 'package:starter/infrastructure/logging/app_logger.dart';

/// `SettingsStore` keys for the persisted feedback draft. The draft survives
/// backgrounding so a half-written report is not lost (feedback spec — draft
/// persistence scope note). Cleared only on a confirmed `accepted` result.
const String feedbackDraftMessageKey = 'feedback.draft.message';
const String feedbackDraftEmailKey = 'feedback.draft.email';
const String feedbackDraftIncludeScreenshotKey = 'feedback.draft.include_screenshot';

/// `SettingsStore` key for the shake-to-feedback opt-in. Default off —
/// shake-to-feedback is divisive (feedback spec — risks / notes). Plaintext
/// is fine here: it is a UI preference, not a secret, so `SettingsStore` (not
/// `SecureStore`) owns it.
const String feedbackShakeEnabledKey = 'feedback.shake_enabled';

/// `SettingsStore` keys persisted by the feedback feature. Used by the
/// composition root's selective-clear helpers and diagnostics; mirrors
/// `SettingsRepository.persistedKeys`.
const List<String> feedbackPersistedKeys = <String>[
  feedbackDraftMessageKey,
  feedbackDraftEmailKey,
  feedbackDraftIncludeScreenshotKey,
  feedbackShakeEnabledKey,
];

/// Cold-start seed for the persisted feedback draft. Pre-loaded in
/// `AppDependencies.production` (three `SettingsStore` reads) and overridden
/// at the `ProviderScope` — mirrors `initialSettingsProvider` /
/// `initialAnalyticsOptInProvider`. Pre-loading lets the controller resolve
/// synchronously to the persisted draft on the first frame so the sheet opens
/// with the user's half-written report.
final initialFeedbackDraftProvider = Provider<FeedbackDraft>((ref) => const FeedbackDraft.empty());

/// Cold-start seed for the shake-to-feedback opt-in. Pre-loaded alongside the
/// draft so `_AppViewState`'s shake-listener mount decision is synchronous.
final initialFeedbackShakeEnabledProvider = Provider<bool>((ref) => false);

/// Snapshot of the app environment attached to every submission (feedback spec
/// — PII in metadata note: version / platform / locale only, no account ids).
/// Overridden at the `ProviderScope` with a value built from `AppBuildInfo` +
/// `PlatformCapabilities` + the active `AppLocale`.
final feedbackAppMetadataProvider = Provider<FeedbackAppMetadata>(
  (ref) => throw StateError(
    'feedbackAppMetadataProvider must be overridden at the composition root.',
  ),
);

/// Optional logger handle. Overridden at the `ProviderScope`; defaults to the
/// bootstrap logger so the controller logs structured, redacted submit
/// outcomes without a hard wiring dependency. The `LogRedactor` scrubs the
/// feedback email (it matches the `email` sensitive key + the free-text email
/// regex) — never log the message body verbatim (feedback spec — PII note).
final feedbackLoggerProvider = Provider<AppLogger>((ref) => AppLogger.bootstrap());

/// Immutable runtime state surfaced by [FeedbackController] to the feedback
/// sheet. Composes the fixture-friendly [FeedbackPresentationState] (the same
/// type the dev-gallery pins deterministically) with the live, controller-
/// owned [FeedbackDraft] the sheet's `TextEditingController`s read from /
/// write to.
@immutable
final class FeedbackControllerState {
  const FeedbackControllerState({
    this.draft = const FeedbackDraft.empty(),
    this.presentation = const FeedbackPresentationState(),
  });

  final FeedbackDraft draft;
  final FeedbackPresentationState presentation;

  FeedbackControllerState copyWith({
    FeedbackDraft? draft,
    FeedbackPresentationState? presentation,
  }) {
    return FeedbackControllerState(
      draft: draft ?? this.draft,
      presentation: presentation ?? this.presentation,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FeedbackControllerState &&
            draft == other.draft &&
            presentation == other.presentation;
  }

  @override
  int get hashCode => Object.hash(draft, presentation);
}

/// Handwritten Riverpod `Notifier` owning the feedback draft + presentation
/// state.
///
/// Owns three concerns, all feature-local (no `core/` / `utils/`):
/// - the **draft** (message / email / include-screenshot), persisted to
///   `SettingsStore` under the `feedback.draft.*` keys so it survives
///   backgrounding; cleared only on a confirmed `accepted` (never on `failed`
///   — a failed submit retains the text for retry);
/// - the **presentation state** (`idle | drafting | validating | submitting |
///   success | failed`) that drives the sheet's exhaustive switch;
/// - the **transport round-trip** via [FeedbackTransport].
///
/// Persistence is debounced: every draft mutation schedules a flush a short
/// `Timer` later; `ref.onDispose` cancels the pending timer. This avoids a
/// `SettingsStore` write per keystroke while still persisting within a few
/// hundred milliseconds — soon enough to survive a subsequent background /
/// crash. The Noop default returns `unavailable`; the controller maps that to
/// `failed` + `common.notConnected` and never fakes success (C2 / guardrail
/// #13). No `riverpod_generator`.
final feedbackControllerProvider = NotifierProvider<FeedbackController, FeedbackControllerState>(
  FeedbackController.new,
);

final class FeedbackController extends Notifier<FeedbackControllerState> {
  Timer? _persistDebounce;

  FeedbackTransport get _transport => ref.read(feedbackTransportProvider);
  SettingsStore get _store => ref.read(settingsStoreProvider);
  AppLogger get _logger => ref.read(feedbackLoggerProvider);

  @override
  FeedbackControllerState build() {
    ref.onDispose(() => _persistDebounce?.cancel());
    final seed = ref.watch(initialFeedbackDraftProvider);
    return FeedbackControllerState(draft: seed);
  }

  /// Replaces the draft message. Trims nothing (the UI is grapheme-aware) and
  /// schedules a debounced persist. Setting a non-empty message while `idle`
  /// flips the presentation to `drafting` so the sheet can surface an
  /// in-progress affordance.
  void setMessage(String message) {
    if (state.presentation.isBusy || state.presentation.isSuccess) return;
    final next = state.draft.copyWith(message: message);
    _emit(next: next, presentation: _draftingOrIdle(next));
  }

  /// Replaces the optional reply-to email. `null` / empty clears it. Trims
  /// before assigning so the persisted + transport values never carry stray
  /// whitespace; the sheet's validator surfaces shape errors.
  void setEmail(String? email) {
    if (state.presentation.isBusy || state.presentation.isSuccess) return;
    final trimmed = email?.trim();
    final isClearing = trimmed == null || trimmed.isEmpty;
    final next = isClearing
        ? state.draft.copyWith(clearEmail: true)
        : state.draft.copyWith(email: trimmed);
    _emit(next: next, presentation: _draftingOrIdle(next));
  }

  /// Toggles the include-screenshot intent. Inert under the Noop transport
  /// (no bytes are captured); a real transport reads this to gate capture.
  void setIncludeScreenshot({required bool value}) {
    if (state.presentation.isBusy || state.presentation.isSuccess) return;
    final next = state.draft.copyWith(includeScreenshot: value);
    _emit(next: next, presentation: _draftingOrIdle(next));
  }

  /// Validates the draft and submits it through the transport.
  ///
  /// Flow: `validating` (sync) -> `submitting` -> transport round-trip. On
  /// [FeedbackOutcome.accepted] the draft is cleared + persisted as empty and
  /// the presentation becomes `success`. On `rejected` / `unavailable` (or a
  /// [FeedbackTransportException]) the presentation becomes `failed` and the
  /// draft is **retained** so the user can retry. Returns `true` only on
  /// `accepted` so the caller (the sheet) can close on success.
  Future<bool> submit() async {
    if (state.presentation.isBusy) return false;
    if (!state.draft.hasMessage) {
      state = state.copyWith(presentation: const FeedbackPresentationState.failed());
      return false;
    }
    state = state.copyWith(presentation: const FeedbackPresentationState.validating());
    final formValue = _buildFormValue();
    final submission = FeedbackSubmission(
      message: formValue.message,
      email: formValue.email,
      appMetadata: formValue.appMetadata,
    );
    state = state.copyWith(presentation: const FeedbackPresentationState.submitting());
    try {
      final result = await _transport.submit(submission);
      switch (result.outcome) {
        case FeedbackOutcome.accepted:
          // Success clears the draft (a confirmed-accepted report is filed).
          // Flush immediately rather than debounced so a subsequent crash does
          // not resurrect a filed message.
          await _clearDraftNow();
          state = state.copyWith(
            draft: const FeedbackDraft.empty(),
            presentation: const FeedbackPresentationState.success(),
          );
          _logger.debug(
            'feedback.submit.accepted',
            context: {'id': result.id ?? ''},
          );
          return true;
        case FeedbackOutcome.rejected:
          state = state.copyWith(presentation: const FeedbackPresentationState.failed());
          _logger.warning(
            'feedback.submit.rejected',
            context: {'cause': '${result.cause}'},
          );
          return false;
        case FeedbackOutcome.unavailable:
          // Honest no-backend path: surface failed + notConnected, never
          // success. The draft is retained for retry.
          state = state.copyWith(presentation: const FeedbackPresentationState.failed());
          _logger.warning('feedback.submit.unavailable');
          return false;
      }
    } on FeedbackTransportException {
      state = state.copyWith(presentation: const FeedbackPresentationState.failed());
      return false;
    } on Object catch (error, stackTrace) {
      // Defensive: an unexpected transport error still maps to failed (never
      // fakes success). The message body is never logged in plaintext.
      _logger.error(
        'feedback.submit.error',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(presentation: const FeedbackPresentationState.failed());
      return false;
    }
  }

  /// Returns the controller to `idle`, retaining the persisted draft. Called
  /// by the sheet when the user dismisses without submitting (the draft is
  /// already persisted; reopening the sheet rehydrates from the seed).
  void reset() {
    if (state.presentation.isBusy) return;
    state = state.copyWith(presentation: const FeedbackPresentationState());
  }

  /// Emits [next] + [presentation] and schedules a debounced persist of the
  /// draft. No-op persistence is skipped when the draft is empty (a cleared
  /// draft leaves the keys absent rather than writing empty strings).
  void _emit({required FeedbackDraft next, required FeedbackPresentationState presentation}) {
    state = state.copyWith(draft: next, presentation: presentation);
    if (next.isEmpty) {
      // An empty draft clears the keys immediately (no debounce) so a cleared
      // message does not resurrect on relaunch.
      _persistDebounce?.cancel();
      unawaited(_clearDraftNow());
      return;
    }
    _schedulePersist(next);
  }

  FeedbackPresentationState _draftingOrIdle(FeedbackDraft draft) {
    return draft.hasMessage
        ? const FeedbackPresentationState.drafting()
        : const FeedbackPresentationState();
  }

  FeedbackFormValue _buildFormValue() {
    return FeedbackFormValue(
      message: state.draft.message,
      email: state.draft.email,
      includeScreenshot: state.draft.includeScreenshot,
      appMetadata: ref.read(feedbackAppMetadataProvider),
    );
  }

  void _schedulePersist(FeedbackDraft draft) {
    _persistDebounce?.cancel();
    _persistDebounce = Timer(_persistDebounceDuration, () => unawaited(_persistNow(draft)));
  }

  static const Duration _persistDebounceDuration = Duration(milliseconds: 400);

  /// Persists [draft] to `SettingsStore`. Wraps each write in `try/on Object`
  /// per the SettingsStore port contract; a persistence failure degrades
  /// silently (the in-memory draft is the source of truth for the current
  /// session) and is logged through the redacting logger.
  Future<void> _persistNow(FeedbackDraft draft) async {
    try {
      await Future.wait<void>([
        _store.writeString(feedbackDraftMessageKey, draft.message),
        switch (draft.email) {
          final email? => _store.writeString(feedbackDraftEmailKey, email),
          null => _store.remove(feedbackDraftEmailKey),
        },
        switch (draft.includeScreenshot) {
          true => _store.writeString(feedbackDraftIncludeScreenshotKey, 'true'),
          false => _store.remove(feedbackDraftIncludeScreenshotKey),
        },
      ]);
    } on SettingsStoreException catch (error, stackTrace) {
      _logger.error(
        'feedback.draft.persist.failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Clears the persisted draft keys immediately (called on `accepted` /
  /// empty-draft collapse). Same `try/on Object` posture as [_persistNow].
  Future<void> _clearDraftNow() async {
    try {
      await Future.wait<void>([
        _store.remove(feedbackDraftMessageKey),
        _store.remove(feedbackDraftEmailKey),
        _store.remove(feedbackDraftIncludeScreenshotKey),
      ]);
    } on SettingsStoreException catch (error, stackTrace) {
      _logger.error(
        'feedback.draft.clear.failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

/// Handwritten Riverpod `Notifier<bool>` for the shake-to-feedback opt-in.
///
/// Backed by `SettingsStore` (a UI preference, not a secret — plaintext is
/// fine; this is the boundary the analytics opt-in draws the other way for a
/// sensitive preference). The `_AppViewState` shake-listener mount reads this
/// controller's state alongside `PlatformCapabilities` before subscribing to
/// `sensors_plus`. Default off; persisted only on opt-in so a missing key reads
/// as off (feedback spec — shake is divisive).
final feedbackShakeEnabledControllerProvider =
    NotifierProvider<FeedbackShakeEnabledController, bool>(FeedbackShakeEnabledController.new);

final class FeedbackShakeEnabledController extends Notifier<bool> {
  SettingsStore get _store => ref.read(settingsStoreProvider);

  @override
  bool build() => ref.watch(initialFeedbackShakeEnabledProvider);

  /// Optimistically persists [value] and updates live state. On persistence
  /// failure the state rolls back to its previous value and the error
  /// rethrows so the SettingsPage can surface failure honestly (guardrail
  /// #13: never fake success). Mirrors `AnalyticsOptInController.setOptIn`.
  Future<void> setEnabled({required bool value}) async {
    final previous = state;
    state = value;
    try {
      if (value) {
        await _store.writeString(feedbackShakeEnabledKey, 'true');
      } else {
        await _store.remove(feedbackShakeEnabledKey);
      }
    } on Object {
      state = previous;
      rethrow;
    }
  }

  /// Flips the current opt-in. Fire-and-forget at the call site; the toggle UI
  /// surfaces failure via [setEnabled]'s rethrow path.
  Future<void> toggle() => setEnabled(value: !state);
}

/// Decodes a persisted draft from raw `SettingsStore` values. Used by the
/// composition root to build the [initialFeedbackDraftProvider] seed (mirrors
/// `SettingsRepository.load`'s tolerant decode). Tolerant of malformed or
/// missing values — a corrupt key reads as an empty draft rather than
/// throwing.
FeedbackDraft decodeFeedbackDraft({
  required String? message,
  required String? email,
  required String? includeScreenshot,
}) {
  final trimmedEmail = email?.trim();
  return FeedbackDraft(
    message: message ?? '',
    email: (trimmedEmail == null || trimmedEmail.isEmpty) ? null : trimmedEmail,
    includeScreenshot: includeScreenshot == 'true',
  );
}
