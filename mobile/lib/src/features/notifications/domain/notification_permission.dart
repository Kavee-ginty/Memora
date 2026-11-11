/// OS-level push permission state, normalized across platforms.
enum NotificationPermission {
  /// The user allowed notifications; token registration may proceed.
  granted,

  /// The user declined notifications. Denial never blocks app use; the
  /// registration flow stays silent (T17 gate carried forward).
  denied,

  /// The user has not been asked yet.
  notDetermined,

  /// The push provider is unavailable on this installation (for example
  /// Firebase without platform configuration, or an unsupported target).
  unavailable,
}
