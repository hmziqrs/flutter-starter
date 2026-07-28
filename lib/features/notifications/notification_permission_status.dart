// Doc cross-references to sibling-class names in the feature package are
// intentional `comment_references`.
// ignore_for_file: comment_references

/// App-owned notification authorization state, abstracted away from the raw
/// plugin authorization levels reported by `firebase_messaging` /
/// `flutter_local_notifications`.
///
/// The notifications controller and the in-app permission rationale switch on
/// this enum — never on the plugin's `AuthorizationStatus` types — so the
/// surface stays stable as the plugins grow new values. Each new plugin value
/// is a compile error in [fromAuthorization] until it is deliberately
/// classified here.
enum NotificationPermissionStatus {
  /// The user has never been asked. The first call to
  /// `NotificationsRepository.requestPermission` should surface the system
  /// prompt (real adapter) or degrade to [denied] (Noop default).
  notRequested,

  /// Authorization was granted. Messages render in the foreground (banner) and
  /// are delivered to the system tray; the token may be registered with the
  /// backend.
  granted,

  /// iOS-only *provisional* authorization: messages are delivered quietly to
  /// the notification center but never audibly alert. Treated as "soft-granted"
  /// for the registration path but surfaced distinctly on the rationale sheet
  /// so the user understands alerts are silent until they explicitly promote
  /// them.
  provisional,

  /// The user explicitly denied authorization, OR the OS has notifications
  /// disabled at the app level. The rationale sheet offers the "open Settings"
  /// CTA in this state. The Noop production default reports [denied] honestly
  /// so the rationale copy matches what a real device shows.
  denied,
  ;

  /// Whether the app may register a token and post local notifications. Only
  /// [granted] and [provisional] authorize delivery; [provisional] is silent.
  bool get canDeliver =>
      this == NotificationPermissionStatus.granted ||
      this == NotificationPermissionStatus.provisional;

  /// Whether the rationale sheet should show the "open system settings" CTA
  /// (true only after an explicit denial — never on the first run).
  bool get showsOpenSettings => this == NotificationPermissionStatus.denied;
}
