import 'package:flutter/foundation.dart';

import '../../../routing/app_routes.dart';

/// Typed representation of a safe, validated in-app destination.
///
/// Designed to prevent open redirects, query-parameter credential leaks,
/// and auth loop redirections.
@immutable
class SafeReturnLocation {
  final String path;

  const SafeReturnLocation._(this.path);

  /// Validates and parses an internal candidate route string.
  ///
  /// Returns `null` if the candidate is unsafe, external, contains sensitive
  /// tokens, or targets auth/splash routes.
  static SafeReturnLocation? parse(String? candidate) {
    if (candidate == null || candidate.isEmpty) return null;

    final trimmed = candidate.trim();

    // Must be an absolute path within the app, not a scheme or protocol-relative
    if (!trimmed.startsWith('/') || trimmed.startsWith('//')) {
      return null;
    }

    // Must not contain URL scheme separators
    if (trimmed.contains('://') || trimmed.contains(r'\\')) {
      return null;
    }

    // Must not contain credentials or tokens in parameters
    final lower = trimmed.toLowerCase();
    if (lower.contains('token') ||
        lower.contains('password') ||
        lower.contains('secret') ||
        lower.contains('user_id') ||
        lower.contains('bearer')) {
      return null;
    }

    // Exclude auth, splash, or recovery loops
    if (trimmed == '/' ||
        trimmed.startsWith('/auth') ||
        trimmed.startsWith('/onboarding') ||
        trimmed.startsWith('/recovery')) {
      return null;
    }

    // Allowable root and detail route roots
    final allowedPrefixes = <String>[
      '/home',
      '/learning',
      '/progress',
      '/profile',
      '/catalog',
      '/consent',
      '/missions',
      '/questions',
    ];

    final isAllowed = allowedPrefixes.any(
      (prefix) => trimmed == prefix || trimmed.startsWith('$prefix/'),
    );

    if (!isAllowed) {
      return null;
    }

    return SafeReturnLocation._(trimmed);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SafeReturnLocation &&
          runtimeType == other.runtimeType &&
          path == other.path;

  @override
  int get hashCode => path.hashCode;

  @override
  String toString() => path;
}

/// Typed route access guard resolution.
enum RouteAccessType {
  allowed,
  signInRequired,
  sessionExpired,
  accountRecoveryRequired,
  consentReviewRequired,
  recentAuthenticationRequired,
  resourceNotFound,
  invalidWorkflowState,
  malformedRoute,
  featureUnavailable,
}

/// Detailed typed route access evaluation.
@immutable
class RouteAccessResult {
  final RouteAccessType type;
  final String? recoveryPath;
  final String? userMessage;
  final SafeReturnLocation? returnLocation;

  const RouteAccessResult({
    required this.type,
    this.recoveryPath,
    this.userMessage,
    this.returnLocation,
  });

  const RouteAccessResult.allowed() : this(type: RouteAccessType.allowed);

  /// A stable internal redirect that is not an access failure.
  const RouteAccessResult.redirect(String path)
    : this(type: RouteAccessType.allowed, recoveryPath: path);

  const RouteAccessResult.signInRequired([SafeReturnLocation? returnLocation])
    : this(
        type: RouteAccessType.signInRequired,
        recoveryPath: AppRoutes.signIn,
        returnLocation: returnLocation,
        userMessage: 'Please sign in to continue.',
      );

  const RouteAccessResult.sessionExpired()
    : this(
        type: RouteAccessType.sessionExpired,
        recoveryPath: AppRoutes.signIn,
        userMessage: 'Your session has expired. Please sign in again.',
      );

  const RouteAccessResult.accountRecoveryRequired([String? reason])
    : this(
        type: RouteAccessType.accountRecoveryRequired,
        recoveryPath: AppRoutes.accountRecovery,
        userMessage:
            reason ?? 'Account requires attention before you can continue.',
      );

  const RouteAccessResult.consentReviewRequired()
    : this(
        type: RouteAccessType.consentReviewRequired,
        recoveryPath: AppRoutes.consent,
        userMessage: 'Policy updates require review before continuing.',
      );

  const RouteAccessResult.recentAuthRequired()
    : this(
        type: RouteAccessType.recentAuthenticationRequired,
        recoveryPath: AppRoutes.signIn,
        userMessage: 'Please confirm your credentials to perform this action.',
      );

  const RouteAccessResult.notFound([String? message])
    : this(
        type: RouteAccessType.resourceNotFound,
        recoveryPath: AppRoutes.notFound,
        userMessage: message ?? 'The requested item was not found.',
      );

  const RouteAccessResult.invalidWorkflowState([String? stableParent])
    : this(
        type: RouteAccessType.invalidWorkflowState,
        recoveryPath: stableParent ?? AppRoutes.home,
        userMessage: 'That activity is not currently available.',
      );

  const RouteAccessResult.malformedRoute()
    : this(
        type: RouteAccessType.malformedRoute,
        recoveryPath: AppRoutes.notFound,
        userMessage: 'Invalid location or parameters.',
      );

  const RouteAccessResult.featureUnavailable([String? stableParent])
    : this(
        type: RouteAccessType.featureUnavailable,
        recoveryPath: stableParent ?? AppRoutes.home,
        userMessage: 'This feature is not yet available in the pilot preview.',
      );

  /// True when the requested location may be shown as requested.
  bool get isAllowed => type == RouteAccessType.allowed && recoveryPath == null;

  /// True when the result asks the router to redirect elsewhere.
  bool get requiresRedirect => recoveryPath != null;
}
