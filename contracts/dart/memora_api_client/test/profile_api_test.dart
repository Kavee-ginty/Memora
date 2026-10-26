import 'package:test/test.dart';
import 'package:memora_api_client/memora_api_client.dart';


/// tests for ProfileApi
void main() {
  final instance = MemoraApiClient().getProfileApi();

  group(ProfileApi, () {
    // Accept a current consent policy
    //
    // Idempotently appends evidence for the authenticated user's current policy version.
    //
    //Future<ConsentAcceptanceResponse> acceptConsent(String xCorrelationID, String xClientVersion, String xPlatform, String idempotencyKey, ConsentAcceptanceRequest consentAcceptanceRequest, { String acceptLanguage }) async
    test('test acceptConsent', () async {
      // TODO
    });

    // Get current consent status
    //
    // Returns configured policy versions and the authenticated user's latest decisions.
    //
    //Future<ConsentResponse> getConsent(String xCorrelationID, String xClientVersion, String xPlatform, { String acceptLanguage }) async
    test('test getConsent', () async {
      // TODO
    });

  });
}
