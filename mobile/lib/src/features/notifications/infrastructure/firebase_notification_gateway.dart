import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../domain/notification_message.dart';
import '../domain/notification_permission.dart';
import 'notification_gateway.dart';

/// Firebase Cloud Messaging implementation of [NotificationGateway].
///
/// The gateway initializes Firebase lazily and never throws: an installation
/// without platform configuration (no google-services.json /
/// GoogleService-Info.plist) or an unsupported target degrades to
/// [NotificationPermission.unavailable] with empty streams. This keeps CI
/// builds and tests free of Firebase configuration (T19 D12).
class FirebaseNotificationGateway implements NotificationGateway {
  static const String _logName = 'memora.notifications';

  Future<bool>? _availability;

  @visibleForTesting
  FirebaseMessaging? messagingOverride;

  /// Resolves once; true when Firebase initialized on this installation.
  /// Initialization failures (missing platform configuration, unsupported
  /// target, missing plugin registry in tests) degrade to false.
  @visibleForTesting
  Future<bool> ensureAvailable() {
    return _availability ??= _initialize();
  }

  Future<bool> _initialize() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return false;
    }
    try {
      await Firebase.initializeApp();
      return true;
    } on Exception catch (_) {
      return false;
    } on Error catch (_) {
      return false;
    }
  }

  Future<FirebaseMessaging?> get _messaging async {
    if (!await ensureAvailable()) {
      return null;
    }
    return messagingOverride ?? FirebaseMessaging.instance;
  }

  NotificationPermission _mapStatus(AuthorizationStatus status) {
    switch (status) {
      case AuthorizationStatus.authorized:
        return NotificationPermission.granted;
      case AuthorizationStatus.denied:
        return NotificationPermission.denied;
      case AuthorizationStatus.notDetermined:
      case AuthorizationStatus.provisional:
        return NotificationPermission.notDetermined;
      case AuthorizationStatus.deniedPermanently:
        return NotificationPermission.denied;
    }
  }

  @override
  Future<NotificationPermission> permissionStatus() async {
    final messaging = await _messaging;
    if (messaging == null) {
      return NotificationPermission.unavailable;
    }
    try {
      final settings = await messaging.getNotificationSettings();
      return _mapStatus(settings.authorizationStatus);
    } on FirebaseException catch (_) {
      return NotificationPermission.unavailable;
    }
  }

  @override
  Future<NotificationPermission> requestPermission() async {
    final messaging = await _messaging;
    if (messaging == null) {
      return NotificationPermission.unavailable;
    }
    try {
      final settings = await messaging.requestPermission();
      return _mapStatus(settings.authorizationStatus);
    } on FirebaseException catch (_) {
      return NotificationPermission.unavailable;
    }
  }

  @override
  Future<String?> currentToken() async {
    final messaging = await _messaging;
    if (messaging == null) {
      return null;
    }
    try {
      // The backend targets the classic FCM token in FCM HTTP v1
      // `message.token`; v17's register()/onRegistered return Firebase
      // Installation IDs for a different send path, so the deprecated
      // token API remains the contract-correct choice.
      // ignore: deprecated_member_use
      return await messaging.getToken();
    } on FirebaseException catch (_) {
      return null;
    }
  }

  @override
  Stream<String> tokenRefreshes() async* {
    final messaging = await _messaging;
    if (messaging == null) {
      return;
    }
    // See currentToken(): the classic token stream is the backend contract.
    // ignore: deprecated_member_use
    yield* messaging.onTokenRefresh;
  }

  @override
  Stream<NotificationMessage> foregroundMessages() async* {
    final messaging = await _messaging;
    if (messaging == null) {
      return;
    }
    yield* FirebaseMessaging.onMessage.map(
      (RemoteMessage message) => NotificationMessage.fromRaw(message.data),
    );
  }

  @override
  Stream<NotificationMessage> tapNavigations() async* {
    final messaging = await _messaging;
    if (messaging == null) {
      return;
    }
    yield* FirebaseMessaging.onMessageOpenedApp.map(
      (RemoteMessage message) => NotificationMessage.fromRaw(message.data),
    );
  }

  @override
  Future<NotificationMessage?> initialTapMessage() async {
    final messaging = await _messaging;
    if (messaging == null) {
      return null;
    }
    try {
      final message = await messaging.getInitialMessage();
      return message == null ? null : NotificationMessage.fromRaw(message.data);
    } on FirebaseException catch (_) {
      debugPrint('$_logName: initial message unavailable');
      return null;
    }
  }
}
