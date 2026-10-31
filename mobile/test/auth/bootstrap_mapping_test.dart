import 'package:built_collection/built_collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora_api_client/memora_api_client.dart';
import 'package:memora_mobile/src/configuration/app_configuration.dart';
import 'package:memora_mobile/src/features/auth/data/session_repository.dart';
import 'package:memora_mobile/src/features/auth/domain/bootstrap_state.dart';

void main() {
  group('Session Bootstrap Mapping Tests', () {
    late MemoraSessionRepository repository;

    setUp(() {
      repository = MemoraSessionRepository(
        apiClient: MemoraApiClient(),
        configuration: const AppConfiguration(
          supabaseUrl: 'https://test.supabase.co',
          supabasePublishableKey: 'test-key',
          apiBaseUrl: 'http://127.0.0.1:8000',
          oauthRedirectUri: 'com.kaveeginty.memora://login-callback',
          platform: 'android',
        ),
      );
    });

    test(
      'Maps full SessionBootstrapResponse to immutable domain BootstrapData',
      () {
        final now = DateTime.utc(2026, 10, 28, 12, 0, 0);

        final response = SessionBootstrapResponse(
          (b) => b
            ..accountStatus = AccountStatus.active
            ..profileSummary.update(
              (p) => p
                ..userId = 'usr_123'
                ..displayName = 'Amani Perera'
                ..onboardingCompleted = true
                ..activeSubjectId = 'sbj_physics'
                ..curriculumVersionId = 'cur_al_2026',
            )
            ..consentStatus = ListBuilder<ConsentStatus>([
              ConsentStatus(
                (c) => c
                  ..policyId = ConsentType.terms
                  ..policyVersion = 'v1'
                  ..isCurrent = true
                  ..required_ = true
                  ..decision = ConsentDecision.granted
                  ..decidedAt = now,
              ),
              ConsentStatus(
                (c) => c
                  ..policyId = ConsentType.privacy
                  ..policyVersion = 'v1'
                  ..isCurrent = true
                  ..required_ = true
                  ..decision = ConsentDecision.granted
                  ..decidedAt = now,
              ),
            ])
            ..subjects = ListBuilder<SubjectSummary>([
              SubjectSummary(
                (s) => s
                  ..id = 'sbj_physics'
                  ..code = 'AL-PHYS'
                  ..name = 'A/L Physics'
                  ..curriculumEditionCode = '2026-ED'
                  ..curriculumVersionId = 'cur_al_2026',
              ),
            ])
            ..activeMission.update(
              (m) => m
                ..id = 'mis_456'
                ..subjectId = 'sbj_physics'
                ..missionDate = Date(2026, 10, 28)
                ..status = ActiveMissionSummaryStatusEnum.started,
            )
            ..pendingLearningUpdates = ListBuilder<PendingResourceSummary>([
              PendingResourceSummary(
                (u) => u
                  ..id = 'upd_789'
                  ..status = 'processing'
                  ..updatedAt = now,
              ),
            ])
            ..pendingPrivacyRequests = ListBuilder<PendingResourceSummary>([])
            ..capabilityFlags.update(
              (f) => f
                ..canStartMission = true
                ..canAddLearningMaterial = true
                ..canRegisterNotifications = Optional.present(true),
            )
            ..serverTime = now,
        );

        // Invoke mapping through repository
        final mapped = repository.mapBootstrapResponse(response);

        expect(mapped.accountStatus, equals(AccountStatusDomain.active));
        expect(mapped.profileSummary.displayName, equals('Amani Perera'));
        expect(mapped.subjects.length, equals(1));
        expect(mapped.activeMission?.status, equals('started'));
        expect(mapped.pendingUpdates.first.status, equals('processing'));
        expect(mapped.capabilities.canStartMission, isTrue);
        expect(mapped.capabilities.canAddLearningMaterial, isTrue);
        expect(mapped.capabilities.canRegisterNotifications, isTrue);
      },
    );

    test(
      'Safely handles unknown AccountStatus enum fallback without throwing',
      () {
        expect(AccountStatusDomain.unknown.canAccessApp, isFalse);
        expect(AccountStatusDomain.unknown.isBlocked, isTrue);
        expect(AccountStatusDomain.suspended.isBlocked, isTrue);
        expect(AccountStatusDomain.deletionPending.isBlocked, isTrue);
        expect(AccountStatusDomain.active.canAccessApp, isTrue);
        expect(AccountStatusDomain.active.isBlocked, isFalse);
      },
    );

    test('Capability flags default safely to false when not present', () {
      const flags = CapabilityFlagsDomain();
      expect(flags.canStartMission, isFalse);
      expect(flags.canAddLearningMaterial, isFalse);
      expect(flags.canRegisterNotifications, isFalse);
    });

    test('ConsentDecisionDomain requiresAction returns true when required but not granted or outdated', () {
      const decisionPending = ConsentDecisionDomain(
        policyId: 'terms',
        policyVersion: 'v2',
        isCurrent: false,
        isRequired: true,
        decision: 'granted',
      );
      expect(decisionPending.requiresAction, isTrue);

      const decisionDeclined = ConsentDecisionDomain(
        policyId: 'terms',
        policyVersion: 'v1',
        isCurrent: true,
        isRequired: true,
        decision: 'declined',
      );
      expect(decisionDeclined.requiresAction, isTrue);

      const decisionValid = ConsentDecisionDomain(
        policyId: 'terms',
        policyVersion: 'v1',
        isCurrent: true,
        isRequired: true,
        decision: 'granted',
      );
      expect(decisionValid.requiresAction, isFalse);
    });
  });
}
