# memora_api_client.api.SessionApi

## Load the API package
```dart
import 'package:memora_api_client/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**bootstrapSession**](SessionApi.md#bootstrapsession) | **GET** /v1/session/bootstrap | Bootstrap the authenticated session
[**deleteDevice**](SessionApi.md#deletedevice) | **DELETE** /v1/devices/{device_id} | Remove a notification device
[**registerDevice**](SessionApi.md#registerdevice) | **POST** /v1/devices | Register or refresh a notification device
[**revokeSession**](SessionApi.md#revokesession) | **POST** /v1/session/revoke | Revoke authenticated sessions


# **bootstrapSession**
> SessionBootstrapResponse bootstrapSession(xCorrelationID, xClientVersion, xPlatform, acceptLanguage)

Bootstrap the authenticated session

Returns the bounded account, consent, subject, mission and pending-state summary.

### Example
```dart
import 'package:memora_api_client/api.dart';

final api = MemoraApiClient().getSessionApi();
final String xCorrelationID = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xClientVersion = xClientVersion_example; // String | 
final String xPlatform = xPlatform_example; // String | 
final String acceptLanguage = acceptLanguage_example; // String | 

try {
    final response = api.bootstrapSession(xCorrelationID, xClientVersion, xPlatform, acceptLanguage);
    print(response);
} on DioException catch (e) {
    print('Exception when calling SessionApi->bootstrapSession: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **xCorrelationID** | **String**|  | 
 **xClientVersion** | **String**|  | 
 **xPlatform** | **String**|  | 
 **acceptLanguage** | **String**|  | [optional] 

### Return type

[**SessionBootstrapResponse**](SessionBootstrapResponse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteDevice**
> deleteDevice(deviceId, xCorrelationID, xClientVersion, xPlatform, acceptLanguage)

Remove a notification device

Idempotently revokes an authenticated user's device registration.

### Example
```dart
import 'package:memora_api_client/api.dart';

final api = MemoraApiClient().getSessionApi();
final String deviceId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xCorrelationID = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xClientVersion = xClientVersion_example; // String | 
final String xPlatform = xPlatform_example; // String | 
final String acceptLanguage = acceptLanguage_example; // String | 

try {
    api.deleteDevice(deviceId, xCorrelationID, xClientVersion, xPlatform, acceptLanguage);
} on DioException catch (e) {
    print('Exception when calling SessionApi->deleteDevice: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **deviceId** | **String**|  | 
 **xCorrelationID** | **String**|  | 
 **xClientVersion** | **String**|  | 
 **xPlatform** | **String**|  | 
 **acceptLanguage** | **String**|  | [optional] 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **registerDevice**
> DeviceRegistrationResponse registerDevice(xCorrelationID, xClientVersion, xPlatform, idempotencyKey, deviceRegistrationRequest, acceptLanguage)

Register or refresh a notification device

Idempotently stores an encrypted push token for the authenticated installation.

### Example
```dart
import 'package:memora_api_client/api.dart';

final api = MemoraApiClient().getSessionApi();
final String xCorrelationID = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xClientVersion = xClientVersion_example; // String | 
final String xPlatform = xPlatform_example; // String | 
final String idempotencyKey = idempotencyKey_example; // String | 
final DeviceRegistrationRequest deviceRegistrationRequest = ; // DeviceRegistrationRequest | 
final String acceptLanguage = acceptLanguage_example; // String | 

try {
    final response = api.registerDevice(xCorrelationID, xClientVersion, xPlatform, idempotencyKey, deviceRegistrationRequest, acceptLanguage);
    print(response);
} on DioException catch (e) {
    print('Exception when calling SessionApi->registerDevice: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **xCorrelationID** | **String**|  | 
 **xClientVersion** | **String**|  | 
 **xPlatform** | **String**|  | 
 **idempotencyKey** | **String**|  | 
 **deviceRegistrationRequest** | [**DeviceRegistrationRequest**](DeviceRegistrationRequest.md)|  | 
 **acceptLanguage** | **String**|  | [optional] 

### Return type

[**DeviceRegistrationResponse**](DeviceRegistrationResponse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **revokeSession**
> revokeSession(xCorrelationID, xClientVersion, xPlatform, idempotencyKey, sessionRevokeRequest, acceptLanguage)

Revoke authenticated sessions

Idempotently revokes the requested Supabase session scope after recent authentication.

### Example
```dart
import 'package:memora_api_client/api.dart';

final api = MemoraApiClient().getSessionApi();
final String xCorrelationID = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xClientVersion = xClientVersion_example; // String | 
final String xPlatform = xPlatform_example; // String | 
final String idempotencyKey = idempotencyKey_example; // String | 
final SessionRevokeRequest sessionRevokeRequest = ; // SessionRevokeRequest | 
final String acceptLanguage = acceptLanguage_example; // String | 

try {
    api.revokeSession(xCorrelationID, xClientVersion, xPlatform, idempotencyKey, sessionRevokeRequest, acceptLanguage);
} on DioException catch (e) {
    print('Exception when calling SessionApi->revokeSession: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **xCorrelationID** | **String**|  | 
 **xClientVersion** | **String**|  | 
 **xPlatform** | **String**|  | 
 **idempotencyKey** | **String**|  | 
 **sessionRevokeRequest** | [**SessionRevokeRequest**](SessionRevokeRequest.md)|  | 
 **acceptLanguage** | **String**|  | [optional] 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

