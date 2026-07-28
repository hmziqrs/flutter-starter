import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/feedback/feedback_controller.dart';
import 'package:starter/features/feedback/feedback_form_value.dart';
import 'package:starter/features/feedback/feedback_presentation_state.dart';
import 'package:starter/features/feedback/feedback_transport.dart';
import 'package:starter/features/feedback/in_memory_feedback_transport.dart';
import 'package:starter/features/feedback/noop_feedback_transport.dart';
import 'package:starter/features/settings/in_memory_settings_store.dart';
import 'package:starter/features/settings/settings_store.dart';

const _metadata = FeedbackAppMetadata(
  appVersion: '1.0.0+1',
  platform: 'ios',
  locale: 'en',
);

ProviderContainer _container({
  required FeedbackTransport transport,
  FeedbackDraft initialDraft = const FeedbackDraft.empty(),
  SettingsStore? store,
}) {
  final settingsStore = store ?? InMemorySettingsStore();
  final container = ProviderContainer(
    overrides: [
      feedbackTransportProvider.overrideWithValue(transport),
      settingsStoreProvider.overrideWithValue(settingsStore),
      initialFeedbackDraftProvider.overrideWithValue(initialDraft),
      initialFeedbackShakeEnabledProvider.overrideWithValue(false),
      feedbackAppMetadataProvider.overrideWithValue(_metadata),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('FeedbackController', () {
    test('initial state is idle with the seeded draft', () {
      final container = _container(
        transport: const NoopFeedbackTransport(),
        initialDraft: const FeedbackDraft(message: 'leftover', email: 'a@b.com'),
      );
      final state = container.read(feedbackControllerProvider);
      expect(state.presentation.status, FeedbackPresentationStatus.idle);
      expect(state.draft.message, 'leftover');
      expect(state.draft.email, 'a@b.com');
    });

    test('setMessage flips to drafting and persists debounced', () async {
      final store = InMemorySettingsStore();
      final container = _container(
        transport: const NoopFeedbackTransport(),
        store: store,
      );
      container.read(feedbackControllerProvider.notifier).setMessage('hello');
      final state = container.read(feedbackControllerProvider);
      expect(state.draft.message, 'hello');
      expect(state.presentation.status, FeedbackPresentationStatus.drafting);
      // Flush the 400ms debounce.
      await Future<void>.delayed(const Duration(milliseconds: 600));
      expect(store.snapshot[feedbackDraftMessageKey], 'hello');
    });

    test('setIncludeScreenshot named-arg toggles intent', () {
      final container = _container(transport: const NoopFeedbackTransport());
      container.read(feedbackControllerProvider.notifier).setIncludeScreenshot(value: true);
      expect(container.read(feedbackControllerProvider).draft.includeScreenshot, true);
    });

    test('setEmail trims and clears on empty', () {
      final container = _container(transport: const NoopFeedbackTransport());
      container.read(feedbackControllerProvider.notifier).setEmail('  A@B.COM  ');
      expect(container.read(feedbackControllerProvider).draft.email, 'A@B.COM');
      container.read(feedbackControllerProvider.notifier).setEmail('   ');
      expect(container.read(feedbackControllerProvider).draft.email, isNull);
    });

    test('submit rejects an empty message with failed state', () async {
      final container = _container(transport: const NoopFeedbackTransport());
      final accepted = await container.read(feedbackControllerProvider.notifier).submit();
      expect(accepted, isFalse);
      expect(
        container.read(feedbackControllerProvider).presentation.status,
        FeedbackPresentationStatus.failed,
      );
    });

    test('Noop transport surfaces failed + notConnected-equivalent, never success', () async {
      final container = _container(transport: const NoopFeedbackTransport());
      container.read(feedbackControllerProvider.notifier).setMessage('a real report');
      final accepted = await container.read(feedbackControllerProvider.notifier).submit();
      expect(accepted, isFalse);
      // The honest no-backend path: failed, never success.
      expect(
        container.read(feedbackControllerProvider).presentation.status,
        FeedbackPresentationStatus.failed,
      );
      // Draft is retained for retry on failure.
      expect(container.read(feedbackControllerProvider).draft.message, 'a real report');
    });

    test('InMemory accepted flips state to success and clears the draft', () async {
      final transport = InMemoryFeedbackTransport();
      final store = InMemorySettingsStore();
      final container = _container(transport: transport, store: store);
      container.read(feedbackControllerProvider.notifier).setMessage('report');
      // Flush the debounced persist so the keys are written before the accept
      // clears them.
      await Future<void>.delayed(const Duration(milliseconds: 600));
      expect(store.snapshot[feedbackDraftMessageKey], 'report');
      final accepted = await container.read(feedbackControllerProvider.notifier).submit();
      expect(accepted, isTrue);
      expect(
        container.read(feedbackControllerProvider).presentation.status,
        FeedbackPresentationStatus.success,
      );
      // Draft cleared in-memory AND in the store.
      expect(container.read(feedbackControllerProvider).draft.message, '');
      expect(store.snapshot[feedbackDraftMessageKey], isNull);
      // The submission carries the app metadata (no PII beyond the message).
      expect(transport.submissions.single.message, 'report');
      expect(transport.submissions.single.appMetadata, _metadata);
    });

    test('InMemory rejected retains the draft', () async {
      final transport = InMemoryFeedbackTransport(
        result: const FeedbackResult.rejected(),
      );
      final container = _container(transport: transport);
      container.read(feedbackControllerProvider.notifier).setMessage('report');
      final accepted = await container.read(feedbackControllerProvider.notifier).submit();
      expect(accepted, isFalse);
      expect(
        container.read(feedbackControllerProvider).presentation.status,
        FeedbackPresentationStatus.failed,
      );
      expect(container.read(feedbackControllerProvider).draft.message, 'report');
    });

    test('transport exception maps to failed, never success', () async {
      final transport = InMemoryFeedbackTransport()
        ..throwException = const FeedbackTransportException.notConnected();
      final container = _container(transport: transport);
      container.read(feedbackControllerProvider.notifier).setMessage('report');
      final accepted = await container.read(feedbackControllerProvider.notifier).submit();
      expect(accepted, isFalse);
      expect(
        container.read(feedbackControllerProvider).presentation.status,
        FeedbackPresentationStatus.failed,
      );
    });

    test('draft persists across controller rebuild via the seed', () async {
      // Simulate the composition-root seed: write the draft to the store, then
      // build a fresh container whose initialFeedbackDraftProvider reads it
      // back (decodeFeedbackDraft mirrors the production decode).
      final store = InMemorySettingsStore();
      await store.writeString(feedbackDraftMessageKey, 'persisted across cold start');
      await store.writeString(feedbackDraftEmailKey, 'u@example.com');
      final decoded = decodeFeedbackDraft(
        message: store.snapshot[feedbackDraftMessageKey],
        email: store.snapshot[feedbackDraftEmailKey],
        includeScreenshot: null,
      );
      final container = _container(
        transport: const NoopFeedbackTransport(),
        initialDraft: decoded,
      );
      expect(
        container.read(feedbackControllerProvider).draft.message,
        'persisted across cold start',
      );
      expect(container.read(feedbackControllerProvider).draft.email, 'u@example.com');
    });
  });

  group('FeedbackShakeEnabledController', () {
    test('defaults to seed and persists opt-in', () async {
      final store = InMemorySettingsStore();
      final container = ProviderContainer(
        overrides: [
          settingsStoreProvider.overrideWithValue(store),
          initialFeedbackShakeEnabledProvider.overrideWithValue(false),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(feedbackShakeEnabledControllerProvider), isFalse);
      await container.read(feedbackShakeEnabledControllerProvider.notifier).toggle();
      expect(container.read(feedbackShakeEnabledControllerProvider), isTrue);
      expect(store.snapshot[feedbackShakeEnabledKey], 'true');
    });

    test('rolls back on persistence failure', () async {
      final store = InMemorySettingsStore()..failWrites = true;
      final container = ProviderContainer(
        overrides: [
          settingsStoreProvider.overrideWithValue(store),
          initialFeedbackShakeEnabledProvider.overrideWithValue(false),
        ],
      );
      addTearDown(container.dispose);
      await expectLater(
        container.read(feedbackShakeEnabledControllerProvider.notifier).setEnabled(value: true),
        throwsA(isA<SettingsStoreException>()),
      );
      expect(container.read(feedbackShakeEnabledControllerProvider), isFalse);
    });
  });

  group('NoopFeedbackTransport', () {
    test('submit returns unavailable and never accepted', () async {
      const transport = NoopFeedbackTransport();
      final result = await transport.submit(
        const FeedbackSubmission(
          message: 'x',
          appMetadata: _metadata,
        ),
      );
      expect(result.outcome, FeedbackOutcome.unavailable);
      expect(result.isAccepted, isFalse);
    });

    test('status returns unavailable', () async {
      const transport = NoopFeedbackTransport();
      expect(await transport.status('any'), FeedbackTriageState.unavailable);
    });
  });
}
