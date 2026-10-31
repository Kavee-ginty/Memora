import 'package:test/test.dart';
import 'package:memora_api_client/memora_api_client.dart';

// tests for EvidenceSummary
void main() {
  final instance = EvidenceSummaryBuilder();
  // TODO add properties to the builder and call build()

  group(EvidenceSummary, () {
    // Banded evidence confidence; raw values are never returned.
    // String confidenceBand
    test('to test the property `confidenceBand`', () async {
      // TODO
    });

    // Lifetime event counts per type; sums to total_events.
    // BuiltMap<String, int> countsByType
    test('to test the property `countsByType`', () async {
      // TODO
    });

    // Lifetime events that were eligible for scheduling.
    // int eligibleEvents
    test('to test the property `eligibleEvents`', () async {
      // TODO
    });

    // Most recent evidence timestamp, or null when none is recorded.
    // String lastObservedAt
    test('to test the property `lastObservedAt`', () async {
      // TODO
    });

    // Evidence events observed inside the recency window.
    // int recentEvents
    test('to test the property `recentEvents`', () async {
      // TODO
    });

    // Lifetime recorded evidence events.
    // int totalEvents
    test('to test the property `totalEvents`', () async {
      // TODO
    });

    // Length of the recency window in days.
    // int windowDays
    test('to test the property `windowDays`', () async {
      // TODO
    });

  });
}
