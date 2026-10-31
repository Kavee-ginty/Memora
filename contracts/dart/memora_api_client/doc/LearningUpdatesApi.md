# memora_api_client.api.LearningUpdatesApi

## Load the API package
```dart
import 'package:memora_api_client/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createLearningUpdate**](LearningUpdatesApi.md#createlearningupdate) | **POST** /v1/learning-updates | Create a text or upload-backed learning update
[**createUploadGrant**](LearningUpdatesApi.md#createuploadgrant) | **POST** /v1/learning-updates/{update_id}/uploads | Request a temporary signed upload grant
[**deleteLearningUpdate**](LearningUpdatesApi.md#deletelearningupdate) | **DELETE** /v1/learning-updates/{update_id} | Discard a draft or cancel an unfinished workflow
[**finalizeUpload**](LearningUpdatesApi.md#finalizeupload) | **POST** /v1/learning-updates/{update_id}/uploads/{upload_id}/finalize | Verify an uploaded object and queue processing once
[**getLearningUpdate**](LearningUpdatesApi.md#getlearningupdate) | **GET** /v1/learning-updates/{update_id} | Read processing and deletion status
[**listLearningUpdates**](LearningUpdatesApi.md#listlearningupdates) | **GET** /v1/learning-updates | List the authenticated student&#39;s learning updates
[**retryLearningUpdate**](LearningUpdatesApi.md#retrylearningupdate) | **POST** /v1/learning-updates/{update_id}/retry | Retry an eligible failed stage
[**updateLearningUpdate**](LearningUpdatesApi.md#updatelearningupdate) | **PATCH** /v1/learning-updates/{update_id} | Edit an eligible draft update


# **createLearningUpdate**
> LearningUpdateResponse createLearningUpdate(xCorrelationID, xClientVersion, xPlatform, idempotencyKey, createLearningUpdateRequest, acceptLanguage)

Create a text or upload-backed learning update

Creates one independent learning update for the authenticated student.

### Example
```dart
import 'package:memora_api_client/api.dart';

final api = MemoraApiClient().getLearningUpdatesApi();
final String xCorrelationID = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xClientVersion = xClientVersion_example; // String | 
final String xPlatform = xPlatform_example; // String | 
final String idempotencyKey = idempotencyKey_example; // String | 
final CreateLearningUpdateRequest createLearningUpdateRequest = ; // CreateLearningUpdateRequest | 
final String acceptLanguage = acceptLanguage_example; // String | 

