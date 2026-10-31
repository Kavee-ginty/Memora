import 'package:test/test.dart';
import 'package:memora_api_client/memora_api_client.dart';


/// tests for CurriculumApi
void main() {
  final instance = MemoraApiClient().getCurriculumApi();

  group(CurriculumApi, () {
    // Read a concept's evidence summary and scheduling history
    //
    // Returns the authenticated student's bounded evidence summary and paginated scheduling decisions for one concept, each with allowlisted reason codes, a template key and safe copy. Another learner's concept returns 404.
    //
    //Future<ConceptHistoryResponse> getConceptHistory(String conceptId, String xCorrelationID, String xClientVersion, String xPlatform, { int limit, String cursor, String acceptLanguage }) async
    test('test getConceptHistory', () async {
      // TODO
    });

    // List due and near-due concept progress for a subject
    //
    // Returns the authenticated student's concept states in next-review order for the requested horizon, with a retrievability band, a review window and a plain-language due reason. Hidden ranking scores and event payloads are never returned.
    //
    //Future<PageConceptProgressItem> listConceptProgress(String subjectId, String xCorrelationID, String xClientVersion, String xPlatform, { int limit, String cursor, num horizonDays, String acceptLanguage }) async
    test('test listConceptProgress', () async {
      // TODO
    });

  });
}
