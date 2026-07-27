import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter/shared/adaptive/app_interaction_policy.dart';
import 'package:starter/shared/adaptive/app_presentation_policy.dart';

void main() {
  test('reports ten-foot and directional-focus semantics independently', () {
    const nearFieldKeyboard = AppPresentationPolicy(
      viewingEnvironment: AppViewingEnvironment.nearField,
      interactionPolicy: AppInteractionPolicy.precisionPointer,
    );
    const tenFootRemote = AppPresentationPolicy(
      viewingEnvironment: AppViewingEnvironment.tenFoot,
      interactionPolicy: AppInteractionPolicy.remote,
    );
    const tenFootHybridRemote = AppPresentationPolicy(
      viewingEnvironment: AppViewingEnvironment.tenFoot,
      interactionPolicy: AppInteractionPolicy.hybridRemote,
    );

    expect(nearFieldKeyboard.isTenFoot, isFalse);
    expect(nearFieldKeyboard.usesDirectionalFocus, isFalse);
    expect(tenFootRemote.isTenFoot, isTrue);
    expect(tenFootRemote.usesDirectionalFocus, isTrue);
    expect(tenFootHybridRemote.usesDirectionalFocus, isTrue);
  });

  test('compares immutable policies by value', () {
    const first = AppPresentationPolicy(
      viewingEnvironment: AppViewingEnvironment.tenFoot,
      interactionPolicy: AppInteractionPolicy.remote,
    );
    const second = AppPresentationPolicy(
      viewingEnvironment: AppViewingEnvironment.tenFoot,
      interactionPolicy: AppInteractionPolicy.remote,
    );
    const different = AppPresentationPolicy(
      viewingEnvironment: AppViewingEnvironment.nearField,
      interactionPolicy: AppInteractionPolicy.remote,
    );

    expect(first, second);
    expect(first.hashCode, second.hashCode);
    expect(first, isNot(different));
  });

  testWidgets('scope exposes and updates the current policy', (tester) async {
    const nearField = AppPresentationPolicy(
      viewingEnvironment: AppViewingEnvironment.nearField,
      interactionPolicy: AppInteractionPolicy.touch,
    );
    const tenFoot = AppPresentationPolicy(
      viewingEnvironment: AppViewingEnvironment.tenFoot,
      interactionPolicy: AppInteractionPolicy.remote,
    );

    await tester.pumpWidget(const _PolicyHarness(policy: nearField));
    expect(find.text('nearField:touch:false'), findsOneWidget);

    await tester.pumpWidget(const _PolicyHarness(policy: tenFoot));
    expect(find.text('tenFoot:remote:true'), findsOneWidget);
  });

  testWidgets('reading policy without a scope reports the composition error', (
    tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (context) {
            AppPresentationPolicy.of(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(tester.takeException(), isA<FlutterError>());
  });
}

class _PolicyHarness extends StatelessWidget {
  const _PolicyHarness({required this.policy});

  final AppPresentationPolicy policy;

  @override
  Widget build(BuildContext context) {
    return AppPresentationScope(
      policy: policy,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (context) {
            final policy = AppPresentationPolicy.of(context);
            return Text(
              '${policy.viewingEnvironment.name}:'
              '${policy.interactionPolicy.name}:'
              '${policy.usesDirectionalFocus}',
            );
          },
        ),
      ),
    );
  }
}
