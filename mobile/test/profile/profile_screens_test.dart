import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memora_mobile/src/app.dart';
import 'package:memora_mobile/src/features/auth/application/session_controller.dart';
import 'package:memora_mobile/src/features/auth/data/auth_repository.dart';
import 'package:memora_mobile/src/features/auth/data/secure_auth_storage.dart';
import 'package:memora_mobile/src/features/auth/data/session_repository.dart';
import 'package:memora_mobile/src/features/profile/application/profile_controller.dart';
import 'package:memora_mobile/src/features/profile/domain/profile_settings.dart';
import 'package:memora_mobile/src/features/profile/presentation/profile_entry_screen.dart';
import 'package:memora_mobile/src/features/profile/presentation/profile_settings_screen.dart';
import 'package:memora_mobile/src/routing/app_routes.dart';

import 'profile_fixtures.dart';

Widget profileHarness(
  Widget screen,
  FakeProfileRepository repository, {
  double scale = 1,
}) {
  final storage = AppLocalStorage(InMemorySecureKeyStore());
  return ProviderScope(
    overrides: [
      appLocalStorageProvider.overrideWithValue(storage),
      profileRepositoryProvider.overrideWithValue(repository),
      sessionControllerProvider.overrideWith(
        (ref) => SessionController(
          authRepository: MockAuthRepository(),
          sessionRepository: MockSessionRepository(),
          localStorage: storage,
          initialState: signedIn(),
        ),
      ),
    ],
    child: MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: screen,
    ),
  );
}

