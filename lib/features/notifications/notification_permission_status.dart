/// App-owned notification authorization state, abstracted away from the raw
/// plugin authorization levels reported by `firebase_messaging` /
/// `flutter_local_notifications`. The controller and rationale UI switch on
/// this enum, never on the plugin's `AuthorizationStatus` types.
enum NotificationPermissionStatus {
  /// The user has never been asked.
  notRequested,

  /// Authorization was granted; messages render in the foreground / tray and
  /// the token may be registered with the backend.
  granted,

  /// iOS-only provisional authorization: messages are delivered quietly to
  /// the notification center but never audibly alert.
  provisional,

  /// The user explicitly denied authorization, or the OS has notifications
  /// disabled at the app level. The rationale sheet offers "open Settings"
  /// here.
  denied,
  ;

  /// Whether the app may register a token and post local notifications. Only
  /// [granted] and [provisional] authorize delivery; [provisional] is silent.
  bool get canDeliver =>
      this == NotificationPermissionStatus.granted ||
      this == NotificationPermissionStatus.provisional;

  /// Whether the rationale sheet should show the "open system settings" CTA.
  bool get showsOpenSettings => this == NotificationPermissionStatus.denied;
}
