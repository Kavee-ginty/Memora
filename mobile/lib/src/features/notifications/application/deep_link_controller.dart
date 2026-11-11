import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:memora_api_client/memora_api_client.dart';

import '../../../configuration/app_configuration.dart';
import '../../../routing/app_router.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/data/secure_auth_storage.dart';
import '../../auth/domain/app_session_state.dart';
import '../domain/consumed_intent_ledger.dart';
import '../domain/deep_link_coordinator.dart';
import '../domain/notification_message.dart';
import '../infrastructure/deep_link_validation_api.dart';
import '../infrastructure/notification_gateway.dart';
import 'push_registration_controller.dart';

final consumedIntentLedgerProvider = Provider<ConsumedIntentLedger>((ref) {
  return ConsumedIntentLedger(keyStore: ref.watch(pushKeyStoreProvider));
});

final deepLinkValidationApiProvider = Provider<DeepLinkValidationApi>((ref) {
  final apiClient = ref.watch(memoraApiClientProvider);
  if (apiClient == null) {
    return const StubDeepLinkValidationApi();
  }
  final configuration = ref.watch(appConfigurationProvider);
  return MemoraDeepLinkValidationApi(
    apiClient: apiClient,
    configuration: configuration,
  );
});

/// The configured API client, or null in mock/unconfigured builds where
/// every deep-link validation degrades to its stable fallback.
final memoraApiClientProvider = Provider<MemoraApiClient?>((ref) {
  return null;
});

/// Validation API used when no client is configured: every resource reads
/// as unavailable so taps resolve to stable parents instead of navigating.
class StubDeepLinkValidationApi implements DeepLinkValidationApi {
  const StubDeepLinkValidationApi();

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

/// Keep-alive deep-link orchestrator: subscribes to gateway taps and cold
/// starts, validates each intent through the coordinator and navigates.
///
/// Cold-start taps wait for the session bootstrap to settle before they are
/// handled, so validation runs against a resolved session (Flow §13.1:
/// bootstrap validates session first).
final deepLinkControllerProvider =
    StateNotifierProvider<DeepLinkController, DeepLinkDecision?>((ref) {
      final controller = DeepLinkController(
        gateway: ref.watch(notificationGatewayProvider),
        validationApi: ref.watch(deepLinkValidationApiProvider),
        ledger: ref.watch(consumedIntentLedgerProvider),
        navigate: (path) => ref.read(appRouterProvider).go(path),
        sessionStates: ref.watch(sessionControllerProvider.notifier).stream,
        isAuthenticated: () =>
            ref.read(sessionControllerProvider).isAuthenticated,
      );
      controller.start();
      // Riverpod disposes the StateNotifier itself.
      return controller;
    });

class DeepLinkController extends StateNotifier<DeepLinkDecision?> {
  final NotificationGateway gateway;
  final DeepLinkValidationApi validationApi;
  final ConsumedIntentLedger ledger;
  final void Function(String path) navigate;
  final Stream<AppSessionState> sessionStates;
  final bool Function() isAuthenticated;

  DeepLinkCoordinator? _coordinator;
  StreamSubscription<NotificationMessage>? _tapSubscription;
  StreamSubscription<AppSessionState>? _sessionSubscription;
  NotificationMessage? _pendingColdStartTap;
  AppSessionState? _lastSessionState;
  bool _started = false;

  DeepLinkController({
    required this.gateway,
    required this.validationApi,
    required this.ledger,
    required this.navigate,
    required this.sessionStates,
    required this.isAuthenticated,
  }) : super(null);

  DeepLinkCoordinator get _resolvedCoordinator {
    return _coordinator ??= DeepLinkCoordinator(
      validationApi: validationApi,
      ledger: ledger,
      navigate: navigate,
      clock: DateTime.now,
      isAuthenticated: isAuthenticated,
    );
  }

  /// Begins listening. Idempotent.
  Future<void> start() async {
    if (_started) {
      return;
    }
    _started = true;

    _sessionSubscription = sessionStates.listen((state) {
      _lastSessionState = state;
      _drainColdStartTap();
    });
    _tapSubscription = gateway.tapNavigations().listen(
      (message) => _handleTapMessage(message),
    );

    final initial = await gateway.initialTapMessage();
    if (initial != null) {
      _pendingColdStartTap = initial;
      _drainColdStartTap();
    }
  }

  /// Test seam: handles one foreground-originated tap explicitly.
  Future<DeepLinkDecision> handleTapData(Map<String, String> data) {
    return _resolvedCoordinator.handleTap(data);
  }

  void _handleTapMessage(NotificationMessage message) {
    _resolvedCoordinator.handleTap(message.data).then((decision) {
      if (mounted) {
        state = decision;
      }
    });
  }

  /// Cold-start taps are held until the bootstrap settles (unknown ->
  /// bootstrapping -> active/signed-out) so session-dependent validation
  /// sees a resolved state. The session stream re-runs this drain on every
  /// transition until the phase resolves.
  void _drainColdStartTap() {
    final pending = _pendingColdStartTap;
    if (pending == null || !_bootstrapSettled) {
      return;
    }
    _pendingColdStartTap = null;
    _handleTapMessage(pending);
  }

  bool get _bootstrapSettled {
    final state = _lastSessionState;
    return state != null && (state.isAuthenticated || state.isSignedOut);
  }

  @override
  void dispose() {
    _tapSubscription?.cancel();
    _sessionSubscription?.cancel();
    super.dispose();
  }
}
