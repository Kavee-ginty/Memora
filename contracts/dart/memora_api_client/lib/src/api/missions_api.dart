//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'dart:async';

import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:dio/dio.dart';

import 'package:memora_api_client/src/api_util.dart';
import 'package:memora_api_client/src/model/attempt_result.dart';
import 'package:memora_api_client/src/model/error_envelope.dart';
import 'package:memora_api_client/src/model/mission_completion_result.dart';
import 'package:memora_api_client/src/model/mission_item_response.dart';
import 'package:memora_api_client/src/model/mission_manifest.dart';
import 'package:memora_api_client/src/model/mission_summary.dart';
import 'package:memora_api_client/src/model/submit_attempt_request.dart';
import 'package:memora_api_client/src/model/today_mission_response.dart';

class MissionsApi {
  final Dio _dio;

  final Serializers _serializers;

  const MissionsApi(this._dio, this._serializers);

  /// Complete a mission from persisted eligible item states
  /// Stores one stable learning result and emits mission.completed. XP, streak and reef projection are applied by the T15 idempotent engagement consumer.
  ///
  /// Parameters:
  /// * [missionId]
  /// * [xCorrelationID]
  /// * [xClientVersion]
  /// * [xPlatform]
  /// * [idempotencyKey]
  /// * [acceptLanguage]
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [MissionCompletionResult] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<MissionCompletionResult>> completeMission({
    required String missionId,
    required String xCorrelationID,
    required String xClientVersion,
    required String xPlatform,
    required String idempotencyKey,
    String? acceptLanguage,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/v1/missions/{mission_id}/complete'.replaceAll(
        '{' r'mission_id' '}',
        encodeQueryParameter(_serializers, missionId, const FullType(String))
            .toString());
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
      validateStatus: validateStatus,
    );

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    MissionCompletionResult? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null
          ? null
          : _serializers.deserialize(
              rawResponse,
              specifiedType: const FullType(MissionCompletionResult),
            ) as MissionCompletionResult;
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<MissionCompletionResult>(
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

  /// Read a mission preview and authoritative progress
  ///
  ///
  /// Parameters:
  /// * [missionId]
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
  /// Returns a [Future] containing a [Response] with a [MissionManifest] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<MissionManifest>> getMission({
    required String missionId,
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
    final _path = r'/v1/missions/{mission_id}'.replaceAll(
        '{' r'mission_id' '}',
        encodeQueryParameter(_serializers, missionId, const FullType(String))
            .toString());
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

    MissionManifest? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null
          ? null
          : _serializers.deserialize(
              rawResponse,
              specifiedType: const FullType(MissionManifest),
            ) as MissionManifest;
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<MissionManifest>(
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

  /// Read the authorized current mission item
  /// Returns the pinned question without an answer key or grading rubric.
  ///
  /// Parameters:
  /// * [missionId]
  /// * [itemId]
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
  /// Returns a [Future] containing a [Response] with a [MissionItemResponse] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<MissionItemResponse>> getMissionItem({
    required String missionId,
    required String itemId,
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
    final _path = r'/v1/missions/{mission_id}/items/{item_id}'
        .replaceAll(
            '{' r'mission_id' '}',
            encodeQueryParameter(
                    _serializers, missionId, const FullType(String))
                .toString())
        .replaceAll(
            '{' r'item_id' '}',
            encodeQueryParameter(_serializers, itemId, const FullType(String))
                .toString());
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

    MissionItemResponse? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null
          ? null
          : _serializers.deserialize(
              rawResponse,
              specifiedType: const FullType(MissionItemResponse),
            ) as MissionItemResponse;
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<MissionItemResponse>(
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

  /// Read stable mission completion results
  ///
  ///
  /// Parameters:
  /// * [missionId]
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
  /// Returns a [Future] containing a [Response] with a [MissionCompletionResult] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<MissionCompletionResult>> getMissionResults({
    required String missionId,
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
    final _path = r'/v1/missions/{mission_id}/results'.replaceAll(
        '{' r'mission_id' '}',
        encodeQueryParameter(_serializers, missionId, const FullType(String))
            .toString());
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

    MissionCompletionResult? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null
          ? null
          : _serializers.deserialize(
              rawResponse,
              specifiedType: const FullType(MissionCompletionResult),
            ) as MissionCompletionResult;
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<MissionCompletionResult>(
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

  /// Read or assemble today&#39;s bounded Daily Mission
  /// Returns one persisted, owner-scoped mission ranked from authoritative memory state, or an explicit no-due state. Hidden candidates and scores are not returned.
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
  /// Returns a [Future] containing a [Response] with a [TodayMissionResponse] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<TodayMissionResponse>> getTodayMission({
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
    final _path = r'/v1/missions/today';
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

    TodayMissionResponse? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null
          ? null
          : _serializers.deserialize(
              rawResponse,
              specifiedType: const FullType(TodayMissionResponse),
            ) as TodayMissionResponse;
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<TodayMissionResponse>(
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

  /// Pause an active mission without losing progress
  ///
  ///
  /// Parameters:
  /// * [missionId]
  /// * [xCorrelationID]
  /// * [xClientVersion]
  /// * [xPlatform]
  /// * [idempotencyKey]
  /// * [acceptLanguage]
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [MissionSummary] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<MissionSummary>> pauseMission({
    required String missionId,
    required String xCorrelationID,
    required String xClientVersion,
    required String xPlatform,
    required String idempotencyKey,
    String? acceptLanguage,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/v1/missions/{mission_id}/pause'.replaceAll(
        '{' r'mission_id' '}',
        encodeQueryParameter(_serializers, missionId, const FullType(String))
            .toString());
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
      validateStatus: validateStatus,
    );

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    MissionSummary? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null
          ? null
          : _serializers.deserialize(
              rawResponse,
              specifiedType: const FullType(MissionSummary),
            ) as MissionSummary;
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<MissionSummary>(
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

  /// Record one permitted mission-item skip
  ///
  ///
  /// Parameters:
  /// * [missionId]
  /// * [itemId]
  /// * [xCorrelationID]
  /// * [xClientVersion]
  /// * [xPlatform]
  /// * [idempotencyKey]
  /// * [acceptLanguage]
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [AttemptResult] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<AttemptResult>> skipMissionItem({
    required String missionId,
    required String itemId,
    required String xCorrelationID,
    required String xClientVersion,
    required String xPlatform,
    required String idempotencyKey,
    String? acceptLanguage,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/v1/missions/{mission_id}/items/{item_id}/skip'
        .replaceAll(
            '{' r'mission_id' '}',
            encodeQueryParameter(
                    _serializers, missionId, const FullType(String))
                .toString())
        .replaceAll(
            '{' r'item_id' '}',
            encodeQueryParameter(_serializers, itemId, const FullType(String))
                .toString());
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
      validateStatus: validateStatus,
    );

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    AttemptResult? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null
          ? null
          : _serializers.deserialize(
              rawResponse,
              specifiedType: const FullType(AttemptResult),
            ) as AttemptResult;
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<AttemptResult>(
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

  /// Start or resume a mission with pinned question versions
  ///
  ///
  /// Parameters:
  /// * [missionId]
  /// * [xCorrelationID]
  /// * [xClientVersion]
  /// * [xPlatform]
  /// * [idempotencyKey]
  /// * [acceptLanguage]
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [MissionManifest] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<MissionManifest>> startMission({
    required String missionId,
    required String xCorrelationID,
    required String xClientVersion,
    required String xPlatform,
    required String idempotencyKey,
    String? acceptLanguage,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/v1/missions/{mission_id}/start'.replaceAll(
        '{' r'mission_id' '}',
        encodeQueryParameter(_serializers, missionId, const FullType(String))
            .toString());
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
      validateStatus: validateStatus,
    );

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    MissionManifest? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null
          ? null
          : _serializers.deserialize(
              rawResponse,
              specifiedType: const FullType(MissionManifest),
            ) as MissionManifest;
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<MissionManifest>(
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

  /// Submit and grade one answer envelope
  /// Uses client_operation_id as the stable retry identity, grades only the pinned question, and publishes bounded memory evidence through the transactional outbox.
  ///
  /// Parameters:
  /// * [missionId]
  /// * [itemId]
  /// * [xCorrelationID]
  /// * [xClientVersion]
  /// * [xPlatform]
  /// * [submitAttemptRequest]
  /// * [acceptLanguage]
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [AttemptResult] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<AttemptResult>> submitAttempt({
    required String missionId,
    required String itemId,
    required String xCorrelationID,
    required String xClientVersion,
    required String xPlatform,
    required SubmitAttemptRequest submitAttemptRequest,
    String? acceptLanguage,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/v1/missions/{mission_id}/items/{item_id}/attempts'
        .replaceAll(
            '{' r'mission_id' '}',
            encodeQueryParameter(
                    _serializers, missionId, const FullType(String))
                .toString())
        .replaceAll(
            '{' r'item_id' '}',
            encodeQueryParameter(_serializers, itemId, const FullType(String))
                .toString());
    final _options = Options(
      method: r'POST',
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
      contentType: 'application/json',
      validateStatus: validateStatus,
    );

    dynamic _bodyData;

    try {
      const _type = FullType(SubmitAttemptRequest);
      _bodyData =
          _serializers.serialize(submitAttemptRequest, specifiedType: _type);
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

    AttemptResult? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null
          ? null
          : _serializers.deserialize(
              rawResponse,
              specifiedType: const FullType(AttemptResult),
            ) as AttemptResult;
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<AttemptResult>(
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
}
