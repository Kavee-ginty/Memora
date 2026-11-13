import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/configuration/app_configuration.dart';
import 'package:memora_mobile/src/features/auth/data/secure_auth_storage.dart';
import 'package:memora_mobile/src/features/notifications/domain/notification_message.dart';
import 'package:memora_mobile/src/features/notifications/domain/notification_permission.dart';
import 'package:memora_mobile/src/features/notifications/infrastructure/device_token_registrar.dart';
import 'package:memora_mobile/src/features/notifications/infrastructure/notification_gateway.dart';

class InMemoryKeyStore implements SecureKeyStore {
  final Map<String, String> values = {};

  @override
  Future<bool> containsKey(String key) async => values.containsKey(key);

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    values.clear();
  }

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}

class RecordingRegistrationApi implements DeviceRegistrationApi {
  final List<Map<String, String>> calls = [];
  final List<Map<String, String>> revocations = [];
  Object? registerFailure;
  Object? revokeFailure;
  String nextDeviceId = 'device-1';

  @override
  Future<String> register({
    required String installationId,
    required String pushToken,
    required String idempotencyKey,
    required String appVersion,
    required String platform,
    required String locale,
  }) async {
    if (registerFailure != null) {
      throw registerFailure!;
    }
    calls.add({
      'installation_id': installationId,
      'push_token': pushToken,
      'idempotency_key': idempotencyKey,
      'app_version': appVersion,
      'platform': platform,
      'locale': locale,
    });
    return nextDeviceId;
  }

  @override
  Future<void> revoke({
    required String deviceId,
    required String accessToken,
  }) async {
    if (revokeFailure != null) {
      throw revokeFailure!;
    }
    revocations.add({'device_id': deviceId, 'access_token': accessToken});
  }
}

class _PendingGateway implements NotificationGateway {
  @override
  Future<String?> currentToken() async => null;

  @override
  Future<NotificationMessage?> initialTapMessage() async => null;

  @override
  Stream<NotificationMessage> foregroundMessages() => const Stream.empty();

  @override
  Future<NotificationPermission> permissionStatus() async =>
      NotificationPermission.notDetermined;

  @override
  Future<NotificationPermission> requestPermission() async =>
      NotificationPermission.notDetermined;

  @override
  Stream<NotificationMessage> tapNavigations() => const Stream.empty();

  @override
  Stream<String> tokenRefreshes() => const Stream.empty();
}

const _testConfiguration = AppConfiguration(
  supabaseUrl: 'https://synthetic.supabase.co',
  supabasePublishableKey: 'synthetic-key',
  apiBaseUrl: 'https://synthetic.example.com',
  oauthRedirectUri: 'com.synthetic://callback',
  clientVersion: '1.2.3',
  platform: 'android',
  environment: 'development',
);

