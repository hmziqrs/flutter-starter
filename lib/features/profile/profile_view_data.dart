import 'package:flutter/foundation.dart';

@immutable
final class ProfileDraft {
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

  final String displayName;
  final String username;
  final String email;
  final String bio;

  ProfileDraft copyWith({
    String? displayName,
    String? username,
    String? email,
    String? bio,
  }) {
    return ProfileDraft(
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      email: email ?? this.email,
      bio: bio ?? this.bio,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ProfileDraft &&
            displayName == other.displayName &&
            username == other.username &&
            email == other.email &&
            bio == other.bio;
  }

  @override
  int get hashCode => Object.hash(displayName, username, email, bio);
}

enum ProfilePresentationPhase { idle, dirty, invalid, saving, saved, discardPrompt }

@immutable
final class ProfilePresentationState {
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

  final ProfilePresentationPhase phase;
  final ProfileDraft? draft;

  bool get isSaving => phase == ProfilePresentationPhase.saving;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ProfilePresentationState && phase == other.phase && draft == other.draft;
  }

  @override
  int get hashCode => Object.hash(phase, draft);
}
