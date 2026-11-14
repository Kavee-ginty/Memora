import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/features/auth/application/session_controller.dart';
import 'package:memora_mobile/src/features/auth/data/auth_repository.dart';
import 'package:memora_mobile/src/features/auth/data/secure_auth_storage.dart';
import 'package:memora_mobile/src/features/auth/data/session_repository.dart';
import 'package:memora_mobile/src/features/auth/domain/app_session_state.dart';
import 'package:memora_mobile/src/features/auth/domain/bootstrap_state.dart';
import 'package:memora_mobile/src/features/profile/presentation/profile_entry_screen.dart';

void main() {
  group('ProfileEntryScreen and Safe Sign Out Tests', () {
    late MockAuthRepository mockAuth;
    late MockSessionRepository mockSession;
    late InMemorySecureKeyStore keyStore;
    late AppLocalStorage localStorage;
    late SessionController controller;

    setUp(() {
      keyStore = InMemorySecureKeyStore();
      localStorage = AppLocalStorage(keyStore);
      mockAuth = MockAuthRepository();
      mockSession = MockSessionRepository();
    });

    Widget createTestWidget({required BootstrapData bootstrap}) {
      controller = SessionController(
        authRepository: mockAuth,
        sessionRepository: mockSession,
        localStorage: localStorage,
        initialState: AppSessionState.active(
          session: const AuthSession(
            accessToken: 'active_token',
            userId: 'usr_p1',
            email: 'profile_user@memora.lk',
          ),
          bootstrapData: bootstrap,
        ),
      );

      return ProviderScope(
        overrides: [
          sessionControllerProvider.overrideWith((ref) => controller),
        ],
        child: const MaterialApp(home: ProfileEntryScreen()),
      );
    }

    testWidgets('Renders profile summary and initial letter avatar', (
      tester,
    ) async {
      final bootstrap = BootstrapData(
        accountStatus: AccountStatusDomain.active,
        profileSummary: const ProfileSummaryDomain(
          userId: 'usr_p1',
          displayName: 'Kavindi Fernando',
          email: 'kavindi@memora.lk',
          streakDays: 12,
        ),
        consentStatus: const ConsentStatusDomain(requiresReview: false),
        subjects: const [],
        capabilities: const CapabilityFlagsDomain(),
        serverTime: DateTime.now(),
      );

      await tester.pumpWidget(createTestWidget(bootstrap: bootstrap));

      expect(find.text('Kavindi Fernando'), findsOneWidget);
      expect(find.text('K'), findsOneWidget);
      expect(find.text('kavindi@memora.lk'), findsOneWidget);
      expect(find.text('Streak: 12 days'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
    });

    testWidgets(
      'Sign out button opens confirmation dialog and confirms sign out',
      (tester) async {
        final bootstrap = BootstrapData(
          accountStatus: AccountStatusDomain.active,
          profileSummary: const ProfileSummaryDomain(
            userId: 'usr_p1',
            displayName: 'Kavindi Fernando',
            email: 'kavindi@memora.lk',
          ),
          consentStatus: const ConsentStatusDomain(requiresReview: false),
          subjects: const [],
          capabilities: const CapabilityFlagsDomain(),
          serverTime: DateTime.now(),
        );

        await tester.pumpWidget(createTestWidget(bootstrap: bootstrap));

        final signOut = find.text('Sign Out');
        await tester.ensureVisible(signOut);
        await tester.tap(signOut);
        await tester.pumpAndSettle();

        expect(
          find.text('Are you sure you want to sign out of Memora?'),
          findsOneWidget,
        );
        expect(find.text('Cancel'), findsOneWidget);

        // Confirm sign out in dialog
        final confirmButtons = find.widgetWithText(ElevatedButton, 'Sign Out');
        if (confirmButtons.evaluate().isNotEmpty) {
          await tester.tap(confirmButtons.first);
        } else {
          await tester.tap(find.text('Sign Out').last);
        }
        await tester.pumpAndSettle();

        expect(controller.state.phase, equals(AppSessionPhase.signedOut));
      },
    );

    testWidgets('Warns about uncommitted pending work when signing out', (
      tester,
    ) async {
      final bootstrap = BootstrapData(
        accountStatus: AccountStatusDomain.active,
        profileSummary: const ProfileSummaryDomain(
          userId: 'usr_p1',
          displayName: 'Kavindi Fernando',
          email: 'kavindi@memora.lk',
        ),
        consentStatus: const ConsentStatusDomain(requiresReview: false),
        subjects: const [],
        pendingUpdates: [
          PendingResourceSummaryDomain(
            id: 'upd_1',
            status: 'uploading',
            updatedAt: DateTime.now(),
          ),
        ],
        capabilities: const CapabilityFlagsDomain(),
        serverTime: DateTime.now(),
      );

      await tester.pumpWidget(createTestWidget(bootstrap: bootstrap));

      final signOut = find.text('Sign Out');
      await tester.ensureVisible(signOut);
      await tester.tap(signOut);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'You have uncommitted or pending operations that will be discarded upon sign-out. Are you sure you wish to sign out?',
        ),
        findsOneWidget,
      );
    });
  });
}
