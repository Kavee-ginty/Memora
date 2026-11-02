//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:memora_api_client/src/model/candidate_status.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'candidate_response.g.dart';

/// CandidateResponse
///
/// Properties:
/// * [candidateType]
/// * [candidateVersion]
/// * [confidence]
/// * [confidenceBand]
/// * [displaySummary]
/// * [displayTitle]
/// * [id]
/// * [requiresVerification]
/// * [sourceLocator]
/// * [status]
@BuiltValue()
abstract class CandidateResponse
    implements Built<CandidateResponse, CandidateResponseBuilder> {
  @BuiltValueField(wireName: r'candidate_type')
  String get candidateType;

  @BuiltValueField(wireName: r'candidate_version')
  int get candidateVersion;

  @BuiltValueField(wireName: r'confidence')
  num get confidence;

  @BuiltValueField(wireName: r'confidence_band')
  CandidateResponseConfidenceBandEnum get confidenceBand;
  // enum confidenceBandEnum {  high,  medium,  low,  };

  @BuiltValueField(wireName: r'display_summary')
  String get displaySummary;

  @BuiltValueField(wireName: r'display_title')
  String get displayTitle;

  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'requires_verification')
  bool get requiresVerification;

  @BuiltValueField(wireName: r'source_locator')
  BuiltMap<String, JsonObject?> get sourceLocator;

  @BuiltValueField(wireName: r'status')
  CandidateStatus get status;
  // enum statusEnum {  candidate,  needs_verification,  accepted,  rejected,  committed,  expired,  };

  CandidateResponse._();

  factory CandidateResponse([void updates(CandidateResponseBuilder b)]) =
      _$CandidateResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CandidateResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CandidateResponse> get serializer =>
      _$CandidateResponseSerializer();
}

class _$CandidateResponseSerializer
    implements PrimitiveSerializer<CandidateResponse> {
  @override
  final Iterable<Type> types = const [CandidateResponse, _$CandidateResponse];

  @override
  final String wireName = r'CandidateResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CandidateResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'candidate_type';
    yield serializers.serialize(
      object.candidateType,
      specifiedType: const FullType(String),
    );
    yield r'candidate_version';
    yield serializers.serialize(
      object.candidateVersion,
      specifiedType: const FullType(int),
    );
    yield r'confidence';
    yield serializers.serialize(
      object.confidence,
      specifiedType: const FullType(num),
    );
    yield r'confidence_band';
    yield serializers.serialize(
      object.confidenceBand,
      specifiedType: const FullType(CandidateResponseConfidenceBandEnum),
    );
    yield r'display_summary';
    yield serializers.serialize(
      object.displaySummary,
      specifiedType: const FullType(String),
    );
    yield r'display_title';
    yield serializers.serialize(
      object.displayTitle,
      specifiedType: const FullType(String),
    );
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'requires_verification';
    yield serializers.serialize(
      object.requiresVerification,
      specifiedType: const FullType(bool),
    );
    yield r'source_locator';
    yield serializers.serialize(
      object.sourceLocator,
      specifiedType: const FullType(
          BuiltMap, [FullType(String), FullType.nullable(JsonObject)]),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(CandidateStatus),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CandidateResponse object, {
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
    required CandidateResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'candidate_type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.candidateType = valueDes;
          break;
        case r'candidate_version':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.candidateVersion = valueDes;
          break;
        case r'confidence':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.confidence = valueDes;
          break;
        case r'confidence_band':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(CandidateResponseConfidenceBandEnum),
          ) as CandidateResponseConfidenceBandEnum;
          result.confidenceBand = valueDes;
          break;
        case r'display_summary':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.displaySummary = valueDes;
          break;
        case r'display_title':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.displayTitle = valueDes;
          break;
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'requires_verification':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.requiresVerification = valueDes;
          break;
        case r'source_locator':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(
                BuiltMap, [FullType(String), FullType.nullable(JsonObject)]),
          ) as BuiltMap<String, JsonObject?>;
          result.sourceLocator.replace(valueDes);
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(CandidateStatus),
          ) as CandidateStatus;
          result.status = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CandidateResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CandidateResponseBuilder();
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

class CandidateResponseConfidenceBandEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'high')
  static const CandidateResponseConfidenceBandEnum high =
      _$candidateResponseConfidenceBandEnum_high;
  @BuiltValueEnumConst(wireName: r'medium')
  static const CandidateResponseConfidenceBandEnum medium =
      _$candidateResponseConfidenceBandEnum_medium;
  @BuiltValueEnumConst(wireName: r'low')
  static const CandidateResponseConfidenceBandEnum low =
      _$candidateResponseConfidenceBandEnum_low;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const CandidateResponseConfidenceBandEnum unknownDefaultOpenApi =
      _$candidateResponseConfidenceBandEnum_unknownDefaultOpenApi;

  static Serializer<CandidateResponseConfidenceBandEnum> get serializer =>
      _$candidateResponseConfidenceBandEnumSerializer;

  const CandidateResponseConfidenceBandEnum._(String name) : super(name);

  static BuiltSet<CandidateResponseConfidenceBandEnum> get values =>
      _$candidateResponseConfidenceBandEnumValues;
  static CandidateResponseConfidenceBandEnum valueOf(String name) =>
      _$candidateResponseConfidenceBandEnumValueOf(name);
}
