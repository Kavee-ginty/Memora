import 'package:test/test.dart';
import 'package:memora_api_client/memora_api_client.dart';


/// tests for LearningUpdatesApi
void main() {
  final instance = MemoraApiClient().getLearningUpdatesApi();

  group(LearningUpdatesApi, () {
    // Create a text or upload-backed learning update
    //
    // Creates one independent learning update for the authenticated student.
    //
    //Future<LearningUpdateResponse> createLearningUpdate(String xCorrelationID, String xClientVersion, String xPlatform, String idempotencyKey, CreateLearningUpdateRequest createLearningUpdateRequest, { String acceptLanguage }) async
    test('test createLearningUpdate', () async {
      // TODO
    });

    // Request a temporary signed upload grant
    //
    //Future<UploadGrantResponse> createUploadGrant(String updateId, String xCorrelationID, String xClientVersion, String xPlatform, String idempotencyKey, UploadGrantRequest uploadGrantRequest, { String acceptLanguage }) async
    test('test createUploadGrant', () async {
      // TODO
    });

    // Discard a draft or cancel an unfinished workflow
    //
    //Future deleteLearningUpdate(String updateId, String xCorrelationID, String xClientVersion, String xPlatform, String idempotencyKey, { String acceptLanguage }) async
    test('test deleteLearningUpdate', () async {
      // TODO
    });

    // Verify an uploaded object and queue processing once
    //
    //Future<LearningUpdateResponse> finalizeUpload(String updateId, String uploadId, String xCorrelationID, String xClientVersion, String xPlatform, String idempotencyKey, FinalizeUploadRequest finalizeUploadRequest, { String acceptLanguage }) async
    test('test finalizeUpload', () async {
      // TODO
    });

    // Read processing and deletion status
    //
    //Future<LearningUpdateResponse> getLearningUpdate(String updateId, String xCorrelationID, String xClientVersion, String xPlatform, { String acceptLanguage }) async
    test('test getLearningUpdate', () async {
      // TODO
    });

    // List the authenticated student's learning updates
    //
    //Future<LearningUpdateListResponse> listLearningUpdates(String xCorrelationID, String xClientVersion, String xPlatform, { String cursor, int limit, String acceptLanguage }) async
    test('test listLearningUpdates', () async {
      // TODO
    });

    // Retry an eligible failed stage
    //
    //Future<LearningUpdateResponse> retryLearningUpdate(String updateId, String xCorrelationID, String xClientVersion, String xPlatform, String idempotencyKey, RetryLearningUpdateRequest retryLearningUpdateRequest, { String acceptLanguage }) async
    test('test retryLearningUpdate', () async {
      // TODO
    });

    // Edit an eligible draft update
    //
    //Future<LearningUpdateResponse> updateLearningUpdate(String updateId, String xCorrelationID, String xClientVersion, String xPlatform, String idempotencyKey, UpdateLearningUpdateRequest updateLearningUpdateRequest, { String acceptLanguage }) async
    test('test updateLearningUpdate', () async {
      // TODO
    });

  });
}
