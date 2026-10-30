# memora_api_client.model.EvidenceSummary

## Load the model package
```dart
import 'package:memora_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**confidenceBand** | **String** | Banded evidence confidence; raw values are never returned. | 
**countsByType** | **BuiltMap&lt;String, int&gt;** | Lifetime event counts per type; sums to total_events. | 
**eligibleEvents** | **int** | Lifetime events that were eligible for scheduling. | 
**lastObservedAt** | **String** | Most recent evidence timestamp, or null when none is recorded. | 
**recentEvents** | **int** | Evidence events observed inside the recency window. | 
**totalEvents** | **int** | Lifetime recorded evidence events. | 
**windowDays** | **int** | Length of the recency window in days. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


