# memora_api_client.api.CurriculumApi

## Load the API package
```dart
import 'package:memora_api_client/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getConceptHistory**](CurriculumApi.md#getconcepthistory) | **GET** /v1/concepts/{concept_id}/history | Read a concept&#39;s evidence summary and scheduling history
[**listConceptProgress**](CurriculumApi.md#listconceptprogress) | **GET** /v1/subjects/{subject_id}/concept-progress | List due and near-due concept progress for a subject


# **getConceptHistory**
> ConceptHistoryResponse getConceptHistory(conceptId, xCorrelationID, xClientVersion, xPlatform, limit, cursor, acceptLanguage)

Read a concept's evidence summary and scheduling history

Returns the authenticated student's bounded evidence summary and paginated scheduling decisions for one concept, each with allowlisted reason codes, a template key and safe copy. Another learner's concept returns 404.

### Example
```dart
import 'package:memora_api_client/api.dart';

final api = MemoraApiClient().getCurriculumApi();
final String conceptId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xCorrelationID = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xClientVersion = xClientVersion_example; // String | 
final String xPlatform = xPlatform_example; // String | 
final int limit = 56; // int | 
final String cursor = cursor_example; // String | 
final String acceptLanguage = acceptLanguage_example; // String | 

try {
    final response = api.getConceptHistory(conceptId, xCorrelationID, xClientVersion, xPlatform, limit, cursor, acceptLanguage);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CurriculumApi->getConceptHistory: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **conceptId** | **String**|  | 
 **xCorrelationID** | **String**|  | 
 **xClientVersion** | **String**|  | 
 **xPlatform** | **String**|  | 
 **limit** | **int**|  | [optional] [default to 20]
 **cursor** | **String**|  | [optional] 
 **acceptLanguage** | **String**|  | [optional] 

### Return type

[**ConceptHistoryResponse**](ConceptHistoryResponse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listConceptProgress**
> PageConceptProgressItem listConceptProgress(subjectId, xCorrelationID, xClientVersion, xPlatform, limit, cursor, horizonDays, acceptLanguage)

List due and near-due concept progress for a subject

Returns the authenticated student's concept states in next-review order for the requested horizon, with a retrievability band, a review window and a plain-language due reason. Hidden ranking scores and event payloads are never returned.

### Example
```dart
import 'package:memora_api_client/api.dart';

final api = MemoraApiClient().getCurriculumApi();
final String subjectId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xCorrelationID = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xClientVersion = xClientVersion_example; // String | 
final String xPlatform = xPlatform_example; // String | 
final int limit = 56; // int | 
final String cursor = cursor_example; // String | 
final num horizonDays = 8.14; // num | 
final String acceptLanguage = acceptLanguage_example; // String | 

try {
    final response = api.listConceptProgress(subjectId, xCorrelationID, xClientVersion, xPlatform, limit, cursor, horizonDays, acceptLanguage);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CurriculumApi->listConceptProgress: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **subjectId** | **String**|  | 
 **xCorrelationID** | **String**|  | 
 **xClientVersion** | **String**|  | 
 **xPlatform** | **String**|  | 
 **limit** | **int**|  | [optional] [default to 20]
 **cursor** | **String**|  | [optional] 
 **horizonDays** | **num**|  | [optional] [default to 3.0]
 **acceptLanguage** | **String**|  | [optional] 

### Return type

[**PageConceptProgressItem**](PageConceptProgressItem.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

