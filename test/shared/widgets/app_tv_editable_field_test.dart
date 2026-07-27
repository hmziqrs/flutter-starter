import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/features/settings/settings_state.dart';
import 'package:starter/shared/adaptive/app_interaction_policy.dart';
import 'package:starter/shared/adaptive/app_presentation_policy.dart';
import 'package:starter/shared/theme/forui_theme_factory.dart';
import 'package:starter/shared/widgets/app_tv_editable_field.dart';

void main() {
  late TextEditingController controller;
  late FocusNode logicalFocusNode;

  setUp(() {
    controller = TextEditingController();
    logicalFocusNode = FocusNode(debugLabel: 'test.logical-field');
  });

  tearDown(() {
    controller.dispose();
    logicalFocusNode.dispose();
  });

  testWidgets('near-field builds the real field directly', (tester) async {
    await _pumpField(
      tester,
      policy: _nearFieldPolicy,
      controller: controller,
      logicalFocusNode: logicalFocusNode,
    );

    expect(find.byKey(_activationKey), findsNothing);
    expect(find.byKey(_editorKey), findsOneWidget);
    expect(
      tester.widget<FTextFormField>(find.byKey(_editorKey)).focusNode,
      same(logicalFocusNode),
    );
  });

  testWidgets('TV Select enters editing and Escape restores activation focus', (tester) async {
    await _pumpField(
      tester,
      policy: _tenFootPolicy,
      controller: controller,
      logicalFocusNode: logicalFocusNode,
      autofocus: true,
    );

    expect(find.byKey(_activationKey), findsOneWidget);
    expect(find.byKey(_editorKey), findsNothing);
    expect(FocusManager.instance.primaryFocus, same(logicalFocusNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(find.byKey(_activationKey), findsNothing);
    expect(find.byKey(_editorKey), findsOneWidget);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'app-tv-editable-field.editor');

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(find.byKey(_activationKey), findsOneWidget);
    expect(find.byKey(_editorKey), findsNothing);
    expect(FocusManager.instance.primaryFocus, same(logicalFocusNode));
  });

  testWidgets('TV Done preserves the controller and returns to activation', (tester) async {
    await _pumpField(
      tester,
      policy: _tenFootPolicy,
      controller: controller,
      logicalFocusNode: logicalFocusNode,
      autofocus: true,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.enterText(find.byKey(_editorKey), 'viewer@example.com');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(controller.text, 'viewer@example.com');
    expect(find.byKey(_activationKey), findsOneWidget);
    expect(find.text('viewer@example.com'), findsOneWidget);
    expect(FocusManager.instance.primaryFocus, same(logicalFocusNode));
  });

  testWidgets('secure TV summary never exposes the value or its length', (tester) async {
    controller.text = 's3cr3t-with-variable-length';
    final semantics = tester.ensureSemantics();
    await _pumpField(
      tester,
      policy: _tenFootPolicy,
      controller: controller,
      logicalFocusNode: logicalFocusNode,
      secure: true,
    );

    expect(find.text(controller.text), findsNothing);
    expect(find.text('••••••••'), findsOneWidget);
    final node = tester.getSemantics(find.bySemanticsLabel('Password'));
    expect(node.value, '••••••••');
    expect(node.value, isNot(contains(controller.text)));

    semantics.dispose();
  });

  testWidgets('TV summary keeps the real form field registered for validation', (tester) async {
    final formKey = GlobalKey<FormState>();
    await _pumpField(
      tester,
      policy: _tenFootPolicy,
      controller: controller,
      logicalFocusNode: logicalFocusNode,
      formKey: formKey,
    );

    expect(find.byKey(_editorKey), findsNothing);
    expect(formKey.currentState, isNotNull);
    expect(formKey.currentState!.validate(), isFalse);
  });
}

Future<void> _pumpField(
  WidgetTester tester, {
  required AppPresentationPolicy policy,
  required TextEditingController controller,
  required FocusNode logicalFocusNode,
  bool secure = false,
  bool autofocus = false,
  GlobalKey<FormState>? formKey,
}) async {
  final theme = ForuiThemeFactory.build(
    brightness: Brightness.light,
    accent: AppAccent.neutral,
    fontScale: 1,
    interactionPolicy: policy.interactionPolicy,
    presentationPolicy: policy,
  );

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: FLocalizations.localizationsDelegates,
      theme: theme.toApproximateMaterialTheme(),
      home: AppPresentationScope(
        policy: policy,
        child: FTheme(
          data: theme,
          accessibility: FAccessibility(
            accessibleNavigation: false,
            motion: FAccessibilityMotion.all,
            focusHighlight: policy.usesDirectionalFocus,
          ),
          child: Scaffold(
            body: Form(
              key: formKey,
              child: AppTvEditableField(
                activationKey: _activationKey,
                label: 'Password',
                controller: controller,
                focusNode: logicalFocusNode,
                secure: secure,
                autofocus: autofocus,
                builder: (context, editorFocusNode, completeEditing) {
                  return FTextFormField(
                    key: _editorKey,
                    control: .managed(controller: controller),
                    focusNode: editorFocusNode,
                    label: const Text('Password'),
                    textInputAction: TextInputAction.done,
                    validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    onSubmit: (_) => completeEditing(),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const ValueKey<String> _activationKey = ValueKey('test-tv-editable-activation');
const ValueKey<String> _editorKey = ValueKey('test-tv-editable-editor');

const _tenFootPolicy = AppPresentationPolicy(
  viewingEnvironment: AppViewingEnvironment.tenFoot,
  interactionPolicy: AppInteractionPolicy.remote,
);

const _nearFieldPolicy = AppPresentationPolicy(
  viewingEnvironment: AppViewingEnvironment.nearField,
  interactionPolicy: AppInteractionPolicy.touch,
);
