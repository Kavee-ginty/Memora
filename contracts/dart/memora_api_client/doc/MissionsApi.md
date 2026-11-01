# memora_api_client.api.MissionsApi

## Load the API package
```dart
import 'package:memora_api_client/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**completeMission**](MissionsApi.md#completemission) | **POST** /v1/missions/{mission_id}/complete | Complete a mission from persisted eligible item states
[**getMission**](MissionsApi.md#getmission) | **GET** /v1/missions/{mission_id} | Read a mission preview and authoritative progress
[**getMissionItem**](MissionsApi.md#getmissionitem) | **GET** /v1/missions/{mission_id}/items/{item_id} | Read the authorized current mission item
[**getMissionResults**](MissionsApi.md#getmissionresults) | **GET** /v1/missions/{mission_id}/results | Read stable mission completion results
[**getTodayMission**](MissionsApi.md#gettodaymission) | **GET** /v1/missions/today | Read or assemble today&#39;s bounded Daily Mission
[**pauseMission**](MissionsApi.md#pausemission) | **POST** /v1/missions/{mission_id}/pause | Pause an active mission without losing progress
[**skipMissionItem**](MissionsApi.md#skipmissionitem) | **POST** /v1/missions/{mission_id}/items/{item_id}/skip | Record one permitted mission-item skip
[**startMission**](MissionsApi.md#startmission) | **POST** /v1/missions/{mission_id}/start | Start or resume a mission with pinned question versions
[**submitAttempt**](MissionsApi.md#submitattempt) | **POST** /v1/missions/{mission_id}/items/{item_id}/attempts | Submit and grade one answer envelope


# **completeMission**
> MissionCompletionResult completeMission(missionId, xCorrelationID, xClientVersion, xPlatform, idempotencyKey, acceptLanguage)

Complete a mission from persisted eligible item states

Stores one stable learning result and emits mission.completed. XP, streak and reef projection are applied by the T15 idempotent engagement consumer.

### Example
```dart
import 'package:memora_api_client/api.dart';

final api = MemoraApiClient().getMissionsApi();
final String missionId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xCorrelationID = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xClientVersion = xClientVersion_example; // String | 
final String xPlatform = xPlatform_example; // String | 
final String idempotencyKey = idempotencyKey_example; // String | 
final String acceptLanguage = acceptLanguage_example; // String | 

