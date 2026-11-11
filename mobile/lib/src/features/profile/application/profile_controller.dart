import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/session_controller.dart';
import '../../auth/domain/app_session_state.dart';
import '../../common/ids.dart';
import '../data/profile_cache.dart';
import '../data/profile_repository.dart';
import '../domain/profile_settings.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => const UnavailableProfileRepository(),
);

final profileControllerProvider =
    StateNotifierProvider<ProfileController, ProfileState>((ref) {
      final controller = ProfileController(
        ref.watch(profileRepositoryProvider),
        ProfileCache(ref.watch(appLocalStorageProvider)),
        () =>
            ref.read(sessionControllerProvider.notifier).handleExpiredSession(),
      );
      ref.listen(
        sessionControllerProvider,
        (_, next) => controller.bind(next),
        fireImmediately: true,
      );
      return controller;
    });

enum ProfilePhase { loading, ready, saving, saved, failed, conflict }

enum SettingsSection { profile, notifications, accessibility }

typedef ProfileState = ({
  ConfirmedSettings? confirmed,
  ProfilePhase phase,
  SettingsSection? section,
  ProfileFailure? failure,
  bool cached,
  bool waitingToRetry,
  AccessibilitySettings? applied,
  bool cacheWriteFailed,
  bool reconciling,
});

const ProfileState _initial = (
  confirmed: null,
  phase: ProfilePhase.loading,
  section: null,
  failure: null,
  cached: false,
  waitingToRetry: false,
  applied: null,
  cacheWriteFailed: false,
  reconciling: false,
);

class ProfileController extends StateNotifier<ProfileState> {
  ProfileController(this.repository, this.cache, this.expireSession)
    : super(_initial);

  final ProfileRepository repository;
  final ProfileCache cache;
  final Future<void> Function() expireSession;

  ProfileAccess? _access;
  String? _startupAccount;
  int _generation = 0;
  bool _busy = false;
  bool _needsConflictRead = false;
  ({Object payload, String key})? _operation;
  Timer? _retryTimer;
  DateTime? _retryAt;
  Future<void> Function()? _retry;

  void bind(AppSessionState session) {
    final previous = _access;
    final credentials = session.session;
    // Refresh can briefly move the same account through bootstrap.
    if (session.phase == AppSessionPhase.bootstrapping &&
        previous != null &&
        credentials?.userId == previous.session.userId) {
      _access = (session: credentials!, owner: previous.owner);
      return;
    }
    if (previous == null &&
        credentials != null &&
        (session.phase == AppSessionPhase.bootstrapping ||
            session.phase == AppSessionPhase.failure)) {
      if (_startupAccount != credentials.userId) {
        final prior = _startupAccount;
        _reset();
        _startupAccount = credentials.userId;
        if (prior != null) unawaited(_clearCache(prior));
        unawaited(
          _restoreStartupAccessibility(credentials.userId, _generation),
        );
      }
      return;
    }
    final owner = session.bootstrapData?.profileSummary.userId;
    if (session.phase == AppSessionPhase.active &&
        credentials != null &&
        owner != null &&
        owner.isNotEmpty) {
      _access = (session: credentials, owner: owner);
      if (previous?.session.userId == credentials.userId &&
          previous?.owner == owner) {
        return;
      }
      final priorStartup = _startupAccount;
      final startupAccessibility = priorStartup == credentials.userId
          ? state.applied
          : null;
      _reset();
      if (startupAccessibility != null) {
        _publish(null, ProfilePhase.loading, applied: startupAccessibility);
      }
      unawaited(Future<void>.microtask(() => reload(restore: true)));
      if (previous != null) unawaited(_clearCache(previous.session.userId));
      if (priorStartup != null && priorStartup != credentials.userId) {
        unawaited(_clearCache(priorStartup));
      }
      return;
    }
    _access = null;
    final priorAccount = previous?.session.userId ?? _startupAccount;
    if (priorAccount != null) {
      _reset();
      if (credentials?.userId != priorAccount) {
        unawaited(_clearCache(priorAccount));
      }
    }
  }

  Future<void> _restoreStartupAccessibility(
    String userId,
    int generation,
  ) async {
    final settings = await cache.readStartupAccessibility(userId);
    if (_current(generation) && settings != null) {
      _publish(null, ProfilePhase.loading, applied: settings);
    }
  }

  Future<void> _clearCache(String userId) async {
    try {
      await cache.storage.clearProfileCache(userId);
    } catch (_) {
      // In-memory state is already isolated by account and generation.
    }
  }

  void _reset() {
    _generation++;
    _startupAccount = null;
    _busy = false;
    _operation = null;
    _retry = null;
    _needsConflictRead = false;
    _retryAt = null;
    _retryTimer?.cancel();
    state = _initial;
  }

  bool _current(int generation) => mounted && generation == _generation;
  bool get _throttled => _retryAt?.isAfter(DateTime.now()) ?? false;

  Future<void> reload({bool restore = false}) async {
    final access = _access;
    if (!mounted || access == null || _busy || _throttled) return;
    final generation = _generation;
    _busy = true;
    final section = state.section;
    if (state.confirmed == null) {
      _publish(null, ProfilePhase.loading, applied: state.applied);
    }
    try {
      if (restore) {
        final cached = await cache.read(access);
        if (!_current(generation)) return;
        if (cached != null) {
          _publish(cached, ProfilePhase.loading, cached: true);
        } else {
          _publish(null, ProfilePhase.loading);
        }
      }
      final result = await repository.load(access);
      if (!_current(generation)) return;
      final phase = _needsConflictRead
          ? ProfilePhase.conflict
          : ProfilePhase.ready;
      _needsConflictRead = false;
      _retry = null;
      await _confirm(access, generation, result, phase, section: section);
    } on ProfileFailure catch (failure) {
      if (_current(generation)) await _fail(failure, section, () => reload());
    } finally {
      if (_current(generation)) _busy = false;
    }
  }

