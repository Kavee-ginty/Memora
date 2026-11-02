import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/features/auth/application/session_controller.dart';
import 'package:memora_mobile/src/features/auth/data/auth_repository.dart';
import 'package:memora_mobile/src/features/auth/data/secure_auth_storage.dart';
import 'package:memora_mobile/src/features/auth/data/session_repository.dart';
import 'package:memora_mobile/src/features/auth/domain/app_session_state.dart';
import 'package:memora_mobile/src/features/auth/domain/bootstrap_state.dart';
import 'package:memora_mobile/src/features/home/presentation/home_screen.dart';

void main() {
  group('HomeScreen Bootstrap Presentation Tests', () {
    late MockAuthRepository mockAuth;
    late MockSessionRepository mockSession;
    late InMemorySecureKeyStore keyStore;
    late AppLocalStorage localStorage;

    setUp(() {
      keyStore = InMemorySecureKeyStore();
      localStorage = AppLocalStorage(keyStore);
      mockAuth = MockAuthRepository();
      mockSession = MockSessionRepository();
    });

    Widget createTestWidget({required BootstrapData bootstrap}) {
      return ProviderScope(
        overrides: [
          sessionControllerProvider.overrideWith(
            (ref) => SessionController(
              authRepository: mockAuth,
              sessionRepository: mockSession,
              localStorage: localStorage,
              initialState: AppSessionState.active(
                session: const AuthSession(
                  accessToken: 'active_token',
                  userId: 'usr_1',
                  email: 'student@memora.internal',
                ),
                bootstrapData: bootstrap,
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      );
    }

    testWidgets('Renders setup card when no subjects or learning path exist', (
      tester,
    ) async {
      final bootstrap = BootstrapData(
        accountStatus: AccountStatusDomain.active,
        profileSummary: const ProfileSummaryDomain(
          userId: 'usr_1',
          displayName: 'Dilum Perera',
          streakDays: 3,
        ),
        consentStatus: const ConsentStatusDomain(requiresReview: false),
        subjects: const [],
        capabilities: const CapabilityFlagsDomain(canAddLearningMaterial: true),
        serverTime: DateTime.now(),
      );

      await tester.pumpWidget(createTestWidget(bootstrap: bootstrap));

      expect(find.text('Ready to start learning'), findsOneWidget);
      expect(
        find.text(
          'No learning material yet. Add notes or a PDF to build your first Physics learning path.',
        ),
        findsOneWidget,
      );
      expect(find.text('Add Learning Material'), findsOneWidget);
      // Confirms streak from profile is displayed in header
      expect(find.text('3 days'), findsOneWidget);
    });

    testWidgets(
      'Renders active mission presence without inventing unearned rewards',
      (tester) async {
        final bootstrap = BootstrapData(
          accountStatus: AccountStatusDomain.active,
          profileSummary: const ProfileSummaryDomain(
            userId: 'usr_1',
            displayName: 'Dilum Perera',
            streakDays: 14,
          ),
          consentStatus: const ConsentStatusDomain(requiresReview: false),
          subjects: const [
            SubjectSummaryDomain(
              id: 'sbj_phys',
              code: 'AL-PHYS',
              name: 'A/L Physics',
              curriculumEditionCode: '2026',
              curriculumVersionId: 'cur_1',
            ),
          ],
          activeMission: const ActiveMissionSummaryDomain(
            id: 'mis_daily_1',
            subjectId: 'sbj_phys',
            missionDate: '2026-10-28',
            status: 'started',
          ),
          capabilities: const CapabilityFlagsDomain(canStartMission: true),
          serverTime: DateTime.now(),
        );

        await tester.pumpWidget(createTestWidget(bootstrap: bootstrap));

        expect(find.text('Daily Mission in Progress'), findsOneWidget);
        expect(find.text('Continue Daily Mission'), findsOneWidget);
        expect(find.text('Your subjects'), findsOneWidget);
        expect(find.text('A/L Physics'), findsOneWidget);
        expect(find.text('14 days'), findsOneWidget);
      },
    );

    testWidgets(
      'Renders pending updates indicator when background operations exist',
      (tester) async {
        final bootstrap = BootstrapData(
          accountStatus: AccountStatusDomain.active,
          profileSummary: const ProfileSummaryDomain(
            userId: 'usr_1',
            displayName: 'Dilum Perera',
            streakDays: 0,
          ),
          consentStatus: const ConsentStatusDomain(requiresReview: false),
          subjects: const [],
          pendingUpdates: [
            PendingResourceSummaryDomain(
              id: 'upd_1',
              status: 'processing',
              updatedAt: DateTime.now(),
            ),
          ],
          capabilities: const CapabilityFlagsDomain(),
          serverTime: DateTime.now(),
        );

        await tester.pumpWidget(createTestWidget(bootstrap: bootstrap));

        expect(
          find.text('1 learning update(s) currently processing.'),
          findsOneWidget,
        );
      },
    );
  });
}
