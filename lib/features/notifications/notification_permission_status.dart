enum NotificationPermissionStatus {
  notRequested,

  granted,

  provisional,

  denied,
  ;

  bool get canDeliver =>
      this == NotificationPermissionStatus.granted ||
      this == NotificationPermissionStatus.provisional;

  bool get showsOpenSettings => this == NotificationPermissionStatus.denied;
}
