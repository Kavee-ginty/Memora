# memora_api_client.api.ProgressApi

## Load the API package
```dart
import 'package:memora_api_client/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getProgressStatistics**](ProgressApi.md#getprogressstatistics) | **GET** /v1/progress/statistics | Get Progress Statistics
[**getReef**](ProgressApi.md#getreef) | **GET** /v1/seabed/reefs/{subject_id} | Get Reef
[**getSeabed**](ProgressApi.md#getseabed) | **GET** /v1/seabed | Get Seabed


# **getProgressStatistics**
> ProgressStatisticsResponse getProgressStatistics(start, end, timezone, xCorrelationID, xClientVersion, xPlatform, acceptLanguage)

Get Progress Statistics

### Example
```dart
import 'package:memora_api_client/api.dart';

final api = MemoraApiClient().getProgressApi();
final Date start = 2013-10-20; // Date | 
final Date end = 2013-10-20; // Date | 
final String timezone = timezone_example; // String | 
final String xCorrelationID = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xClientVersion = xClientVersion_example; // String | 
final String xPlatform = xPlatform_example; // String | 
final String acceptLanguage = acceptLanguage_example; // String | 

try {
    final response = api.getProgressStatistics(start, end, timezone, xCorrelationID, xClientVersion, xPlatform, acceptLanguage);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ProgressApi->getProgressStatistics: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **start** | **Date**|  | 
 **end** | **Date**|  | 
 **timezone** | **String**|  | 
 **xCorrelationID** | **String**|  | 
 **xClientVersion** | **String**|  | 
 **xPlatform** | **String**|  | 
 **acceptLanguage** | **String**|  | [optional] 

### Return type

[**ProgressStatisticsResponse**](ProgressStatisticsResponse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getReef**
> ReefDetail getReef(subjectId, xCorrelationID, xClientVersion, xPlatform, acceptLanguage)

Get Reef

### Example
```dart
import 'package:memora_api_client/api.dart';

final api = MemoraApiClient().getProgressApi();
final String subjectId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xCorrelationID = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xClientVersion = xClientVersion_example; // String | 
final String xPlatform = xPlatform_example; // String | 
final String acceptLanguage = acceptLanguage_example; // String | 

try {
    final response = api.getReef(subjectId, xCorrelationID, xClientVersion, xPlatform, acceptLanguage);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ProgressApi->getReef: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **subjectId** | **String**|  | 
 **xCorrelationID** | **String**|  | 
 **xClientVersion** | **String**|  | 
 **xPlatform** | **String**|  | 
 **acceptLanguage** | **String**|  | [optional] 

### Return type

[**ReefDetail**](ReefDetail.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getSeabed**
> SeabedResponse getSeabed(xCorrelationID, xClientVersion, xPlatform, acceptLanguage)

Get Seabed

### Example
```dart
import 'package:memora_api_client/api.dart';

final api = MemoraApiClient().getProgressApi();
final String xCorrelationID = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xClientVersion = xClientVersion_example; // String | 
final String xPlatform = xPlatform_example; // String | 
final String acceptLanguage = acceptLanguage_example; // String | 

try {
    final response = api.getSeabed(xCorrelationID, xClientVersion, xPlatform, acceptLanguage);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ProgressApi->getSeabed: $e\n');
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

[**SeabedResponse**](SeabedResponse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

