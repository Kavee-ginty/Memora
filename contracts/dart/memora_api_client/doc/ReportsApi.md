# memora_api_client.api.ReportsApi

## Load the API package
```dart
import 'package:memora_api_client/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createQuestionReport**](ReportsApi.md#createquestionreport) | **POST** /v1/questions/{question_version_id}/reports | Report a question, answer, explanation or grading issue
[**getQuestionReport**](ReportsApi.md#getquestionreport) | **GET** /v1/question-reports/{report_id} | Read a question report and its safe resolution state
[**listQuestionReports**](ReportsApi.md#listquestionreports) | **GET** /v1/question-reports | List the authenticated student&#39;s question reports


# **createQuestionReport**
> QuestionReportResponse createQuestionReport(questionVersionId, xCorrelationID, xClientVersion, xPlatform, idempotencyKey, questionReportCreateRequest, acceptLanguage)

Report a question, answer, explanation or grading issue

Idempotently records a bounded report without changing historical content or grading, and states whether disputed evidence is limited pending review.

### Example
```dart
import 'package:memora_api_client/api.dart';

final api = MemoraApiClient().getReportsApi();
final String questionVersionId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xCorrelationID = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xClientVersion = xClientVersion_example; // String | 
final String xPlatform = xPlatform_example; // String | 
final String idempotencyKey = idempotencyKey_example; // String | 
final QuestionReportCreateRequest questionReportCreateRequest = ; // QuestionReportCreateRequest | 
final String acceptLanguage = acceptLanguage_example; // String | 

try {
    final response = api.createQuestionReport(questionVersionId, xCorrelationID, xClientVersion, xPlatform, idempotencyKey, questionReportCreateRequest, acceptLanguage);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ReportsApi->createQuestionReport: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **questionVersionId** | **String**|  | 
 **xCorrelationID** | **String**|  | 
 **xClientVersion** | **String**|  | 
 **xPlatform** | **String**|  | 
 **idempotencyKey** | **String**|  | 
 **questionReportCreateRequest** | [**QuestionReportCreateRequest**](QuestionReportCreateRequest.md)|  | 
 **acceptLanguage** | **String**|  | [optional] 

### Return type

[**QuestionReportResponse**](QuestionReportResponse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getQuestionReport**
> QuestionReportResponse getQuestionReport(reportId, xCorrelationID, xClientVersion, xPlatform, acceptLanguage)

Read a question report and its safe resolution state

Returns only the authenticated owner's report, status and safe resolution code. Reviewer identity, internal notes and report text are never returned.

### Example
```dart
import 'package:memora_api_client/api.dart';

final api = MemoraApiClient().getReportsApi();
final String reportId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xCorrelationID = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xClientVersion = xClientVersion_example; // String | 
final String xPlatform = xPlatform_example; // String | 
final String acceptLanguage = acceptLanguage_example; // String | 

try {
    final response = api.getQuestionReport(reportId, xCorrelationID, xClientVersion, xPlatform, acceptLanguage);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ReportsApi->getQuestionReport: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **reportId** | **String**|  | 
 **xCorrelationID** | **String**|  | 
 **xClientVersion** | **String**|  | 
 **xPlatform** | **String**|  | 
 **acceptLanguage** | **String**|  | [optional] 

### Return type

[**QuestionReportResponse**](QuestionReportResponse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listQuestionReports**
> PageQuestionReportSummary listQuestionReports(xCorrelationID, xClientVersion, xPlatform, limit, cursor, acceptLanguage)

List the authenticated student's question reports

Returns owner-scoped reports in stable reverse submission order.

### Example
```dart
import 'package:memora_api_client/api.dart';

final api = MemoraApiClient().getReportsApi();
final String xCorrelationID = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xClientVersion = xClientVersion_example; // String | 
final String xPlatform = xPlatform_example; // String | 
final int limit = 56; // int | 
final String cursor = cursor_example; // String | 
final String acceptLanguage = acceptLanguage_example; // String | 

try {
    final response = api.listQuestionReports(xCorrelationID, xClientVersion, xPlatform, limit, cursor, acceptLanguage);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ReportsApi->listQuestionReports: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **xCorrelationID** | **String**|  | 
 **xClientVersion** | **String**|  | 
 **xPlatform** | **String**|  | 
 **limit** | **int**|  | [optional] [default to 20]
 **cursor** | **String**|  | [optional] 
 **acceptLanguage** | **String**|  | [optional] 

### Return type

[**PageQuestionReportSummary**](PageQuestionReportSummary.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

