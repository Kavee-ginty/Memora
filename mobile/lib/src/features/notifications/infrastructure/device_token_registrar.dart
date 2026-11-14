import 'dart:async';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/foundation.dart';
import 'package:memora_api_client/memora_api_client.dart';

import '../../../configuration/app_configuration.dart';
import '../../common/ids.dart';
import '../../auth/data/secure_auth_storage.dart';
import '../domain/notification_permission.dart';
import 'notification_gateway.dart';

/// Transport for the `POST /v1/devices` registration and the
/// `DELETE /v1/devices/{device_id}` revocation (T06 operations).
///
/// Indirection keeps the registrar testable without the generated client.
abstract class DeviceRegistrationApi {
  /// Registers the device; completes only after server confirmation.
  Future<String> register({
    required String installationId,
    required String pushToken,
    required String idempotencyKey,
    required String appVersion,
    required String platform,
    required String locale,
  });

  /// Revokes a device registration while the session is still valid.
  Future<void> revoke({required String deviceId, required String accessToken});
}

class MemoraDeviceRegistrationApi implements DeviceRegistrationApi {
  final MemoraApiClient apiClient;
  final AppConfiguration configuration;

  const MemoraDeviceRegistrationApi({
    required this.apiClient,
    required this.configuration,
  });

  @override
  Future<String> register({
    required String installationId,
    required String pushToken,
    required String idempotencyKey,
    required String appVersion,
    required String platform,
    required String locale,
  }) async {
    final request = DeviceRegistrationRequest((b) {
      b
        ..installationId = installationId
        ..pushToken = pushToken
        ..appVersion = appVersion
        ..locale = locale
        ..platform = configuration.platform == 'ios'
            ? DeviceRegistrationRequestPlatformEnum.ios
            : DeviceRegistrationRequestPlatformEnum.android;
    });
    final response = await apiClient.getSessionApi().registerDevice(
      xCorrelationID: generateUuid(),
      xClientVersion: appVersion,
      xPlatform: platform,
      idempotencyKey: idempotencyKey,
      deviceRegistrationRequest: request,
    );
    return response.data?.id ?? '';
  }

  @override
  Future<void> revoke({
    required String deviceId,
    required String accessToken,
  }) async {
    // Explicit bearer header: the shared client may already hold a cleared
    // or rotated token by the time sign-out revocation runs.
    await apiClient.getSessionApi().deleteDevice(
      deviceId: deviceId,
      xCorrelationID: generateUuid(),
      xClientVersion: configuration.clientVersion,
      xPlatform: configuration.platform,
      headers: <String, String>{'Authorization': 'Bearer $accessToken'},
    );
  }
}

/// Registers the device push token after session activation.
///
/// Failure handling follows the notification-denial-never-blocks-use gate:
/// every failure is swallowed with a code-only debug log; the next token
/// refresh or session activation retries. The push token is never logged.
class DeviceTokenRegistrar {
  static const String _installationKey = 'memora_push_installation_id';
  static const String _logName = 'memora.notifications';

  final NotificationGateway gateway;
  final DeviceRegistrationApi api;
  final SecureKeyStore keyStore;
  final AppConfiguration configuration;

  DeviceTokenRegistrar({
    required this.gateway,
    required this.api,
    required this.keyStore,
    required this.configuration,
  });

  /// Registers [pushToken] for this installation, or completes silently
  /// when permission is missing or the provider is unavailable.
  Future<void> registerIfPermitted() async {
    final permission = await gateway.permissionStatus();
    if (permission != NotificationPermission.granted) {
      return;
    }
    final token = await gateway.currentToken();
    if (token == null || token.isEmpty) {
      return;
    }
    await registerToken(token, accessToken: '', userId: '');
  }

  /// Registers one token and reports whether the server confirmed it
  /// (Flow §12.1: registration failure is recoverable — the caller decides
  /// when to retry). Failures are logged code-only, never the token.
  Future<bool> registerToken(
    String pushToken, {
    required String accessToken,
    required String userId,
  }) async {
    try {
      final installationId = await _installationId();
      final deviceId = await api.register(
        installationId: installationId,
        pushToken: pushToken,
        idempotencyKey: _idempotencyKey(installationId, pushToken),
        appVersion: configuration.clientVersion,
        platform: configuration.platform,
        // MVP ships English (Sri Lanka) only (PRD §9.1).
        locale: 'en-LK',
      );
      if (deviceId.isEmpty) {
        return false;
      }
      _lastDeviceId = deviceId;
      _lastAccessToken = accessToken;
      _lastUserId = userId;
      return true;
    } catch (error) {
      debugPrint(
        '$_logName: device registration failed '
        '(${error.runtimeType})',
      ); // never the token itself
      return false;
    }
  }

  /// Revokes the last confirmed registration while its session token is
  /// still valid (review finding 2: sign-out removes the server-side
  /// registration). Returns whether the revocation succeeded; on failure
  /// the tracking is kept so a later attempt can retry.
  Future<bool> revokeLastRegistration({String? accessToken}) async {
    final deviceId = _lastDeviceId;
    final token = accessToken ?? _lastAccessToken;
    if (deviceId == null || token == null) {
      return true; // nothing registered: nothing to revoke
    }
    try {
      await api.revoke(deviceId: deviceId, accessToken: token);
    } catch (error) {
      debugPrint(
        '$_logName: device revocation failed '
        '(${error.runtimeType})',
      ); // offline: keep tracking for retry
      return false;
    }
    _lastDeviceId = null;
    _lastAccessToken = null;
    _lastUserId = null;
    return true;
  }

  /// The account the last confirmed registration belongs to.
  String? get lastUserId => _lastUserId;

  String? _lastDeviceId;
  String? _lastAccessToken;
  String? _lastUserId;

  /// Stable per-installation identifier, generated once and persisted in
  /// the OS-protected key store.
  Future<String> _installationId() async {
    final existing = await keyStore.read(_installationKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final generated = generateUuid();
    await keyStore.write(_installationKey, generated);
    return generated;
  }

  /// Stable operation identity per installation and token (API-003).
  String _idempotencyKey(String installationId, String pushToken) {
    final digest = crypto.sha256
        .convert('register:$installationId:$pushToken'.codeUnits)
        .toString();
    return 'device-register-$digest';
  }
}

/// Requests notification permission once per installation (PRD 031: the
/// user controls categories from settings; the OS prompt never re-nags).
Future<NotificationPermission> requestPermissionOnce({
  required NotificationGateway gateway,
  required SecureKeyStore keyStore,
}) async {
  // A decided OS answer is returned without prompting again; the persisted
  // flag only guards against re-prompting across restarts for installs
  // whose first answer never resolved.
  const askedKey = 'memora_push_permission_asked';
  final current = await gateway.permissionStatus();
  if (current != NotificationPermission.notDetermined) {
    return current;
  }
  final asked = await keyStore.read(askedKey);
  if (asked == 'true') {
    return gateway.permissionStatus();
  }
  final permission = await gateway.requestPermission();
  if (permission != NotificationPermission.notDetermined) {
    await keyStore.write(askedKey, 'true');
  }
  return permission;
}
