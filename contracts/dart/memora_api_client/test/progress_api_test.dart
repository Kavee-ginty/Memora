import 'package:test/test.dart';
import 'package:memora_api_client/memora_api_client.dart';


/// tests for ProgressApi
void main() {
  final instance = MemoraApiClient().getProgressApi();

  group(ProgressApi, () {
    // Get Progress Statistics
    //
    //Future<ProgressStatisticsResponse> getProgressStatistics(Date start, Date end, String timezone, String xCorrelationID, String xClientVersion, String xPlatform, { String acceptLanguage }) async
    test('test getProgressStatistics', () async {
      // TODO
    });

    // Get Reef
    //
    //Future<ReefDetail> getReef(String subjectId, String xCorrelationID, String xClientVersion, String xPlatform, { String acceptLanguage }) async
    test('test getReef', () async {
      // TODO
    });

    // Get Seabed
    //
    //Future<SeabedResponse> getSeabed(String xCorrelationID, String xClientVersion, String xPlatform, { String acceptLanguage }) async
    test('test getSeabed', () async {
      // TODO
    });

  });
}
