import 'package:url_launcher/url_launcher.dart';

/// Raised when the device cannot open an export download externally.
class PrivacyDownloadUnavailable implements Exception {
  const PrivacyDownloadUnavailable();

  @override
  String toString() => 'PrivacyDownloadUnavailable';
}

/// Opens an already-validated signed export URL in the external browser.
abstract class PrivacyDownloadLauncher {
  Future<void> openExternal(Uri uri);
}

/// Production launcher backed by `url_launcher`.
///
/// The repository validates the scheme before a URI reaches this class. The
/// extra guard here keeps unsafe schemes from ever leaving the app if a future
/// caller bypasses the repository.
class UrlLauncherPrivacyDownloadLauncher implements PrivacyDownloadLauncher {
  UrlLauncherPrivacyDownloadLauncher({
    this.allowLocalHttp = false,
    Future<bool> Function(Uri uri)? launch,
  }) : _launch = launch ?? _launchExternal;

  final bool allowLocalHttp;
  final Future<bool> Function(Uri uri) _launch;

  static Future<bool> _launchExternal(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Future<void> openExternal(Uri uri) async {
    if (!_isAllowed(uri)) {
      throw const PrivacyDownloadUnavailable();
    }

    final bool opened;
    try {
      opened = await _launch(uri);
    } catch (_) {
      throw const PrivacyDownloadUnavailable();
    }

    if (!opened) {
      throw const PrivacyDownloadUnavailable();
    }
  }

  bool _isAllowed(Uri uri) {
    if (uri.scheme == 'https') return true;
    if (uri.scheme != 'http' || !allowLocalHttp) return false;
    final host = uri.host.toLowerCase();
    return host == 'localhost' || host == '127.0.0.1' || host == '::1';
  }
}
