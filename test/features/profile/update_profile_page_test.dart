import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/profile/profile_view_data.dart';
import 'package:starter/features/profile/update_profile_page.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/infrastructure/media/media_picker.dart';
import 'package:starter/infrastructure/media/noop_media_picker.dart';
import 'package:starter/infrastructure/permissions/noop_permission_service.dart';
import 'package:starter/infrastructure/permissions/permission_service.dart';
import 'package:starter/shared/adaptive/app_interaction_policy.dart';
import 'package:starter/shared/adaptive/app_presentation_policy.dart';
import 'package:starter/shared/theme/forui_theme_factory.dart';

void main() {
  testWidgets('avatar action runs the permission rationale flow deterministically', (tester) async {
    // permissions-media: tapping "Change profile image" now opens the
    // rationale sheet (always before the OS prompt). With the Noop permission
    // service, dismissing the sheet fires onAvatarPicked(null) — the honest
    // "denied / unavailable" surface. The flow never reaches a platform
    // channel; it stays deterministic for the test harness.
    var feedbackCount = 0;
    await _pumpProfile(
      tester,
      page: UpdateProfilePage(
        initialDraft: const ProfileDraft.defaults(),
        onSave: _noopSave,
        onAvatarPicked: (_) => feedbackCount += 1,
      ),
    );

    await tester.tap(find.byKey(const ValueKey('profile-avatar-feedback')));
    await tester.pumpAndSettle();
    // Rationale sheet is shown.
    expect(find.text('Photo library access'), findsOneWidget);

    // Dismiss via "Not now" → onAvatarPicked(null) fires.
    await tester.tap(find.byKey(const ValueKey('permission-rationale-dismiss')));
    await tester.pumpAndSettle();

    expect(feedbackCount, 1);
  });

  testWidgets('paints an opaque page surface and respects device insets', (tester) async {
    const safePadding = EdgeInsets.only(top: 59, bottom: 34);
    await _pumpProfile(
      tester,
      safePadding: safePadding,
      page: const UpdateProfilePage(
        initialDraft: ProfileDraft.defaults(),
        onSave: _noopSave,
        onAvatarPicked: _noopAvatar,
      ),
    );

    expect(find.byType(FScaffold), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Update profile')).dy,
      greaterThan(safePadding.top),
    );
  });

  testWidgets('invalid submit focuses and reveals the first visual error', (tester) async {
    await _pumpProfile(
      tester,
      page: const UpdateProfilePage(
        initialDraft: ProfileDraft.defaults(),
        onSave: _noopSave,
        onAvatarPicked: _noopAvatar,
      ),
    );

    await tester.enterText(find.byKey(const ValueKey('profile-display-name')), '');
    await tester.enterText(find.byKey(const ValueKey('profile-username')), 'bad space');
    await _tapSave(tester);

    final displayNameField = tester.widget<FTextFormField>(
      find.byKey(const ValueKey('profile-display-name')),
    );
    expect(displayNameField.focusNode?.hasFocus, isTrue);
    expect(find.text('Display name is required.'), findsOneWidget);
    expect(find.text('Use 3–24 letters, numbers, periods, or underscores.'), findsOneWidget);
  });

  testWidgets('bio counts grapheme clusters and Enter never submits it', (tester) async {
    var saveCount = 0;
    await _pumpProfile(
      tester,
      page: UpdateProfilePage(
        initialDraft: const ProfileDraft.defaults(),
        onSave: (_) => saveCount += 1,
        onAvatarPicked: _noopAvatar,
      ),
    );

    final bio = find.byKey(const ValueKey('profile-bio'));
    await tester.enterText(bio, '👨‍👩‍👧‍👦');
    await tester.pump();
    expect(find.text('1 of 160 characters'), findsOneWidget);

    await tester.showKeyboard(bio);
    await tester.testTextInput.receiveAction(TextInputAction.newline);
    await tester.pump();
    expect(saveCount, 0);
  });

  testWidgets('save exposes progress, normalizes typed values, and retains edits', (tester) async {
    final completion = Completer<void>();
    ProfileDraft? submitted;
    await _pumpProfile(
      tester,
      page: UpdateProfilePage(
        initialDraft: const ProfileDraft.defaults(),
        onSave: (draft) {
          submitted = draft;
          return completion.future;
        },
        onAvatarPicked: _noopAvatar,
      ),
    );

    await tester.enterText(find.byKey(const ValueKey('profile-display-name')), '  Sam Rivera  ');
    await tester.enterText(find.byKey(const ValueKey('profile-username')), 'Sam.User');
    await tester.enterText(find.byKey(const ValueKey('profile-bio')), '  A short bio.  ');
    await _tapSave(tester, settle: false);

    expect(find.text('Saving profile'), findsOneWidget);
    expect(submitted?.displayName, 'Sam Rivera');
    expect(submitted?.username, 'sam.user');
    expect(submitted?.bio, 'A short bio.');

    completion.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('profile-saved')), findsOneWidget);
    expect(_fieldText(tester, 'profile-display-name'), 'Sam Rivera');
    expect(_fieldText(tester, 'profile-username'), 'sam.user');
    expect(_fieldText(tester, 'profile-bio'), 'A short bio.');
  });

  testWidgets('TV save retains a visible focus target while in flight', (
    tester,
  ) async {
    final completion = Completer<void>();
    await _pumpProfile(
      tester,
      presentationPolicy: const AppPresentationPolicy(
        viewingEnvironment: AppViewingEnvironment.tenFoot,
        interactionPolicy: AppInteractionPolicy.remote,
      ),
      page: UpdateProfilePage(
        initialDraft: const ProfileDraft.defaults(),
        onSave: (_) => completion.future,
        onAvatarPicked: _noopAvatar,
      ),
    );

    await _tapSave(tester, settle: false);
    expect(
      _focusIsWithin(tester, 'profile-save'),
      isTrue,
      reason: FocusManager.instance.primaryFocus?.toStringDeep(),
    );

    completion.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('resize preserves draft values and adds an expanded preview', (tester) async {
    await _pumpProfile(
      tester,
      page: const UpdateProfilePage(
        initialDraft: ProfileDraft.defaults(),
        onSave: _noopSave,
        onAvatarPicked: _noopAvatar,
      ),
    );
    final displayName = find.byKey(const ValueKey('profile-display-name'));
    await tester.enterText(displayName, 'Resize Survivor');
    await tester.showKeyboard(displayName);
    expect(
      tester.widget<FTextFormField>(displayName).focusNode?.hasFocus,
      isTrue,
    );
    expect(find.byKey(const ValueKey('profile-layout-compact')), findsOneWidget);

    tester.view.physicalSize = const Size(1200, 900);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('profile-layout-expanded')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-preview')), findsOneWidget);
    expect(
      tester.widget<FTextFormField>(displayName).focusNode?.hasFocus,
      isTrue,
    );
    expect(_fieldText(tester, 'profile-display-name'), 'Resize Survivor');
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('profile-preview-name'))).data,
      'Resize Survivor',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('dirty Back asks to keep editing or discard typed values', (tester) async {
    await _pumpProfile(
      tester,
      page: const UpdateProfilePage(
        initialDraft: ProfileDraft.defaults(),
        onSave: _noopSave,
        onAvatarPicked: _noopAvatar,
      ),
    );
    await tester.enterText(find.byKey(const ValueKey('profile-display-name')), 'Unsaved name');
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('profile-discard-dialog')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('profile-keep-editing')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('profile-save')), findsOneWidget);
    expect(_fieldText(tester, 'profile-display-name'), 'Unsaved name');

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('profile-discard-changes')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('profile-test-home')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-save')), findsNothing);
  });

  testWidgets('injected saving and saved fixtures render production states', (tester) async {
    await _pumpProfile(
      tester,
      settle: false,
      page: const UpdateProfilePage(
        initialDraft: ProfileDraft.defaults(),
        presentationState: ProfilePresentationState.saving(),
        onSave: _noopSave,
        onAvatarPicked: _noopAvatar,
      ),
    );
    expect(find.text('Saving profile'), findsOneWidget);

    await _pumpProfile(
      tester,
      page: const UpdateProfilePage(
        initialDraft: ProfileDraft.defaults(),
        presentationState: ProfilePresentationState.saved(),
        onSave: _noopSave,
        onAvatarPicked: _noopAvatar,
      ),
    );
    await tester.ensureVisible(find.byKey(const ValueKey('profile-saved')));
    expect(find.byKey(const ValueKey('profile-saved')), findsOneWidget);
  });
}

