import 'package:dio/dio.dart';
import 'package:memora_api_client/memora_api_client.dart';

import '../../../configuration/app_configuration.dart';
import '../../auth/data/api_error_mapper.dart';
import '../../auth/domain/app_session_state.dart';
import '../../common/ids.dart';
import '../domain/profile_settings.dart';

typedef ProfileAccess = ({AuthSession session, String owner});

abstract interface class ProfileRepository {
  Future<ConfirmedSettings> load(ProfileAccess access);
  Future<Profile> saveProfile(
    ProfileAccess access,
    Profile before,
    ProfileFields draft,
    String key,
  );
  Future<Preferences> savePreferences(
    ProfileAccess access,
    Preferences before,
    PreferenceFields draft,
    String key,
  );
}

class MemoraProfileRepository implements ProfileRepository {
  const MemoraProfileRepository(this.api, this.config, this.refresh);

  final ProfileApi api;
  final AppConfiguration config;
  final Future<AuthSession?> Function(AuthSession) refresh;

  // The Profile client uses request-local credentials so overlapping requests
  // cannot pick up a different account's bearer token.
  Map<String, dynamic> _headers(String token) => {
    'Authorization': 'Bearer $token',
  };

  @override
  Future<ConfirmedSettings> load(ProfileAccess access) => _execute(access, (
    token,
  ) async {
    final profile = await api.getProfile(
      xCorrelationID: generateUuid(),
      xClientVersion: config.clientVersion,
      xPlatform: config.platform,
      headers: _headers(token),
    );
    final confirmed = _profile(profile.data, access.owner);
    final preferences = await api.getProfilePreferences(
      xCorrelationID: generateUuid(),
      xClientVersion: config.clientVersion,
      xPlatform: config.platform,
      headers: _headers(token),
    );
    return (profile: confirmed, preferences: _preferences(preferences.data));
  });

  @override
  Future<Profile> saveProfile(
    ProfileAccess access,
    Profile before,
    ProfileFields draft,
    String key,
  ) => _execute(access, (token) async {
    final response = await api.updateProfile(
      xCorrelationID: generateUuid(),
      xClientVersion: config.clientVersion,
      xPlatform: config.platform,
      headers: _headers(token),
      idempotencyKey: key,
      profileUpdateRequest: ProfileUpdateRequest((b) {
        b.version = before.version;
        if (before.fields.displayName != draft.displayName) {
          b.displayName = Optional.present(draft.displayName);
        }
        if (before.fields.locale != draft.locale) {
          b.locale = Optional.present(draft.locale);
        }
        if (before.fields.timezone != draft.timezone) {
          b.timezone = Optional.present(draft.timezone);
        }
      }),
    );
    return _profile(response.data, access.owner);
  });

  @override
  Future<Preferences> savePreferences(
    ProfileAccess access,
    Preferences before,
    PreferenceFields draft,
    String key,
  ) => _execute(access, (token) async {
    final old = before.fields.notifications;
    final next = draft.notifications;
    final accessibility = draft.accessibility;
    final response = await api.updateProfilePreferences(
      xCorrelationID: generateUuid(),
      xClientVersion: config.clientVersion,
      xPlatform: config.platform,
      headers: _headers(token),
      idempotencyKey: key,
      profilePreferencesUpdateRequest: ProfilePreferencesUpdateRequest((b) {
        b.version = before.version;
        if (old.enabled != next.enabled) {
          b.notificationsEnabled = Optional.present(next.enabled);
        }
        if (old.mission != next.mission) {
          b.missionEnabled = Optional.present(next.mission);
        }
        if (old.reward != next.reward) {
          b.rewardEnabled = Optional.present(next.reward);
        }
        if (old.streak != next.streak) {
          b.streakEnabled = Optional.present(next.streak);
        }
        if (old.timezone != next.timezone) {
          b.timezone = Optional.present(next.timezone);
        }
        if (old.preview != next.preview) {
          b.lockScreenDetail = Optional.present(next.preview.name);
        }
        if (old.dailyLimit != next.dailyLimit) {
          b.maxDailyReminders = Optional.present(next.dailyLimit);
        }
        if (old.quiet != next.quiet) {
          b.quietStartLocal = Optional.present(next.quiet?.start);
          b.quietEndLocal = Optional.present(next.quiet?.end);
        }
        if (old.preferred != next.preferred) {
          b.preferredWindowStartLocal = Optional.present(next.preferred?.start);
          b.preferredWindowEndLocal = Optional.present(next.preferred?.end);
        }
        if (before.fields.accessibility != accessibility) {
          b.accessibility = Optional.present(
            AccessibilityPreferences(
              (a) => a
                ..schemaVersion = const Optional.present('1')
                ..reducedMotion = Optional.present(accessibility.reducedMotion)
                ..soundEnabled = Optional.present(accessibility.soundEnabled)
                ..hapticsEnabled = Optional.present(
                  accessibility.hapticsEnabled,
                )
                ..timerVisible = Optional.present(accessibility.timerVisible)
                ..highContrast = Optional.present(accessibility.highContrast),
            ),
          );
        }
      }),
    );
    return _preferences(response.data);
  });

