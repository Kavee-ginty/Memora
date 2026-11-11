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

AppSessionState _activeSession() {
  return AppSessionState.active(
    session: const AuthSession(accessToken: 'token', userId: 'usr_1'),
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
    test(
      'registers after session activation with granted permission',
      () async {
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

        expect(api.calls, hasLength(1));
        expect(controller.state, PushRegistrationPhase.ready);
      },
    );

    test('denied permission never registers and never re-prompts', () async {
      final gateway = FakeNotificationGateway(
        initialPermission: NotificationPermission.denied,
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
      sessions.add(_activeSession());
      await pumpEventQueue();

      expect(api.calls, isEmpty);
      expect(controller.state, PushRegistrationPhase.denied);
      expect(gateway.askWasCalled, isFalse);
    });

    test('sign-out stops the flow and resets the phase', () async {
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

      sessions.add(const AppSessionState.signedOut());
      await pumpEventQueue();
      expect(controller.state, PushRegistrationPhase.idle);
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
