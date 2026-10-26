# memora_api_client.api.ProfileApi

## Load the API package
```dart
import 'package:memora_api_client/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**acceptConsent**](ProfileApi.md#acceptconsent) | **POST** /v1/consent/acceptances | Accept a current consent policy
[**getConsent**](ProfileApi.md#getconsent) | **GET** /v1/consent | Get current consent status


# **acceptConsent**
> ConsentAcceptanceResponse acceptConsent(xCorrelationID, xClientVersion, xPlatform, idempotencyKey, consentAcceptanceRequest, acceptLanguage)

Accept a current consent policy

Idempotently appends evidence for the authenticated user's current policy version.

### Example
```dart
import 'package:memora_api_client/api.dart';

final api = MemoraApiClient().getProfileApi();
final String xCorrelationID = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xClientVersion = xClientVersion_example; // String | 
final String xPlatform = xPlatform_example; // String | 
final String idempotencyKey = idempotencyKey_example; // String | 
final ConsentAcceptanceRequest consentAcceptanceRequest = ; // ConsentAcceptanceRequest | 
final String acceptLanguage = acceptLanguage_example; // String | 

try {
    final response = api.acceptConsent(xCorrelationID, xClientVersion, xPlatform, idempotencyKey, consentAcceptanceRequest, acceptLanguage);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ProfileApi->acceptConsent: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **xCorrelationID** | **String**|  | 
 **xClientVersion** | **String**|  | 
 **xPlatform** | **String**|  | 
 **idempotencyKey** | **String**|  | 
 **consentAcceptanceRequest** | [**ConsentAcceptanceRequest**](ConsentAcceptanceRequest.md)|  | 
 **acceptLanguage** | **String**|  | [optional] 

### Return type

[**ConsentAcceptanceResponse**](ConsentAcceptanceResponse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getConsent**
> ConsentResponse getConsent(xCorrelationID, xClientVersion, xPlatform, acceptLanguage)

Get current consent status

Returns configured policy versions and the authenticated user's latest decisions.

### Example
```dart
import 'package:memora_api_client/api.dart';

final api = MemoraApiClient().getProfileApi();
final String xCorrelationID = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xClientVersion = xClientVersion_example; // String | 
final String xPlatform = xPlatform_example; // String | 
final String acceptLanguage = acceptLanguage_example; // String | 

try {
    final response = api.getConsent(xCorrelationID, xClientVersion, xPlatform, acceptLanguage);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ProfileApi->getConsent: $e\n');
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

[**ConsentResponse**](ConsentResponse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

