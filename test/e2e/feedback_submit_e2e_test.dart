import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/feedback/feedback_form_value.dart';
import 'package:starter/features/feedback/feedback_transport.dart';
import 'package:starter/features/feedback/http_feedback_transport.dart';

import '../infrastructure/hono_server_handle.dart';

/// Tiny 1x1 transparent PNG — the in-repo screenshot fixture feedback.md pins.
const String _tinyPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJ'
    'AAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

const FeedbackAppMetadata _metadata = FeedbackAppMetadata(
  appVersion: '1.0.0+1',
  platform: 'e2e',
  locale: 'en',
);

/// Live feedback-submit e2e: `HttpFeedbackTransport` (the optional real impl,
/// constructed here via override only) POSTs real submissions to the live JS
/// Hono server and round-trips `GET /v1/feedback/{id}/status`.
void main() {
  final runtime = JsRuntime.resolve();

  group('feedback submit e2e (HttpFeedbackTransport <-> live JS Hono)', () {
    if (runtime == null) {
      test(
        'skipped: no JS runtime (bun or npx tsx) available',
        () {},
        skip: 'no JS runtime (bun or npx tsx) available on PATH',
      );
      return;
    }

    HonoServerHandle? server;
    late final Uri baseUri;

    setUpAll(() async {
      final handle = await HonoServerHandle.start(runtime: runtime);
      server = handle;
      baseUri = handle.baseUri;
    });

    tearDownAll(() async {
      final handle = server;
      if (handle != null) await handle.close();
    });

    test(
      'real submissions (plain + screenshot) are accepted, status round-trips',
      () async {
        final transport = HttpFeedbackTransport(baseUrl: baseUri);
        final result = await transport.submit(
          const FeedbackSubmission(
            message: 'e2e live feedback report',
            email: 'e2e@example.test',
            appMetadata: _metadata,
          ),
        );

        expect(result.outcome, FeedbackOutcome.accepted);
        final id = result.id;
        expect(id, isNotNull);
        expect(await transport.status(id!), FeedbackTriageState.queued);

        final withScreenshot = await transport.submit(
          const FeedbackSubmission(
            message: 'e2e live feedback report with screenshot',
            appMetadata: _metadata,
            screenshotMime: 'image/png',
            screenshotBase64: _tinyPngBase64,
          ),
        );
        expect(withScreenshot.outcome, FeedbackOutcome.accepted);
        expect(await transport.status(withScreenshot.id!), FeedbackTriageState.queued);
      },
    );

    test('invalid and oversized submissions are rejected, never accepted', () async {
      final transport = HttpFeedbackTransport(baseUrl: baseUri);
      final blank = await transport.submit(
        const FeedbackSubmission(message: '   ', appMetadata: _metadata),
      );
      expect(blank.outcome, FeedbackOutcome.rejected);

      final oversized = await transport.submit(
        FeedbackSubmission(
          message: 'e2e oversized screenshot',
          appMetadata: _metadata,
          screenshotMime: 'image/png',
          // One byte past the server's 2 MiB base64 cap (413).
          screenshotBase64: 'A' * (2 * 1024 * 1024 + 1),
        ),
      );
      expect(oversized.outcome, FeedbackOutcome.rejected);
    });
  });
}
