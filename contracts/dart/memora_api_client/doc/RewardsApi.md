# memora_api_client.api.RewardsApi

## Load the API package
```dart
import 'package:memora_api_client/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**listRewards**](RewardsApi.md#listrewards) | **GET** /v1/rewards | List Rewards
[**updateRewardPlacement**](RewardsApi.md#updaterewardplacement) | **PATCH** /v1/rewards/{reward_grant_id} | Update Reward Placement


# **listRewards**
> RewardInventoryResponse listRewards(xCorrelationID, xClientVersion, xPlatform, grantId, acceptLanguage)

List Rewards

### Example
```dart
import 'package:memora_api_client/api.dart';

final api = MemoraApiClient().getRewardsApi();
final String xCorrelationID = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xClientVersion = xClientVersion_example; // String | 
final String xPlatform = xPlatform_example; // String | 
final String grantId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String acceptLanguage = acceptLanguage_example; // String | 

try {
    final response = api.listRewards(xCorrelationID, xClientVersion, xPlatform, grantId, acceptLanguage);
    print(response);
} on DioException catch (e) {
    print('Exception when calling RewardsApi->listRewards: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **xCorrelationID** | **String**|  | 
 **xClientVersion** | **String**|  | 
 **xPlatform** | **String**|  | 
 **grantId** | **String**|  | [optional] 
 **acceptLanguage** | **String**|  | [optional] 

### Return type

[**RewardInventoryResponse**](RewardInventoryResponse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateRewardPlacement**
> RewardGrant updateRewardPlacement(rewardGrantId, xCorrelationID, xClientVersion, xPlatform, idempotencyKey, rewardPlacementRequest, acceptLanguage)

Update Reward Placement

### Example
```dart
import 'package:memora_api_client/api.dart';

final api = MemoraApiClient().getRewardsApi();
final String rewardGrantId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xCorrelationID = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String xClientVersion = xClientVersion_example; // String | 
final String xPlatform = xPlatform_example; // String | 
final String idempotencyKey = idempotencyKey_example; // String | 
final RewardPlacementRequest rewardPlacementRequest = ; // RewardPlacementRequest | 
final String acceptLanguage = acceptLanguage_example; // String | 

try {
    final response = api.updateRewardPlacement(rewardGrantId, xCorrelationID, xClientVersion, xPlatform, idempotencyKey, rewardPlacementRequest, acceptLanguage);
    print(response);
} on DioException catch (e) {
    print('Exception when calling RewardsApi->updateRewardPlacement: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **rewardGrantId** | **String**|  | 
 **xCorrelationID** | **String**|  | 
 **xClientVersion** | **String**|  | 
 **xPlatform** | **String**|  | 
 **idempotencyKey** | **String**|  | 
 **rewardPlacementRequest** | [**RewardPlacementRequest**](RewardPlacementRequest.md)|  | 
 **acceptLanguage** | **String**|  | [optional] 

### Return type

[**RewardGrant**](RewardGrant.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

