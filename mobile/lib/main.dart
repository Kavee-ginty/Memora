import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora_api_client/memora_api_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/app.dart';
import 'src/configuration/app_configuration.dart';
import 'src/features/auth/application/session_controller.dart';
import 'src/features/auth/data/auth_repository.dart';
import 'src/features/auth/data/secure_auth_storage.dart';
import 'src/features/auth/data/session_repository.dart';
import 'src/features/auth/domain/app_session_state.dart';
import 'src/features/consent/application/consent_controller.dart';
import 'src/features/consent/data/consent_repository.dart';
import 'src/features/ingestion/application/ingestion_flow_controller.dart';
import 'src/features/ingestion/data/ingestion_repository.dart';
import 'src/features/notifications/application/deep_link_controller.dart';
import 'src/features/notifications/application/push_registration_controller.dart';
import 'src/features/notifications/domain/notification_permission.dart';
import 'src/features/notifications/infrastructure/device_token_registrar.dart';
import 'src/features/notifications/infrastructure/notification_gateway.dart';
import 'src/features/privacy/application/privacy_controller.dart';
import 'src/features/privacy/data/privacy_download_launcher.dart';
import 'src/features/privacy/data/privacy_reachability.dart';
import 'src/features/privacy/data/privacy_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfiguration.fromEnvironment();

  const keyStore = FlutterSecureKeyStore();
  const secureStorage = SecureSupabaseLocalStorage(keyStore: keyStore);
  final appLocalStorage = AppLocalStorage(keyStore);

  AuthRepository authRepository;
  SessionRepository sessionRepository;
  ConsentRepository consentRepository = MockConsentRepository();
  PrivacyRepository privacyRepository = MockPrivacyRepository();
  PrivacyReachability privacyReachability = const StaticPrivacyReachability(
    true,
  );
  PrivacyDownloadLauncher privacyDownloadLauncher =
      UrlLauncherPrivacyDownloadLauncher();
  IngestionRepository ingestionRepository = MockIngestionRepository();
  NotificationGateway notificationGateway = FakeNotificationGateway();
  DeviceRegistrationApi? deviceRegistrationApi;
  MemoraApiClient? deepLinkApiClient;

  if (config.isValid &&
      config.supabaseUrl != 'https://placeholder.supabase.co') {
    await Supabase.initialize(
      url: config.supabaseUrl,
      publishableKey: config.supabasePublishableKey,
      authOptions: const FlutterAuthClientOptions(
        localStorage: secureStorage,
        pkceAsyncStorage: secureStorage,
      ),
    );
    authRepository = SupabaseAuthRepository(Supabase.instance.client);

    final dio = Dio(
      BaseOptions(
        baseUrl: config.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );
    final apiClient = MemoraApiClient(dio: dio);
    sessionRepository = MemoraSessionRepository(
      apiClient: apiClient,
      configuration: config,
      authRepository: authRepository,
    );
    consentRepository = MemoraConsentRepository(
      apiClient: apiClient,
      configuration: config,
    );
    privacyRepository = MemoraPrivacyRepository(
      apiClient: apiClient,
      configuration: config,
    );
    privacyReachability = ApiPrivacyReachability(apiClient: apiClient);
    privacyDownloadLauncher = UrlLauncherPrivacyDownloadLauncher(
      allowLocalHttp: config.environment == 'local',
    );
    ingestionRepository = MemoraIngestionRepository(
      apiClient: apiClient,
      configuration: config,
    );
    deviceRegistrationApi = MemoraDeviceRegistrationApi(
      apiClient: apiClient,
      configuration: config,
    );
    deepLinkApiClient = apiClient;
  } else {
    authRepository = MockAuthRepository()
      ..shouldFailSignIn = true
      ..configuredFailure = AuthFailure.unknown(
        'Memora is not configured. Rebuild the app with the required environment values.',
      );
    sessionRepository = MockSessionRepository();
    // Push is unavailable in unconfigured/mock builds: the registration
    // controller stays idle and never prompts (denial never blocks use).
    (notificationGateway as FakeNotificationGateway).setPermission(
      NotificationPermission.unavailable,
    );
  }

  runApp(
    ProviderScope(
      overrides: [
        appConfigurationProvider.overrideWithValue(config),
        secureKeyStoreProvider.overrideWithValue(keyStore),
        appLocalStorageProvider.overrideWithValue(appLocalStorage),
        authRepositoryProvider.overrideWithValue(authRepository),
        sessionRepositoryProvider.overrideWithValue(sessionRepository),
        consentRepositoryProvider.overrideWithValue(consentRepository),
        privacyRepositoryProvider.overrideWithValue(privacyRepository),
        privacyReachabilityProvider.overrideWithValue(privacyReachability),
        privacyDownloadLauncherProvider.overrideWithValue(
          privacyDownloadLauncher,
        ),
        ingestionRepositoryProvider.overrideWithValue(ingestionRepository),
        notificationGatewayProvider.overrideWithValue(notificationGateway),
        deviceRegistrationApiProvider.overrideWithValue(
          deviceRegistrationApi ?? _UnconfiguredDeviceRegistrationApi(),
        ),
        if (deepLinkApiClient != null)
          memoraApiClientProvider.overrideWithValue(deepLinkApiClient!),
      ],
      child: const MemoraApp(),
    ),
  );
}

/// Placeholder registration transport for unconfigured builds; the push
/// gateway reports unavailable there, so this is never reached in practice.
class _UnconfiguredDeviceRegistrationApi implements DeviceRegistrationApi {
  @override
  Future<void> register({
    required String installationId,
    required String pushToken,
    required String idempotencyKey,
    required String appVersion,
    required String platform,
    required String locale,
  }) async {
    throw UnimplementedError('Push registration requires a configured API.');
  }
}