  Future<T> _execute<T>(
    ProfileAccess access,
    Future<T> Function(String) call,
  ) async {
    try {
      try {
        return await call(access.session.accessToken);
      } on DioException catch (error) {
        if (error.response?.statusCode != 401) rethrow;
        final refreshed = await refresh(access.session);
        if (refreshed?.userId != access.session.userId ||
            refreshed!.accessToken.isEmpty) {
          throw _expired;
        }
        return await call(refreshed.accessToken);
      }
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      if (status == 401) throw _expired;
      final envelope = parseApiErrorEnvelope(error.response?.data)?.error;
      final safe = mapDioExceptionToFailure(error);
      final seconds =
          int.tryParse(error.response?.headers.value('retry-after') ?? '') ??
          envelope?.retryAfterSeconds;
      if (status == 403 && safe.code == 'unknown') {
        throw const ProfileFailure(
          'forbidden',
          'Settings are unavailable for this account.',
        );
      }
      throw ProfileFailure(
        safe.code,
        safe.message,
        retryable: safe.retryable,
        retryAfter: seconds == null || seconds < 0
            ? null
            : Duration(seconds: seconds),
        fields: Set.unmodifiable(
          envelope?.fieldErrors.map((e) => e.field) ?? const <String>[],
        ),
      );
    } on ProfileFailure {
      rethrow;
    } on AuthFailure catch (failure) {
      if (failure.code == 'expired_session') throw _expired;
      throw const ProfileFailure(
        'network_error',
        'Check your connection and try again.',
        retryable: true,
      );
    } catch (_) {
      throw _unavailable;
    }
  }

  static const _expired = ProfileFailure(
    'expired_session',
    'Please sign in again.',
  );
  static const _unavailable = ProfileFailure(
    'unavailable',
    'Settings could not be loaded or saved. Try again.',
    retryable: true,
  );

  static Profile _profile(ProfileResponse? dto, String owner) {
    if (dto == null || dto.userId != owner || dto.version < 1) {
      throw _unavailable;
    }
    return (
      fields: (
        displayName: dto.displayName,
        locale: dto.locale,
        timezone: dto.timezone,
      ),
      version: dto.version,
    );
  }

  static Preferences _preferences(ProfilePreferencesResponse? dto) {
    if (dto == null ||
        dto.version < 1 ||
        dto.maxDailyReminders < 0 ||
        dto.maxDailyReminders > maxDailyReminders) {
      throw _unavailable;
    }
    final a = dto.accessibility;
    return (
      version: dto.version,
      fields: (
        notifications: (
          enabled: dto.notificationsEnabled,
          mission: dto.missionEnabled,
          reward: dto.rewardEnabled,
          streak: dto.streakEnabled,
          quiet: _window(dto.quietStartLocal, dto.quietEndLocal),
          preferred: _window(
            dto.preferredWindowStartLocal,
            dto.preferredWindowEndLocal,
          ),
          timezone: dto.timezone,
          dailyLimit: dto.maxDailyReminders,
          preview: PreviewDetail.values.firstWhere(
            (value) => value.name == dto.lockScreenDetail.name,
            orElse: () => PreviewDetail.unknown,
          ),
        ),
        accessibility: (
          reducedMotion: a.reducedMotion.orElse(false) ?? false,
          soundEnabled: a.soundEnabled.orElse(true) ?? true,
          hapticsEnabled: a.hapticsEnabled.orElse(true) ?? true,
          timerVisible: a.timerVisible.orElse(false) ?? false,
          highContrast: a.highContrast.orElse(false) ?? false,
        ),
      ),
    );
  }

  static LocalWindow? _window(String? start, String? end) =>
      start == null || end == null ? null : (start: start, end: end);
}

class UnavailableProfileRepository implements ProfileRepository {
  const UnavailableProfileRepository();

  @override
  Future<ConfirmedSettings> load(ProfileAccess access) async =>
      throw MemoraProfileRepository._unavailable;

  @override
  Future<Profile> saveProfile(
    ProfileAccess access,
    Profile before,
    ProfileFields draft,
    String key,
  ) async => throw MemoraProfileRepository._unavailable;

  @override
  Future<Preferences> savePreferences(
    ProfileAccess access,
    Preferences before,
    PreferenceFields draft,
    String key,
  ) async => throw MemoraProfileRepository._unavailable;
}
