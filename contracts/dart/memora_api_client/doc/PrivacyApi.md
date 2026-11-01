# memora_api_client.api.PrivacyApi

## Load the API package
```dart
import 'package:memora_api_client/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**cancelPrivacyDeletion**](PrivacyApi.md#cancelprivacydeletion) | **POST** /v1/privacy/deletions/{request_id}/cancel | Cancel pending account deletion
[**createPrivacyDeletion**](PrivacyApi.md#createprivacydeletion) | **POST** /v1/privacy/deletions | Request account deletion
[**createPrivacyExport**](PrivacyApi.md#createprivacyexport) | **POST** /v1/privacy/exports | Request account data export
[**getPrivacyDeletion**](PrivacyApi.md#getprivacydeletion) | **GET** /v1/privacy/deletions/{request_id} | Get account deletion status
[**getPrivacyExport**](PrivacyApi.md#getprivacyexport) | **GET** /v1/privacy/exports/{request_id} | Get privacy export status


# **cancelPrivacyDeletion**
> PrivacyDeletionResponse cancelPrivacyDeletion(requestId, xCorrelationID, xClientVersion, xPlatform, idempotencyKey, privacyDeletionCancelRequest, acceptLanguage)

Cancel pending account deletion

Cancels a deletion request if processing has not yet commenced.

### Example
```dart
import 'package:memora_api_client/api.dart';

final api = MemoraApiClient().getPrivacyApi();
final String requestId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xCorrelationID = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xClientVersion = xClientVersion_example; // String | 
final String xPlatform = xPlatform_example; // String | 
final String idempotencyKey = idempotencyKey_example; // String | 
final PrivacyDeletionCancelRequest privacyDeletionCancelRequest = ; // PrivacyDeletionCancelRequest | 
final String acceptLanguage = acceptLanguage_example; // String | 

