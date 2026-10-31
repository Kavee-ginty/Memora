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

    // Get the authenticated profile
    //
    // Returns the owner-scoped profile with its optimistic concurrency version.
    //
    //Future<ProfileResponse> getProfile(String xCorrelationID, String xClientVersion, String xPlatform, { String acceptLanguage }) async
    test('test getProfile', () async {
      // TODO
    });

    // Get profile preferences
    //
    // Returns confirmed notification, accessibility and mission settings.
    //
    //Future<ProfilePreferencesResponse> getProfilePreferences(String xCorrelationID, String xClientVersion, String xPlatform, { String acceptLanguage }) async
    test('test getProfilePreferences', () async {
      // TODO
    });

    // Update the authenticated profile
    //
    // Idempotently updates allowlisted profile fields when the supplied version is current.
    //
    //Future<ProfileResponse> updateProfile(String xCorrelationID, String xClientVersion, String xPlatform, String idempotencyKey, ProfileUpdateRequest profileUpdateRequest, { String acceptLanguage }) async
    test('test updateProfile', () async {
      // TODO
    });

    // Update profile preferences
    //
    // Idempotently updates explicit settings when the supplied version is current.
    //
    //Future<ProfilePreferencesResponse> updateProfilePreferences(String xCorrelationID, String xClientVersion, String xPlatform, String idempotencyKey, ProfilePreferencesUpdateRequest profilePreferencesUpdateRequest, { String acceptLanguage }) async
    test('test updateProfilePreferences', () async {
      // TODO
    });

  });
}
