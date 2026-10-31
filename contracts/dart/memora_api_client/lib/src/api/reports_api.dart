//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'dart:async';

import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:dio/dio.dart';

import 'package:memora_api_client/src/api_util.dart';
import 'package:memora_api_client/src/model/error_envelope.dart';
import 'package:memora_api_client/src/model/page_question_report_summary.dart';
import 'package:memora_api_client/src/model/question_report_create_request.dart';
import 'package:memora_api_client/src/model/question_report_response.dart';

class ReportsApi {
  final Dio _dio;

  final Serializers _serializers;

  const ReportsApi(this._dio, this._serializers);

  /// Report a question, answer, explanation or grading issue
  /// Idempotently records a bounded report without changing historical content or grading, and states whether disputed evidence is limited pending review.
  ///
  /// Parameters:
  /// * [questionVersionId]
  /// * [xCorrelationID]
  /// * [xClientVersion]
  /// * [xPlatform]
  /// * [idempotencyKey]
  /// * [questionReportCreateRequest]
  /// * [acceptLanguage]
  /// * [cancelToken] - A [CancelToken] that can be used to cancel the operation
  /// * [headers] - Can be used to add additional headers to the request
  /// * [extras] - Can be used to add flags to the request
  /// * [validateStatus] - A [ValidateStatus] callback that can be used to determine request success based on the HTTP status of the response
  /// * [onSendProgress] - A [ProgressCallback] that can be used to get the send progress
  /// * [onReceiveProgress] - A [ProgressCallback] that can be used to get the receive progress
  ///
  /// Returns a [Future] containing a [Response] with a [QuestionReportResponse] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<QuestionReportResponse>> createQuestionReport({
    required String questionVersionId,
    required String xCorrelationID,
    required String xClientVersion,
    required String xPlatform,
    required String idempotencyKey,
    required QuestionReportCreateRequest questionReportCreateRequest,
    String? acceptLanguage,
    CancelToken? cancelToken,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    ValidateStatus? validateStatus,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final _path = r'/v1/questions/{question_version_id}/reports'.replaceAll(
        '{' r'question_version_id' '}',
        encodeQueryParameter(
                _serializers, questionVersionId, const FullType(String))
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
      contentType: 'application/json',
      validateStatus: validateStatus,
    );

    dynamic _bodyData;

    try {
      const _type = FullType(QuestionReportCreateRequest);
      _bodyData = _serializers.serialize(questionReportCreateRequest,
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

    QuestionReportResponse? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null
          ? null
          : _serializers.deserialize(
              rawResponse,
              specifiedType: const FullType(QuestionReportResponse),
            ) as QuestionReportResponse;
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<QuestionReportResponse>(
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

  /// Read a question report and its safe resolution state
  /// Returns only the authenticated owner&#39;s report, status and safe resolution code. Reviewer identity, internal notes and report text are never returned.
  ///
  /// Parameters:
  /// * [reportId]
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
  /// Returns a [Future] containing a [Response] with a [QuestionReportResponse] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<QuestionReportResponse>> getQuestionReport({
    required String reportId,
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
    final _path = r'/v1/question-reports/{report_id}'.replaceAll(
        '{' r'report_id' '}',
        encodeQueryParameter(_serializers, reportId, const FullType(String))
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

    QuestionReportResponse? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null
          ? null
          : _serializers.deserialize(
              rawResponse,
              specifiedType: const FullType(QuestionReportResponse),
            ) as QuestionReportResponse;
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<QuestionReportResponse>(
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

  /// List the authenticated student&#39;s question reports
  /// Returns owner-scoped reports in stable reverse submission order.
  ///
  /// Parameters:
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
  /// Returns a [Future] containing a [Response] with a [PageQuestionReportSummary] as data
  /// Throws [DioException] if API call or serialization fails
  Future<Response<PageQuestionReportSummary>> listQuestionReports({
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
    final _path = r'/v1/question-reports';
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
      if (limit != null)
        r'limit':
            encodeQueryParameter(_serializers, limit, const FullType(int)),
      if (cursor != null)
        r'cursor':
            encodeQueryParameter(_serializers, cursor, const FullType(String)),
    };

    final _response = await _dio.request<Object>(
      _path,
      options: _options,
      queryParameters: _queryParameters,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );

    PageQuestionReportSummary? _responseData;

    try {
      final rawResponse = _response.data;
      _responseData = rawResponse == null
          ? null
          : _serializers.deserialize(
              rawResponse,
              specifiedType: const FullType(PageQuestionReportSummary),
            ) as PageQuestionReportSummary;
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: _response.requestOptions,
        response: _response,
        type: DioExceptionType.unknown,
        error: error,
        stackTrace: stackTrace,
      );
    }

    return Response<PageQuestionReportSummary>(
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