void main() {
  group('DeviceTokenRegistrar', () {
    test('reports server confirmation with a stable installation id', () async {
      final keyStore = InMemoryKeyStore();
      final api = RecordingRegistrationApi();
      final registrar = DeviceTokenRegistrar(
        gateway: FakeNotificationGateway(
          initialPermission: NotificationPermission.granted,
          initialToken: 'push-token-1',
        ),
        api: api,
        keyStore: keyStore,
        configuration: _testConfiguration,
      );

      final confirmed = await registrar.registerToken(
        'push-token-1',
        accessToken: 'access-1',
        userId: 'usr_1',
      );

      expect(confirmed, isTrue);
      expect(api.calls, hasLength(1));
      expect(api.calls[0]['push_token'], 'push-token-1');
      expect(api.calls[0]['app_version'], '1.2.3');
      expect(api.calls[0]['locale'], 'en-LK');
      expect(keyStore.values['memora_push_installation_id'], isNotEmpty);
    });

    test('token rotation produces a fresh idempotency key', () async {
      final api = RecordingRegistrationApi();
      final registrar = DeviceTokenRegistrar(
        gateway: FakeNotificationGateway(
          initialPermission: NotificationPermission.granted,
          initialToken: 'push-token-1',
        ),
        api: api,
        keyStore: InMemoryKeyStore(),
        configuration: _testConfiguration,
      );

      await registrar.registerToken(
        'push-token-1',
        accessToken: 'a',
        userId: 'u',
      );
      await registrar.registerToken(
        'push-token-2',
        accessToken: 'a',
        userId: 'u',
      );

      expect(api.calls, hasLength(2));
      expect(
        api.calls[1]['idempotency_key'],
        isNot(api.calls[0]['idempotency_key']),
      );
    });

    test('unconfirmed registration reports false for retry', () async {
      final api = RecordingRegistrationApi()
        ..registerFailure = Exception('offline');
      final registrar = DeviceTokenRegistrar(
        gateway: FakeNotificationGateway(
          initialPermission: NotificationPermission.granted,
          initialToken: 'push-token-1',
        ),
        api: api,
        keyStore: InMemoryKeyStore(),
        configuration: _testConfiguration,
      );

      final confirmed = await registrar.registerToken(
        'push-token-1',
        accessToken: 'a',
        userId: 'u',
      );
      expect(confirmed, isFalse);
    });

    test('revokes the last confirmed registration on sign-out', () async {
      final api = RecordingRegistrationApi();
      final registrar = DeviceTokenRegistrar(
        gateway: FakeNotificationGateway(
          initialPermission: NotificationPermission.granted,
          initialToken: 'push-token-1',
        ),
        api: api,
        keyStore: InMemoryKeyStore(),
        configuration: _testConfiguration,
      );
      await registrar.registerToken(
        'push-token-1',
        accessToken: 'a1',
        userId: 'u1',
      );

      final revoked = await registrar.revokeLastRegistration();

      expect(revoked, isTrue);
      expect(api.revocations.single['device_id'], 'device-1');
      expect(api.revocations.single['access_token'], 'a1');
      // A second revocation is a no-op: nothing tracked anymore.
      expect(await registrar.revokeLastRegistration(), isTrue);
      expect(api.revocations, hasLength(1));
    });

    test('keeps tracking when the revocation fails offline', () async {
      final api = RecordingRegistrationApi()
        ..revokeFailure = Exception('offline');
      final registrar = DeviceTokenRegistrar(
        gateway: FakeNotificationGateway(
          initialPermission: NotificationPermission.granted,
          initialToken: 'push-token-1',
        ),
        api: api,
        keyStore: InMemoryKeyStore(),
        configuration: _testConfiguration,
      );
      await registrar.registerToken(
        'push-token-1',
        accessToken: 'a1',
        userId: 'u1',
      );

      final revoked = await registrar.revokeLastRegistration();

      expect(revoked, isFalse);
      // Retry after connectivity returns succeeds with the same identity.
      api.revokeFailure = null;
      expect(await registrar.revokeLastRegistration(), isTrue);
      expect(api.revocations, hasLength(1));
    });

    test('revoking without a registration is a no-op', () async {
      final api = RecordingRegistrationApi();
      final registrar = DeviceTokenRegistrar(
        gateway: FakeNotificationGateway(),
        api: api,
        keyStore: InMemoryKeyStore(),
        configuration: _testConfiguration,
      );
      expect(await registrar.revokeLastRegistration(), isTrue);
      expect(api.revocations, isEmpty);
    });

    test('skips registration when permission is not granted', () async {
      final api = RecordingRegistrationApi();
      final registrar = DeviceTokenRegistrar(
        gateway: FakeNotificationGateway(
          initialPermission: NotificationPermission.denied,
          initialToken: 'push-token-1',
        ),
        api: api,
        keyStore: InMemoryKeyStore(),
        configuration: _testConfiguration,
      );

      await registrar.registerIfPermitted();
      expect(api.calls, isEmpty);
    });
  });

  group('requestPermissionOnce', () {
    test('prompts once then replays the stored status', () async {
      final keyStore = InMemoryKeyStore();
      final gateway = FakeNotificationGateway();

      final first = await requestPermissionOnce(
        gateway: gateway,
        keyStore: keyStore,
      );
      final second = await requestPermissionOnce(
        gateway: gateway,
        keyStore: keyStore,
      );

      expect(first, NotificationPermission.granted);
      expect(second, NotificationPermission.granted);
      expect(gateway.askWasCalled, isTrue);
      expect(keyStore.values['memora_push_permission_asked'], 'true');
    });

    test('does not persist the flag while the OS answer is pending', () async {
      final keyStore = InMemoryKeyStore();
      final gatewayStub = _PendingGateway();
      final result = await requestPermissionOnce(
        gateway: gatewayStub,
        keyStore: keyStore,
      );

      expect(result, NotificationPermission.notDetermined);
      expect(
        keyStore.values.containsKey('memora_push_permission_asked'),
        isFalse,
      );
    });
  });
}
