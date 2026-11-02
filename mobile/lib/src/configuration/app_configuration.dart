import 'package:flutter/foundation.dart';

/// Application build-time and runtime configuration.
///
/// Loaded from environment definitions (--dart-define) with safe fallbacks
/// for local development and testing. Sensitive secrets are never stored here.
class AppConfiguration {
  final String supabaseUrl;
  final String supabasePublishableKey;
  final String apiBaseUrl;
  final String oauthRedirectUri;
  final String clientVersion;
  final String platform;
  final String environment;

  const AppConfiguration({
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    required this.apiBaseUrl,
    required this.oauthRedirectUri,
    this.clientVersion = '0.1.0',
    required this.platform,
    this.environment = 'local',
  });

  /// Factory creating configuration from compile-time environment variables.
  factory AppConfiguration.fromEnvironment() {
    final platformName = defaultTargetPlatform == TargetPlatform.iOS
        ? 'ios'
        : 'android';

    return AppConfiguration(
      supabaseUrl: const String.fromEnvironment(
        'MEMORA_SUPABASE_URL',
        defaultValue: 'https://placeholder.supabase.co',
      ),
      supabasePublishableKey: const String.fromEnvironment(
        'MEMORA_SUPABASE_PUBLISHABLE_KEY',
        defaultValue: 'placeholder-anon-key',
      ),
      apiBaseUrl: const String.fromEnvironment(
        'MEMORA_API_BASE_URL',
        defaultValue: 'http://127.0.0.1:8000',
      ),
      oauthRedirectUri: const String.fromEnvironment(
        'MEMORA_OAUTH_REDIRECT_URI',
        defaultValue: 'com.kaveeginty.memora://login-callback',
      ),
      clientVersion: const String.fromEnvironment(
        'MEMORA_CLIENT_VERSION',
        defaultValue: '0.1.0',
      ),
      platform: platformName,
      environment: const String.fromEnvironment(
        'MEMORA_ENVIRONMENT',
        defaultValue: 'local',
      ),
    );
  }

  /// Whether the configuration contains non-empty endpoints required to run.
  bool get isValid =>
      supabaseUrl.isNotEmpty &&
      supabasePublishableKey.isNotEmpty &&
      apiBaseUrl.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppConfiguration &&
          runtimeType == other.runtimeType &&
          supabaseUrl == other.supabaseUrl &&
          supabasePublishableKey == other.supabasePublishableKey &&
          apiBaseUrl == other.apiBaseUrl &&
          oauthRedirectUri == other.oauthRedirectUri &&
          clientVersion == other.clientVersion &&
          platform == other.platform &&
          environment == other.environment;

  @override
  int get hashCode => Object.hash(
    supabaseUrl,
    supabasePublishableKey,
    apiBaseUrl,
    oauthRedirectUri,
    clientVersion,
    platform,
    environment,
  );
}
