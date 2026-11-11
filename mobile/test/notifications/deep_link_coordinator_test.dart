import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/features/notifications/domain/consumed_intent_ledger.dart';
import 'package:memora_mobile/src/features/notifications/domain/deep_link_coordinator.dart';
import 'package:memora_mobile/src/features/notifications/infrastructure/deep_link_validation_api.dart';

import 'device_token_registrar_test.dart' show InMemoryKeyStore;

class FakeValidationApi implements DeepLinkValidationApi {
  MissionValidation missionResult = const MissionValidation.valid('mission-1');
  DeepLinkResourceState updateResult = DeepLinkResourceState.valid;
  DeepLinkResourceState exportResult = DeepLinkResourceState.valid;

  @override
  Future<MissionValidation> todayMission() async => missionResult;

  @override
  Future<DeepLinkResourceState> learningUpdate(
    String updateId, {
    required bool requireCommitted,
  }) async => updateResult;

  @override
  Future<DeepLinkResourceState> privacyExport(String requestId) async =>
      exportResult;
}

DateTime _fixedClock() => DateTime.utc(2026, 11, 11, 12);

String _expiry({int hours = 24}) =>
    _fixedClock().add(Duration(hours: hours)).toIso8601String();

Map<String, String> _payload(
  String category, {
  String? resourceId,
  String? routeIntent,
  String? locKey,
  String notificationId = 'a1b2c3d4e5f60718293a4b5c6d7e8f90',
  String? expiresAt,
}) {
  return {
    'schema_version': '1',
    'notification_id': notificationId,
    'category': category,
    'route_intent': routeIntent ?? _defaultRouteIntent(category),
    'resource_type': 'resource',
    'resource_id': resourceId ?? '018f3c2a-7b9c-4d1e-9f2a-3b4c5d6e7f80',
    'expires_at': expiresAt ?? _expiry(),
    'loc_key': locKey ?? _defaultLocKey(category),
  };
}

String _defaultRouteIntent(String category) {
  switch (category) {
    case 'mission_ready':
    case 'due_memories':
      return 'open_mission_preview';
    case 'verification_required':
      return 'open_verify_concepts';
    case 'learning_path_ready':
      return 'open_path_preview';
    case 'reward_ready':
      return 'open_progress';
    case 'privacy_export_ready':
      return 'open_export_status';
  }
  return '';
}

String _defaultLocKey(String category) => 'notification.$category';

class Harness {
  final FakeValidationApi validationApi = FakeValidationApi();
  final InMemoryKeyStore keyStore = InMemoryKeyStore();
  final List<String> navigations = [];
  bool authenticated = true;

  late final ConsumedIntentLedger ledger = ConsumedIntentLedger(
    keyStore: keyStore,
  );
  late final DeepLinkCoordinator coordinator = DeepLinkCoordinator(
    validationApi: validationApi,
    ledger: ledger,
    navigate: navigations.add,
    clock: _fixedClock,
    isAuthenticated: () => authenticated,
  );
}

