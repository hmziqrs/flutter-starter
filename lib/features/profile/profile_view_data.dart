import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_view_data.freezed.dart';

@freezed
class ProfileDraft with _$ProfileDraft {
  const ProfileDraft({
    required this.displayName,
    required this.username,
    required this.email,
    required this.bio,
  });

  const ProfileDraft.defaults()
    : displayName = 'Alex Morgan',
      username = 'alex.morgan',
      email = 'alex@example.com',
      bio = 'Building a thoughtful foundation for the next product.';

  @override
  final String displayName;
  @override
  final String username;
  @override
  final String email;
  @override
  final String bio;
}

enum ProfilePresentationPhase { idle, dirty, invalid, saving, saved, discardPrompt }

@freezed
class ProfilePresentationState with _$ProfilePresentationState {
  const ProfilePresentationState._({required this.phase, this.draft});

  const ProfilePresentationState.defaults({ProfileDraft? draft})
    : this._(phase: ProfilePresentationPhase.idle, draft: draft);

  const ProfilePresentationState.dirty({required ProfileDraft draft})
    : this._(phase: ProfilePresentationPhase.dirty, draft: draft);

  const ProfilePresentationState.invalid({required ProfileDraft draft})
    : this._(phase: ProfilePresentationPhase.invalid, draft: draft);

  const ProfilePresentationState.saving({ProfileDraft? draft})
    : this._(phase: ProfilePresentationPhase.saving, draft: draft);

  const ProfilePresentationState.saved({ProfileDraft? draft})
    : this._(phase: ProfilePresentationPhase.saved, draft: draft);

  const ProfilePresentationState.discardPrompt({required ProfileDraft draft})
    : this._(phase: ProfilePresentationPhase.discardPrompt, draft: draft);

  @override
  final ProfilePresentationPhase phase;
  @override
  final ProfileDraft? draft;

  bool get isSaving => phase == ProfilePresentationPhase.saving;
}
