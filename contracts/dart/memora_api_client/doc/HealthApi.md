# memora_api_client.api.HealthApi

## Load the API package
```dart
import 'package:memora_api_client/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**healthLive**](HealthApi.md#healthlive) | **GET** /health/live | Live
[**healthReady**](HealthApi.md#healthready) | **GET** /health/ready | Ready


# **healthLive**
> HealthResponse healthLive()

Live

### Example
```dart
import 'package:memora_api_client/api.dart';

final api = MemoraApiClient().getHealthApi();

try {
    final response = api.healthLive();
    print(response);
} on DioException catch (e) {
    print('Exception when calling HealthApi->healthLive: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**HealthResponse**](HealthResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **healthReady**
> HealthResponse healthReady()

Ready

### Example
```dart
import 'package:memora_api_client/api.dart';

final api = MemoraApiClient().getHealthApi();

try {
    final response = api.healthReady();
    print(response);
} on DioException catch (e) {
    print('Exception when calling HealthApi->healthReady: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**HealthResponse**](HealthResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

