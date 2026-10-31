//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'dart:async';

import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:dio/dio.dart';

import 'package:memora_api_client/src/api_util.dart';
import 'package:memora_api_client/src/model/concept_history_response.dart';
import 'package:memora_api_client/src/model/error_envelope.dart';
import 'package:memora_api_client/src/model/page_concept_progress_item.dart';

class CurriculumApi {

  final Dio _dio;

  final Serializers _serializers;

  const CurriculumApi(this._dio, this._serializers);

  /// Read a concept&#39;s evidence summary and scheduling history
  /// Returns the authenticated student&#39;s bounded evidence summary and paginated scheduling decisions for one concept, each with allowlisted reason codes, a template key and safe copy. Another learner&#39;s concept returns 404.
  ///
  /// Parameters:
  /// * [conceptId] 
  /// * [xCorrelationID] 
  /// * [xClientVersion] 
  /// * [xPlatform] 
  /// * [limit] 
  /// * [cursor] 
  /// * [acceptLanguage] 
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [ConceptHistoryResponse] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<ConceptHistoryResponse>> getConceptHistory({ 
    required String conceptId,
    required String xCorrelationID,
    required String xClientVersion,
    required String xPlatform,
    int? limit = 20,
    String? cursor,
    String? acceptLanguage,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/v1/concepts/{concept_id}/history'.replaceAll('{' r'concept_id' '}', encodeQueryParameter(_serializers, conceptId, const FullType(String)).toString());
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

    final _queryParameters = <String, dynamic>{
      if (limit != null) r'limit': encodeQueryParameter(_serializers, limit, const FullType(int)),
      if (cursor != null) r'cursor': encodeQueryParameter(_serializers, cursor, const FullType(String)),
    };

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      queryParameters: _queryParameters,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    ConceptHistoryResponse? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null ? null : _serializers.deserialize(
        rawResponse,
        specifiedType: const FullType(ConceptHistoryResponse),
      ) as ConceptHistoryResponse;

    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<ConceptHistoryResponse>(
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

  /// List due and near-due concept progress for a subject
  /// Returns the authenticated student&#39;s concept states in next-review order for the requested horizon, with a retrievability band, a review window and a plain-language due reason. Hidden ranking scores and event payloads are never returned.
  ///
  /// Parameters:
  /// * [subjectId] 
  /// * [xCorrelationID] 
  /// * [xClientVersion] 
  /// * [xPlatform] 
  /// * [limit] 
  /// * [cursor] 
  /// * [horizonDays] 
  /// * [acceptLanguage] 
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [PageConceptProgressItem] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<PageConceptProgressItem>> listConceptProgress({ 
    required String subjectId,
    required String xCorrelationID,
    required String xClientVersion,
    required String xPlatform,
    int? limit = 20,
    String? cursor,
    num? horizonDays = 3.0,
    String? acceptLanguage,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/v1/subjects/{subject_id}/concept-progress'.replaceAll('{' r'subject_id' '}', encodeQueryParameter(_serializers, subjectId, const FullType(String)).toString());
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

    final _queryParameters = <String, dynamic>{
      if (limit != null) r'limit': encodeQueryParameter(_serializers, limit, const FullType(int)),
      if (cursor != null) r'cursor': encodeQueryParameter(_serializers, cursor, const FullType(String)),
      if (horizonDays != null) r'horizon_days': encodeQueryParameter(_serializers, horizonDays, const FullType(num)),
    };

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      queryParameters: _queryParameters,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    PageConceptProgressItem? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null ? null : _serializers.deserialize(
        rawResponse,
        specifiedType: const FullType(PageConceptProgressItem),
      ) as PageConceptProgressItem;

    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<PageConceptProgressItem>(
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
