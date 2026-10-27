import 'package:test/test.dart';
import 'package:memora_api_client/memora_api_client.dart';


/// tests for SessionApi
void main() {
  final instance = MemoraApiClient().getSessionApi();

  group(SessionApi, () {
    // Bootstrap the authenticated session
    //
    // Returns the bounded account, consent, subject, mission and pending-state summary.
    //
    //Future<SessionBootstrapResponse> bootstrapSession(String xCorrelationID, String xClientVersion, String xPlatform, { String acceptLanguage }) async
    test('test bootstrapSession', () async {
      // TODO
    });

    // Remove a notification device
    //
    // Idempotently revokes an authenticated user's device registration.
    //
    //Future deleteDevice(String deviceId, String xCorrelationID, String xClientVersion, String xPlatform, { String acceptLanguage }) async
    test('test deleteDevice', () async {
      // TODO
    });

    // Register or refresh a notification device
    //
    // Idempotently stores an encrypted push token for the authenticated installation.
    //
    //Future<DeviceRegistrationResponse> registerDevice(String xCorrelationID, String xClientVersion, String xPlatform, String idempotencyKey, DeviceRegistrationRequest deviceRegistrationRequest, { String acceptLanguage }) async
    test('test registerDevice', () async {
      // TODO
    });

    // Revoke authenticated sessions
    //
    // Idempotently revokes the requested Supabase session scope after recent authentication.
    //
    //Future revokeSession(String xCorrelationID, String xClientVersion, String xPlatform, String idempotencyKey, SessionRevokeRequest sessionRevokeRequest, { String acceptLanguage }) async
    test('test revokeSession', () async {
      // TODO
    });

  });
}
