import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memora_api_client/memora_api_client.dart';
import 'package:memora_mobile/src/app.dart';
import 'package:memora_mobile/src/configuration/app_configuration.dart';
import 'package:memora_mobile/src/features/auth/application/session_controller.dart';
import 'package:memora_mobile/src/features/auth/data/auth_repository.dart';
import 'package:memora_mobile/src/features/auth/data/secure_auth_storage.dart';
import 'package:memora_mobile/src/features/auth/data/session_repository.dart';
import 'package:memora_mobile/src/features/profile/application/profile_controller.dart';
import 'package:memora_mobile/src/features/profile/data/profile_repository.dart';
import 'package:memora_mobile/src/routing/app_router.dart';
import 'package:memora_mobile/src/routing/app_routes.dart';

import 'profile_fixtures.dart';

class _SettingsTransport implements HttpClientAdapter {
  bool offline = false;
  bool loseNextResponse = false;
  final patches = <({String key, Map<String, dynamic> body})>[];
  final completed = <String, Map<String, Object?>>{};
  final profile = <String, Object?>{
    'user_id': 'test-owner',
    'display_name': 'Amani Perera',
    'locale': 'en-LK',
    'timezone': 'Asia/Colombo',
    'active_subject_id': null,
    'curriculum_version_id': null,
    'version': 1,
  };
  final preferences = <String, Object?>{
    'version': 1,
    'notifications_enabled': false,
    'mission_enabled': true,
    'reward_enabled': true,
    'streak_enabled': true,
    'timezone': 'Asia/Colombo',
    'lock_screen_detail': 'minimal',
    'max_daily_reminders': 1,
    'quiet_start_local': null,
    'quiet_end_local': null,
    'preferred_window_start_local': null,
    'preferred_window_end_local': null,
    'accessibility': {'schema_version': '1', 'reduced_motion': false},
  };

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    expect(options.headers['Authorization'], 'Bearer synthetic-access');
    final data = switch (options.path) {
      '/v1/profile' => profile,
      '/v1/profile/preferences' => preferences,
      _ => throw StateError('Unexpected profile API path'),
    };
    if (options.method == 'PATCH') {
      final json = await utf8.decoder.bind(requestStream!).join();
      final body = jsonDecode(json) as Map<String, dynamic>;
      final key = options.headers['Idempotency-Key'] as String;
      patches.add((key: key, body: body));
      if (offline) throw _disconnected(options);
      final replay = completed[key];
      if (replay != null) return _reply(replay);
      if (body['version'] != data['version']) {
        return _reply({
          'error': {
            'code': 'version_conflict',
            'message': 'Settings changed',
            'request_id': 'synthetic-conflict',
            'retryable': false,
            'field_errors': [],
            'retry_after_seconds': null,
          },
        }, status: 409);
      }
      data.addAll(body);
      data['version'] = (data['version'] as int) + 1;
      completed[key] = Map.of(data);
      if (loseNextResponse) {
        loseNextResponse = false;
        throw _disconnected(options);
      }
    }
    if (offline) throw _disconnected(options);
    return _reply(data);
  }

  DioException _disconnected(RequestOptions options) =>
      DioException.connectionError(requestOptions: options, reason: 'Offline');

  ResponseBody _reply(Map<String, Object?> data, {int status = 200}) =>
      ResponseBody.fromString(
        jsonEncode(data),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  @override
  void close({bool force = false}) {}
}

void main() {
  testWidgets('profile routes save, reconcile, and recover across restart', (
    tester,
  ) async {
    final keyStore = InMemorySecureKeyStore();
    final transport = _SettingsTransport();
    final dio = Dio()..httpClientAdapter = transport;
    addTearDown(dio.close);
    final repository = MemoraProfileRepository(
      MemoraApiClient(dio: dio, interceptors: const []).getProfileApi(),
      AppConfiguration.fromEnvironment(),
      (_) async => null,
    );

    Future<ProviderContainer> launch() async {
      final storage = AppLocalStorage(keyStore);
      final auth = MockAuthRepository();
      final container = ProviderContainer(
        overrides: [
          appLocalStorageProvider.overrideWithValue(storage),
          profileRepositoryProvider.overrideWithValue(repository),
          sessionControllerProvider.overrideWith(
            (ref) => SessionController(
              authRepository: auth,
              sessionRepository: MockSessionRepository(),
              localStorage: storage,
              initialState: signedIn(),
            ),
          ),
        ],
      );
      addTearDown(auth.dispose);
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MemoraApp(key: ObjectKey(container)),
        ),
      );
      await tester.pumpAndSettle();
      return container;
    }

    Future<void> tap(Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    var container = await launch();
    GoRouter router() => container.read(appRouterProvider);
    ProfileState state() => container.read(profileControllerProvider);
    router().go(AppRoutes.editProfile);
    await tester.pumpAndSettle();
    final name = find.byType(TextFormField).first;
    final save = find.text('Save changes');
    final retry = find.text('Retry');

    await tester.enterText(name, 'First draft');
    await tester.pumpAndSettle();
    await tap(find.text('Profile').last);
    expect(
      router().routerDelegate.currentConfiguration.uri.path,
      AppRoutes.editProfile,
    );
    expect(tester.widget<TextFormField>(name).controller!.text, 'First draft');
    await tap(find.byTooltip('Back to Profile'));
    expect(find.text('Discard your changes?'), findsOneWidget);
    await tap(find.text('Keep editing'));

    transport.offline = true;
    await tap(save);
    expect(retry, findsOneWidget);
    final failed = transport.patches.last;
    await tester.enterText(name, 'Revised draft');
    await tester.pumpAndSettle();
    expect(retry, findsNothing);
    transport.offline = false;
    await tap(save);
    final revised = transport.patches.last;
    expect(revised.key, isNot(failed.key));
    expect(revised.body, {'version': 1, 'display_name': 'Revised draft'});
    expect(transport.profile['display_name'], 'Revised draft');

    transport.profile['version'] = 3;
    transport.profile['locale'] = 'en-GB';
    await tester.enterText(name, 'Final draft');
    await tester.pumpAndSettle();
    await tap(save);
    expect(state().phase, ProfilePhase.conflict);
    expect(
      tester.widget<TextFormField>(name).controller!.text,
      'Revised draft',
    );
    await tap(find.text('Restore my edits'));
    await tap(save);
    expect(transport.patches.last.body, {
      'version': 3,
      'display_name': 'Final draft',
    });
    expect(state().confirmed?.profile.fields.locale, 'en-GB');

    router().go(AppRoutes.profileAccessibility);
    await tester.pumpAndSettle();
    final motion = find.widgetWithText(SwitchListTile, 'Reduced motion');
    bool applied() => MediaQuery.disableAnimationsOf(tester.element(motion));
    await tap(motion);
    expect(applied(), isTrue);
    transport.loseNextResponse = true;
    await tap(save);
    expect(applied(), isFalse);
    final lostResponse = transport.patches.last;
    await tap(retry);
    expect(transport.patches.last.key, lostResponse.key);
    expect(transport.patches.last.body, lostResponse.body);
    expect(transport.preferences['version'], 2);
    expect(applied(), isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    transport.offline = true;
    container = await launch();
    router().go(AppRoutes.profileAccessibility);
    await tester.pumpAndSettle();
    expect(state().cached, isTrue);
    expect(state().confirmed?.profile.fields.displayName, 'Final draft');
    expect(applied(), isTrue);
    expect(find.textContaining('You may be offline'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