try {
    final response = api.createLearningUpdate(xCorrelationID, xClientVersion, xPlatform, idempotencyKey, createLearningUpdateRequest, acceptLanguage);
    print(response);
} on DioException catch (e) {
    print('Exception when calling LearningUpdatesApi->createLearningUpdate: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **xCorrelationID** | **String**|  | 
 **xClientVersion** | **String**|  | 
 **xPlatform** | **String**|  | 
 **idempotencyKey** | **String**|  | 
 **createLearningUpdateRequest** | [**CreateLearningUpdateRequest**](CreateLearningUpdateRequest.md)|  | 
 **acceptLanguage** | **String**|  | [optional] 

### Return type

[**LearningUpdateResponse**](LearningUpdateResponse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createUploadGrant**
> UploadGrantResponse createUploadGrant(updateId, xCorrelationID, xClientVersion, xPlatform, idempotencyKey, uploadGrantRequest, acceptLanguage)

Request a temporary signed upload grant

### Example
```dart
import 'package:memora_api_client/api.dart';

final api = MemoraApiClient().getLearningUpdatesApi();
final String updateId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xCorrelationID = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xClientVersion = xClientVersion_example; // String | 
final String xPlatform = xPlatform_example; // String | 
final String idempotencyKey = idempotencyKey_example; // String | 
final UploadGrantRequest uploadGrantRequest = ; // UploadGrantRequest | 
final String acceptLanguage = acceptLanguage_example; // String | 

try {
    final response = api.createUploadGrant(updateId, xCorrelationID, xClientVersion, xPlatform, idempotencyKey, uploadGrantRequest, acceptLanguage);
    print(response);
} on DioException catch (e) {
    print('Exception when calling LearningUpdatesApi->createUploadGrant: $e\n');
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
 **uploadGrantRequest** | [**UploadGrantRequest**](UploadGrantRequest.md)|  | 
 **acceptLanguage** | **String**|  | [optional] 

### Return type

[**UploadGrantResponse**](UploadGrantResponse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteLearningUpdate**
> deleteLearningUpdate(updateId, xCorrelationID, xClientVersion, xPlatform, idempotencyKey, acceptLanguage)

Discard a draft or cancel an unfinished workflow

### Example
```dart
import 'package:memora_api_client/api.dart';

final api = MemoraApiClient().getLearningUpdatesApi();
final String updateId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xCorrelationID = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xClientVersion = xClientVersion_example; // String | 
final String xPlatform = xPlatform_example; // String | 
final String idempotencyKey = idempotencyKey_example; // String | 
final String acceptLanguage = acceptLanguage_example; // String | 

try {
    api.deleteLearningUpdate(updateId, xCorrelationID, xClientVersion, xPlatform, idempotencyKey, acceptLanguage);
} on DioException catch (e) {
    print('Exception when calling LearningUpdatesApi->deleteLearningUpdate: $e\n');
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

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **finalizeUpload**
> LearningUpdateResponse finalizeUpload(updateId, uploadId, xCorrelationID, xClientVersion, xPlatform, idempotencyKey, finalizeUploadRequest, acceptLanguage)

Verify an uploaded object and queue processing once

### Example
```dart
import 'package:memora_api_client/api.dart';

final api = MemoraApiClient().getLearningUpdatesApi();
final String updateId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String uploadId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xCorrelationID = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xClientVersion = xClientVersion_example; // String | 
final String xPlatform = xPlatform_example; // String | 
final String idempotencyKey = idempotencyKey_example; // String | 
final FinalizeUploadRequest finalizeUploadRequest = ; // FinalizeUploadRequest | 
final String acceptLanguage = acceptLanguage_example; // String | 

try {
    final response = api.finalizeUpload(updateId, uploadId, xCorrelationID, xClientVersion, xPlatform, idempotencyKey, finalizeUploadRequest, acceptLanguage);
    print(response);
} on DioException catch (e) {
    print('Exception when calling LearningUpdatesApi->finalizeUpload: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **updateId** | **String**|  | 
 **uploadId** | **String**|  | 
 **xCorrelationID** | **String**|  | 
 **xClientVersion** | **String**|  | 
 **xPlatform** | **String**|  | 
 **idempotencyKey** | **String**|  | 
 **finalizeUploadRequest** | [**FinalizeUploadRequest**](FinalizeUploadRequest.md)|  | 
 **acceptLanguage** | **String**|  | [optional] 

### Return type

[**LearningUpdateResponse**](LearningUpdateResponse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getLearningUpdate**
> LearningUpdateResponse getLearningUpdate(updateId, xCorrelationID, xClientVersion, xPlatform, acceptLanguage)

Read processing and deletion status

### Example
```dart
import 'package:memora_api_client/api.dart';

final api = MemoraApiClient().getLearningUpdatesApi();
final String updateId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xCorrelationID = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xClientVersion = xClientVersion_example; // String | 
final String xPlatform = xPlatform_example; // String | 
final String acceptLanguage = acceptLanguage_example; // String | 

try {
    final response = api.getLearningUpdate(updateId, xCorrelationID, xClientVersion, xPlatform, acceptLanguage);
    print(response);
} on DioException catch (e) {
    print('Exception when calling LearningUpdatesApi->getLearningUpdate: $e\n');
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

[**LearningUpdateResponse**](LearningUpdateResponse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listLearningUpdates**
> LearningUpdateListResponse listLearningUpdates(xCorrelationID, xClientVersion, xPlatform, cursor, limit, acceptLanguage)

List the authenticated student's learning updates

### Example
```dart
import 'package:memora_api_client/api.dart';

final api = MemoraApiClient().getLearningUpdatesApi();
final String xCorrelationID = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xClientVersion = xClientVersion_example; // String | 
final String xPlatform = xPlatform_example; // String | 
final String cursor = cursor_example; // String | 
final int limit = 56; // int | 
final String acceptLanguage = acceptLanguage_example; // String | 

try {
    final response = api.listLearningUpdates(xCorrelationID, xClientVersion, xPlatform, cursor, limit, acceptLanguage);
    print(response);
} on DioException catch (e) {
    print('Exception when calling LearningUpdatesApi->listLearningUpdates: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **xCorrelationID** | **String**|  | 
 **xClientVersion** | **String**|  | 
 **xPlatform** | **String**|  | 
 **cursor** | **String**|  | [optional] 
 **limit** | **int**|  | [optional] [default to 20]
 **acceptLanguage** | **String**|  | [optional] 

### Return type

[**LearningUpdateListResponse**](LearningUpdateListResponse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **retryLearningUpdate**
> LearningUpdateResponse retryLearningUpdate(updateId, xCorrelationID, xClientVersion, xPlatform, idempotencyKey, retryLearningUpdateRequest, acceptLanguage)

Retry an eligible failed stage

### Example
```dart
import 'package:memora_api_client/api.dart';

final api = MemoraApiClient().getLearningUpdatesApi();
final String updateId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xCorrelationID = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xClientVersion = xClientVersion_example; // String | 
final String xPlatform = xPlatform_example; // String | 
final String idempotencyKey = idempotencyKey_example; // String | 
final RetryLearningUpdateRequest retryLearningUpdateRequest = ; // RetryLearningUpdateRequest | 
final String acceptLanguage = acceptLanguage_example; // String | 

try {
    final response = api.retryLearningUpdate(updateId, xCorrelationID, xClientVersion, xPlatform, idempotencyKey, retryLearningUpdateRequest, acceptLanguage);
    print(response);
} on DioException catch (e) {
    print('Exception when calling LearningUpdatesApi->retryLearningUpdate: $e\n');
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
 **retryLearningUpdateRequest** | [**RetryLearningUpdateRequest**](RetryLearningUpdateRequest.md)|  | 
 **acceptLanguage** | **String**|  | [optional] 

### Return type

[**LearningUpdateResponse**](LearningUpdateResponse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateLearningUpdate**
> LearningUpdateResponse updateLearningUpdate(updateId, xCorrelationID, xClientVersion, xPlatform, idempotencyKey, updateLearningUpdateRequest, acceptLanguage)

Edit an eligible draft update

### Example
```dart
import 'package:memora_api_client/api.dart';

final api = MemoraApiClient().getLearningUpdatesApi();
final String updateId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xCorrelationID = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xClientVersion = xClientVersion_example; // String | 
final String xPlatform = xPlatform_example; // String | 
final String idempotencyKey = idempotencyKey_example; // String | 
final UpdateLearningUpdateRequest updateLearningUpdateRequest = ; // UpdateLearningUpdateRequest | 
final String acceptLanguage = acceptLanguage_example; // String | 

try {
    final response = api.updateLearningUpdate(updateId, xCorrelationID, xClientVersion, xPlatform, idempotencyKey, updateLearningUpdateRequest, acceptLanguage);
    print(response);
} on DioException catch (e) {
    print('Exception when calling LearningUpdatesApi->updateLearningUpdate: $e\n');
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
 **updateLearningUpdateRequest** | [**UpdateLearningUpdateRequest**](UpdateLearningUpdateRequest.md)|  | 
 **acceptLanguage** | **String**|  | [optional] 

### Return type

[**LearningUpdateResponse**](LearningUpdateResponse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

