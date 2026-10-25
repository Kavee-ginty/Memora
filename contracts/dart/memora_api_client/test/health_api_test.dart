import 'package:test/test.dart';
import 'package:memora_api_client/memora_api_client.dart';


/// tests for HealthApi
void main() {
  final instance = MemoraApiClient().getHealthApi();

  group(HealthApi, () {
    // Live
    //
    //Future<HealthResponse> healthLive() async
    test('test healthLive', () async {
      // TODO
    });

    // Ready
    //
    //Future<HealthResponse> healthReady() async
    test('test healthReady', () async {
      // TODO
    });

  });
}
