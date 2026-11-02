import 'package:flutter_test/flutter_test.dart';
import 'package:memora_mobile/src/features/auth/application/session_controller.dart';
import 'package:memora_mobile/src/features/auth/data/auth_repository.dart';
import 'package:memora_mobile/src/features/auth/data/secure_auth_storage.dart';
import 'package:memora_mobile/src/features/auth/data/session_repository.dart';
import 'package:memora_mobile/src/features/auth/domain/app_session_state.dart';
import 'package:memora_mobile/src/features/auth/domain/bootstrap_state.dart';
import 'package:memora_mobile/src/features/auth/domain/route_access.dart';
import 'package:memora_mobile/src/features/consent/application/consent_controller.dart';
import 'package:memora_mobile/src/features/consent/data/consent_repository.dart';
import 'package:memora_mobile/src/features/consent/domain/consent_policy.dart';
import 'package:memora_mobile/src/features/consent/domain/consent_state.dart';

ConsentPolicy termsPolicy({
  String version = '2026-10-01',
  bool isCurrent = false,
}) {
  return ConsentPolicy(
    kind: ConsentPolicyKind.terms,
    wireId: 'terms',
    version: version,
    isRequired: true,
    isCurrent: isCurrent,
  );
}

ConsentPolicy privacyPolicy({bool isRequired = true, bool isCurrent = false}) {
  return ConsentPolicy(
    kind: ConsentPolicyKind.privacy,
    wireId: 'privacy',
    version: '2026-09-15',
    isRequired: isRequired,
    isCurrent: isCurrent,
  );
}

ConsentPolicy unknownPolicy() {
  return const ConsentPolicy(
    kind: ConsentPolicyKind.unknown,
    wireId: 'future_policy',
    version: '2027-01-01',
    isRequired: true,
    isCurrent: false,
  );
}

BootstrapData bootstrap({bool requiresReview = false}) {
  return BootstrapData(
    accountStatus: AccountStatusDomain.active,
    profileSummary: const ProfileSummaryDomain(
      userId: 'usr_1',
      displayName: 'Amani Perera',
    ),
    consentStatus: ConsentStatusDomain(requiresReview: requiresReview),
    subjects: const <SubjectSummaryDomain>[],
    capabilities: const CapabilityFlagsDomain(),
    serverTime: DateTime.utc(2026, 10, 28),
  );
}

/// Consent repository that can fail once per policy and mutate policy versions
/// to exercise retry, partial success and version conflicts.
class ScriptedConsentRepository implements ConsentRepository {
  ScriptedConsentRepository({List<ConsentPolicy>? policies})
    : policies = policies ?? <ConsentPolicy>[];

  List<ConsentPolicy> policies;
  final Map<String, AuthFailure> failuresByWireId = <String, AuthFailure>{};
  final List<ConsentAcceptCall> acceptCalls = <ConsentAcceptCall>[];
  final Set<String> acceptedWireIds = <String>{};
  AuthFailure? fetchFailure;
  int fetchCallCount = 0;

  /// Called before an acceptance is recorded, allowing version changes.
  void Function(ConsentPolicy policy)? onAccept;

  @override
  Future<List<ConsentPolicy>> fetchConsent({
    required String accessToken,
  }) async {
    fetchCallCount++;
    if (fetchFailure != null) {
      throw fetchFailure!;
    }
    return policies
        .where((policy) => !acceptedWireIds.contains(policy.wireId))
        .toList(growable: false);
  }

  @override
  Future<void> acceptConsent({
    required String accessToken,
    required ConsentPolicyKind kind,
    required String wireId,
    required String policyVersion,
    required String idempotencyKey,
  }) async {
    acceptCalls.add(
      ConsentAcceptCall(
        wireId: wireId,
        policyVersion: policyVersion,
        idempotencyKey: idempotencyKey,
      ),
    );
    onAccept?.call(policies.firstWhere((policy) => policy.wireId == wireId));
    final failure = failuresByWireId.remove(wireId);
    if (failure != null) {
      throw failure;
    }
    acceptedWireIds.add(wireId);
  }
}

