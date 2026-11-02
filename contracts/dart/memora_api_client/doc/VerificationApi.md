# memora_api_client.api.VerificationApi

## Load the API package
```dart
import 'package:memora_api_client/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**commitLearningUpdate**](VerificationApi.md#commitlearningupdate) | **POST** /v1/learning-updates/{update_id}/commit | Commit accepted knowledge and exposure once
[**listExtractionCandidates**](VerificationApi.md#listextractioncandidates) | **GET** /v1/learning-updates/{update_id}/candidates | List authorized extraction candidates
[**previewLearningPath**](VerificationApi.md#previewlearningpath) | **GET** /v1/learning-updates/{update_id}/preview | Preview the validated learning path
[**submitVerificationDecisions**](VerificationApi.md#submitverificationdecisions) | **POST** /v1/learning-updates/{update_id}/verification-decisions | Submit versioned concept verification decisions


# **commitLearningUpdate**
> KnowledgeCommitResponse commitLearningUpdate(updateId, xCorrelationID, xClientVersion, xPlatform, idempotencyKey, acceptLanguage)

Commit accepted knowledge and exposure once

### Example
```dart
import 'package:memora_api_client/api.dart';

final api = MemoraApiClient().getVerificationApi();
final String updateId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xCorrelationID = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xClientVersion = xClientVersion_example; // String | 
final String xPlatform = xPlatform_example; // String | 
final String idempotencyKey = idempotencyKey_example; // String | 
final String acceptLanguage = acceptLanguage_example; // String | 

try {
    final response = api.commitLearningUpdate(updateId, xCorrelationID, xClientVersion, xPlatform, idempotencyKey, acceptLanguage);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VerificationApi->commitLearningUpdate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **updateId** | **String**|  | 
 **xCorrelationID** | **String**|  | 
 **xClientVersion** | **String**|  | 
 **xPlatform** | **String**|  | 
 **idempotencyKey** | **String**|  | 
 **acceptLanguage** | **String**|  | [optional] 

### Return type

[**KnowledgeCommitResponse**](KnowledgeCommitResponse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listExtractionCandidates**
> CandidateListResponse listExtractionCandidates(updateId, xCorrelationID, xClientVersion, xPlatform, cursor, limit, acceptLanguage)

List authorized extraction candidates

### Example
```dart
import 'package:memora_api_client/api.dart';

final api = MemoraApiClient().getVerificationApi();
final String updateId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xCorrelationID = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xClientVersion = xClientVersion_example; // String | 
final String xPlatform = xPlatform_example; // String | 
final String cursor = cursor_example; // String | 
final int limit = 56; // int | 
final String acceptLanguage = acceptLanguage_example; // String | 

try {
    final response = api.listExtractionCandidates(updateId, xCorrelationID, xClientVersion, xPlatform, cursor, limit, acceptLanguage);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VerificationApi->listExtractionCandidates: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **updateId** | **String**|  | 
 **xCorrelationID** | **String**|  | 
 **xClientVersion** | **String**|  | 
 **xPlatform** | **String**|  | 
 **cursor** | **String**|  | [optional] 
 **limit** | **int**|  | [optional] [default to 20]
 **acceptLanguage** | **String**|  | [optional] 

### Return type

[**CandidateListResponse**](CandidateListResponse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **previewLearningPath**
> LearningPathPreviewResponse previewLearningPath(updateId, xCorrelationID, xClientVersion, xPlatform, acceptLanguage)

Preview the validated learning path

### Example
```dart
import 'package:memora_api_client/api.dart';

final api = MemoraApiClient().getVerificationApi();
final String updateId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xCorrelationID = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xClientVersion = xClientVersion_example; // String | 
final String xPlatform = xPlatform_example; // String | 
final String acceptLanguage = acceptLanguage_example; // String | 

try {
    final response = api.previewLearningPath(updateId, xCorrelationID, xClientVersion, xPlatform, acceptLanguage);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VerificationApi->previewLearningPath: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **updateId** | **String**|  | 
 **xCorrelationID** | **String**|  | 
 **xClientVersion** | **String**|  | 
 **xPlatform** | **String**|  | 
 **acceptLanguage** | **String**|  | [optional] 

### Return type

[**LearningPathPreviewResponse**](LearningPathPreviewResponse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **submitVerificationDecisions**
> SubmitVerificationDecisionsResponse submitVerificationDecisions(updateId, xCorrelationID, xClientVersion, xPlatform, idempotencyKey, submitVerificationDecisionsRequest, acceptLanguage)

Submit versioned concept verification decisions

### Example
```dart
import 'package:memora_api_client/api.dart';

final api = MemoraApiClient().getVerificationApi();
final String updateId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xCorrelationID = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xClientVersion = xClientVersion_example; // String | 
final String xPlatform = xPlatform_example; // String | 
final String idempotencyKey = idempotencyKey_example; // String | 
final SubmitVerificationDecisionsRequest submitVerificationDecisionsRequest = ; // SubmitVerificationDecisionsRequest | 
final String acceptLanguage = acceptLanguage_example; // String | 

try {
    final response = api.submitVerificationDecisions(updateId, xCorrelationID, xClientVersion, xPlatform, idempotencyKey, submitVerificationDecisionsRequest, acceptLanguage);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VerificationApi->submitVerificationDecisions: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **updateId** | **String**|  | 
 **xCorrelationID** | **String**|  | 
 **xClientVersion** | **String**|  | 
 **xPlatform** | **String**|  | 
 **idempotencyKey** | **String**|  | 
 **submitVerificationDecisionsRequest** | [**SubmitVerificationDecisionsRequest**](SubmitVerificationDecisionsRequest.md)|  | 
 **acceptLanguage** | **String**|  | [optional] 

### Return type

[**SubmitVerificationDecisionsResponse**](SubmitVerificationDecisionsResponse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

