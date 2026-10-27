import 'package:test/test.dart';
import 'package:memora_api_client/memora_api_client.dart';


/// tests for ReportsApi
void main() {
  final instance = MemoraApiClient().getReportsApi();

  group(ReportsApi, () {
    // Report a question, answer, explanation or grading issue
    //
    // Idempotently records a bounded report without changing historical content or grading, and states whether disputed evidence is limited pending review.
    //
    //Future<QuestionReportResponse> createQuestionReport(String questionVersionId, String xCorrelationID, String xClientVersion, String xPlatform, String idempotencyKey, QuestionReportCreateRequest questionReportCreateRequest, { String acceptLanguage }) async
    test('test createQuestionReport', () async {
      // TODO
    });

    // Read a question report and its safe resolution state
    //
    // Returns only the authenticated owner's report, status and safe resolution code. Reviewer identity, internal notes and report text are never returned.
    //
    //Future<QuestionReportResponse> getQuestionReport(String reportId, String xCorrelationID, String xClientVersion, String xPlatform, { String acceptLanguage }) async
    test('test getQuestionReport', () async {
      // TODO
    });

    // List the authenticated student's question reports
    //
    // Returns owner-scoped reports in stable reverse submission order.
    //
    //Future<PageQuestionReportSummary> listQuestionReports(String xCorrelationID, String xClientVersion, String xPlatform, { int limit, String cursor, String acceptLanguage }) async
    test('test listQuestionReports', () async {
      // TODO
    });

  });
}
