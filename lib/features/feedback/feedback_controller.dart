import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:starter/features/feedback/feedback_form_value.dart';
import 'package:starter/features/feedback/feedback_presentation_state.dart';
import 'package:starter/features/feedback/feedback_transport.dart';
import 'package:starter/features/settings/settings_store.dart';
import 'package:starter/infrastructure/logging/app_logger.dart';

part 'feedback_controller.freezed.dart';

/// `SettingsStore` keys for the persisted feedback draft. Cleared only on a
/// confirmed `accepted` result.
const String feedbackDraftMessageKey = 'feedback.draft.message';
const String feedbackDraftEmailKey = 'feedback.draft.email';
const String feedbackDraftIncludeScreenshotKey = 'feedback.draft.include_screenshot';

/// `SettingsStore` key for the shake-to-feedback opt-in. Default off; a UI
/// preference, so `SettingsStore` (not `SecureStore`) owns it.
const String feedbackShakeEnabledKey = 'feedback.shake_enabled';

/// `SettingsStore` keys persisted by the feedback feature. Used by the
/// composition root's selective-clear helpers and diagnostics.
const List<String> feedbackPersistedKeys = <String>[
  feedbackDraftMessageKey,
  feedbackDraftEmailKey,
  feedbackDraftIncludeScreenshotKey,
  feedbackShakeEnabledKey,
];

/// Cold-start seed for the persisted feedback draft. Overridden at the
/// `ProviderScope` so the sheet opens with the user's half-written report.
final initialFeedbackDraftProvider = Provider<FeedbackDraft>((ref) => const FeedbackDraft.empty());

/// Cold-start seed for the shake-to-feedback opt-in.
final initialFeedbackShakeEnabledProvider = Provider<bool>((ref) => false);

/// Snapshot of the app environment attached to every submission (version /
/// platform / locale only, never account ids). Overridden at the
/// `ProviderScope` with a value built from `AppBuildInfo` +
/// `PlatformCapabilities` + the active `AppLocale`.
final feedbackAppMetadataProvider = Provider<FeedbackAppMetadata>(
  (ref) => throw StateError(
    'feedbackAppMetadataProvider must be overridden at the composition root.',
  ),
);

/// Optional logger handle, overridden at the `ProviderScope`; defaults to the
/// bootstrap logger. The `LogRedactor` scrubs the feedback email; the message
/// body is never logged verbatim.
final feedbackLoggerProvider = Provider<AppLogger>((ref) => AppLogger.bootstrap());

/// Immutable runtime state surfaced by [FeedbackController] to the feedback
/// sheet: the fixture-friendly [FeedbackPresentationState] plus the live
/// [FeedbackDraft] the sheet's `TextEditingController`s read from / write to.
@freezed
abstract class FeedbackControllerState with _$FeedbackControllerState {
  const factory FeedbackControllerState({
    @Default(FeedbackDraft.empty()) FeedbackDraft draft,
    @Default(FeedbackPresentationState()) FeedbackPresentationState presentation,
  }) = _FeedbackControllerState;
}

/// Handwritten Riverpod `Notifier` owning the feedback draft + presentation
/// state.
///
/// Persists the draft to `SettingsStore` (debounced ~400ms per mutation,
/// cancelled on dispose) so it survives backgrounding; cleared only on a
/// confirmed `accepted` (never on `failed`, so a failed submit can retry).
/// The Noop transport default returns `unavailable`, which maps to `failed` +
/// `common.notConnected` rather than a faked success.
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

  /// Replaces the draft message and schedules a debounced persist. A
  /// non-empty message while `idle` flips the presentation to `drafting`.
  void setMessage(String message) {
    if (state.presentation.isBusy || state.presentation.isSuccess) return;
    final next = state.draft.copyWith(message: message);
    _emit(next: next, presentation: _draftingOrIdle(next));
  }

  /// Replaces the optional reply-to email; `null` / empty clears it. Trimmed
  /// before assigning so persisted + transport values carry no stray
  /// whitespace.
  void setEmail(String? email) {
    if (state.presentation.isBusy || state.presentation.isSuccess) return;
    final trimmed = email?.trim();
    final isClearing = trimmed == null || trimmed.isEmpty;
    final next = isClearing
        ? state.draft.copyWith(clearEmail: true)
        : state.draft.copyWith(email: trimmed);
    _emit(next: next, presentation: _draftingOrIdle(next));
  }

  /// Toggles the include-screenshot intent. Inert under the Noop transport;
  /// a real transport reads this to gate capture.
  void setIncludeScreenshot({required bool value}) {
    if (state.presentation.isBusy || state.presentation.isSuccess) return;
    final next = state.draft.copyWith(includeScreenshot: value);
    _emit(next: next, presentation: _draftingOrIdle(next));
  }

  /// Validates the draft and submits it through the transport: `validating`
  /// (sync) -> `submitting` -> transport round-trip. Clears the draft only on
  /// [FeedbackOutcome.accepted]; `rejected` / `unavailable` land on `failed`
  /// and retain the draft for retry. Returns `true` only on `accepted`.
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
          state = state.copyWith(presentation: const FeedbackPresentationState.failed());
          _logger.warning('feedback.submit.unavailable');
          return false;
      }
    } on FeedbackTransportException {
      state = state.copyWith(presentation: const FeedbackPresentationState.failed());
      return false;
    } on Object catch (error, stackTrace) {
      _logger.error(
        'feedback.submit.error',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(presentation: const FeedbackPresentationState.failed());
      return false;
    }
  }

  /// Returns the controller to `idle`, retaining the persisted draft.
  void reset() {
    if (state.presentation.isBusy) return;
    state = state.copyWith(presentation: const FeedbackPresentationState());
  }

  /// Emits [next] + [presentation] and schedules a debounced persist. An
  /// empty draft clears the keys immediately instead (no debounce) so it
  /// does not resurrect on relaunch.
  void _emit({required FeedbackDraft next, required FeedbackPresentationState presentation}) {
    state = state.copyWith(draft: next, presentation: presentation);
    if (next.isEmpty) {
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

  /// Persists [draft] to `SettingsStore`. A failure degrades silently (the
  /// in-memory draft stays the source of truth) and is logged.
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

  /// Clears the persisted draft keys immediately (on `accepted` / empty-draft
  /// collapse).
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

/// Handwritten Riverpod `Notifier<bool>` for the shake-to-feedback opt-in,
/// backed by `SettingsStore`. Default off; persisted only on opt-in so a
/// missing key reads as off.
final feedbackShakeEnabledControllerProvider =
    NotifierProvider<FeedbackShakeEnabledController, bool>(FeedbackShakeEnabledController.new);

final class FeedbackShakeEnabledController extends Notifier<bool> {
  SettingsStore get _store => ref.read(settingsStoreProvider);

  @override
  bool build() => ref.watch(initialFeedbackShakeEnabledProvider);

  /// Optimistically persists [value]. On failure the state rolls back and
  /// the error rethrows so the caller can surface it.
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

  /// Flips the current opt-in.
  Future<void> toggle() => setEnabled(value: !state);
}

/// Decodes a persisted draft from raw `SettingsStore` values. Tolerant of
/// malformed or missing values — a corrupt key reads as an empty draft.
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
