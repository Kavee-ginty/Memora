import 'dart:async';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/foundation.dart';
import 'package:memora_api_client/memora_api_client.dart';

import '../../../configuration/app_configuration.dart';
import '../../common/ids.dart';
import '../../auth/data/secure_auth_storage.dart';
import '../domain/notification_permission.dart';
import 'notification_gateway.dart';

/// Transport for the `POST /v1/devices` registration (T06 operation).
///
/// Indirection keeps the registrar testable without the generated client.
abstract class DeviceRegistrationApi {
  Future<void> register({
    required String installationId,
    required String pushToken,
    required String idempotencyKey,
    required String appVersion,
    required String platform,
    required String locale,
  });
}

class MemoraDeviceRegistrationApi implements DeviceRegistrationApi {
  final MemoraApiClient apiClient;
  final AppConfiguration configuration;

  const MemoraDeviceRegistrationApi({
    required this.apiClient,
    required this.configuration,
  });

  @override
  Future<void> register({
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
    await apiClient.getSessionApi().registerDevice(
      xCorrelationID: generateUuid(),
      xClientVersion: appVersion,
      xPlatform: platform,
      idempotencyKey: idempotencyKey,
      deviceRegistrationRequest: request,
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

  const DeviceTokenRegistrar({
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
    await registerToken(token);
  }

  /// Registers one token. Safe to call repeatedly: the installation id and
  /// the idempotency key are stable per installation and token, so retries
  /// converge on the server (T06 idempotent device registration).
  Future<void> registerToken(String pushToken) async {
    try {
      final installationId = await _installationId();
      await api.register(
        installationId: installationId,
        pushToken: pushToken,
        idempotencyKey: _idempotencyKey(installationId, pushToken),
        appVersion: configuration.clientVersion,
        platform: configuration.platform,
        // MVP ships English (Sri Lanka) only (PRD §9.1).
        locale: 'en-LK',
      );
    } catch (error) {
      debugPrint(
        '$_logName: device registration failed '
        '(${error.runtimeType})',
      ); // never the token itself
    }
  }

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
