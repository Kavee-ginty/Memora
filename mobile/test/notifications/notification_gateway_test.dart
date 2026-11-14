import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/features/notifications/domain/notification_message.dart';
import 'package:memora_mobile/src/features/notifications/domain/notification_permission.dart';
import 'package:memora_mobile/src/features/notifications/infrastructure/notification_gateway.dart';

void main() {
  group('FakeNotificationGateway', () {
    test('reports programmed permission without prompting', () async {
      final gateway = FakeNotificationGateway(
        initialPermission: NotificationPermission.denied,
      );

      expect(await gateway.permissionStatus(), NotificationPermission.denied);
      expect(gateway.askWasCalled, isFalse);
      gateway.dispose();
    });

    test('requestPermission resolves notDetermined to granted once', () async {
      final gateway = FakeNotificationGateway();

      final granted = await gateway.requestPermission();
      expect(granted, NotificationPermission.granted);
      expect(gateway.askWasCalled, isTrue);
      expect(await gateway.permissionStatus(), NotificationPermission.granted);
      gateway.dispose();
    });

    test('requestPermission keeps an explicit denial sticky', () async {
      final gateway = FakeNotificationGateway(
        initialPermission: NotificationPermission.denied,
      );

      expect(await gateway.requestPermission(), NotificationPermission.denied);
      expect(await gateway.permissionStatus(), NotificationPermission.denied);
      gateway.dispose();
    });

    test('token and message streams broadcast to multiple listeners', () async {
      final gateway = FakeNotificationGateway(initialToken: 'token-a');

      final tokens = <String>[];
      final taps = <NotificationMessage>[];
      final sub1 = gateway.tokenRefreshes().listen(tokens.add);
      final sub2 = gateway.tapNavigations().listen(taps.add);
      addTearDown(() async {
        await sub1.cancel();
        await sub2.cancel();
        gateway.dispose();
      });

      gateway.emitTokenRefresh('token-b');
      gateway.emitTap(const NotificationMessage(data: {'category': 'x'}));
      await pumpEventQueue();

      expect(tokens, ['token-b']);
      expect(taps.single.data['category'], 'x');
      expect(await gateway.currentToken(), 'token-a');
    });

    test('initial tap message is readable before streams fire', () async {
      final gateway = FakeNotificationGateway()
        ..initialTap = const NotificationMessage(data: {'cold': 'start'});

      final initial = await gateway.initialTapMessage();
      expect(initial?.data['cold'], 'start');
      gateway.dispose();
    });
  });
}
