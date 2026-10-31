import 'package:test/test.dart';
import 'package:memora_api_client/memora_api_client.dart';


/// tests for VerificationApi
void main() {
  final instance = MemoraApiClient().getVerificationApi();

  group(VerificationApi, () {
    // Commit accepted knowledge and exposure once
    //
    //Future<KnowledgeCommitResponse> commitLearningUpdate(String updateId, String xCorrelationID, String xClientVersion, String xPlatform, String idempotencyKey, { String acceptLanguage }) async
    test('test commitLearningUpdate', () async {
      // TODO
    });

    // List authorized extraction candidates
    //
    //Future<CandidateListResponse> listExtractionCandidates(String updateId, String xCorrelationID, String xClientVersion, String xPlatform, { String cursor, int limit, String acceptLanguage }) async
    test('test listExtractionCandidates', () async {
      // TODO
    });

    // Preview the validated learning path
    //
    //Future<LearningPathPreviewResponse> previewLearningPath(String updateId, String xCorrelationID, String xClientVersion, String xPlatform, { String acceptLanguage }) async
    test('test previewLearningPath', () async {
      // TODO
    });

    // Submit versioned concept verification decisions
    //
    //Future<SubmitVerificationDecisionsResponse> submitVerificationDecisions(String updateId, String xCorrelationID, String xClientVersion, String xPlatform, String idempotencyKey, SubmitVerificationDecisionsRequest submitVerificationDecisionsRequest, { String acceptLanguage }) async
    test('test submitVerificationDecisions', () async {
      // TODO
    });

  });
}