void main() {
  group('ConsentController', () {
    late MockAuthRepository authRepository;
    late MockSessionRepository sessionRepository;
    late SessionController sessionController;
    late ScriptedConsentRepository repository;

    const session = AuthSession(accessToken: 'token', userId: 'usr_1');

    SessionController buildSessionController({
      AppSessionState? initialState,
      bool requiresReview = false,
    }) {
      sessionRepository = MockSessionRepository(
        configuredBootstrap: bootstrap(requiresReview: requiresReview),
      );
      return SessionController(
        authRepository: authRepository,
        sessionRepository: sessionRepository,
        localStorage: AppLocalStorage(InMemorySecureKeyStore()),
        initialState:
            initialState ??
            AppSessionState.active(
              session: session,
              bootstrapData: bootstrap(requiresReview: true),
            ),
      );
    }

    ConsentController buildController() {
      return ConsentController(
        repository: repository,
        sessionController: sessionController,
      );
    }

    setUp(() {
      authRepository = MockAuthRepository(initialSession: session);
      repository = ScriptedConsentRepository();
      sessionController = buildSessionController();
    });

    tearDown(() {
      sessionController.dispose();
    });

    test('load exposes only policies that require action', () async {
      repository.policies = <ConsentPolicy>[
        termsPolicy(),
        privacyPolicy(isRequired: false, isCurrent: true),
      ];
      final controller = buildController();
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.state.phase, ConsentPhase.ready);
      expect(controller.state.policies, hasLength(2));
      expect(controller.state.requiredPolicies, hasLength(1));
      expect(controller.state.requiredPolicies.single.wireId, 'terms');
      expect(controller.state.selectedWireIds, isEmpty);
      expect(controller.state.notice, isNull);
    });

    test('toggle only selects known required policies', () async {
      repository.policies = <ConsentPolicy>[
        termsPolicy(),
        privacyPolicy(isRequired: false, isCurrent: true),
      ];
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.load();

      controller.toggle('privacy');
      expect(controller.state.isSelected('privacy'), isFalse);

      controller.toggle('terms');
      expect(controller.state.isSelected('terms'), isTrue);
      expect(controller.state.canSubmit, isTrue);

      controller.toggle('terms');
      expect(controller.state.isSelected('terms'), isFalse);
      expect(controller.state.canSubmit, isFalse);
    });

    test(
      'submit does nothing until every required policy is selected',
      () async {
        repository.policies = <ConsentPolicy>[termsPolicy(), privacyPolicy()];
        final controller = buildController();
        addTearDown(controller.dispose);
        await controller.load();

        controller.toggle('terms');
        await controller.submit();

        expect(repository.acceptCalls, isEmpty);
        expect(controller.state.phase, ConsentPhase.ready);
      },
    );

    test('successful submit records every policy then completes', () async {
      repository.policies = <ConsentPolicy>[termsPolicy(), privacyPolicy()];
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.load();

      controller.toggle('terms');
      controller.toggle('privacy');
      await controller.submit();

      expect(repository.acceptCalls, hasLength(2));
      expect(repository.acceptCalls.map((call) => call.wireId), <String>[
        'terms',
        'privacy',
      ]);
      expect(repository.acceptCalls.map((call) => call.policyVersion), <String>[
        '2026-10-01',
        '2026-09-15',
      ]);
      expect(
        repository.acceptCalls.map((call) => call.idempotencyKey).toSet(),
        hasLength(2),
      );
      expect(sessionRepository.bootstrapCallCount, 1);
      expect(controller.state.phase, ConsentPhase.completed);
      expect(controller.state.selectedWireIds, isEmpty);
    });

    test(
      'retry after a transport failure reuses the same idempotency key',
      () async {
        repository.policies = <ConsentPolicy>[termsPolicy()];
        repository.failuresByWireId['terms'] = AuthFailure.networkError();
        final controller = buildController();
        addTearDown(controller.dispose);
        await controller.load();

        controller.toggle('terms');
        await controller.submit();

        expect(controller.state.phase, ConsentPhase.ready);
        expect(repository.acceptCalls, hasLength(1));

        controller.toggle('terms');
        await controller.submit();

        expect(repository.acceptCalls, hasLength(2));
        expect(
          repository.acceptCalls[0].idempotencyKey,
          repository.acceptCalls[1].idempotencyKey,
        );
        expect(controller.state.phase, ConsentPhase.completed);
      },
    );

    test('partial success only retries the policy that failed', () async {
      repository.policies = <ConsentPolicy>[termsPolicy(), privacyPolicy()];
      repository.failuresByWireId['privacy'] = AuthFailure.networkError();
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.load();

      controller.toggle('terms');
      controller.toggle('privacy');
      await controller.submit();

      expect(repository.acceptCalls.map((call) => call.wireId), <String>[
        'terms',
        'privacy',
      ]);
      expect(controller.state.phase, ConsentPhase.ready);
      expect(controller.state.requiredPolicies, hasLength(1));
      expect(controller.state.requiredPolicies.single.wireId, 'privacy');

      controller.toggle('privacy');
      await controller.submit();

      expect(repository.acceptCalls.map((call) => call.wireId), <String>[
        'terms',
        'privacy',
        'privacy',
      ]);
      expect(
        repository.acceptCalls[1].idempotencyKey,
        repository.acceptCalls[2].idempotencyKey,
      );
      expect(controller.state.phase, ConsentPhase.completed);
    });

    test(
      'version conflict reloads the new version and clears acceptance',
      () async {
        repository.policies = <ConsentPolicy>[termsPolicy()];
        repository.failuresByWireId['terms'] = const AuthFailure(
          code: 'version_conflict',
          message: 'This information has changed. Please review it again.',
        );
        repository.onAccept = (policy) {
          repository.policies = <ConsentPolicy>[
            termsPolicy(version: '2026-10-20'),
          ];
        };
        final controller = buildController();
        addTearDown(controller.dispose);
        await controller.load();

        controller.toggle('terms');
        await controller.submit();

        expect(controller.state.phase, ConsentPhase.ready);
        expect(controller.state.notice, contains('changed'));
        expect(controller.state.selectedWireIds, isEmpty);
        expect(controller.state.requiredPolicies.single.version, '2026-10-20');

        controller.toggle('terms');
        await controller.submit();

        expect(repository.acceptCalls, hasLength(2));
        expect(repository.acceptCalls[0].policyVersion, '2026-10-01');
        expect(repository.acceptCalls[1].policyVersion, '2026-10-20');
        expect(
          repository.acceptCalls[0].idempotencyKey,
          isNot(repository.acceptCalls[1].idempotencyKey),
        );
      },
    );

    test('unknown required policies fail closed', () async {
      repository.policies = <ConsentPolicy>[unknownPolicy()];
      final controller = buildController();
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.state.phase, ConsentPhase.blocked);
      expect(controller.state.hasUnknownRequired, isTrue);

      controller.toggle('future_policy');
      expect(controller.state.selectedWireIds, isEmpty);

      await controller.submit();
      expect(controller.state.phase, ConsentPhase.blocked);
      expect(repository.acceptCalls, isEmpty);
    });

    test('fetch failure is retryable and a retry can succeed', () async {
      repository.fetchFailure = AuthFailure.networkError();
      final controller = buildController();
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.state.phase, ConsentPhase.error);
      expect(controller.state.retryable, isTrue);
      expect(controller.state.errorMessage, isNotNull);

      repository.fetchFailure = null;
      repository.policies = <ConsentPolicy>[termsPolicy()];
      await controller.load();

      expect(controller.state.phase, ConsentPhase.ready);
      expect(controller.state.policies, hasLength(1));
    });

    test('expired session during acceptance clears the session once', () async {
      repository.policies = <ConsentPolicy>[termsPolicy()];
      repository.failuresByWireId['terms'] = AuthFailure.expiredSession();
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.load();

      sessionController.setSafeReturnLocation(
        SafeReturnLocation.parse('/learning'),
      );
      controller.toggle('terms');
      await controller.submit();

      expect(sessionController.state.phase, AppSessionPhase.signedOut);
      expect(sessionController.state.failure?.code, 'expired_session');
      expect(sessionController.pendingReturnLocation, isNull);
      expect(authRepository.signOutCallCount, 1);
      expect(controller.state.phase, isNot(ConsentPhase.completed));
    });

    test('missing session cannot submit', () async {
      sessionController.dispose();
      sessionController = buildSessionController(
        initialState: const AppSessionState.signedOut(),
      );
      final controller = buildController();
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.state.phase, ConsentPhase.error);
      expect(controller.state.retryable, isFalse);
      expect(repository.fetchCallCount, 0);
    });

    test(
      'bootstrap that still requires review reloads instead of completing',
      () async {
        repository.policies = <ConsentPolicy>[termsPolicy()];
        sessionController.dispose();
        sessionController = buildSessionController(requiresReview: true);
        final controller = buildController();
        addTearDown(controller.dispose);
        await controller.load();

        controller.toggle('terms');
        await controller.submit();

        expect(controller.state.phase, ConsentPhase.ready);
        expect(controller.state.notice, 'Additional policies require review.');
        expect(sessionRepository.bootstrapCallCount, 1);
      },
    );
  });
}