try {
    final response = api.completeMission(missionId, xCorrelationID, xClientVersion, xPlatform, idempotencyKey, acceptLanguage);
    print(response);
} on DioException catch (e) {
    print('Exception when calling MissionsApi->completeMission: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **missionId** | **String**|  | 
 **xCorrelationID** | **String**|  | 
 **xClientVersion** | **String**|  | 
 **xPlatform** | **String**|  | 
 **idempotencyKey** | **String**|  | 
 **acceptLanguage** | **String**|  | [optional] 

### Return type

[**MissionCompletionResult**](MissionCompletionResult.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getMission**
> MissionManifest getMission(missionId, xCorrelationID, xClientVersion, xPlatform, acceptLanguage)

Read a mission preview and authoritative progress

### Example
```dart
import 'package:memora_api_client/api.dart';

final api = MemoraApiClient().getMissionsApi();
final String missionId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xCorrelationID = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xClientVersion = xClientVersion_example; // String | 
final String xPlatform = xPlatform_example; // String | 
final String acceptLanguage = acceptLanguage_example; // String | 

try {
    final response = api.getMission(missionId, xCorrelationID, xClientVersion, xPlatform, acceptLanguage);
    print(response);
} on DioException catch (e) {
    print('Exception when calling MissionsApi->getMission: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **missionId** | **String**|  | 
 **xCorrelationID** | **String**|  | 
 **xClientVersion** | **String**|  | 
 **xPlatform** | **String**|  | 
 **acceptLanguage** | **String**|  | [optional] 

### Return type

[**MissionManifest**](MissionManifest.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getMissionItem**
> MissionItemResponse getMissionItem(missionId, itemId, xCorrelationID, xClientVersion, xPlatform, acceptLanguage)

Read the authorized current mission item

Returns the pinned question without an answer key or grading rubric.

### Example
```dart
import 'package:memora_api_client/api.dart';

final api = MemoraApiClient().getMissionsApi();
final String missionId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String itemId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xCorrelationID = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xClientVersion = xClientVersion_example; // String | 
final String xPlatform = xPlatform_example; // String | 
final String acceptLanguage = acceptLanguage_example; // String | 

try {
    final response = api.getMissionItem(missionId, itemId, xCorrelationID, xClientVersion, xPlatform, acceptLanguage);
    print(response);
} on DioException catch (e) {
    print('Exception when calling MissionsApi->getMissionItem: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **missionId** | **String**|  | 
 **itemId** | **String**|  | 
 **xCorrelationID** | **String**|  | 
 **xClientVersion** | **String**|  | 
 **xPlatform** | **String**|  | 
 **acceptLanguage** | **String**|  | [optional] 

### Return type

[**MissionItemResponse**](MissionItemResponse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getMissionResults**
> MissionCompletionResult getMissionResults(missionId, xCorrelationID, xClientVersion, xPlatform, acceptLanguage)

Read stable mission completion results

### Example
```dart
import 'package:memora_api_client/api.dart';

final api = MemoraApiClient().getMissionsApi();
final String missionId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xCorrelationID = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xClientVersion = xClientVersion_example; // String | 
final String xPlatform = xPlatform_example; // String | 
final String acceptLanguage = acceptLanguage_example; // String | 

try {
    final response = api.getMissionResults(missionId, xCorrelationID, xClientVersion, xPlatform, acceptLanguage);
    print(response);
} on DioException catch (e) {
    print('Exception when calling MissionsApi->getMissionResults: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **missionId** | **String**|  | 
 **xCorrelationID** | **String**|  | 
 **xClientVersion** | **String**|  | 
 **xPlatform** | **String**|  | 
 **acceptLanguage** | **String**|  | [optional] 

### Return type

[**MissionCompletionResult**](MissionCompletionResult.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getTodayMission**
> TodayMissionResponse getTodayMission(xCorrelationID, xClientVersion, xPlatform, acceptLanguage)

Read or assemble today's bounded Daily Mission

Returns one persisted, owner-scoped mission ranked from authoritative memory state, or an explicit no-due state. Hidden candidates and scores are not returned.

### Example
```dart
import 'package:memora_api_client/api.dart';

final api = MemoraApiClient().getMissionsApi();
final String xCorrelationID = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xClientVersion = xClientVersion_example; // String | 
final String xPlatform = xPlatform_example; // String | 
final String acceptLanguage = acceptLanguage_example; // String | 

try {
    final response = api.getTodayMission(xCorrelationID, xClientVersion, xPlatform, acceptLanguage);
    print(response);
} on DioException catch (e) {
    print('Exception when calling MissionsApi->getTodayMission: $e\n');
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

[**TodayMissionResponse**](TodayMissionResponse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **pauseMission**
> MissionSummary pauseMission(missionId, xCorrelationID, xClientVersion, xPlatform, idempotencyKey, acceptLanguage)

Pause an active mission without losing progress

### Example
```dart
import 'package:memora_api_client/api.dart';

final api = MemoraApiClient().getMissionsApi();
final String missionId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xCorrelationID = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xClientVersion = xClientVersion_example; // String | 
final String xPlatform = xPlatform_example; // String | 
final String idempotencyKey = idempotencyKey_example; // String | 
final String acceptLanguage = acceptLanguage_example; // String | 

try {
    final response = api.pauseMission(missionId, xCorrelationID, xClientVersion, xPlatform, idempotencyKey, acceptLanguage);
    print(response);
} on DioException catch (e) {
    print('Exception when calling MissionsApi->pauseMission: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **missionId** | **String**|  | 
 **xCorrelationID** | **String**|  | 
 **xClientVersion** | **String**|  | 
 **xPlatform** | **String**|  | 
 **idempotencyKey** | **String**|  | 
 **acceptLanguage** | **String**|  | [optional] 

### Return type

[**MissionSummary**](MissionSummary.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **skipMissionItem**
> AttemptResult skipMissionItem(missionId, itemId, xCorrelationID, xClientVersion, xPlatform, idempotencyKey, acceptLanguage)

Record one permitted mission-item skip

### Example
```dart
import 'package:memora_api_client/api.dart';

final api = MemoraApiClient().getMissionsApi();
final String missionId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String itemId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xCorrelationID = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xClientVersion = xClientVersion_example; // String | 
final String xPlatform = xPlatform_example; // String | 
final String idempotencyKey = idempotencyKey_example; // String | 
final String acceptLanguage = acceptLanguage_example; // String | 

try {
    final response = api.skipMissionItem(missionId, itemId, xCorrelationID, xClientVersion, xPlatform, idempotencyKey, acceptLanguage);
    print(response);
} on DioException catch (e) {
    print('Exception when calling MissionsApi->skipMissionItem: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **missionId** | **String**|  | 
 **itemId** | **String**|  | 
 **xCorrelationID** | **String**|  | 
 **xClientVersion** | **String**|  | 
 **xPlatform** | **String**|  | 
 **idempotencyKey** | **String**|  | 
 **acceptLanguage** | **String**|  | [optional] 

### Return type

[**AttemptResult**](AttemptResult.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **startMission**
> MissionManifest startMission(missionId, xCorrelationID, xClientVersion, xPlatform, idempotencyKey, acceptLanguage)

Start or resume a mission with pinned question versions

### Example
```dart
import 'package:memora_api_client/api.dart';

final api = MemoraApiClient().getMissionsApi();
final String missionId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xCorrelationID = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xClientVersion = xClientVersion_example; // String | 
final String xPlatform = xPlatform_example; // String | 
final String idempotencyKey = idempotencyKey_example; // String | 
final String acceptLanguage = acceptLanguage_example; // String | 

try {
    final response = api.startMission(missionId, xCorrelationID, xClientVersion, xPlatform, idempotencyKey, acceptLanguage);
    print(response);
} on DioException catch (e) {
    print('Exception when calling MissionsApi->startMission: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **missionId** | **String**|  | 
 **xCorrelationID** | **String**|  | 
 **xClientVersion** | **String**|  | 
 **xPlatform** | **String**|  | 
 **idempotencyKey** | **String**|  | 
 **acceptLanguage** | **String**|  | [optional] 

### Return type

[**MissionManifest**](MissionManifest.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **submitAttempt**
> AttemptResult submitAttempt(missionId, itemId, xCorrelationID, xClientVersion, xPlatform, submitAttemptRequest, acceptLanguage)

Submit and grade one answer envelope

Uses client_operation_id as the stable retry identity, grades only the pinned question, and publishes bounded memory evidence through the transactional outbox.

### Example
```dart
import 'package:memora_api_client/api.dart';

final api = MemoraApiClient().getMissionsApi();
final String missionId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String itemId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xCorrelationID = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xClientVersion = xClientVersion_example; // String | 
final String xPlatform = xPlatform_example; // String | 
final SubmitAttemptRequest submitAttemptRequest = ; // SubmitAttemptRequest | 
final String acceptLanguage = acceptLanguage_example; // String | 

try {
    final response = api.submitAttempt(missionId, itemId, xCorrelationID, xClientVersion, xPlatform, submitAttemptRequest, acceptLanguage);
    print(response);
} on DioException catch (e) {
    print('Exception when calling MissionsApi->submitAttempt: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **missionId** | **String**|  | 
 **itemId** | **String**|  | 
 **xCorrelationID** | **String**|  | 
 **xClientVersion** | **String**|  | 
 **xPlatform** | **String**|  | 
 **submitAttemptRequest** | [**SubmitAttemptRequest**](SubmitAttemptRequest.md)|  | 
 **acceptLanguage** | **String**|  | [optional] 

### Return type

[**AttemptResult**](AttemptResult.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

