import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora_api_client/memora_api_client.dart';
import 'package:memora_mobile/src/features/privacy/data/privacy_reachability.dart';

void main() {
  group('ApiPrivacyReachability', () {
    late Dio dio;
    late MemoraApiClient apiClient;

    setUp(() {
      dio = Dio();
      apiClient = MemoraApiClient(dio: dio);
    });

    test('returns true for a live backend', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: <String, dynamic>{'status': 'ok'},
              ),
            );
          },
        ),
      );

      final reachability = ApiPrivacyReachability(apiClient: apiClient);

      expect(await reachability.check(), isTrue);
    });

    test('returns false for a non-success response', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: Response<dynamic>(
                  requestOptions: options,
                  statusCode: 503,
                ),
              ),
            );
          },
        ),
      );

      final reachability = ApiPrivacyReachability(apiClient: apiClient);

      expect(await reachability.check(), isFalse);
    });

    test('returns false for a transport failure', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionError,
              ),
            );
          },
        ),
      );

      final reachability = ApiPrivacyReachability(apiClient: apiClient);

      expect(await reachability.check(), isFalse);
    });

    test('returns false when the probe exceeds its deadline', () async {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            Future<void>.delayed(const Duration(milliseconds: 100)).then((_) {
              handler.resolve(
                Response<Map<String, dynamic>>(
                  requestOptions: options,
                  statusCode: 200,
                  data: <String, dynamic>{'status': 'ok'},
                ),
              );
            });
          },
        ),
      );

      final reachability = ApiPrivacyReachability(
        apiClient: apiClient,
        timeout: const Duration(milliseconds: 10),
      );

      expect(await reachability.check(), isFalse);
    });
  });
}
