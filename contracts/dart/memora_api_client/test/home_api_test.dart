import 'package:test/test.dart';
import 'package:memora_api_client/memora_api_client.dart';


/// tests for HomeApi
void main() {
  final instance = MemoraApiClient().getHomeApi();

  group(HomeApi, () {
    // Get Home
    //
    //Future<HomeResponse> getHome(String xCorrelationID, String xClientVersion, String xPlatform, { String acceptLanguage }) async
    test('test getHome', () async {
      // TODO
    });

  });
}