  void previewAccessibility(AccessibilitySettings? value) {
    if (_busy || state.confirmed == null) return;
    state = (
      confirmed: state.confirmed,
      phase: state.phase,
      section: state.section,
      failure: state.failure,
      cached: state.cached,
      waitingToRetry: state.waitingToRetry,
      applied: value,
      cacheWriteFailed: state.cacheWriteFailed,
      reconciling: state.reconciling,
    );
  }

  Future<void> saveProfile(ProfileFields draft) => _save(
    SettingsSection.profile,
    draft,
    (access, before, key) async => (
      profile: await repository.saveProfile(access, before.profile, draft, key),
      preferences: before.preferences,
    ),
    unchanged: (before) => before.profile.fields == draft,
  );

  Future<void> saveNotifications(NotificationSettings draft) => _save(
    SettingsSection.notifications,
    draft,
    (access, before, key) async => (
      profile: before.profile,
      preferences: await repository.savePreferences(
        access,
        before.preferences,
        (
          notifications: draft,
          accessibility: before.preferences.fields.accessibility,
        ),
        key,
      ),
    ),
    unchanged: (before) => before.preferences.fields.notifications == draft,
  );

  Future<void> saveAccessibility(AccessibilitySettings draft) => _save(
    SettingsSection.accessibility,
    draft,
    (access, before, key) async => (
      profile: before.profile,
      preferences: await repository.savePreferences(
        access,
        before.preferences,
        (
          notifications: before.preferences.fields.notifications,
          accessibility: draft,
        ),
        key,
      ),
    ),
    unchanged: (before) => before.preferences.fields.accessibility == draft,
    applied: draft,
  );

  Future<void> _save(
    SettingsSection section,
    Object draft,
    Future<ConfirmedSettings> Function(ProfileAccess, ConfirmedSettings, String)
    mutation, {
    required bool Function(ConfirmedSettings) unchanged,
    AccessibilitySettings? applied,
  }) async {
    final access = _access;
    final before = state.confirmed;
    if (access == null ||
        before == null ||
        _busy ||
        _throttled ||
        _needsConflictRead ||
        unchanged(before)) {
      return;
    }
    final generation = _generation;
    final version = section == SettingsSection.profile
        ? before.profile.version
        : before.preferences.version;
    final payload = (section, version, draft);
    final key = _operation?.payload == payload
        ? _operation!.key
        : generateUuid();
    _operation = (payload: payload, key: key);
    _busy = true;
    _publish(
      before,
      ProfilePhase.saving,
      section: section,
      cached: state.cached,
      applied: applied,
    );
    try {
      final result = await mutation(access, before, key);
      if (!_current(generation)) return;
      _operation = null;
      _retry = null;
      await _confirm(
        access,
        generation,
        result,
        ProfilePhase.saved,
        section: section,
      );
    } on ProfileFailure catch (failure) {
      if (!_current(generation)) return;
      if (!failure.retryable) _operation = null;
      if (failure.code == 'version_conflict') {
        _needsConflictRead = true;
        _busy = false;
        _publish(
          before,
          ProfilePhase.loading,
          section: section,
          cached: state.cached,
        );
        await reload();
      } else {
        await _fail(
          failure,
          section,
          () => _save(
            section,
            draft,
            mutation,
            unchanged: unchanged,
            applied: applied,
          ),
        );
      }
    } finally {
      if (_current(generation)) _busy = false;
    }
  }

  Future<void> retry() async {
    if (!_throttled) await _retry?.call();
  }

  Future<void> _fail(
    ProfileFailure failure,
    SettingsSection? section,
    Future<void> Function() retry,
  ) async {
    if (failure.code == 'expired_session') {
      await expireSession();
      return;
    }
    _retry = failure.retryable ? retry : null;
    final wait = failure.retryAfter;
    if (wait != null && wait > Duration.zero) {
      _retryAt = DateTime.now().add(wait);
      _retryTimer?.cancel();
      _retryTimer = Timer(wait, () {
        if (mounted) {
          _publish(
            state.confirmed,
            state.phase,
            section: state.section,
            failure: state.failure,
            cached: state.cached,
          );
        }
      });
    }
    _publish(
      state.confirmed,
      ProfilePhase.failed,
      section: section,
      failure: failure,
      cached: state.cached,
    );
  }

  Future<void> _confirm(
    ProfileAccess access,
    int generation,
    ConfirmedSettings confirmed,
    ProfilePhase phase, {
    SettingsSection? section,
  }) async {
    var cacheWriteFailed = false;
    try {
      await cache.write(access, confirmed);
    } catch (_) {
      cacheWriteFailed = true;
      // A previous cache value could otherwise be shown as the last saved value.
      if (_current(generation)) await _clearCache(access.session.userId);
    }
    if (!_current(generation)) return;
    _busy = false;
    _publish(
      confirmed,
      phase,
      section: section,
      cacheWriteFailed: cacheWriteFailed,
    );
  }

  void _publish(
    ConfirmedSettings? confirmed,
    ProfilePhase phase, {
    SettingsSection? section,
    ProfileFailure? failure,
    bool cached = false,
    AccessibilitySettings? applied,
    bool cacheWriteFailed = false,
  }) {
    state = (
      confirmed: confirmed,
      phase: phase,
      section: section,
      failure: failure,
      cached: cached,
      waitingToRetry: _throttled,
      applied: applied,
      cacheWriteFailed: cacheWriteFailed,
      reconciling: _needsConflictRead,
    );
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }
}
