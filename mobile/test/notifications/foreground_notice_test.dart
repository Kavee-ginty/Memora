import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/features/auth/domain/app_session_state.dart';
import 'package:memora_mobile/src/features/notifications/application/deep_link_controller.dart';
import 'package:memora_mobile/src/features/notifications/application/push_registration_controller.dart';
import 'package:memora_mobile/src/features/notifications/domain/consumed_intent_ledger.dart';
import 'package:memora_mobile/src/features/notifications/domain/notification_message.dart';
import 'package:memora_mobile/src/features/notifications/domain/deep_link_coordinator.dart';
import 'package:memora_mobile/src/features/notifications/infrastructure/deep_link_validation_api.dart';
import 'package:memora_mobile/src/features/notifications/infrastructure/notification_gateway.dart';
import 'package:memora_mobile/src/features/notifications/presentation/foreground_notice.dart';

import 'device_token_registrar_test.dart' show InMemoryKeyStore;

class _StubValidationApi implements DeepLinkValidationApi {
  const _StubValidationApi();

  @override
  Future<MissionValidation> todayMission() async =>
      const MissionValidation.invalid();

  @override
  Future<DeepLinkResourceState> learningUpdate(
    String updateId, {
    required bool requireCommitted,
  }) async {
    return DeepLinkResourceState.unavailable;
  }

  @override
  Future<DeepLinkResourceState> privacyExport(String requestId) async {
    return DeepLinkResourceState.unavailable;
  }
}

const _missionPayload = <String, String>{
  'schema_version': '1',
  'notification_id': 'a1b2c3d4e5f60718293a4b5c6d7e8f90',
  'category': 'mission_ready',
  'route_intent': 'open_mission_preview',
  'resource_type': 'mission',
  'resource_id': '018f3c2a-7b9c-4d1e-9f2a-3b4c5d6e7f80',
  'expires_at': '2099-01-01T00:00:00Z',
  'loc_key': 'notification.mission_ready',
  'param.count': '5',
};

