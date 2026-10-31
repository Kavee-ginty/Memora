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
[**getProfile**](ProfileApi.md#getprofile) | **GET** /v1/profile | Get the authenticated profile
[**getProfilePreferences**](ProfileApi.md#getprofilepreferences) | **GET** /v1/profile/preferences | Get profile preferences
[**updateProfile**](ProfileApi.md#updateprofile) | **PATCH** /v1/profile | Update the authenticated profile
[**updateProfilePreferences**](ProfileApi.md#updateprofilepreferences) | **PATCH** /v1/profile/preferences | Update profile preferences


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

# **getProfile**
> ProfileResponse getProfile(xCorrelationID, xClientVersion, xPlatform, acceptLanguage)

Get the authenticated profile

Returns the owner-scoped profile with its optimistic concurrency version.

### Example
```dart
import 'package:memora_api_client/api.dart';

final api = MemoraApiClient().getProfileApi();
final String xCorrelationID = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String |
final String xClientVersion = xClientVersion_example; // String |
final String xPlatform = xPlatform_example; // String |
final String acceptLanguage = acceptLanguage_example; // String |

try {
    final response = api.getProfile(xCorrelationID, xClientVersion, xPlatform, acceptLanguage);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ProfileApi->getProfile: $e\n');
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

[**ProfileResponse**](ProfileResponse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getProfilePreferences**
> ProfilePreferencesResponse getProfilePreferences(xCorrelationID, xClientVersion, xPlatform, acceptLanguage)

Get profile preferences

Returns confirmed notification, accessibility and mission settings.

### Example
```dart
import 'package:memora_api_client/api.dart';

final api = MemoraApiClient().getProfileApi();
final String xCorrelationID = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String |
final String xClientVersion = xClientVersion_example; // String |
final String xPlatform = xPlatform_example; // String |
final String acceptLanguage = acceptLanguage_example; // String |

try {
    final response = api.getProfilePreferences(xCorrelationID, xClientVersion, xPlatform, acceptLanguage);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ProfileApi->getProfilePreferences: $e\n');
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

[**ProfilePreferencesResponse**](ProfilePreferencesResponse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateProfile**
> ProfileResponse updateProfile(xCorrelationID, xClientVersion, xPlatform, idempotencyKey, profileUpdateRequest, acceptLanguage)

Update the authenticated profile

Idempotently updates allowlisted profile fields when the supplied version is current.

### Example
```dart
import 'package:memora_api_client/api.dart';

final api = MemoraApiClient().getProfileApi();
final String xCorrelationID = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String |
final String xClientVersion = xClientVersion_example; // String |
final String xPlatform = xPlatform_example; // String |
final String idempotencyKey = idempotencyKey_example; // String |
final ProfileUpdateRequest profileUpdateRequest = ; // ProfileUpdateRequest |
final String acceptLanguage = acceptLanguage_example; // String |

try {
    final response = api.updateProfile(xCorrelationID, xClientVersion, xPlatform, idempotencyKey, profileUpdateRequest, acceptLanguage);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ProfileApi->updateProfile: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **xCorrelationID** | **String**|  |
 **xClientVersion** | **String**|  |
 **xPlatform** | **String**|  |
 **idempotencyKey** | **String**|  |
 **profileUpdateRequest** | [**ProfileUpdateRequest**](ProfileUpdateRequest.md)|  |
 **acceptLanguage** | **String**|  | [optional]

### Return type

[**ProfileResponse**](ProfileResponse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateProfilePreferences**
> ProfilePreferencesResponse updateProfilePreferences(xCorrelationID, xClientVersion, xPlatform, idempotencyKey, profilePreferencesUpdateRequest, acceptLanguage)

Update profile preferences

Idempotently updates explicit settings when the supplied version is current.

### Example
```dart
import 'package:memora_api_client/api.dart';

final api = MemoraApiClient().getProfileApi();
final String xCorrelationID = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String |
final String xClientVersion = xClientVersion_example; // String |
final String xPlatform = xPlatform_example; // String |
final String idempotencyKey = idempotencyKey_example; // String |
final ProfilePreferencesUpdateRequest profilePreferencesUpdateRequest = ; // ProfilePreferencesUpdateRequest |
final String acceptLanguage = acceptLanguage_example; // String |

try {
    final response = api.updateProfilePreferences(xCorrelationID, xClientVersion, xPlatform, idempotencyKey, profilePreferencesUpdateRequest, acceptLanguage);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ProfileApi->updateProfilePreferences: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **xCorrelationID** | **String**|  |
 **xClientVersion** | **String**|  |
 **xPlatform** | **String**|  |
 **idempotencyKey** | **String**|  |
 **profilePreferencesUpdateRequest** | [**ProfilePreferencesUpdateRequest**](ProfilePreferencesUpdateRequest.md)|  |
 **acceptLanguage** | **String**|  | [optional]

### Return type

[**ProfilePreferencesResponse**](ProfilePreferencesResponse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)