try {
    final response = api.cancelPrivacyDeletion(requestId, xCorrelationID, xClientVersion, xPlatform, idempotencyKey, privacyDeletionCancelRequest, acceptLanguage);
    print(response);
} on DioException catch (e) {
    print('Exception when calling PrivacyApi->cancelPrivacyDeletion: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **requestId** | **String**|  | 
 **xCorrelationID** | **String**|  | 
 **xClientVersion** | **String**|  | 
 **xPlatform** | **String**|  | 
 **idempotencyKey** | **String**|  | 
 **privacyDeletionCancelRequest** | [**PrivacyDeletionCancelRequest**](PrivacyDeletionCancelRequest.md)|  | 
 **acceptLanguage** | **String**|  | [optional] 

### Return type

[**PrivacyDeletionResponse**](PrivacyDeletionResponse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createPrivacyDeletion**
> PrivacyDeletionResponse createPrivacyDeletion(xCorrelationID, xClientVersion, xPlatform, idempotencyKey, privacyDeletionRequest, acceptLanguage)

Request account deletion

Idempotently initiates verified durable account deletion after recent authentication.

### Example
```dart
import 'package:memora_api_client/api.dart';

final api = MemoraApiClient().getPrivacyApi();
final String xCorrelationID = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xClientVersion = xClientVersion_example; // String | 
final String xPlatform = xPlatform_example; // String | 
final String idempotencyKey = idempotencyKey_example; // String | 
final PrivacyDeletionRequest privacyDeletionRequest = ; // PrivacyDeletionRequest | 
final String acceptLanguage = acceptLanguage_example; // String | 

try {
    final response = api.createPrivacyDeletion(xCorrelationID, xClientVersion, xPlatform, idempotencyKey, privacyDeletionRequest, acceptLanguage);
    print(response);
} on DioException catch (e) {
    print('Exception when calling PrivacyApi->createPrivacyDeletion: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **xCorrelationID** | **String**|  | 
 **xClientVersion** | **String**|  | 
 **xPlatform** | **String**|  | 
 **idempotencyKey** | **String**|  | 
 **privacyDeletionRequest** | [**PrivacyDeletionRequest**](PrivacyDeletionRequest.md)|  | 
 **acceptLanguage** | **String**|  | [optional] 

### Return type

[**PrivacyDeletionResponse**](PrivacyDeletionResponse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **createPrivacyExport**
> PrivacyExportResponse createPrivacyExport(xCorrelationID, xClientVersion, xPlatform, idempotencyKey, privacyExportRequest, acceptLanguage)

Request account data export

Idempotently initiates an asynchronous data export job after recent authentication.

### Example
```dart
import 'package:memora_api_client/api.dart';

final api = MemoraApiClient().getPrivacyApi();
final String xCorrelationID = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xClientVersion = xClientVersion_example; // String | 
final String xPlatform = xPlatform_example; // String | 
final String idempotencyKey = idempotencyKey_example; // String | 
final PrivacyExportRequest privacyExportRequest = ; // PrivacyExportRequest | 
final String acceptLanguage = acceptLanguage_example; // String | 

try {
    final response = api.createPrivacyExport(xCorrelationID, xClientVersion, xPlatform, idempotencyKey, privacyExportRequest, acceptLanguage);
    print(response);
} on DioException catch (e) {
    print('Exception when calling PrivacyApi->createPrivacyExport: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **xCorrelationID** | **String**|  | 
 **xClientVersion** | **String**|  | 
 **xPlatform** | **String**|  | 
 **idempotencyKey** | **String**|  | 
 **privacyExportRequest** | [**PrivacyExportRequest**](PrivacyExportRequest.md)|  | 
 **acceptLanguage** | **String**|  | [optional] 

### Return type

[**PrivacyExportResponse**](PrivacyExportResponse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getPrivacyDeletion**
> PrivacyDeletionResponse getPrivacyDeletion(requestId, xCorrelationID, xClientVersion, xPlatform, acceptLanguage)

Get account deletion status

Returns deletion workflow progress and cryptographic deletion proofs upon completion.

### Example
```dart
import 'package:memora_api_client/api.dart';

final api = MemoraApiClient().getPrivacyApi();
final String requestId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xCorrelationID = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xClientVersion = xClientVersion_example; // String | 
final String xPlatform = xPlatform_example; // String | 
final String acceptLanguage = acceptLanguage_example; // String | 

try {
    final response = api.getPrivacyDeletion(requestId, xCorrelationID, xClientVersion, xPlatform, acceptLanguage);
    print(response);
} on DioException catch (e) {
    print('Exception when calling PrivacyApi->getPrivacyDeletion: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **requestId** | **String**|  | 
 **xCorrelationID** | **String**|  | 
 **xClientVersion** | **String**|  | 
 **xPlatform** | **String**|  | 
 **acceptLanguage** | **String**|  | [optional] 

### Return type

[**PrivacyDeletionResponse**](PrivacyDeletionResponse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getPrivacyExport**
> PrivacyExportResponse getPrivacyExport(requestId, xCorrelationID, xClientVersion, xPlatform, acceptLanguage)

Get privacy export status

Returns the status and ephemeral download link of an export request.

### Example
```dart
import 'package:memora_api_client/api.dart';

final api = MemoraApiClient().getPrivacyApi();
final String requestId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xCorrelationID = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xClientVersion = xClientVersion_example; // String | 
final String xPlatform = xPlatform_example; // String | 
final String acceptLanguage = acceptLanguage_example; // String | 

try {
    final response = api.getPrivacyExport(requestId, xCorrelationID, xClientVersion, xPlatform, acceptLanguage);
    print(response);
} on DioException catch (e) {
    print('Exception when calling PrivacyApi->getPrivacyExport: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **requestId** | **String**|  | 
 **xCorrelationID** | **String**|  | 
 **xClientVersion** | **String**|  | 
 **xPlatform** | **String**|  | 
 **acceptLanguage** | **String**|  | [optional] 

### Return type

[**PrivacyExportResponse**](PrivacyExportResponse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

