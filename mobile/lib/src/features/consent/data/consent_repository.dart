import 'package:dio/dio.dart';
import 'package:memora_api_client/memora_api_client.dart';

import '../../../configuration/app_configuration.dart';
import '../../auth/data/api_error_mapper.dart';
import '../../auth/domain/app_session_state.dart';
import '../../common/ids.dart';
import '../domain/consent_policy.dart';

/// Contract for reading and accepting server-derived consent policies.
abstract class ConsentRepository {
  /// Fetches every configured policy and the current user's latest decision.
  Future<List<ConsentPolicy>> fetchConsent({required String accessToken});

  /// Records one acceptance for [wireId] and [policyVersion].
  ///
  /// [idempotencyKey] must remain stable while the same acceptance is
  /// unresolved so retries converge on one server result.
  Future<void> acceptConsent({
    required String accessToken,
    required ConsentPolicyKind kind,
    required String wireId,
    required String policyVersion,
    required String idempotencyKey,
  });
}

/// Generated client implementation of [ConsentRepository].
class MemoraConsentRepository implements ConsentRepository {
  const MemoraConsentRepository({
    required this.apiClient,
    required this.configuration,
  });

  final MemoraApiClient apiClient;
  final AppConfiguration configuration;

  @override
  Future<List<ConsentPolicy>> fetchConsent({
    required String accessToken,
  }) async {
    try {
      apiClient.setBearerAuth('bearerAuth', accessToken);
      final response = await apiClient.getProfileApi().getConsent(
        xCorrelationID: generateUuid(),
        xClientVersion: configuration.clientVersion,
        xPlatform: configuration.platform,
      );

      final data = response.data;
      if (data == null) {
        throw AuthFailure.unknown();
      }

      return data.policies.map(_mapPolicy).toList(growable: false);
    } on DioException catch (error) {
      throw mapDioExceptionToFailure(error);
    } catch (error) {
      if (error is AuthFailure) rethrow;
      throw AuthFailure.unknown();
    }
  }

  @override
  Future<void> acceptConsent({
    required String accessToken,
    required ConsentPolicyKind kind,
    required String wireId,
    required String policyVersion,
    required String idempotencyKey,
  }) async {
    if (!kind.isKnown) {
      // Unknown policies must never be accepted.
      throw AuthFailure.unknown();
    }

    try {
      apiClient.setBearerAuth('bearerAuth', accessToken);
      final request = ConsentAcceptanceRequest((builder) {
        builder
          ..policyId = _toGenerated(kind)
          ..policyVersion = policyVersion;
        builder.acceptedScopes.add(wireId);
      });

      await apiClient.getProfileApi().acceptConsent(
        xCorrelationID: generateUuid(),
        xClientVersion: configuration.clientVersion,
        xPlatform: configuration.platform,
        idempotencyKey: idempotencyKey,
        consentAcceptanceRequest: request,
      );
    } on DioException catch (error) {
      throw mapDioExceptionToFailure(error);
    } catch (error) {
      if (error is AuthFailure) rethrow;
      throw AuthFailure.unknown();
    }
  }

  ConsentPolicy _mapPolicy(ConsentStatus status) {
    final wireIdValue = standardSerializers.serializeWith(
      ConsentType.serializer,
      status.policyId,
    );
    final wireId = wireIdValue is String ? wireIdValue : '';
    final decisionValue = status.decision == null
        ? null
        : standardSerializers.serializeWith(
            ConsentDecision.serializer,
            status.decision!,
          );
    final decision = decisionValue is String ? decisionValue : null;

    return ConsentPolicy(
      kind: ConsentPolicyKind.fromWireId(wireId),
      wireId: wireId,
      version: status.policyVersion,
      isRequired: status.required_,
      isCurrent: status.isCurrent,
      decision: decision,
      decidedAt: status.decidedAt,
    );
  }

  ConsentType _toGenerated(ConsentPolicyKind kind) {
    switch (kind) {
      case ConsentPolicyKind.terms:
        return ConsentType.terms;
      case ConsentPolicyKind.privacy:
        return ConsentType.privacy;
      case ConsentPolicyKind.materialProcessing:
        return ConsentType.materialProcessing;
      case ConsentPolicyKind.modelProcessing:
        return ConsentType.modelProcessing;
      case ConsentPolicyKind.notifications:
        return ConsentType.notifications;
      case ConsentPolicyKind.unknown:
        throw StateError('Unknown consent policies cannot be accepted.');
    }
  }
}

/// Deterministic in-memory repository used by tests and the local baseline.
class MockConsentRepository implements ConsentRepository {
  MockConsentRepository({List<ConsentPolicy>? policies})
    : policies = policies ?? const <ConsentPolicy>[];

  List<ConsentPolicy> policies;
  AuthFailure? fetchFailure;
  AuthFailure? acceptFailure;
  int fetchCallCount = 0;
  final List<ConsentAcceptCall> acceptCalls = <ConsentAcceptCall>[];
  final Set<String> acceptedWireIds = <String>{};

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
    if (acceptFailure != null) {
      throw acceptFailure!;
    }
    acceptedWireIds.add(wireId);
  }
}

/// One recorded acceptance request for assertions.
class ConsentAcceptCall {
  const ConsentAcceptCall({
    required this.wireId,
    required this.policyVersion,
    required this.idempotencyKey,
  });

  final String wireId;
  final String policyVersion;
  final String idempotencyKey;
}
