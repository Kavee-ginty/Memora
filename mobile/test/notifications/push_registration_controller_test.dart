import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/configuration/app_configuration.dart';
import 'package:memora_mobile/src/features/auth/domain/app_session_state.dart';
import 'package:memora_mobile/src/features/auth/domain/bootstrap_state.dart';
import 'package:memora_mobile/src/features/notifications/application/push_registration_controller.dart';
import 'package:memora_mobile/src/features/notifications/domain/notification_permission.dart';
import 'package:memora_mobile/src/features/notifications/infrastructure/device_token_registrar.dart';
import 'package:memora_mobile/src/features/notifications/infrastructure/notification_gateway.dart';

import 'device_token_registrar_test.dart'
    show InMemoryKeyStore, RecordingRegistrationApi;

const _testConfiguration = AppConfiguration(
  supabaseUrl: 'https://synthetic.supabase.co',
  supabasePublishableKey: 'synthetic-key',
  apiBaseUrl: 'https://synthetic.example.com',
  oauthRedirectUri: 'com.synthetic://callback',
  clientVersion: '1.2.3',
  platform: 'android',
  environment: 'development',
);

AppSessionState _activeSession({String userId = 'usr_1'}) {
  return AppSessionState.active(
    session: AuthSession(accessToken: 'token', userId: userId),
    bootstrapData: BootstrapData(
      accountStatus: AccountStatusDomain.active,
      profileSummary: const ProfileSummaryDomain(
        userId: 'usr_1',
        displayName: 'Amani Perera',
        streakDays: 4,
      ),
      consentStatus: const ConsentStatusDomain(requiresReview: false),
      subjects: const <SubjectSummaryDomain>[],
      capabilities: const CapabilityFlagsDomain(),
      serverTime: DateTime.utc(2026, 11, 11),
    ),
  );
}

