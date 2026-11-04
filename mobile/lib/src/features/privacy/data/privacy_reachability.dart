import 'dart:async';

import 'package:dio/dio.dart';
import 'package:memora_api_client/memora_api_client.dart';

/// Small reachability probe used before privacy mutations and downloads.
///
/// T21 deliberately reuses the existing liveness endpoint instead of adding a
/// connectivity dependency, because the backend being reachable is the fact
/// that matters for a privacy mutation.
abstract class PrivacyReachability {
  Future<bool> check();
}

/// Probes `GET /health/live` with a short bounded timeout.
class ApiPrivacyReachability implements PrivacyReachability {
  const ApiPrivacyReachability({
    required this.apiClient,
    this.timeout = const Duration(seconds: 4),
  });

  final MemoraApiClient apiClient;
  final Duration timeout;

  @override
  Future<bool> check() async {
    final cancelToken = CancelToken();
    try {
      final response = await apiClient
          .getHealthApi()
          .healthLive(cancelToken: cancelToken)
          .timeout(
            timeout,
            onTimeout: () {
              cancelToken.cancel('privacy_reachability_timeout');
              throw TimeoutException('privacy_reachability_timeout');
            },
          );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
