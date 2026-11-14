import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/features/auth/application/session_controller.dart';
import 'package:memora_mobile/src/features/auth/data/auth_repository.dart';
import 'package:memora_mobile/src/features/auth/data/secure_auth_storage.dart';
import 'package:memora_mobile/src/features/auth/data/session_repository.dart';
import 'package:memora_mobile/src/features/auth/domain/app_session_state.dart';
import 'package:memora_mobile/src/features/profile/application/profile_controller.dart';
import 'package:memora_mobile/src/features/profile/data/profile_cache.dart';
import 'package:memora_mobile/src/features/profile/domain/profile_settings.dart';

import 'profile_fixtures.dart';

class _DeferredAuthRepository extends MockAuthRepository {
  final refresh = Completer<AuthSession?>();
  int calls = 0;

  @override
  Future<AuthSession?> refreshSession() {
    calls++;
    return refresh.future;
  }
}

void main() {
  late FakeProfileRepository repository;
  late AppLocalStorage storage;
  late ProfileController controller;
  final session = signedIn();
  final access = (session: session.session!, owner: 'test-owner');
  const offline = ProfileFailure('network_error', 'Offline', retryable: true);
  const reduced = (
    reducedMotion: true,
    soundEnabled: false,
    hapticsEnabled: true,
    timerVisible: true,
    highContrast: true,
  );

  Future<void> tick() => Future<void>.delayed(Duration.zero);

  setUp(() {
    repository = FakeProfileRepository();
    storage = AppLocalStorage(InMemorySecureKeyStore());
    controller = ProfileController(
      repository,
      ProfileCache(storage),
      () async {},
    );
  });
  tearDown(() => controller.dispose());

  test(
    'startup restores only accessibility before account bootstrap',
    () async {
      await ProfileCache(storage).write(access, (
        profile: confirmedSettings.profile,
        preferences: (
          fields: (notifications: notificationFields, accessibility: reduced),
          version: 2,
        ),
      ));
      controller.bind(AppSessionState.bootstrapping(session: session.session!));
      await tick();
      expect(controller.state.applied, reduced);
      expect(controller.state.confirmed, isNull);
      expect(repository.reads, 0);
      controller.bind(const AppSessionState.signedOut());
      await tick();
      expect(controller.state.applied, isNull);
      expect(await storage.readProfileCache(access.session.userId), isNull);
    },
  );

  test('restores saved settings offline after controller recreation', () async {
    controller.bind(session);
    await tick();
    expect(controller.state.confirmed, confirmedSettings);
    await controller.saveAccessibility(reduced);
    expect(controller.state.phase, ProfilePhase.saved);
    controller.dispose();

    repository.readFailure = offline;
    controller = ProfileController(
      repository,
      ProfileCache(storage),
      () async {},
    );
    controller.bind(session);
    await tick();
    expect(controller.state.cached, isTrue);
    expect(controller.state.failure?.code, 'network_error');
    expect(
      controller.state.confirmed?.preferences.fields.accessibility,
      reduced,
    );
    expect(
      await storage.readProfileCache('test-account'),
      isNot(contains('synthetic-access')),
    );
  });

  test(
    'failed accessibility save rolls back and retry keeps its key',
    () async {
      controller.bind(session);
      await tick();
      controller.previewAccessibility(reduced);
      expect(controller.state.applied, reduced);
      repository.saveFailure = offline;
      await controller.saveAccessibility(reduced);
      expect(controller.state.applied, isNull);
      expect(
        controller.state.confirmed?.preferences.fields.accessibility,
        accessibilityFields,
      );
      repository.saveFailure = null;
      await controller.retry();
      expect(repository.keys.length, 2);
      expect(repository.keys.toSet(), hasLength(1));
      expect(
        controller.state.confirmed?.preferences.fields.accessibility,
        reduced,
      );
    },
  );

  test(
    'changing the draft after a failed request generates a new key',
    () async {
      controller.bind(session);
      await tick();
      repository.saveFailure = offline;
      await controller.saveProfile((
        displayName: 'New name',
        locale: 'en-LK',
        timezone: 'Asia/Colombo',
      ));
      repository.saveFailure = null;
      await controller.saveProfile((
        displayName: 'Another name',
        locale: 'en-LK',
        timezone: 'Asia/Colombo',
      ));
      expect(repository.keys.toSet(), hasLength(2));
      expect(
        controller.state.confirmed?.profile.fields.displayName,
        'Another name',
      );
    },
  );

  test(
    'version conflict refreshes current values without repeating the PATCH',
    () async {
      controller.bind(session);
      await tick();
      repository.data = (
        profile: (
          fields: (
            displayName: 'Other device',
            locale: 'en-LK',
            timezone: 'Asia/Colombo',
          ),
          version: 4,
        ),
        preferences: confirmedSettings.preferences,
      );
      repository.saveFailure = const ProfileFailure(
        'version_conflict',
        'Refresh settings',
      );
      await controller.saveProfile((
        displayName: 'New name',
        locale: 'en-LK',
        timezone: 'Asia/Colombo',
      ));
      expect(controller.state.phase, ProfilePhase.conflict);
      expect(
        controller.state.confirmed?.profile.fields.displayName,
        'Other device',
      );
      expect(repository.keys, hasLength(1));
      expect(repository.reads, 2);
    },
  );

  test(
    'account switch drops a late response and never restores the old cache',
    () async {
      await ProfileCache(storage).write(access, confirmedSettings);
      final oldRead = Completer<ConfirmedSettings>();
      repository.pendingRead = oldRead.future;
      controller.bind(session);
      await tick();
      expect(controller.state.cached, isTrue);

      repository.pendingRead = null;
      repository.readFailure = offline;
      controller.bind(signedIn(account: 'other-account', owner: 'other-owner'));
      await tick();
      oldRead.complete(confirmedSettings);
      await tick();
      expect(controller.state.confirmed, isNull);
      expect(await storage.readProfileCache('test-account'), isNull);
    },
  );

  test('invalid or wrong-owner cache is discarded', () async {
    for (final invalid in ['not-json', '{"schema":1,"owner":"someone-else"}']) {
      await storage.writeProfileCache(access.session.userId, invalid);
      expect(await ProfileCache(storage).read(access), isNull);
      expect(await storage.readProfileCache(access.session.userId), isNull);
    }
  });

  test('sign-out clears the cache even if a save is still in flight', () async {
    controller.bind(session);
    await tick();
    final pending = Completer<void>();
    repository.pendingSave = pending.future;
    final save = controller.saveAccessibility(reduced);
    expect(controller.state.phase, ProfilePhase.saving);
    controller.bind(const AppSessionState.signedOut());
    pending.complete();
    await save;
    expect(controller.state.confirmed, isNull);
    expect(await storage.readProfileCache(access.session.userId), isNull);
  });

  test('rate limit disables retry until the server delay elapses', () async {
    controller.bind(session);
    await tick();
    repository.saveFailure = const ProfileFailure(
      'rate_limited',
      'Wait',
      retryable: true,
      retryAfter: Duration(seconds: 10),
    );
    await controller.saveAccessibility(reduced);
    await controller.retry();
    expect(controller.state.waitingToRetry, isTrue);
    expect(repository.keys, hasLength(1));
  });

  test('settings refresh keeps the active bootstrap and account', () async {
    final auth = MockAuthRepository(initialSession: session.session);
    final sessionController = SessionController(
      authRepository: auth,
      sessionRepository: MockSessionRepository(),
      localStorage: storage,
      initialState: session,
    );
    addTearDown(sessionController.dispose);
    addTearDown(auth.dispose);
    final phases = <AppSessionPhase>[];
    sessionController.addListener((state) => phases.add(state.phase));
    final fresh = await sessionController.refreshForSettings(session.session!);
    await tick();
    expect(fresh?.accessToken, isNot(session.session!.accessToken));
    expect(sessionController.state.session, fresh);
    expect(sessionController.state.bootstrapData, same(session.bootstrapData));
    expect(phases, everyElement(AppSessionPhase.active));
  });

  test(
    'concurrent refresh callers reject a different provider account',
    () async {
      final auth = _DeferredAuthRepository();
      final sessionController = SessionController(
        authRepository: auth,
        sessionRepository: MockSessionRepository(),
        localStorage: storage,
        initialState: session,
      );
      addTearDown(sessionController.dispose);
      addTearDown(auth.dispose);

      final first = sessionController.refreshForSettings(access.session);
      final second = sessionController.refreshForSettings(access.session);
      auth.refresh.complete(signedIn(account: 'different-account').session);

      expect(await Future.wait([first, second]), [null, null]);
      expect(auth.calls, 1);
      expect(sessionController.state.session, session.session);
    },
  );

  test(
    'expiry clears confirmed settings through the existing session lifecycle',
    () async {
      final auth = MockAuthRepository(initialSession: session.session);
      final sessionController = SessionController(
        authRepository: auth,
        sessionRepository: MockSessionRepository(),
        localStorage: storage,
        initialState: session,
      );
      addTearDown(sessionController.dispose);
      addTearDown(auth.dispose);
      controller.dispose();
      controller = ProfileController(
        repository,
        ProfileCache(storage),
        sessionController.handleExpiredSession,
      );
      final stop = sessionController.addListener(controller.bind);
      addTearDown(stop);
      await tick();
      expect(await storage.readProfileCache(access.session.userId), isNotNull);
      repository.saveFailure = const ProfileFailure(
        'expired_session',
        'Sign in again',
      );
      await controller.saveAccessibility(reduced);
      expect(sessionController.state.phase, AppSessionPhase.signedOut);
      expect(await storage.readProfileCache(access.session.userId), isNull);
      expect(controller.state.confirmed, isNull);
    },
  );
}
