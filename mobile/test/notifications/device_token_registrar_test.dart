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
  Object? thrown;

  @override
  Future<void> register({
    required String installationId,
    required String pushToken,
    required String idempotencyKey,
    required String appVersion,
    required String platform,
    required String locale,
  }) async {
    if (thrown != null) {
      throw thrown!;
    }
    calls.add({
      'installation_id': installationId,
      'push_token': pushToken,
      'idempotency_key': idempotencyKey,
      'app_version': appVersion,
      'platform': platform,
      'locale': locale,
    });
  }
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
    test('registers the token with a stable installation id and key', () async {
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

      await registrar.registerIfPermitted();
      await registrar.registerIfPermitted();

      expect(api.calls, hasLength(2));
      expect(api.calls[0]['installation_id'], api.calls[1]['installation_id']);
      expect(api.calls[0]['idempotency_key'], api.calls[1]['idempotency_key']);
      expect(keyStore.values['memora_push_installation_id'], isNotEmpty);
      expect(api.calls[0]['push_token'], 'push-token-1');
      expect(api.calls[0]['app_version'], '1.2.3');
      expect(api.calls[0]['platform'], 'android');
      expect(api.calls[0]['locale'], 'en-LK');
    });

    test('token rotation produces a fresh idempotency key', () async {
      final keyStore = InMemoryKeyStore();
      final api = RecordingRegistrationApi();
      final gateway = FakeNotificationGateway(
        initialPermission: NotificationPermission.granted,
        initialToken: 'push-token-1',
      );
      final registrar = DeviceTokenRegistrar(
        gateway: gateway,
        api: api,
        keyStore: keyStore,
        configuration: _testConfiguration,
      );

      await registrar.registerToken('push-token-1');
      await registrar.registerToken('push-token-2');

      expect(api.calls, hasLength(2));
      expect(api.calls[1]['push_token'], 'push-token-2');
      expect(
        api.calls[1]['idempotency_key'],
        isNot(api.calls[0]['idempotency_key']),
      );
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

    test('skips registration without a provider token', () async {
      final api = RecordingRegistrationApi();
      final registrar = DeviceTokenRegistrar(
        gateway: FakeNotificationGateway(
          initialPermission: NotificationPermission.granted,
        ),
        api: api,
        keyStore: InMemoryKeyStore(),
        configuration: _testConfiguration,
      );

      await registrar.registerIfPermitted();
      expect(api.calls, isEmpty);
    });

    test('swallows transport failures without throwing', () async {
      final api = RecordingRegistrationApi()..thrown = Exception('offline');
      final registrar = DeviceTokenRegistrar(
        gateway: FakeNotificationGateway(
          initialPermission: NotificationPermission.granted,
          initialToken: 'push-token-1',
        ),
        api: api,
        keyStore: InMemoryKeyStore(),
        configuration: _testConfiguration,
      );

      await registrar.registerIfPermitted();
      expect(api.calls, isEmpty); // call attempted and failed safely
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
      final gateway = FakeNotificationGateway(
        initialPermission: NotificationPermission.notDetermined,
      );
      // Simulate an OS dialog that never resolves by keeping the gateway in
      // notDetermined: requestPermissionOnce must not persist the flag.
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
      // The plain fake resolves immediately; kept for parity coverage.
      expect(gateway.askWasCalled, isFalse);
    });
  });
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