void main() {
  testWidgets(
    'Profile shows the authorized subject, settings, and Privacy entry',
    (tester) async {
      await tester.pumpWidget(
        profileHarness(const ProfileEntryScreen(), FakeProfileRepository()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Amani Perera'), findsOneWidget);
      expect(find.text('A/L Physics'), findsOneWidget);
      expect(find.text('Edit profile'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Privacy'), findsOneWidget);
      expect(find.textContaining('Streak:'), findsNothing);
      expect(find.textContaining('XP'), findsNothing);
    },
  );

  for (final section in SettingsSection.values) {
    testWidgets('${section.name} is usable at 320 px and 200 percent text', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        profileHarness(
          ProfileSettingsScreen(section),
          FakeProfileRepository(),
          scale: 2,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Back to Profile'), findsOneWidget);
      final save = find.text('Save changes');
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      expect(save.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }

  testWidgets(
    'edit validation is announced and keyboard traversal reaches fields',
    (tester) async {
      final repository = FakeProfileRepository();
      await tester.pumpWidget(
        profileHarness(
          const ProfileSettingsScreen(SettingsSection.profile),
          repository,
        ),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final name = find.byType(TextFormField).first;
      final nameInput = find.descendant(
        of: name,
        matching: find.byType(EditableText),
      );
      expect(tester.widget<EditableText>(nameInput).focusNode.hasFocus, isTrue);
      await tester.enterText(name, ' ');
      await tester.pump();
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();
      expect(find.text('Check the highlighted fields.'), findsOneWidget);
      expect(repository.keys, isEmpty);
      await tester.enterText(name, 'New Name');
      await tester.pump();
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();
      expect(find.text('Settings saved.'), findsOneWidget);
      expect(repository.data.profile.fields.displayName, 'New Name');
    },
  );

  testWidgets('quiet hours require both endpoints and can be cleared', (
    tester,
  ) async {
    final repository = FakeProfileRepository();
    await tester.pumpWidget(
      profileHarness(
        const ProfileSettingsScreen(SettingsSection.notifications),
        repository,
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Preferred reminder window'));
    await tester.tap(find.text('Preferred reminder window'));
    await tester.pumpAndSettle();
    final inputs = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(inputs.first, '18:00');
    await tester.tap(find.text('Set window'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.enterText(inputs.last, '20:00');
    await tester.tap(find.text('Set window'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    final clear = find.text('Clear quiet hours');
    await tester.ensureVisible(clear);
    await tester.tap(clear);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(repository.data.preferences.fields.notifications.quiet, isNull);
    expect(repository.data.preferences.fields.notifications.preferred, (
      start: '18:00',
      end: '20:00',
    ));
    expect(repository.data.preferences.fields.notifications.enabled, isFalse);
  });

  testWidgets(
    'conflict shows confirmed profile and offers to restore only edited fields',
    (tester) async {
      final repository = FakeProfileRepository();
      await tester.pumpWidget(
        profileHarness(
          const ProfileSettingsScreen(SettingsSection.profile),
          repository,
        ),
      );
      await tester.pumpAndSettle();
      final inputs = find.byType(TextFormField);
      await tester.enterText(inputs.first, 'My new display name');
      await tester.pump();
      repository.data = (
        profile: (
          fields: (
            displayName: 'Amani Perera',
            locale: 'si-LK',
            timezone: 'Asia/Colombo',
          ),
          version: 2,
        ),
        preferences: confirmedSettings.preferences,
      );
      repository.saveFailure = const ProfileFailure(
        'version_conflict',
        'Changed',
      );
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();
      expect(find.textContaining('changed elsewhere'), findsOneWidget);
      expect(find.text('si-LK'), findsOneWidget);
      expect(find.text('Amani Perera'), findsOneWidget);
      await tester.tap(find.text('Restore my edits'));
      await tester.pumpAndSettle();
      expect(find.text('My new display name'), findsOneWidget);
      expect(find.text('si-LK'), findsOneWidget);
      repository.saveFailure = null;
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();
      expect(repository.data.profile.fields.displayName, 'My new display name');
      expect(repository.data.profile.fields.locale, 'si-LK');
      expect(repository.keys.toSet(), hasLength(2));
    },
  );

  testWidgets(
    'reduced motion applies immediately and rolls back after offline save',
    (tester) async {
      final repository = FakeProfileRepository()
        ..saveFailure = const ProfileFailure(
          'network_error',
          'Offline',
          retryable: true,
        );
      final router = GoRouter(
        initialLocation: AppRoutes.profileAccessibility,
        routes: [
          GoRoute(
            path: AppRoutes.profileAccessibility,
            builder: (_, _) =>
                const ProfileSettingsScreen(SettingsSection.accessibility),
          ),
        ],
      );
      addTearDown(router.dispose);
      final storage = AppLocalStorage(InMemorySecureKeyStore());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appLocalStorageProvider.overrideWithValue(storage),
            profileRepositoryProvider.overrideWithValue(repository),
            sessionControllerProvider.overrideWith(
              (ref) => SessionController(
                authRepository: MockAuthRepository(),
                sessionRepository: MockSessionRepository(),
                localStorage: storage,
                initialState: signedIn(),
              ),
            ),
          ],
          child: MemoraApp(router: router),
        ),
      );
      await tester.pumpAndSettle();
      final reducedMotion = find.widgetWithText(
        SwitchListTile,
        'Reduced motion',
      );
      final semantics = tester.ensureSemantics();
      await tester.pump();
      final switchLabel = find.bySemanticsLabel('Reduced motion');
      expect(switchLabel, findsOneWidget);
      final off = tester.getSemantics(switchLabel).getSemanticsData();
      expect(off.flagsCollection.isToggled, Tristate.isFalse);
      expect(off.hasAction(SemanticsAction.tap), isTrue);
      bool motionDisabled() =>
          MediaQuery.disableAnimationsOf(tester.element(reducedMotion));
      expect(motionDisabled(), isFalse);
      await tester.tap(reducedMotion);
      await tester.pumpAndSettle();
      expect(motionDisabled(), isTrue);
      await tester.ensureVisible(find.text('Save changes'));
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();
      expect(motionDisabled(), isFalse);
      expect(tester.widget<SwitchListTile>(reducedMotion).value, isFalse);
      expect(find.textContaining('You may be offline'), findsOneWidget);
      repository.saveFailure = null;
      await tester.ensureVisible(find.text('Retry'));
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(motionDisabled(), isTrue);
      expect(repository.keys.toSet(), hasLength(1));
      final on = tester.getSemantics(switchLabel).getSemanticsData();
      expect(on.flagsCollection.isToggled, Tristate.isTrue);
      expect(on.hasAction(SemanticsAction.tap), isTrue);
      semantics.dispose();
    },
  );
}
