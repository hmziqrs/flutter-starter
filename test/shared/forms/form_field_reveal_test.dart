import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:starter/i18n/translations.g.dart';
import 'package:starter/shared/forms/form_field_reveal.dart';
import 'package:starter/shared/theme/generated_forui_theme.dart' as generated;

void main() {
  group('revealFirstInvalid', () {
    testWidgets('focuses the first invalid field in explicit visual order', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final key1 = GlobalKey<FormFieldState<Object?>>();
      final key2 = GlobalKey<FormFieldState<Object?>>();
      final key3 = GlobalKey<FormFieldState<Object?>>();
      final focus1 = FocusNode(debugLabel: 'field-1');
      final focus2 = FocusNode(debugLabel: 'field-2');
      final focus3 = FocusNode(debugLabel: 'field-3');

      await tester.pumpWidget(
        _harness(
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  _RevealField(
                    key: key1,
                    focusNode: focus1,
                    label: 'field-1',
                  ),
                  _RevealField(
                    key: key2,
                    focusNode: focus2,
                    label: 'field-2',
                  ),
                  _RevealField(
                    key: key3,
                    focusNode: focus3,
                    label: 'field-3',
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final invalid = <FormFieldState<Object?>>{key2.currentState!};
      await revealFirstInvalid(
        invalid,
        orderedTargets: [
          (
            field: key1.currentState,
            context: key1.currentContext,
            focusNode: focus1,
          ),
          (
            field: key2.currentState,
            context: key2.currentContext,
            focusNode: focus2,
          ),
          (
            field: key3.currentState,
            context: key3.currentContext,
            focusNode: focus3,
          ),
        ],
        isMounted: () => true,
      );
      await tester.pump(Duration.zero);

      expect(focus2.hasFocus, isTrue);
      expect(focus1.hasFocus, isFalse);
      expect(focus3.hasFocus, isFalse);

      focus1.dispose();
      focus2.dispose();
      focus3.dispose();
    });

    testWidgets('when several fields are invalid, reveals the earliest one', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final key1 = GlobalKey<FormFieldState<Object?>>();
      final key2 = GlobalKey<FormFieldState<Object?>>();
      final key3 = GlobalKey<FormFieldState<Object?>>();
      final focus1 = FocusNode(debugLabel: 'field-1');
      final focus2 = FocusNode(debugLabel: 'field-2');
      final focus3 = FocusNode(debugLabel: 'field-3');

      await tester.pumpWidget(
        _harness(
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  _RevealField(key: key1, focusNode: focus1, label: 'field-1'),
                  _RevealField(key: key2, focusNode: focus2, label: 'field-2'),
                  _RevealField(key: key3, focusNode: focus3, label: 'field-3'),
                ],
              ),
            ),
          ),
        ),
      );

      final invalid = <FormFieldState<Object?>>{
        key1.currentState!,
        key3.currentState!,
      };
      await revealFirstInvalid(
        invalid,
        orderedTargets: [
          (
            field: key1.currentState,
            context: key1.currentContext,
            focusNode: focus1,
          ),
          (
            field: key2.currentState,
            context: key2.currentContext,
            focusNode: focus2,
          ),
          (
            field: key3.currentState,
            context: key3.currentContext,
            focusNode: focus3,
          ),
        ],
        isMounted: () => true,
      );
      await tester.pump(Duration.zero);

      expect(focus1.hasFocus, isTrue);
      expect(focus3.hasFocus, isFalse);

      focus1.dispose();
      focus2.dispose();
      focus3.dispose();
    });

    testWidgets('does nothing when no target field is invalid', (tester) async {
      final formKey = GlobalKey<FormState>();
      final key1 = GlobalKey<FormFieldState<Object?>>();
      final focus1 = FocusNode(debugLabel: 'field-1');

      await tester.pumpWidget(
        _harness(
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  _RevealField(key: key1, focusNode: focus1, label: 'field-1'),
                ],
              ),
            ),
          ),
        ),
      );

      await revealFirstInvalid(
        <FormFieldState<Object?>>{},
        orderedTargets: [
          (
            field: key1.currentState,
            context: key1.currentContext,
            focusNode: focus1,
          ),
        ],
        isMounted: () => true,
      );
      await tester.pump(Duration.zero);

      expect(focus1.hasFocus, isFalse);
      focus1.dispose();
    });

    testWidgets('skips targets whose field state is not yet mounted', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final key1 = GlobalKey<FormFieldState<Object?>>();
      final key2 = GlobalKey<FormFieldState<Object?>>();
      final focus1 = FocusNode(debugLabel: 'field-1');
      final focus2 = FocusNode(debugLabel: 'field-2');

      await tester.pumpWidget(
        _harness(
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  _RevealField(key: key1, focusNode: focus1, label: 'field-1'),
                  _RevealField(key: key2, focusNode: focus2, label: 'field-2'),
                ],
              ),
            ),
          ),
        ),
      );

      final invalid = <FormFieldState<Object?>>{key2.currentState!};
      await revealFirstInvalid(
        invalid,
        orderedTargets: [
          (field: null, context: key1.currentContext, focusNode: focus1),
          (
            field: key2.currentState,
            context: key2.currentContext,
            focusNode: focus2,
          ),
        ],
        isMounted: () => true,
      );
      await tester.pump(Duration.zero);

      expect(focus2.hasFocus, isTrue);
      expect(focus1.hasFocus, isFalse);

      focus1.dispose();
      focus2.dispose();
    });

    testWidgets('does not request focus when isMounted reports false', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      final key1 = GlobalKey<FormFieldState<Object?>>();
      final focus1 = FocusNode(debugLabel: 'field-1');

      await tester.pumpWidget(
        _harness(
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  _RevealField(key: key1, focusNode: focus1, label: 'field-1'),
                ],
              ),
            ),
          ),
        ),
      );

      await revealFirstInvalid(
        <FormFieldState<Object?>>{key1.currentState!},
        orderedTargets: [
          (
            field: key1.currentState,
            context: key1.currentContext,
            focusNode: focus1,
          ),
        ],
        isMounted: () => false,
      );
      await tester.pump(Duration.zero);

      expect(focus1.hasFocus, isFalse);
      focus1.dispose();
    });
  });
}

class _RevealField extends FormField<Object?> {
  _RevealField({
    required FocusNode focusNode,
    required String label,
    super.key,
  }) : super(
         initialValue: null,
         builder: (state) => Focus(
           focusNode: focusNode,
           child: Container(
             height: 240,
             alignment: Alignment.center,
             child: Text(label),
           ),
         ),
       );
}

Widget _harness({required Widget child}) {
  return TranslationProvider(
    child: Builder(
      builder: (context) {
        final localeData = TranslationProvider.of(context);
        final theme = generated.lightTheme;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: localeData.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: FLocalizations.localizationsDelegates,
          theme: theme.toApproximateMaterialTheme(),
          home: Scaffold(body: child),
          builder: (context, built) => FTheme(
            data: theme,
            child: FToaster(child: FTooltipGroup(child: built ?? const SizedBox.shrink())),
          ),
        );
      },
    ),
  );
}
