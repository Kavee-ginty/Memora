import 'package:test/test.dart';
import 'package:memora_api_client/memora_api_client.dart';


/// tests for PrivacyApi
void main() {
  final instance = MemoraApiClient().getPrivacyApi();

  group(PrivacyApi, () {
    // Cancel pending account deletion
    //
    // Cancels a deletion request if processing has not yet commenced.
    //
    //Future<PrivacyDeletionResponse> cancelPrivacyDeletion(String requestId, String xCorrelationID, String xClientVersion, String xPlatform, String idempotencyKey, PrivacyDeletionCancelRequest privacyDeletionCancelRequest, { String acceptLanguage }) async
    test('test cancelPrivacyDeletion', () async {
      // TODO
    });

    // Request account deletion
    //
    // Idempotently initiates verified durable account deletion after recent authentication.
    //
    //Future<PrivacyDeletionResponse> createPrivacyDeletion(String xCorrelationID, String xClientVersion, String xPlatform, String idempotencyKey, PrivacyDeletionRequest privacyDeletionRequest, { String acceptLanguage }) async
    test('test createPrivacyDeletion', () async {
      // TODO
    });

    // Request account data export
    //
    // Idempotently initiates an asynchronous data export job after recent authentication.
    //
    //Future<PrivacyExportResponse> createPrivacyExport(String xCorrelationID, String xClientVersion, String xPlatform, String idempotencyKey, PrivacyExportRequest privacyExportRequest, { String acceptLanguage }) async
    test('test createPrivacyExport', () async {
      // TODO
    });

    // Get account deletion status
    //
    // Returns deletion workflow progress and cryptographic deletion proofs upon completion.
    //
    //Future<PrivacyDeletionResponse> getPrivacyDeletion(String requestId, String xCorrelationID, String xClientVersion, String xPlatform, { String acceptLanguage }) async
    test('test getPrivacyDeletion', () async {
      // TODO
    });

    // Get privacy export status
    //
    // Returns the status and ephemeral download link of an export request.
    //
    //Future<PrivacyExportResponse> getPrivacyExport(String requestId, String xCorrelationID, String xClientVersion, String xPlatform, { String acceptLanguage }) async
    test('test getPrivacyExport', () async {
      // TODO
    });

  });
}
