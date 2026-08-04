import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:starter/features/feedback/feedback_form_value.dart';
import 'package:starter/features/feedback/feedback_presentation_state.dart';
import 'package:starter/features/feedback/feedback_transport.dart';
import 'package:starter/features/settings/settings_store.dart';
import 'package:starter/infrastructure/logging/app_logger.dart';
import 'package:starter/infrastructure/preferences/bool_codec.dart';
import 'package:starter/shared/state/optimistic_notifier.dart';

part 'feedback_controller.freezed.dart';

const String feedbackDraftMessageKey = 'feedback.draft.message';
const String feedbackDraftEmailKey = 'feedback.draft.email';
const String feedbackDraftIncludeScreenshotKey = 'feedback.draft.include_screenshot';

const String feedbackShakeEnabledKey = 'feedback.shake_enabled';

const List<String> feedbackPersistedKeys = <String>[
  feedbackDraftMessageKey,
  feedbackDraftEmailKey,
  feedbackDraftIncludeScreenshotKey,
  feedbackShakeEnabledKey,
];

final initialFeedbackDraftProvider = Provider<FeedbackDraft>((ref) => const FeedbackDraft.empty());

final initialFeedbackShakeEnabledProvider = Provider<bool>((ref) => false);

final feedbackAppMetadataProvider = Provider<FeedbackAppMetadata>(
  (ref) => throw StateError(
    'feedbackAppMetadataProvider must be overridden at the composition root.',
  ),
);

@freezed
abstract class FeedbackControllerState with _$FeedbackControllerState {
  const factory FeedbackControllerState({
    @Default(FeedbackDraft.empty()) FeedbackDraft draft,
    @Default(FeedbackPresentationState()) FeedbackPresentationState presentation,
  }) = _FeedbackControllerState;
}

final feedbackControllerProvider = NotifierProvider<FeedbackController, FeedbackControllerState>(
  FeedbackController.new,
);

final class FeedbackController extends Notifier<FeedbackControllerState> {
  Timer? _persistDebounce;

  FeedbackTransport get _transport => ref.read(feedbackTransportProvider);
  SettingsStore get _store => ref.read(settingsStoreProvider);
  AppLogger get _logger => ref.read(appLoggerProvider);

  @override
  FeedbackControllerState build() {
    ref.onDispose(() => _persistDebounce?.cancel());
    final seed = ref.watch(initialFeedbackDraftProvider);
    return FeedbackControllerState(draft: seed);
  }

  void setMessage(String message) {
    if (state.presentation.isBusy || state.presentation.isSuccess) return;
    final next = state.draft.copyWith(message: message);
    _emit(next: next, presentation: _draftingOrIdle(next));
  }

  void setEmail(String? email) {
    if (state.presentation.isBusy || state.presentation.isSuccess) return;
    final trimmed = email?.trim();
    final isClearing = trimmed == null || trimmed.isEmpty;
    final next = isClearing
        ? state.draft.copyWith(clearEmail: true)
        : state.draft.copyWith(email: trimmed);
    _emit(next: next, presentation: _draftingOrIdle(next));
  }

  void setIncludeScreenshot({required bool value}) {
    if (state.presentation.isBusy || state.presentation.isSuccess) return;
    final next = state.draft.copyWith(includeScreenshot: value);
    _emit(next: next, presentation: _draftingOrIdle(next));
  }

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

  void reset() {
    if (state.presentation.isBusy) return;
    state = state.copyWith(presentation: const FeedbackPresentationState());
  }

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

  Future<void> _persistNow(FeedbackDraft draft) async {
    try {
      await Future.wait<void>([
        _store.writeString(feedbackDraftMessageKey, draft.message),
        switch (draft.email) {
          final email? => _store.writeString(feedbackDraftEmailKey, email),
          null => _store.remove(feedbackDraftEmailKey),
        },
        _store.writeBool(feedbackDraftIncludeScreenshotKey, value: draft.includeScreenshot),
      ]);
    } on SettingsStoreException catch (error, stackTrace) {
      _logger.error(
        'feedback.draft.persist.failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

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

final feedbackShakeEnabledControllerProvider =
    NotifierProvider<FeedbackShakeEnabledController, bool>(FeedbackShakeEnabledController.new);

final class FeedbackShakeEnabledController extends Notifier<bool> with OptimisticNotifier<bool> {
  SettingsStore get _store => ref.read(settingsStoreProvider);

  @override
  bool build() => ref.watch(initialFeedbackShakeEnabledProvider);

  Future<void> setEnabled({required bool value}) async {
    await guardRollback(value, () => _store.writeBool(feedbackShakeEnabledKey, value: value));
  }

  Future<void> toggle() => setEnabled(value: !state);
}

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
