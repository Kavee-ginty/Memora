//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'dart:async';

import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:dio/dio.dart';

import 'package:memora_api_client/src/api_util.dart';
import 'package:memora_api_client/src/model/device_registration_request.dart';
import 'package:memora_api_client/src/model/device_registration_response.dart';
import 'package:memora_api_client/src/model/error_envelope.dart';
import 'package:memora_api_client/src/model/session_bootstrap_response.dart';
import 'package:memora_api_client/src/model/session_revoke_request.dart';

class SessionApi {
  final Dio _dio;

  final Serializers _serializers;

  const SessionApi(this._dio, this._serializers);

  /// Bootstrap the authenticated session
  /// Returns the bounded account, consent, subject, mission and pending-state summary.
  ///
  /// Parameters:
  /// * [xCorrelationID]
  /// * [xClientVersion]
  /// * [xPlatform]
  /// * [acceptLanguage]
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [SessionBootstrapResponse] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<SessionBootstrapResponse>> bootstrapSession({
    required String xCorrelationID,
    required String xClientVersion,
    required String xPlatform,
    String? acceptLanguage,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/v1/session/bootstrap';
    final _options = Options(
      method: r'GET',
      headers: <String, dynamic>{
        r'X-Correlation-ID': xCorrelationID,
        r'X-Client-Version': xClientVersion,
        r'X-Platform': xPlatform,
        r'Accept-Language': acceptLanguage,
        ...?headers,
      },
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {
            'type': 'http',
            'scheme': 'bearer',
            'name': 'bearerAuth',
          },
        ],
        ...?extra,
      },
      validateStatus: validateStatus,
    );

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    SessionBootstrapResponse? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null
          ? null
          : _serializers.deserialize(
              rawResponse,
              specifiedType: const FullType(SessionBootstrapResponse),
            ) as SessionBootstrapResponse;
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<SessionBootstrapResponse>(
      data: _responseData,
      headers: _response.headers,
      isRedirect: _response.isRedirect,
      requestOptions: _response.requestOptions,
      redirects: _response.redirects,
      statusCode: _response.statusCode,
      statusMessage: _response.statusMessage,
      extra: _response.extra,
    );
  }

  /// Remove a notification device
  /// Idempotently revokes an authenticated user&#39;s device registration.
  ///
  /// Parameters:
  /// * [deviceId]
  /// * [xCorrelationID]
  /// * [xClientVersion]
  /// * [xPlatform]
  /// * [acceptLanguage]
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future]
  /// Throws [DioException] if API call or serialization fails
  Future<Response<void>> deleteDevice({
    required String deviceId,
    required String xCorrelationID,
    required String xClientVersion,
    required String xPlatform,
    String? acceptLanguage,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/v1/devices/{device_id}'.replaceAll(
        '{' r'device_id' '}',
        encodeQueryParameter(_serializers, deviceId, const FullType(String))
            .toString());
    final _options = Options(
      method: r'DELETE',
      headers: <String, dynamic>{
        r'X-Correlation-ID': xCorrelationID,
        r'X-Client-Version': xClientVersion,
        r'X-Platform': xPlatform,
        r'Accept-Language': acceptLanguage,
        ...?headers,
      },
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {
            'type': 'http',
            'scheme': 'bearer',
            'name': 'bearerAuth',
          },
        ],
        ...?extra,
      },
      validateStatus: validateStatus,
    );

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    return _response;
  }

  /// Register or refresh a notification device
  /// Idempotently stores an encrypted push token for the authenticated installation.
  ///
  /// Parameters:
  /// * [xCorrelationID]
  /// * [xClientVersion]
  /// * [xPlatform]
  /// * [idempotencyKey]
  /// * [deviceRegistrationRequest]
  /// * [acceptLanguage]
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [DeviceRegistrationResponse] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<DeviceRegistrationResponse>> registerDevice({
    required String xCorrelationID,
    required String xClientVersion,
    required String xPlatform,
    required String idempotencyKey,
    required DeviceRegistrationRequest deviceRegistrationRequest,
    String? acceptLanguage,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/v1/devices';
    final _options = Options(
      method: r'POST',
      headers: <String, dynamic>{
        r'X-Correlation-ID': xCorrelationID,
        r'X-Client-Version': xClientVersion,
        r'X-Platform': xPlatform,
        r'Accept-Language': acceptLanguage,
        r'Idempotency-Key': idempotencyKey,
        ...?headers,
      },
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {
            'type': 'http',
            'scheme': 'bearer',
            'name': 'bearerAuth',
          },
        ],
        ...?extra,
      },
      contentType: 'application/json',
      validateStatus: validateStatus,
    );

    dynamic _bodyData;

    try {
      const _type = FullType(DeviceRegistrationRequest);
      _bodyData = _serializers.serialize(deviceRegistrationRequest,
          specifiedType: _type);
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _options.compose(
          _dio.options,
          _path,
        ),
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    final _response = await _dio.request<Object>(
      _path,
      data: _bodyData,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    DeviceRegistrationResponse? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null
          ? null
          : _serializers.deserialize(
              rawResponse,
              specifiedType: const FullType(DeviceRegistrationResponse),
            ) as DeviceRegistrationResponse;
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<DeviceRegistrationResponse>(
      data: _responseData,
      headers: _response.headers,
      isRedirect: _response.isRedirect,
      requestOptions: _response.requestOptions,
      redirects: _response.redirects,
      statusCode: _response.statusCode,
      statusMessage: _response.statusMessage,
      extra: _response.extra,
    );
  }

  /// Revoke authenticated sessions
  /// Idempotently revokes the requested Supabase session scope after recent authentication.
  ///
  /// Parameters:
  /// * [xCorrelationID]
  /// * [xClientVersion]
  /// * [xPlatform]
  /// * [idempotencyKey]
  /// * [sessionRevokeRequest]
  /// * [acceptLanguage]
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future]
  /// Throws [DioException] if API call or serialization fails
  Future<Response<void>> revokeSession({
    required String xCorrelationID,
    required String xClientVersion,
    required String xPlatform,
    required String idempotencyKey,
    required SessionRevokeRequest sessionRevokeRequest,
    String? acceptLanguage,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/v1/session/revoke';
    final _options = Options(
      method: r'POST',
      headers: <String, dynamic>{
        r'X-Correlation-ID': xCorrelationID,
        r'X-Client-Version': xClientVersion,
        r'X-Platform': xPlatform,
        r'Accept-Language': acceptLanguage,
        r'Idempotency-Key': idempotencyKey,
        ...?headers,
      },
      extra: <String, dynamic>{
        'secure': <Map<String, String>>[
          {
            'type': 'http',
            'scheme': 'bearer',
            'name': 'bearerAuth',
          },
        ],
        ...?extra,
      },
      contentType: 'application/json',
      validateStatus: validateStatus,
    );

    dynamic _bodyData;

    try {
      const _type = FullType(SessionRevokeRequest);
      _bodyData =
          _serializers.serialize(sessionRevokeRequest, specifiedType: _type);
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _options.compose(
          _dio.options,
          _path,
        ),
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    final _response = await _dio.request<Object>(
      _path,
      data: _bodyData,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    return _response;
  }
}