Future<void> _pumpProfile(
  WidgetTester tester, {
  required UpdateProfilePage page,
  Size size = const Size(390, 900),
  bool settle = true,
  EdgeInsets safePadding = EdgeInsets.zero,
  AppPresentationPolicy presentationPolicy = const AppPresentationPolicy(
    viewingEnvironment: AppViewingEnvironment.nearField,
    interactionPolicy: AppInteractionPolicy.touch,
  ),
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await LocaleSettings.setLocale(AppLocale.en);

  final theme = ForuiThemeFactory.build(
    brightness: Brightness.light,
    accent: AppAccent.neutral,
    fontScale: 1,
    interactionPolicy: presentationPolicy.interactionPolicy,
    presentationPolicy: presentationPolicy,
  );
  await tester.pumpWidget(
    ProviderScope(
      // permissions-media: the avatar flow reads the permission + media
      // providers via `ProviderScope.containerOf`. Override both with the
      // Noop defaults so the flow surfaces an honest `null` (denied / no
      // pick) without reaching a platform channel.
      overrides: [
        permissionServiceProvider.overrideWithValue(const NoopPermissionService()),
        mediaPickerProvider.overrideWithValue(const NoopMediaPicker()),
      ],
      child: TranslationProvider(
        child: MaterialApp(
          key: ValueKey(page.presentationState.phase),
          initialRoute: '/profile',
          routes: {
            '/': (_) => const SizedBox(key: ValueKey('profile-test-home')),
            '/profile': (_) => page,
          },
          locale: AppLocale.en.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: FLocalizations.localizationsDelegates,
          theme: theme.toApproximateMaterialTheme(),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: safePadding,
                viewPadding: safePadding,
              ),
              child: AppPresentationScope(
                policy: presentationPolicy,
                child: FTheme(
                  data: theme,
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }
}

Future<void> _tapSave(WidgetTester tester, {bool settle = true}) async {
  final save = find.byKey(const ValueKey('profile-save'));
  final layout = find.byKey(const ValueKey('profile-layout-compact'));
  await tester.drag(layout, const Offset(0, -600));
  await tester.pumpAndSettle();
  await tester.tap(save);
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

String _fieldText(WidgetTester tester, String key) {
  final editable = find.descendant(
    of: find.byKey(ValueKey(key)),
    matching: find.byType(EditableText),
  );
  return tester.widget<EditableText>(editable).controller.text;
}

bool _focusIsWithin(WidgetTester tester, String key) {
  final focusContext = FocusManager.instance.primaryFocus?.context;
  if (focusContext is! Element) {
    return false;
  }
  final target = tester.element(find.byKey(ValueKey(key)));
  if (identical(focusContext, target)) {
    return true;
  }
  var found = false;
  focusContext.visitAncestorElements((ancestor) {
    if (identical(ancestor, target)) {
      found = true;
      return false;
    }
    return true;
  });
  return found;
}

Future<void> _noopSave(ProfileDraft _) async {}

void _noopAvatar(PickedMedia? _) {}
