import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/notification_message.dart';
import '../domain/notification_permission.dart';

/// One notification adapter for the app (TRD §5.1): permission, token and
/// message streams, independent of the underlying provider.
///
/// Implementations must be safe to construct on any platform; a provider
/// that cannot initialize reports [NotificationPermission.unavailable] and
/// empty streams instead of throwing, so the rest of the app never depends
/// on push availability.
abstract class NotificationGateway {
  /// The current OS permission state.
  Future<NotificationPermission> permissionStatus();

  /// Asks the user for notification permission (once per installation).
  Future<NotificationPermission> requestPermission();

  /// The current provider token, or null when unavailable.
  Future<String?> currentToken();

  /// Invalidates this installation's token so a signed-out account cannot
  /// receive pushes while server revocation is unavailable.
  Future<bool> invalidateToken();

  /// Fires whenever the provider rotates the token.
  Stream<String> tokenRefreshes();

  /// Messages received while the app is foregrounded.
  Stream<NotificationMessage> foregroundMessages();

  /// Message taps that open or focus the app (background taps and, through
  /// [initialTapMessage], cold starts).
  Stream<NotificationMessage> tapNavigations();

  /// The tap that launched the app from a terminated state, if any.
  Future<NotificationMessage?> initialTapMessage();
}

/// Programmable in-memory gateway for tests and unconfigured builds.
class FakeNotificationGateway implements NotificationGateway {
  NotificationPermission _permission;
  String? _token;
  bool _askCalled = false;

  final StreamController<String> _tokenRefreshes =
      StreamController<String>.broadcast();
  final StreamController<NotificationMessage> _foreground =
      StreamController<NotificationMessage>.broadcast();
  final StreamController<NotificationMessage> _taps =
      StreamController<NotificationMessage>.broadcast();
  NotificationMessage? _initialTap;

  FakeNotificationGateway({
    NotificationPermission initialPermission =
        NotificationPermission.notDetermined,
    String? initialToken,
  }) : _permission = initialPermission,
       _token = initialToken;

  bool get askWasCalled => _askCalled;

  void setPermission(NotificationPermission permission) {
    _permission = permission;
  }

  void setToken(String? token) {
    _token = token;
  }

  void emitTokenRefresh(String token) {
    _tokenRefreshes.add(token);
  }

  void emitForeground(NotificationMessage message) {
    _foreground.add(message);
  }

  void emitTap(NotificationMessage message) {
    _taps.add(message);
  }

  set initialTap(NotificationMessage? message) {
    _initialTap = message;
  }

  @override
  Future<NotificationPermission> permissionStatus() async => _permission;

  @override
  Future<NotificationPermission> requestPermission() async {
    _askCalled = true;
    if (_permission == NotificationPermission.notDetermined) {
      _permission = NotificationPermission.granted;
    }
    return _permission;
  }

  @override
  Future<String?> currentToken() async => _token;

  @override
  Future<bool> invalidateToken() async {
    _token = null;
    return true;
  }

  @override
  Stream<String> tokenRefreshes() => _tokenRefreshes.stream;

  @override
  Stream<NotificationMessage> foregroundMessages() => _foreground.stream;

  @override
  Stream<NotificationMessage> tapNavigations() => _taps.stream;

  @override
  Future<NotificationMessage?> initialTapMessage() async => _initialTap;

  @visibleForTesting
  void dispose() {
    _tokenRefreshes.close();
    _foreground.close();
    _taps.close();
  }
}
