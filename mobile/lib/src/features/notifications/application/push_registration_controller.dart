import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/session_controller.dart';
import '../../auth/data/secure_auth_storage.dart';
import '../../auth/domain/app_session_state.dart';
import '../domain/notification_permission.dart';
import '../infrastructure/device_token_registrar.dart';
import '../infrastructure/firebase_notification_gateway.dart';
import '../infrastructure/notification_gateway.dart';

/// Push gateway for this installation. Production builds use Firebase;
/// tests and unconfigured builds override with [FakeNotificationGateway].
final notificationGatewayProvider = Provider<NotificationGateway>((ref) {
  return FirebaseNotificationGateway();
});

final deviceRegistrationApiProvider = Provider<DeviceRegistrationApi>((ref) {
  // Silent no-op default: widget tests and unconfigured builds pump the app
  // without a registration transport; main.dart overrides with the real one.
  return SilentDeviceRegistrationApi();
});

/// Registration transport that intentionally does nothing (and never
/// throws), used when no API client is configured.
class SilentDeviceRegistrationApi implements DeviceRegistrationApi {
  @override
  Future<void> register({
    required String installationId,
    required String pushToken,
    required String idempotencyKey,
    required String appVersion,
    required String platform,
    required String locale,
  }) async {}
}

final pushKeyStoreProvider = Provider<SecureKeyStore>((ref) {
  return ref.watch(secureKeyStoreProvider);
});

final deviceTokenRegistrarProvider = Provider<DeviceTokenRegistrar>((ref) {
  return DeviceTokenRegistrar(
    gateway: ref.watch(notificationGatewayProvider),
    api: ref.watch(deviceRegistrationApiProvider),
    keyStore: ref.watch(pushKeyStoreProvider),
    configuration: ref.watch(appConfigurationProvider),
  );
});

/// Keep-alive orchestrator (T19 D12): on session activation, asks for
/// permission once per installation, registers the push token, and
/// re-registers whenever the provider rotates the token. Every failure
/// stays silent — notification denial never blocks use (PRD 031, T17 gate).
///
/// The app widget keeps this provider alive with `ref.watch`; tests drive
/// [PushRegistrationController] directly with fakes.
final pushRegistrationControllerProvider =
    StateNotifierProvider<PushRegistrationController, PushRegistrationPhase>((
      ref,
    ) {
      final controller = PushRegistrationController(
        gateway: ref.watch(notificationGatewayProvider),
        registrar: ref.watch(deviceTokenRegistrarProvider),
        keyStore: ref.watch(pushKeyStoreProvider),
        sessionStates: ref.watch(sessionControllerProvider.notifier).stream,
      );
      controller.start();
      // StateNotifierProvider disposes the controller itself; an extra
      // onDispose hook would double-dispose and throw "use after dispose".
      return controller;
    });

/// Lifecycle phase of the registration flow (safe, non-blocking states).
enum PushRegistrationPhase { idle, registering, ready, unavailable, denied }

class PushRegistrationController extends StateNotifier<PushRegistrationPhase> {
  final NotificationGateway gateway;
  final DeviceTokenRegistrar registrar;
  final SecureKeyStore keyStore;
  final Stream<AppSessionState> sessionStates;

  StreamSubscription<AppSessionState>? _sessionSubscription;
  StreamSubscription<String>? _tokenSubscription;
  bool _started = false;
  String? _lastRegisteredToken;
  bool _registering = false;

  PushRegistrationController({
    required this.gateway,
    required this.registrar,
    required this.keyStore,
    required this.sessionStates,
  }) : super(PushRegistrationPhase.idle);

  /// Begins listening to session transitions. Idempotent.
  void start() {
    if (_started) {
      return;
    }
    _started = true;
    _sessionSubscription = sessionStates.listen(onSessionState);
  }

  /// Called on every session-state emission; registers only for active
  /// authenticated sessions and silently resets on sign-out.
  Future<void> onSessionState(AppSessionState sessionState) async {
    if (!mounted) {
      return;
    }
    if (!sessionState.isAuthenticated) {
      await _tokenSubscription?.cancel();
      _tokenSubscription = null;
      _lastRegisteredToken = null;
      if (mounted && state != PushRegistrationPhase.idle) {
        state = PushRegistrationPhase.idle;
      }
      return;
    }
    await _registerForActiveSession();
  }

  Future<void> _registerForActiveSession() async {
    if (_registering) {
      return;
    }
    _registering = true;
    try {
      final permission = await requestPermissionOnce(
        gateway: gateway,
        keyStore: keyStore,
      );
      if (!mounted) {
        return;
      }
      if (permission == NotificationPermission.unavailable) {
        state = PushRegistrationPhase.unavailable;
        return;
      }
      if (permission == NotificationPermission.denied) {
        state = PushRegistrationPhase.denied;
        return;
      }
      if (permission != NotificationPermission.granted) {
        state = PushRegistrationPhase.idle;
        return;
      }

      final token = await gateway.currentToken();
      if (!mounted) {
        return;
      }
      if (token == null || token.isEmpty) {
        state = PushRegistrationPhase.idle;
        return;
      }
      state = PushRegistrationPhase.registering;
      await registrar.registerToken(token);
      _lastRegisteredToken = token;
      if (!mounted) {
        return;
      }
      state = PushRegistrationPhase.ready;

      // Re-register when the provider rotates the token. Server-side
      // registration is idempotent per installation and token (API-003),
      // so replays converge.
      _tokenSubscription ??= gateway.tokenRefreshes().listen((token) async {
        if (token == _lastRegisteredToken || !mounted) {
          return;
        }
        await registrar.registerToken(token);
        _lastRegisteredToken = token;
      });
    } finally {
      _registering = false;
    }
  }

  @override
  void dispose() {
    _sessionSubscription?.cancel();
    _tokenSubscription?.cancel();
    super.dispose();
  }
}