Widget _wrap({required FakeNotificationGateway gateway}) {
  return ProviderScope(
    overrides: <Override>[
      notificationGatewayProvider.overrideWithValue(gateway),
      currentRoutePathProvider.overrideWithValue('/home'),
    ],
    child: MaterialApp(
      home: ForegroundNoticeHost(
        child: const Scaffold(body: SizedBox.expand()),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the foreground notice with contextual copy', (
    WidgetTester tester,
  ) async {
    final gateway = FakeNotificationGateway();
    await tester.pumpWidget(_wrap(gateway: gateway));

    gateway.emitForeground(const NotificationMessage(data: _missionPayload));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('notice_tap')), findsOneWidget);
    expect(find.textContaining('daily mission is ready'), findsOneWidget);
  });

  testWidgets('tap consumes the intent through the coordinator', (
    WidgetTester tester,
  ) async {
    final gateway = FakeNotificationGateway();
    final keyStore = InMemoryKeyStore();
    final navigations = <String>[];
    DeepLinkController? controller;

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          notificationGatewayProvider.overrideWithValue(gateway),
          currentRoutePathProvider.overrideWithValue('/home'),
          deepLinkControllerProvider.overrideWith((ref) {
            controller = DeepLinkController(
              gateway: gateway,
              validationApi: const _StubValidationApi(),
              ledger: ConsumedIntentLedger(keyStore: keyStore),
              navigate: navigations.add,
              sessionStates: const Stream<AppSessionState>.empty(),
              isAuthenticated: () => true,
            );
            return controller!;
          }),
        ],
        child: MaterialApp(
          home: ForegroundNoticeHost(
            child: const Scaffold(body: SizedBox.expand()),
          ),
        ),
      ),
    );

    gateway.emitForeground(const NotificationMessage(data: _missionPayload));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('notice_tap')));
    await tester.pumpAndSettle();

    expect(navigations, isNotEmpty); // coordinator consumed + navigated
    expect(
      await ConsumedIntentLedger(keyStore: keyStore)
          .alreadyConsumed('a1b2c3d4e5f60718293a4b5c6d7e8f90'),
      isTrue,
    );
    expect(find.byKey(const ValueKey('notice_tap')), findsNothing);
  });

  testWidgets('dismissal closes the notice and leaves state unchanged', (
    WidgetTester tester,
  ) async {
    final gateway = FakeNotificationGateway();
    final keyStore = InMemoryKeyStore();
    final navigations = <String>[];

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          notificationGatewayProvider.overrideWithValue(gateway),
          currentRoutePathProvider.overrideWithValue('/home'),
          deepLinkControllerProvider.overrideWith((ref) {
            return DeepLinkController(
              gateway: gateway,
              validationApi: const _StubValidationApi(),
              ledger: ConsumedIntentLedger(keyStore: keyStore),
              navigate: navigations.add,
              sessionStates: const Stream<AppSessionState>.empty(),
              isAuthenticated: () => true,
            );
          }),
        ],
        child: MaterialApp(
          home: ForegroundNoticeHost(
            child: const Scaffold(body: SizedBox.expand()),
          ),
        ),
      ),
    );

    gateway.emitForeground(const NotificationMessage(data: _missionPayload));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('notice_dismiss')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('notice_dismiss')), findsNothing);
    expect(navigations, isEmpty); // dismiss changes nothing (Flow §13.2)
    expect(
      await ConsumedIntentLedger(keyStore: keyStore)
          .alreadyConsumed('a1b2c3d4e5f60718293a4b5c6d7e8f90'),
      isFalse,
    );
  });

  testWidgets('queues notices during an active answer and drains after', (
    WidgetTester tester,
  ) async {
    final gateway = FakeNotificationGateway();
    final pathBox = <String?>['/missions/m1/item/i1'];

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return ProviderScope(
            overrides: <Override>[
              notificationGatewayProvider.overrideWithValue(gateway),
              currentRoutePathProvider.overrideWith((ref) => pathBox[0]),
            ],
            child: MaterialApp(
              home: ForegroundNoticeHost(
                routePathReader: () => pathBox[0],
                child: Scaffold(
                  body: TextButton(
                    onPressed: () {
                      pathBox[0] = '/home';
                      setState(() {});
                    },
                    child: const Text('leave mission'),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    gateway.emitForeground(const NotificationMessage(data: _missionPayload));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('notice_tap')), findsNothing);

    await tester.tap(find.text('leave mission'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('notice_tap')), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 7));
  });

  testWidgets('announces the notice politely for screen readers', (
    WidgetTester tester,
  ) async {
    final gateway = FakeNotificationGateway();
    await tester.pumpWidget(_wrap(gateway: gateway));

    gateway.emitForeground(const NotificationMessage(data: _missionPayload));
    await tester.pumpAndSettle();

    final semantics = tester.getSemantics(
      find
          .ancestor(
            of: find.byKey(const ValueKey('notice_tap')),
            matching: find.byType(Semantics),
          )
          .first,
    );
    expect(semantics.hasFlag(SemanticsFlag.isLiveRegion), isTrue);

    await tester.pumpAndSettle(const Duration(seconds: 7));
  });

  testWidgets('fallback taps surface the brief explanation snackbar', (
    WidgetTester tester,
  ) async {
    final gateway = FakeNotificationGateway();
    final keyStore = InMemoryKeyStore();
    final navigations = <String>[];

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          notificationGatewayProvider.overrideWithValue(gateway),
          currentRoutePathProvider.overrideWithValue('/home'),
          deepLinkControllerProvider.overrideWith((ref) {
            return DeepLinkController(
              gateway: gateway,
              // Stub validation reports unavailable: the tap resolves to the
              // stable parent with an explanation (Flow §13.1).
              validationApi: const _StubValidationApi(),
              ledger: ConsumedIntentLedger(keyStore: keyStore),
              navigate: navigations.add,
              sessionStates: const Stream<AppSessionState>.empty(),
              isAuthenticated: () => true,
            );
          }),
        ],
        child: MaterialApp(
          home: ForegroundNoticeHost(
            child: const Scaffold(body: SizedBox.expand()),
          ),
        ),
      ),
    );

    gateway.emitForeground(const NotificationMessage(data: _missionPayload));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('notice_tap')));
    await tester.pumpAndSettle();

    expect(navigations, isNotEmpty);
    expect(find.byKey(const ValueKey('notice_explanation')), findsOneWidget);
    expect(find.textContaining('workflow already moved on'), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 7));
  });

  testWidgets('renders within 320 px and 200 percent text scale', (
    WidgetTester tester,
  ) async {
    final gateway = FakeNotificationGateway();
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          notificationGatewayProvider.overrideWithValue(gateway),
          currentRoutePathProvider.overrideWithValue('/home'),
        ],
        child: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: MaterialApp(
            home: ForegroundNoticeHost(
              child: const Scaffold(body: SizedBox.expand()),
            ),
          ),
        ),
      ),
    );

    gateway.emitForeground(const NotificationMessage(data: _missionPayload));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('notice_tap')), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 7));
  });
}
