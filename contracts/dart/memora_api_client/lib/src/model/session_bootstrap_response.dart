//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:memora_api_client/src/model/account_status.dart';
import 'package:memora_api_client/src/model/active_mission_summary.dart';
import 'package:memora_api_client/src/model/capability_flags.dart';
import 'package:built_collection/built_collection.dart';
import 'package:memora_api_client/src/model/profile_summary.dart';
import 'package:memora_api_client/src/model/pending_resource_summary.dart';
import 'package:memora_api_client/src/model/subject_summary.dart';
import 'package:memora_api_client/src/model/consent_status.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'session_bootstrap_response.g.dart';

/// SessionBootstrapResponse
///
/// Properties:
/// * [accountStatus]
/// * [activeMission]
/// * [capabilityFlags]
/// * [consentStatus]
/// * [pendingLearningUpdates]
/// * [pendingPrivacyRequests]
/// * [profileSummary]
/// * [serverTime]
/// * [subjects]
@BuiltValue()
abstract class SessionBootstrapResponse
    implements
        Built<SessionBootstrapResponse, SessionBootstrapResponseBuilder> {
  @BuiltValueField(wireName: r'account_status')
  AccountStatus get accountStatus;
  // enum accountStatusEnum {  active,  suspended,  deletion_pending,  deleted,  };

  @BuiltValueField(wireName: r'active_mission')
  ActiveMissionSummary? get activeMission;

  @BuiltValueField(wireName: r'capability_flags')
  CapabilityFlags get capabilityFlags;

  @BuiltValueField(wireName: r'consent_status')
  BuiltList<ConsentStatus> get consentStatus;

  @BuiltValueField(wireName: r'pending_learning_updates')
  BuiltList<PendingResourceSummary> get pendingLearningUpdates;

  @BuiltValueField(wireName: r'pending_privacy_requests')
  BuiltList<PendingResourceSummary> get pendingPrivacyRequests;

  @BuiltValueField(wireName: r'profile_summary')
  ProfileSummary get profileSummary;

  @BuiltValueField(wireName: r'server_time')
  DateTime get serverTime;

  @BuiltValueField(wireName: r'subjects')
  BuiltList<SubjectSummary> get subjects;

  SessionBootstrapResponse._();

  factory SessionBootstrapResponse(
          [void updates(SessionBootstrapResponseBuilder b)]) =
      _$SessionBootstrapResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SessionBootstrapResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SessionBootstrapResponse> get serializer =>
      _$SessionBootstrapResponseSerializer();
}

class _$SessionBootstrapResponseSerializer
    implements PrimitiveSerializer<SessionBootstrapResponse> {
  @override
  final Iterable<Type> types = const [
    SessionBootstrapResponse,
    _$SessionBootstrapResponse
  ];

  @override
  final String wireName = r'SessionBootstrapResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SessionBootstrapResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'account_status';
    yield serializers.serialize(
      object.accountStatus,
      specifiedType: const FullType(AccountStatus),
    );
    yield r'active_mission';
    yield object.activeMission == null
        ? null
        : serializers.serialize(
            object.activeMission,
            specifiedType: const FullType.nullable(ActiveMissionSummary),
          );
    yield r'capability_flags';
    yield serializers.serialize(
      object.capabilityFlags,
      specifiedType: const FullType(CapabilityFlags),
    );
    yield r'consent_status';
    yield serializers.serialize(
      object.consentStatus,
      specifiedType: const FullType(BuiltList, [FullType(ConsentStatus)]),
    );
    yield r'pending_learning_updates';
    yield serializers.serialize(
      object.pendingLearningUpdates,
      specifiedType:
          const FullType(BuiltList, [FullType(PendingResourceSummary)]),
    );
    yield r'pending_privacy_requests';
    yield serializers.serialize(
      object.pendingPrivacyRequests,
      specifiedType:
          const FullType(BuiltList, [FullType(PendingResourceSummary)]),
    );
    yield r'profile_summary';
    yield serializers.serialize(
      object.profileSummary,
      specifiedType: const FullType(ProfileSummary),
    );
    yield r'server_time';
    yield serializers.serialize(
      object.serverTime,
      specifiedType: const FullType(DateTime),
    );
    yield r'subjects';
    yield serializers.serialize(
      object.subjects,
      specifiedType: const FullType(BuiltList, [FullType(SubjectSummary)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    SessionBootstrapResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object,
            specifiedType: specifiedType)
        .toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SessionBootstrapResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'account_status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(AccountStatus),
          ) as AccountStatus;
          result.accountStatus = valueDes;
          break;
        case r'active_mission':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(ActiveMissionSummary),
          ) as ActiveMissionSummary?;
          if (valueDes == null) continue;
          result.activeMission.replace(valueDes);
          break;
        case r'capability_flags':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(CapabilityFlags),
          ) as CapabilityFlags;
          result.capabilityFlags.replace(valueDes);
          break;
        case r'consent_status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(ConsentStatus)]),
          ) as BuiltList<ConsentStatus>;
          result.consentStatus.replace(valueDes);
          break;
        case r'pending_learning_updates':
          final valueDes = serializers.deserialize(
            value,
            specifiedType:
                const FullType(BuiltList, [FullType(PendingResourceSummary)]),
          ) as BuiltList<PendingResourceSummary>;
          result.pendingLearningUpdates.replace(valueDes);
          break;
        case r'pending_privacy_requests':
          final valueDes = serializers.deserialize(
            value,
            specifiedType:
                const FullType(BuiltList, [FullType(PendingResourceSummary)]),
          ) as BuiltList<PendingResourceSummary>;
          result.pendingPrivacyRequests.replace(valueDes);
          break;
        case r'profile_summary':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ProfileSummary),
          ) as ProfileSummary;
          result.profileSummary.replace(valueDes);
          break;
        case r'server_time':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.serverTime = valueDes;
          break;
        case r'subjects':
          final valueDes = serializers.deserialize(
            value,
            specifiedType:
                const FullType(BuiltList, [FullType(SubjectSummary)]),
          ) as BuiltList<SubjectSummary>;
          result.subjects.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SessionBootstrapResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SessionBootstrapResponseBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}