void main() {
  group('DeepLinkCoordinator', () {
    test('malformed payloads discard silently without navigation', () async {
      final harness = Harness();

      final decision = await harness.coordinator.handleTap({
        'schema_version': '9',
        'category': 'mission_ready',
      });

      expect(decision.resolution, DeepLinkResolution.discarded);
      expect(harness.navigations, isEmpty);
    });

    test('expired intents fall back and are consumed', () async {
      final harness = Harness();
      final payload = _payload(
        'verification_required',
        expiresAt: _fixedClock()
            .subtract(const Duration(hours: 1))
            .toIso8601String(),
      );

      final decision = await harness.coordinator.handleTap(payload);

      expect(decision.resolution, DeepLinkResolution.fallback);
      expect(decision.explanationLocKey, DeepLinkExplanations.linkExpired);
      expect(
        decision.navigationPath,
        '/learning/updates/018f3c2a-7b9c-4d1e-9f2a-3b4c5d6e7f80',
      );
      expect(harness.navigations.single, decision.navigationPath);
      expect(
        await harness.ledger.alreadyConsumed(
          'a1b2c3d4e5f60718293a4b5c6d7e8f90',
        ),
        isTrue,
      );
    });

    test('consumed intents never replay after later navigation', () async {
      final harness = Harness();
      final payload = _payload('reward_ready');

      final first = await harness.coordinator.handleTap(payload);
      expect(first.resolution, DeepLinkResolution.navigate);

      final replay = await harness.coordinator.handleTap(payload);
      expect(replay.resolution, DeepLinkResolution.alreadyConsumed);
      expect(harness.navigations, hasLength(1));
    });

    test(
      'signed-out mission tap hands off to sign-in without consuming',
      () async {
        final harness = Harness()..authenticated = false;

        final decision = await harness.coordinator.handleTap(
          _payload('mission_ready'),
        );

        expect(decision.resolution, DeepLinkResolution.handedToSignIn);
        expect(
          decision.navigationPath,
          '/missions/018f3c2a-7b9c-4d1e-9f2a-3b4c5d6e7f80/preview',
        );
        expect(
          await harness.ledger.alreadyConsumed(
            'a1b2c3d4e5f60718293a4b5c6d7e8f90',
          ),
          isFalse,
        );
      },
    );

    test('mission intents validate the open mission through the API', () async {
      final harness = Harness();

      final decision = await harness.coordinator.handleTap(
        _payload('due_memories'),
      );

      expect(decision.resolution, DeepLinkResolution.navigate);
      expect(decision.navigationPath, '/missions/mission-1/preview');
    });

    test('mission intents fall home when no open mission exists', () async {
      final harness = Harness()
        ..validationApi.missionResult = const MissionValidation.invalid();

      final decision = await harness.coordinator.handleTap(
        _payload('due_memories'),
      );

      expect(decision.resolution, DeepLinkResolution.fallback);
      expect(decision.navigationPath, '/home');
      expect(decision.explanationLocKey, DeepLinkExplanations.workflowMovedOn);
    });

    test('verification taps navigate to the verify route', () async {
      final harness = Harness();

      final decision = await harness.coordinator.handleTap(
        _payload(
          'verification_required',
          routeIntent: 'open_verify_concepts',
          locKey: 'notification.verification_required',
        ),
      );

      expect(decision.resolution, DeepLinkResolution.navigate);
      expect(
        decision.navigationPath,
        '/learning/updates/018f3c2a-7b9c-4d1e-9f2a-3b4c5d6e7f80/verify',
      );
    });

    test(
      'wrong-owner verification updates fall back to material status',
      () async {
        final harness = Harness()
          ..validationApi.updateResult = DeepLinkResourceState.missing;

        final decision = await harness.coordinator.handleTap(
          _payload(
            'verification_required',
            routeIntent: 'open_verify_concepts',
            locKey: 'notification.verification_required',
          ),
        );

        expect(decision.resolution, DeepLinkResolution.fallback);
        expect(
          decision.navigationPath,
          '/learning/updates/018f3c2a-7b9c-4d1e-9f2a-3b4c5d6e7f80',
        );
        expect(
          decision.explanationLocKey,
          DeepLinkExplanations.linkUnavailable,
        );
      },
    );

    test('learning-path taps demand the committed workflow state', () async {
      final harness = Harness()
        ..validationApi.updateResult = DeepLinkResourceState.invalidState;

      final decision = await harness.coordinator.handleTap(
        _payload(
          'learning_path_ready',
          routeIntent: 'open_path_preview',
          locKey: 'notification.learning_path_ready',
        ),
      );

      expect(decision.resolution, DeepLinkResolution.fallback);
      expect(decision.navigationPath, '/learning');
      expect(decision.explanationLocKey, DeepLinkExplanations.workflowMovedOn);
    });

    test('reward taps resolve to progress without an API call', () async {
      final harness = Harness();

      final decision = await harness.coordinator.handleTap(
        _payload(
          'reward_ready',
          routeIntent: 'open_progress',
          locKey: 'notification.reward_ready',
        ),
      );

      expect(decision.resolution, DeepLinkResolution.navigate);
      expect(decision.navigationPath, '/progress');
    });

    test('privacy export taps navigate to the status route', () async {
      final harness = Harness();

      final decision = await harness.coordinator.handleTap(
        _payload(
          'privacy_export_ready',
          routeIntent: 'open_export_status',
          locKey: 'notification.privacy_export_ready',
        ),
      );

      expect(decision.resolution, DeepLinkResolution.navigate);
      expect(
        decision.navigationPath,
        '/profile/privacy/export/018f3c2a-7b9c-4d1e-9f2a-3b4c5d6e7f80',
      );
    });

    test('missing privacy exports fall back to the privacy hub', () async {
      final harness = Harness()
        ..validationApi.exportResult = DeepLinkResourceState.missing;

      final decision = await harness.coordinator.handleTap(
        _payload(
          'privacy_export_ready',
          routeIntent: 'open_export_status',
          locKey: 'notification.privacy_export_ready',
        ),
      );

      expect(decision.resolution, DeepLinkResolution.fallback);
      expect(decision.navigationPath, '/profile/privacy');
    });
  });
}
