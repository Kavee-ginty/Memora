import 'dart:convert';

import '../../auth/data/secure_auth_storage.dart';
import '../domain/profile_settings.dart';
import 'profile_repository.dart';

class ProfileCache {
  const ProfileCache(this.storage);

  final AppLocalStorage storage;

  /// Restore presentation-only settings while the same provider session is
  /// bootstrapping. Private profile data still requires a verified app owner.
  Future<AccessibilitySettings?> readStartupAccessibility(String userId) async {
    try {
      final data = await _read(userId);
      if (data == null) return null;
      final preferences = data['preferences'] as Map<String, dynamic>;
      return _accessibility(preferences);
    } catch (_) {
      await _discard(userId);
      return null;
    }
  }

  Future<Map<String, dynamic>?> _read(String userId) async {
    final raw = await storage.readProfileCache(userId);
    if (raw == null) return null;
    final data = jsonDecode(raw) as Map<String, dynamic>;
    if (data['schema'] != 1 || data['account'] != userId) {
      throw const FormatException('Incompatible settings cache');
    }
    return data;
  }

  static AccessibilitySettings _accessibility(Map<String, dynamic> settings) {
    final a = settings['accessibility'] as Map<String, dynamic>;
    return (
      reducedMotion: a['reducedMotion'] as bool,
      soundEnabled: a['soundEnabled'] as bool,
      hapticsEnabled: a['hapticsEnabled'] as bool,
      timerVisible: a['timerVisible'] as bool,
      highContrast: a['highContrast'] as bool,
    );
  }

  Future<ConfirmedSettings?> read(ProfileAccess access) async {
    final userId = access.session.userId;
    try {
      final data = await _read(userId);
      if (data == null) return null;
      if (data['owner'] != access.owner) {
        throw const FormatException('Incompatible settings cache');
      }
      final profile = data['profile'] as Map<String, dynamic>;
      final settings = data['preferences'] as Map<String, dynamic>;
      final limit = settings['dailyLimit'] as int;
      if (limit < 0 || limit > maxDailyReminders) {
        throw const FormatException('Invalid reminder limit');
      }
      return (
        profile: (
          version: _version(profile),
          fields: (
            displayName: profile['displayName'] as String,
            locale: profile['locale'] as String,
            timezone: profile['timezone'] as String,
          ),
        ),
        preferences: (
          version: _version(settings),
          fields: (
            notifications: (
              enabled: settings['enabled'] as bool,
              mission: settings['mission'] as bool,
              reward: settings['reward'] as bool,
              streak: settings['streak'] as bool,
              quiet: _readWindow(settings['quiet']),
              preferred: _readWindow(settings['preferred']),
              timezone: settings['timezone'] as String,
              dailyLimit: limit,
              preview: PreviewDetail.values.byName(
                settings['preview'] as String,
              ),
            ),
            accessibility: _accessibility(settings),
          ),
        ),
      );
    } catch (_) {
      await _discard(userId);
      return null;
    }
  }

  Future<void> _discard(String userId) async {
    try {
      await storage.clearProfileCache(userId);
    } catch (_) {
      // Treat inaccessible storage as an empty cache.
    }
  }

  Future<void> write(ProfileAccess access, ConfirmedSettings value) {
    final p = value.profile.fields;
    final n = value.preferences.fields.notifications;
    final a = value.preferences.fields.accessibility;
    return storage.writeProfileCache(
      access.session.userId,
      jsonEncode({
        'schema': 1,
        'account': access.session.userId,
        'owner': access.owner,
        'profile': {
          'version': value.profile.version,
          'displayName': p.displayName,
          'locale': p.locale,
          'timezone': p.timezone,
        },
        'preferences': {
          'version': value.preferences.version,
          'enabled': n.enabled,
          'mission': n.mission,
          'reward': n.reward,
          'streak': n.streak,
          'quiet': _encodeWindow(n.quiet),
          'preferred': _encodeWindow(n.preferred),
          'timezone': n.timezone,
          'dailyLimit': n.dailyLimit,
          'preview': n.preview.name,
          'accessibility': {
            'reducedMotion': a.reducedMotion,
            'soundEnabled': a.soundEnabled,
            'hapticsEnabled': a.hapticsEnabled,
            'timerVisible': a.timerVisible,
            'highContrast': a.highContrast,
          },
        },
      }),
    );
  }

  static int _version(Map<String, dynamic> data) {
    final version = data['version'] as int;
    if (version < 1) throw const FormatException('Invalid version');
    return version;
  }

  static List<String>? _encodeWindow(LocalWindow? value) =>
      value == null ? null : [value.start, value.end];

  static LocalWindow? _readWindow(Object? value) {
    if (value == null) return null;
    if (value case [String start, String end]) {
      final time = RegExp(r'^([01]\d|2[0-3]):[0-5]\d(:[0-5]\d(\.\d{1,6})?)?$');
      if (time.hasMatch(start) && time.hasMatch(end)) {
        return (start: start, end: end);
      }
    }
    throw const FormatException('Invalid time window');
  }
}
