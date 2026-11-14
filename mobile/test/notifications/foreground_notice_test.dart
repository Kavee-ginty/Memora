import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memora_api_client/memora_api_client.dart';
import 'package:memora_mobile/src/configuration/app_configuration.dart';
import 'package:memora_mobile/src/features/auth/domain/app_session_state.dart';
import 'package:memora_mobile/src/features/auth/domain/bootstrap_state.dart';
import 'package:memora_mobile/src/features/notifications/application/deep_link_controller.dart';
import 'package:memora_mobile/src/features/notifications/application/push_registration_controller.dart';
import 'package:memora_mobile/src/features/notifications/domain/consumed_intent_ledger.dart';
import 'package:memora_mobile/src/features/notifications/domain/notification_message.dart';
import 'package:memora_mobile/src/features/notifications/domain/notification_permission.dart';
import 'package:memora_mobile/src/features/notifications/infrastructure/deep_link_validation_api.dart';
import 'package:memora_mobile/src/features/notifications/infrastructure/device_token_registrar.dart';
import 'package:memora_mobile/src/features/notifications/infrastructure/notification_gateway.dart';
import 'package:memora_mobile/src/features/notifications/presentation/foreground_notice.dart';
import 'package:memora_mobile/src/routing/app_router.dart';

import 'device_token_registrar_test.dart'
    show InMemoryKeyStore, RecordingRegistrationApi;

class _StubValidationApi implements DeepLinkValidationApi {
  const _StubValidationApi();

  @override
  Future<MissionValidation> todayMission() async =>
      const MissionValidation.invalid();

  @override
  Future<DeepLinkResourceState> learningUpdate(
    String updateId, {
    required LearningUpdateStatus requiredStatus,
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

Widget _wrap({
  required FakeNotificationGateway gateway,
  bool reducedMotion = false,
}) {
  return ProviderScope(
    overrides: <Override>[
      notificationGatewayProvider.overrideWithValue(gateway),
      currentRoutePathProvider.overrideWith(
        (ref) =>
            () => '/home',
      ),
    ],
    child: MaterialApp(
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(disableAnimations: reducedMotion),
          child: ForegroundNoticeHost(
            child: const Scaffold(body: SizedBox.expand()),
          ),
        ),
      ),
    ),
  );
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

  testWidgets('removes notice motion when reduced motion is requested', (
    WidgetTester tester,
  ) async {
    final gateway = FakeNotificationGateway();
    await tester.pumpWidget(_wrap(gateway: gateway, reducedMotion: true));

    gateway.emitForeground(const NotificationMessage(data: _missionPayload));
    await tester.pumpAndSettle();

    final slide = tester.widget<AnimatedSlide>(find.byType(AnimatedSlide));
    expect(slide.duration, Duration.zero);
    expect(slide.offset, Offset.zero);
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
          currentRoutePathProvider.overrideWith(
            (ref) =>
                () => '/home',
          ),
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
          currentRoutePathProvider.overrideWith(
            (ref) =>
                () => '/home',
          ),
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
    // Production router: the host observes real route changes (review
    // finding 7) instead of relying on an injected reader.
    final gateway = FakeNotificationGateway();
    late final GoRouter router;
    router = GoRouter(
      initialLocation: '/missions/m1/item/i1',
      routes: <RouteBase>[
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: Text('home')),
        ),
        GoRoute(
          path: '/missions/m1/item/i1',
          builder: (_, _) => Scaffold(
            body: TextButton(
              onPressed: () => router.go('/home'),
              child: const Text('go home'),
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          notificationGatewayProvider.overrideWithValue(gateway),
          appRouterProvider.overrideWithValue(router),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          builder: (context, child) =>
              ForegroundNoticeHost(child: child ?? const SizedBox.shrink()),
        ),
      ),
    );

    gateway.emitForeground(const NotificationMessage(data: _missionPayload));
    await tester.pumpAndSettle();
    // Suppressed while the active answer is on screen.
    expect(find.byKey(const ValueKey('notice_tap')), findsNothing);

    await tester.tap(find.text('go home'));
    await tester.pumpAndSettle();
    expect(find.text('go home'), findsNothing); // route left the answer
    expect(find.byKey(const ValueKey('notice_tap')), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 7));
  });

  testWidgets('background taps surface the explanation snackbar too', (
    WidgetTester tester,
  ) async {
    final gateway = FakeNotificationGateway();
    final navigations = <String>[];

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          notificationGatewayProvider.overrideWithValue(gateway),
          currentRoutePathProvider.overrideWith(
            (ref) =>
                () => '/home',
          ),
          deepLinkControllerProvider.overrideWith((ref) {
            final controller = DeepLinkController(
              gateway: gateway,
              // Unavailable validation: the expired intent below resolves to
              // the stable parent with an explanation.
              validationApi: const _StubValidationApi(),
              ledger: ConsumedIntentLedger(keyStore: InMemoryKeyStore()),
              navigate: navigations.add,
              sessionStates: const Stream<AppSessionState>.empty(),
              isAuthenticated: () => true,
            );
            controller.start();
            return controller;
          }),
        ],
        child: MaterialApp(
          home: ForegroundNoticeHost(
            child: const Scaffold(body: SizedBox.expand()),
          ),
        ),
      ),
    );

    // A background tap with an expired intent: no notice banner exists in
    // the foreground stream path — the explanation must still surface
    // (review finding 8).
    final expired = Map<String, String>.from(_missionPayload)
      ..['expires_at'] = '2026-01-01T00:00:00Z';
    gateway.emitTap(NotificationMessage(data: expired));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('notice_explanation')), findsOneWidget);
    expect(find.textContaining('has expired'), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 7));
  });

  testWidgets('explains notification value before requesting permission', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final gateway = FakeNotificationGateway(
      initialPermission: NotificationPermission.notDetermined,
      initialToken: 'push-token-1',
    );
    final api = RecordingRegistrationApi()
      ..registerFailure = Exception('offline');
    final sessions = StreamController<AppSessionState>.broadcast();
    addTearDown(sessions.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          notificationGatewayProvider.overrideWithValue(gateway),
          currentRoutePathProvider.overrideWith(
            (ref) =>
                () => '/home',
          ),
          pushRegistrationControllerProvider.overrideWith((ref) {
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
            return controller;
          }),
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

    sessions.add(
      AppSessionState.active(
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
      ),
    );
    await tester.pumpAndSettle();

    // The explanation banner is visible and the OS prompt has NOT run yet
    // (Flow §12.1).
    expect(find.byKey(const ValueKey('push_explanation')), findsOneWidget);
    expect(gateway.askWasCalled, isFalse);

    await tester.tap(find.byKey(const ValueKey('push_explanation_enable')));
    await tester.pumpAndSettle();
    expect(gateway.askWasCalled, isTrue);
    expect(
      find.byKey(const ValueKey('push_registration_retry_notice')),
      findsOneWidget,
    );
    api.registerFailure = null;
    await tester.tap(find.byKey(const ValueKey('push_registration_retry')));
    await tester.pumpAndSettle();
    expect(api.calls, hasLength(1));
    expect(
      find.byKey(const ValueKey('push_registration_retry_notice')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
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
    expect(semantics.flagsCollection.isLiveRegion, isTrue);

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
          currentRoutePathProvider.overrideWith(
            (ref) =>
                () => '/home',
          ),
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
          currentRoutePathProvider.overrideWith(
            (ref) =>
                () => '/home',
          ),
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
