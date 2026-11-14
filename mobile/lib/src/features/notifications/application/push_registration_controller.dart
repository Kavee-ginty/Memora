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
  Future<String> register({
    required String installationId,
    required String pushToken,
    required String idempotencyKey,
    required String appVersion,
    required String platform,
    required String locale,
  }) async {
    return '';
  }

  @override
  Future<void> revoke({
    required String deviceId,
    required String accessToken,
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
/// re-registers whenever the provider rotates the token. Registration
/// failures offer a non-blocking retry; denial never blocks use (PRD 031,
/// T17 gate).
///
/// The app widget keeps this provider alive with `ref.watch`; tests drive
/// [PushRegistrationController] directly with fakes.
final pushRegistrationControllerProvider =
    StateNotifierProvider<PushRegistrationController, PushRegistrationPhase>((
      ref,
    ) {
      final sessionController = ref.read(sessionControllerProvider.notifier);
      final controller = PushRegistrationController(
        gateway: ref.watch(notificationGatewayProvider),
        registrar: ref.watch(deviceTokenRegistrarProvider),
        keyStore: ref.watch(pushKeyStoreProvider),
        sessionStates: ref.watch(sessionControllerProvider.notifier).stream,
      );
      sessionController.revokePushBeforeSignOut =
          controller.revokeBeforeSignOut;
      ref.onDispose(() => sessionController.revokePushBeforeSignOut = null);
      controller.start();
      // StateNotifierProvider disposes the controller itself; an extra
      // onDispose hook would double-dispose and throw "use after dispose".
      return controller;
    });

/// Lifecycle phase of the registration flow (safe, non-blocking states).
///
/// `awaitingExplanation` holds before the OS prompt until the in-app value
/// explanation is confirmed (Flow 12.1: the app explains notification value
/// before the system prompt). `registrationFailed` is recoverable: the
/// controller retries on request or the next authenticated session emission.
enum PushRegistrationPhase {
  idle,
  awaitingExplanation,
  registering,
  ready,
  registrationFailed,
  unavailable,
  denied,
}

class PushRegistrationController extends StateNotifier<PushRegistrationPhase> {
  final NotificationGateway gateway;
  final DeviceTokenRegistrar registrar;
  final SecureKeyStore keyStore;
  final Stream<AppSessionState> sessionStates;

  StreamSubscription<AppSessionState>? _sessionSubscription;
  StreamSubscription<String>? _tokenSubscription;
  bool _started = false;
  String? _lastRegisteredToken;
  String? _lastRegisteredUserId;
  AppSessionState? _lastSessionState;
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

  /// Called on every session-state emission. Sign-out revokes the device
  /// registration while the token may still be valid (review finding 2);
  /// authenticated states register, and also revoke a stale registration
  /// from a previously signed-in account before switching.
  Future<void> onSessionState(AppSessionState sessionState) async {
    _lastSessionState = sessionState;
    if (!mounted) {
      return;
    }
    if (!sessionState.isAuthenticated) {
      await _tokenSubscription?.cancel();
      _tokenSubscription = null;
      _lastRegisteredToken = null;
      await _revokeTrackedRegistration();
      await gateway.invalidateToken();
      if (mounted && state != PushRegistrationPhase.idle) {
        state = PushRegistrationPhase.idle;
      }
      return;
    }
    final userId = sessionState.session?.userId;
    if (_lastRegisteredUserId != null &&
        userId != null &&
        _lastRegisteredUserId != userId) {
      // Account switch: the previous account's registration must not keep
      // receiving pushes on this installation.
      await _revokeTrackedRegistration();
    }
    _lastRegisteredUserId = userId;
    await _handleAuthenticatedSession(sessionState);
  }

  /// Runs before ordinary sign-out revokes the session. If the backend is
  /// offline, invalidating the provider token still stops delivery here.
  Future<bool> revokeBeforeSignOut(String accessToken) async {
    await _tokenSubscription?.cancel();
    _tokenSubscription = null;
    _lastRegisteredToken = null;
    final revoked = await registrar.revokeLastRegistration(
      accessToken: accessToken,
    );
    await gateway.invalidateToken();
    return revoked;
  }

  /// Confirms the in-app notification-value explanation and proceeds to the
  /// OS prompt (Flow 12.1). No-op unless awaiting the explanation.
  Future<void> confirmNotificationExplanation() async {
    if (state != PushRegistrationPhase.awaitingExplanation) {
      return;
    }
    final sessionState = _lastSessionState;
    if (sessionState == null || !sessionState.isAuthenticated) {
      return;
    }
    await _requestPermissionAndRegister(sessionState);
  }

  /// Recoverable denial (Flow 12.1): the user may re-attempt from settings
  /// once the OS allows prompting again.
  Future<void> requestPermissionAgain() async {
    if (state != PushRegistrationPhase.denied) {
      return;
    }
    final sessionState = _lastSessionState;
    if (sessionState == null || !sessionState.isAuthenticated) {
      return;
    }
    await _requestPermissionAndRegister(sessionState);
  }

  /// Allows recovery from a failed registration without waiting for another
  /// auth event or provider token rotation.
  Future<void> retryRegistration() async {
    if (state != PushRegistrationPhase.registrationFailed) {
      return;
    }
    final sessionState = _lastSessionState;
    if (sessionState != null && sessionState.isAuthenticated) {
      await _handleAuthenticatedSession(sessionState);
    }
  }

  Future<void> _handleAuthenticatedSession(AppSessionState sessionState) async {
    if (_registering) {
      return;
    }
    _registering = true;
    try {
      final permission = await gateway.permissionStatus();
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
      if (permission == NotificationPermission.notDetermined) {
        // Flow 12.1: explain the notification value BEFORE the system
        // prompt. The host surfaces the explanation; the prompt runs only
        // after confirmNotificationExplanation().
        state = PushRegistrationPhase.awaitingExplanation;
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
      await _registerToken(sessionState, token);
    } finally {
      _registering = false;
    }
  }

  Future<void> _requestPermissionAndRegister(
    AppSessionState sessionState,
  ) async {
    if (_registering) {
      return;
    }
    _registering = true;
    try {
      final permission = await gateway.requestPermission();
      if (!mounted) {
        return;
      }
      if (permission == NotificationPermission.notDetermined) {
        state = PushRegistrationPhase.awaitingExplanation;
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
      // The decided answer is persisted so restarts skip straight to it.
      const askedKey = 'memora_push_permission_asked';
      await keyStore.write(askedKey, 'true');

      final token = await gateway.currentToken();
      if (!mounted) {
        return;
      }
      if (token == null || token.isEmpty) {
        state = PushRegistrationPhase.idle;
        return;
      }
      await _registerToken(sessionState, token);
    } finally {
      _registering = false;
    }
  }

  Future<void> _registerToken(
    AppSessionState sessionState,
    String token,
  ) async {
    state = PushRegistrationPhase.registering;
    final accessToken = sessionState.session?.accessToken ?? '';
    final userId = sessionState.session?.userId ?? '';
    // Ready only after server confirmation (review finding 1); a failure is
    // recoverable and retried on the next authenticated session emission
    // (bootstrap refresh after reconnect) or token rotation.
    final confirmed = await registrar.registerToken(
      token,
      accessToken: accessToken,
      userId: userId,
    );
    if (!mounted) {
      return;
    }
    if (!confirmed) {
      state = PushRegistrationPhase.registrationFailed;
      return;
    }
    _lastRegisteredToken = token;
    _lastRegisteredUserId = userId;
    state = PushRegistrationPhase.ready;

    // Re-register when the provider rotates the token. Server-side
    // registration is idempotent per installation and token (API-003), so
    // replays converge.
    _tokenSubscription ??= gateway.tokenRefreshes().listen((token) async {
      if (token == _lastRegisteredToken || !mounted) {
        return;
      }
      final sessionState = _lastSessionState;
      if (sessionState == null || !sessionState.isAuthenticated) {
        return;
      }
      final confirmed = await registrar.registerToken(
        token,
        accessToken: sessionState.session?.accessToken ?? '',
        userId: sessionState.session?.userId ?? '',
      );
      if (!mounted) {
        return;
      }
      if (confirmed) {
        _lastRegisteredToken = token;
        state = PushRegistrationPhase.ready;
      } else {
        state = PushRegistrationPhase.registrationFailed;
      }
    });
  }

  Future<void> _revokeTrackedRegistration() async {
    await registrar.revokeLastRegistration();
    _lastRegisteredUserId = null;
  }

  @override
  void dispose() {
    _sessionSubscription?.cancel();
    _tokenSubscription?.cancel();
    super.dispose();
  }
}
