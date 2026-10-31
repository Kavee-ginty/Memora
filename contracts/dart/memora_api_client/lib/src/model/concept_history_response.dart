//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:memora_api_client/src/model/scheduling_explanation.dart';
import 'package:built_collection/built_collection.dart';
import 'package:memora_api_client/src/model/evidence_summary.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'concept_history_response.g.dart';

/// Concept state, bounded evidence summary and paginated explanations.
///
/// Properties:
/// * [conceptId] 
/// * [conceptVersionId] 
/// * [evidence] 
/// * [hasMore] 
/// * [items] 
/// * [nextCursor] 
/// * [nextReviewAt] 
/// * [stableCode] 
/// * [stateBand] 
/// * [title] 
@BuiltValue()
abstract class ConceptHistoryResponse implements Built<ConceptHistoryResponse, ConceptHistoryResponseBuilder> {
  @BuiltValueField(wireName: r'concept_id')
  String get conceptId;

  @BuiltValueField(wireName: r'concept_version_id')
  String get conceptVersionId;

  @BuiltValueField(wireName: r'evidence')
  EvidenceSummary get evidence;

  @BuiltValueField(wireName: r'has_more')
  bool get hasMore;

  @BuiltValueField(wireName: r'items')
  BuiltList<SchedulingExplanation> get items;

  @BuiltValueField(wireName: r'next_cursor')
  String? get nextCursor;

  @BuiltValueField(wireName: r'next_review_at')
  String get nextReviewAt;

  @BuiltValueField(wireName: r'stable_code')
  String get stableCode;

  @BuiltValueField(wireName: r'state_band')
  ConceptHistoryResponseStateBandEnum get stateBand;
  // enum stateBandEnum {  fresh,  settling,  fading,  critical,  };

  @BuiltValueField(wireName: r'title')
  String get title;

  ConceptHistoryResponse._();

  factory ConceptHistoryResponse([void updates(ConceptHistoryResponseBuilder b)]) = _$ConceptHistoryResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ConceptHistoryResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ConceptHistoryResponse> get serializer => _$ConceptHistoryResponseSerializer();
}

class _$ConceptHistoryResponseSerializer implements PrimitiveSerializer<ConceptHistoryResponse> {
  @override
  final Iterable<Type> types = const [ConceptHistoryResponse, _$ConceptHistoryResponse];

  @override
  final String wireName = r'ConceptHistoryResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ConceptHistoryResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'concept_id';
    yield serializers.serialize(
      object.conceptId,
      specifiedType: const FullType(String),
    );
    yield r'concept_version_id';
    yield serializers.serialize(
      object.conceptVersionId,
      specifiedType: const FullType(String),
    );
    yield r'evidence';
    yield serializers.serialize(
      object.evidence,
      specifiedType: const FullType(EvidenceSummary),
    );
    yield r'has_more';
    yield serializers.serialize(
      object.hasMore,
      specifiedType: const FullType(bool),
    );
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(SchedulingExplanation)]),
    );
    yield r'next_cursor';
    yield object.nextCursor == null ? null : serializers.serialize(
      object.nextCursor,
      specifiedType: const FullType.nullable(String),
    );
    yield r'next_review_at';
    yield serializers.serialize(
      object.nextReviewAt,
      specifiedType: const FullType(String),
    );
    yield r'stable_code';
    yield serializers.serialize(
      object.stableCode,
      specifiedType: const FullType(String),
    );
    yield r'state_band';
    yield serializers.serialize(
      object.stateBand,
      specifiedType: const FullType(ConceptHistoryResponseStateBandEnum),
    );
    yield r'title';
    yield serializers.serialize(
      object.title,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ConceptHistoryResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ConceptHistoryResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'concept_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.conceptId = valueDes;
          break;
        case r'concept_version_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.conceptVersionId = valueDes;
          break;
        case r'evidence':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(EvidenceSummary),
          ) as EvidenceSummary;
          result.evidence.replace(valueDes);
          break;
        case r'has_more':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.hasMore = valueDes;
          break;
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(SchedulingExplanation)]),
          ) as BuiltList<SchedulingExplanation>;
          result.items.replace(valueDes);
          break;
        case r'next_cursor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.nextCursor = valueDes;
          break;
        case r'next_review_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.nextReviewAt = valueDes;
          break;
        case r'stable_code':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.stableCode = valueDes;
          break;
        case r'state_band':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ConceptHistoryResponseStateBandEnum),
          ) as ConceptHistoryResponseStateBandEnum;
          result.stateBand = valueDes;
          break;
        case r'title':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.title = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ConceptHistoryResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ConceptHistoryResponseBuilder();
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


class ConceptHistoryResponseStateBandEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'fresh')
  static const ConceptHistoryResponseStateBandEnum fresh = _$conceptHistoryResponseStateBandEnum_fresh;
  @BuiltValueEnumConst(wireName: r'settling')
  static const ConceptHistoryResponseStateBandEnum settling = _$conceptHistoryResponseStateBandEnum_settling;
  @BuiltValueEnumConst(wireName: r'fading')
  static const ConceptHistoryResponseStateBandEnum fading = _$conceptHistoryResponseStateBandEnum_fading;
  @BuiltValueEnumConst(wireName: r'critical')
  static const ConceptHistoryResponseStateBandEnum critical = _$conceptHistoryResponseStateBandEnum_critical;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const ConceptHistoryResponseStateBandEnum unknownDefaultOpenApi = _$conceptHistoryResponseStateBandEnum_unknownDefaultOpenApi;

  static Serializer<ConceptHistoryResponseStateBandEnum> get serializer => _$conceptHistoryResponseStateBandEnumSerializer;

  const ConceptHistoryResponseStateBandEnum._(String name): super(name);

  static BuiltSet<ConceptHistoryResponseStateBandEnum> get values => _$conceptHistoryResponseStateBandEnumValues;
  static ConceptHistoryResponseStateBandEnum valueOf(String name) => _$conceptHistoryResponseStateBandEnumValueOf(name);
}