void main() {
  group('PushRegistrationController', () {
    test('awaits the in-app explanation before the OS prompt', () async {
      final gateway = FakeNotificationGateway(
        initialPermission: NotificationPermission.notDetermined,
        initialToken: 'push-token-1',
      );
      final api = RecordingRegistrationApi();
      final sessions = StreamController<AppSessionState>.broadcast();
      addTearDown(sessions.close);

      final controller = PushRegistrationController(
        gateway: gateway,
        registrar: DeviceTokenRegistrar(
          gateway: gateway,
          api: api,
          keyStore: InMemoryKeyStore(),
          configuration: _testConfiguration,
        ),
        keyStore: InMemoryKeyStore(),
        sessionStates: sessions.stream,
      );
      controller.start();
      addTearDown(controller.dispose);

      sessions.add(_activeSession());
      await pumpEventQueue();

      // Flow 12.1: no OS prompt before the in-app explanation.
      expect(controller.state, PushRegistrationPhase.awaitingExplanation);
      expect(gateway.askWasCalled, isFalse);
      expect(api.calls, isEmpty);
    });

    test('confirming the explanation prompts and registers', () async {
      final gateway = FakeNotificationGateway(
        initialPermission: NotificationPermission.notDetermined,
        initialToken: 'push-token-1',
      );
      final api = RecordingRegistrationApi();
      final sessions = StreamController<AppSessionState>.broadcast();
      addTearDown(sessions.close);

      final controller = PushRegistrationController(
        gateway: gateway,
        registrar: DeviceTokenRegistrar(
          gateway: gateway,
          api: api,
          keyStore: InMemoryKeyStore(),
          configuration: _testConfiguration,
        ),
        keyStore: InMemoryKeyStore(),
        sessionStates: sessions.stream,
      );
      controller.start();
      addTearDown(controller.dispose);

      sessions.add(_activeSession());
      await pumpEventQueue();
      await controller.confirmNotificationExplanation();
      await pumpEventQueue();

      expect(api.calls, hasLength(1));
      expect(controller.state, PushRegistrationPhase.ready);
      expect(gateway.askWasCalled, isTrue);
    });

    test('granted permission registers without an explanation wait', () async {
      final gateway = FakeNotificationGateway(
        initialPermission: NotificationPermission.granted,
        initialToken: 'push-token-1',
      );
      final api = RecordingRegistrationApi();
      final sessions = StreamController<AppSessionState>.broadcast();
      addTearDown(sessions.close);

      final controller = PushRegistrationController(
        gateway: gateway,
        registrar: DeviceTokenRegistrar(
          gateway: gateway,
          api: api,
          keyStore: InMemoryKeyStore(),
          configuration: _testConfiguration,
        ),
        keyStore: InMemoryKeyStore(),
        sessionStates: sessions.stream,
      );
      controller.start();
      addTearDown(controller.dispose);

      sessions.add(_activeSession());
      await pumpEventQueue();
      expect(controller.state, PushRegistrationPhase.ready);
      expect(api.calls, hasLength(1));
    });

    test('denial is recoverable through requestPermissionAgain', () async {
      final gateway = FakeNotificationGateway(
        initialPermission: NotificationPermission.notDetermined,
        initialToken: 'push-token-1',
      );
      final api = RecordingRegistrationApi();
      final sessions = StreamController<AppSessionState>.broadcast();
      addTearDown(sessions.close);

      final controller = PushRegistrationController(
        gateway: gateway,
        registrar: DeviceTokenRegistrar(
          gateway: gateway,
          api: api,
          keyStore: InMemoryKeyStore(),
          configuration: _testConfiguration,
        ),
        keyStore: InMemoryKeyStore(),
        sessionStates: sessions.stream,
      );
      controller.start();
      addTearDown(controller.dispose);

      sessions.add(_activeSession());
      await pumpEventQueue();
      gateway.setPermission(NotificationPermission.denied);
      await controller.confirmNotificationExplanation();
      await pumpEventQueue();
      expect(controller.state, PushRegistrationPhase.denied);
      expect(api.calls, isEmpty);

      // The user grants from settings later: the controller recovers.
      gateway.setPermission(NotificationPermission.granted);
      await controller.requestPermissionAgain();
      await pumpEventQueue();
      expect(controller.state, PushRegistrationPhase.ready);
      expect(api.calls, hasLength(1));
    });

    test(
      'registration failure is recoverable on session re-emission',
      () async {
        final gateway = FakeNotificationGateway(
          initialPermission: NotificationPermission.granted,
          initialToken: 'push-token-1',
        );
        final api = RecordingRegistrationApi()
          ..registerFailure = Exception('offline');
        final sessions = StreamController<AppSessionState>.broadcast();
        addTearDown(sessions.close);

        final controller = PushRegistrationController(
          gateway: gateway,
          registrar: DeviceTokenRegistrar(
            gateway: gateway,
            api: api,
            keyStore: InMemoryKeyStore(),
            configuration: _testConfiguration,
          ),
          keyStore: InMemoryKeyStore(),
          sessionStates: sessions.stream,
        );
        controller.start();
        addTearDown(controller.dispose);

        sessions.add(_activeSession());
        await pumpEventQueue();
        expect(controller.state, PushRegistrationPhase.registrationFailed);
        expect(api.calls, isEmpty);

        // Connectivity returns: the next authenticated emission retries and
        // marks ready only after server confirmation.
        api.registerFailure = null;
        sessions.add(_activeSession());
        await pumpEventQueue();
        expect(controller.state, PushRegistrationPhase.ready);
        expect(api.calls, hasLength(1));
      },
    );

    test('sign-out revokes the device registration while it can', () async {
      final gateway = FakeNotificationGateway(
        initialPermission: NotificationPermission.granted,
        initialToken: 'push-token-1',
      );
      final api = RecordingRegistrationApi();
      final sessions = StreamController<AppSessionState>.broadcast();
      addTearDown(sessions.close);

      final controller = PushRegistrationController(
        gateway: gateway,
        registrar: DeviceTokenRegistrar(
          gateway: gateway,
          api: api,
          keyStore: InMemoryKeyStore(),
          configuration: _testConfiguration,
        ),
        keyStore: InMemoryKeyStore(),
        sessionStates: sessions.stream,
      );
      controller.start();
      addTearDown(controller.dispose);

      sessions.add(_activeSession());
      await pumpEventQueue();
      expect(api.calls, hasLength(1));

      sessions.add(const AppSessionState.signedOut());
      await pumpEventQueue();
      expect(controller.state, PushRegistrationPhase.idle);
      expect(api.revocations, hasLength(1));
      expect(api.revocations.single['access_token'], 'token');
    });

    test(
      'sign-out with unreachable backend keeps the revocation tracked',
      () async {
        final gateway = FakeNotificationGateway(
          initialPermission: NotificationPermission.granted,
          initialToken: 'push-token-1',
        );
        final api = RecordingRegistrationApi()
          ..revokeFailure = Exception('offline');
        final sessions = StreamController<AppSessionState>.broadcast();
        addTearDown(sessions.close);

        final controller = PushRegistrationController(
          gateway: gateway,
          registrar: DeviceTokenRegistrar(
            gateway: gateway,
            api: api,
            keyStore: InMemoryKeyStore(),
            configuration: _testConfiguration,
          ),
          keyStore: InMemoryKeyStore(),
          sessionStates: sessions.stream,
        );
        controller.start();
        addTearDown(controller.dispose);

        sessions.add(_activeSession());
        await pumpEventQueue();
        sessions.add(const AppSessionState.signedOut());
        await pumpEventQueue();

        // Offline: the revocation stays tracked for a later attempt.
        expect(api.revocations, isEmpty);
        api.revokeFailure = null;
        await controller.onSessionState(const AppSessionState.signedOut());
        await pumpEventQueue();
        expect(api.revocations, hasLength(1));
      },
    );

    test('account switch revokes the previous registration first', () async {
      final gateway = FakeNotificationGateway(
        initialPermission: NotificationPermission.granted,
        initialToken: 'push-token-1',
      );
      final api = RecordingRegistrationApi();
      final sessions = StreamController<AppSessionState>.broadcast();
      addTearDown(sessions.close);

      final controller = PushRegistrationController(
        gateway: gateway,
        registrar: DeviceTokenRegistrar(
          gateway: gateway,
          api: api,
          keyStore: InMemoryKeyStore(),
          configuration: _testConfiguration,
        ),
        keyStore: InMemoryKeyStore(),
        sessionStates: sessions.stream,
      );
      controller.start();
      addTearDown(controller.dispose);

      sessions.add(_activeSession(userId: 'usr_1'));
      await pumpEventQueue();
      expect(api.calls, hasLength(1));

      final other = _activeSession(userId: 'usr_2');
      sessions.add(other);
      await pumpEventQueue();

      expect(api.revocations, hasLength(1));
      expect(api.calls, hasLength(2));
    });

    test('unavailable provider is a terminal safe state', () async {
      final gateway = FakeNotificationGateway(
        initialPermission: NotificationPermission.unavailable,
      );
      final api = RecordingRegistrationApi();
      final sessions = StreamController<AppSessionState>.broadcast();
      addTearDown(sessions.close);

      final controller = PushRegistrationController(
        gateway: gateway,
        registrar: DeviceTokenRegistrar(
          gateway: gateway,
          api: api,
          keyStore: InMemoryKeyStore(),
          configuration: _testConfiguration,
        ),
        keyStore: InMemoryKeyStore(),
        sessionStates: sessions.stream,
      );
      controller.start();
      addTearDown(controller.dispose);

      sessions.add(_activeSession());
      await pumpEventQueue();

      expect(api.calls, isEmpty);
      expect(controller.state, PushRegistrationPhase.unavailable);
    });

    test('token rotation after activation re-registers', () async {
      final gateway = FakeNotificationGateway(
        initialPermission: NotificationPermission.granted,
        initialToken: 'push-token-1',
      );
      final api = RecordingRegistrationApi();
      final sessions = StreamController<AppSessionState>.broadcast();
      addTearDown(sessions.close);

      final controller = PushRegistrationController(
        gateway: gateway,
        registrar: DeviceTokenRegistrar(
          gateway: gateway,
          api: api,
          keyStore: InMemoryKeyStore(),
          configuration: _testConfiguration,
        ),
        keyStore: InMemoryKeyStore(),
        sessionStates: sessions.stream,
      );
      controller.start();
      addTearDown(controller.dispose);

      sessions.add(_activeSession());
      await pumpEventQueue();
      gateway.emitTokenRefresh('push-token-2');
      await pumpEventQueue();

      expect(api.calls, hasLength(2));
      expect(api.calls[1]['push_token'], 'push-token-2');
    });
  });
}
