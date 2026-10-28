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
import 'src/features/consent/application/consent_controller.dart';
import 'src/features/consent/data/consent_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfiguration.fromEnvironment();

  const keyStore = FlutterSecureKeyStore();
  const secureStorage = SecureSupabaseLocalStorage(keyStore: keyStore);
  final appLocalStorage = AppLocalStorage(keyStore);

  AuthRepository authRepository;
  SessionRepository sessionRepository;
  ConsentRepository consentRepository = MockConsentRepository();

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
  } else {
    // Default safe local baseline when environment define is not provided
    authRepository = MockAuthRepository();
    sessionRepository = MockSessionRepository();
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
      ],
      child: const MemoraApp(),
    ),
  );
}
