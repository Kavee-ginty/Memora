/// Confirmed values and editable values are kept separately by the controller.
typedef ProfileFields = ({String displayName, String locale, String timezone});
typedef Profile = ({ProfileFields fields, int version});
typedef LocalWindow = ({String start, String end});
typedef AccessibilitySettings = ({
  bool reducedMotion,
  bool soundEnabled,
  bool hapticsEnabled,
  bool timerVisible,
  bool highContrast,
});
typedef NotificationSettings = ({
  bool enabled,
  bool mission,
  bool reward,
  bool streak,
  LocalWindow? quiet,
  LocalWindow? preferred,
  String timezone,
  PreviewDetail preview,
  int dailyLimit,
});
typedef PreferenceFields = ({
  NotificationSettings notifications,
  AccessibilitySettings accessibility,
});
typedef Preferences = ({PreferenceFields fields, int version});
typedef ConfirmedSettings = ({Profile profile, Preferences preferences});

enum PreviewDetail { minimal, subject, detailed, unknown }

// The maximum specified by the T17 preference contract.
const maxDailyReminders = 3;

class ProfileFailure implements Exception {
  final String code;
  final String message;
  final bool retryable;
  final Duration? retryAfter;
  final Set<String> fields;

  const ProfileFailure(
    this.code,
    this.message, {
    this.retryable = false,
    this.retryAfter,
    this.fields = const {},
  });
}
