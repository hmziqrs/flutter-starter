import 'package:flutter_test/flutter_test.dart';
import 'package:starter/features/profile/profile_view_data.dart';

void main() {
  test('ProfileDraft is immutable by value and supports typed copies', () {
    const draft = ProfileDraft.defaults();
    final edited = draft.copyWith(displayName: 'Sam', username: 'SAM.User');

    expect(edited.displayName, 'Sam');
    expect(edited.username, 'SAM.User');
    expect(edited.email, draft.email);
    expect(draft, const ProfileDraft.defaults());
  });

  test('ProfilePresentationState names every deterministic screen state', () {
    const draft = ProfileDraft.defaults();
    const states = [
      ProfilePresentationState.defaults(),
      ProfilePresentationState.dirty(draft: draft),
      ProfilePresentationState.invalid(draft: draft),
      ProfilePresentationState.saving(draft: draft),
      ProfilePresentationState.saved(draft: draft),
      ProfilePresentationState.discardPrompt(draft: draft),
    ];

    expect(states.map((state) => state.phase), ProfilePresentationPhase.values);
    expect(states.singleWhere((state) => state.isSaving).phase, ProfilePresentationPhase.saving);
  });
}
