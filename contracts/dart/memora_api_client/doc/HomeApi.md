# memora_api_client.api.HomeApi

## Load the API package
```dart
import 'package:memora_api_client/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getHome**](HomeApi.md#gethome) | **GET** /v1/home | Get Home


# **getHome**
> HomeResponse getHome(xCorrelationID, xClientVersion, xPlatform, acceptLanguage)

Get Home

### Example
```dart
import 'package:memora_api_client/api.dart';

final api = MemoraApiClient().getHomeApi();
final String xCorrelationID = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xClientVersion = xClientVersion_example; // String | 
final String xPlatform = xPlatform_example; // String | 
final String acceptLanguage = acceptLanguage_example; // String | 

try {
    final response = api.getHome(xCorrelationID, xClientVersion, xPlatform, acceptLanguage);
    print(response);
} on DioException catch (e) {
    print('Exception when calling HomeApi->getHome: $e\n');
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

[**HomeResponse**](HomeResponse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

