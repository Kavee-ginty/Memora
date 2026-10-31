//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:memora_api_client/src/model/due_reason_explanation.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'concept_progress_item.g.dart';

/// One concept's progress and due reason for a subject.
///
/// Properties:
/// * [conceptId] 
/// * [conceptVersionId] 
/// * [confidenceBand] 
/// * [dueReason] 
/// * [eligibleReviewCount] 
/// * [exposureCount] 
/// * [isComeback] 
/// * [isNewConcept] 
/// * [lapseCount] 
/// * [lastReviewedAt] 
/// * [nextReviewAt] 
/// * [reviewWindow] 
/// * [stableCode] 
/// * [stateBand] 
/// * [title] 
@BuiltValue()
abstract class ConceptProgressItem implements Built<ConceptProgressItem, ConceptProgressItemBuilder> {
  @BuiltValueField(wireName: r'concept_id')
  String get conceptId;

  @BuiltValueField(wireName: r'concept_version_id')
  String get conceptVersionId;

  @BuiltValueField(wireName: r'confidence_band')
  ConceptProgressItemConfidenceBandEnum get confidenceBand;
  // enum confidenceBandEnum {  high,  medium,  low,  };

  @BuiltValueField(wireName: r'due_reason')
  DueReasonExplanation get dueReason;

  @BuiltValueField(wireName: r'eligible_review_count')
  int get eligibleReviewCount;

  @BuiltValueField(wireName: r'exposure_count')
  int get exposureCount;

  @BuiltValueField(wireName: r'is_comeback')
  bool get isComeback;

  @BuiltValueField(wireName: r'is_new_concept')
  bool get isNewConcept;

  @BuiltValueField(wireName: r'lapse_count')
  int get lapseCount;

  @BuiltValueField(wireName: r'last_reviewed_at')
  String? get lastReviewedAt;

  @BuiltValueField(wireName: r'next_review_at')
  String get nextReviewAt;

  @BuiltValueField(wireName: r'review_window')
  ConceptProgressItemReviewWindowEnum get reviewWindow;
  // enum reviewWindowEnum {  overdue,  due,  near_due,  };

  @BuiltValueField(wireName: r'stable_code')
  String get stableCode;

  @BuiltValueField(wireName: r'state_band')
  ConceptProgressItemStateBandEnum get stateBand;
  // enum stateBandEnum {  fresh,  settling,  fading,  critical,  };

  @BuiltValueField(wireName: r'title')
  String get title;

  ConceptProgressItem._();

  factory ConceptProgressItem([void updates(ConceptProgressItemBuilder b)]) = _$ConceptProgressItem;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ConceptProgressItemBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ConceptProgressItem> get serializer => _$ConceptProgressItemSerializer();
}

class _$ConceptProgressItemSerializer implements PrimitiveSerializer<ConceptProgressItem> {
  @override
  final Iterable<Type> types = const [ConceptProgressItem, _$ConceptProgressItem];

  @override
  final String wireName = r'ConceptProgressItem';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ConceptProgressItem object, {
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
    yield r'confidence_band';
    yield serializers.serialize(
      object.confidenceBand,
      specifiedType: const FullType(ConceptProgressItemConfidenceBandEnum),
    );
    yield r'due_reason';
    yield serializers.serialize(
      object.dueReason,
      specifiedType: const FullType(DueReasonExplanation),
    );
    yield r'eligible_review_count';
    yield serializers.serialize(
      object.eligibleReviewCount,
      specifiedType: const FullType(int),
    );
    yield r'exposure_count';
    yield serializers.serialize(
      object.exposureCount,
      specifiedType: const FullType(int),
    );
    yield r'is_comeback';
    yield serializers.serialize(
      object.isComeback,
      specifiedType: const FullType(bool),
    );
    yield r'is_new_concept';
    yield serializers.serialize(
      object.isNewConcept,
      specifiedType: const FullType(bool),
    );
    yield r'lapse_count';
    yield serializers.serialize(
      object.lapseCount,
      specifiedType: const FullType(int),
    );
    yield r'last_reviewed_at';
    yield object.lastReviewedAt == null ? null : serializers.serialize(
      object.lastReviewedAt,
      specifiedType: const FullType.nullable(String),
    );
    yield r'next_review_at';
    yield serializers.serialize(
      object.nextReviewAt,
      specifiedType: const FullType(String),
    );
    yield r'review_window';
    yield serializers.serialize(
      object.reviewWindow,
      specifiedType: const FullType(ConceptProgressItemReviewWindowEnum),
    );
    yield r'stable_code';
    yield serializers.serialize(
      object.stableCode,
      specifiedType: const FullType(String),
    );
    yield r'state_band';
    yield serializers.serialize(
      object.stateBand,
      specifiedType: const FullType(ConceptProgressItemStateBandEnum),
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
    ConceptProgressItem object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ConceptProgressItemBuilder result,
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
        case r'confidence_band':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ConceptProgressItemConfidenceBandEnum),
          ) as ConceptProgressItemConfidenceBandEnum;
          result.confidenceBand = valueDes;
          break;
        case r'due_reason':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DueReasonExplanation),
          ) as DueReasonExplanation;
          result.dueReason.replace(valueDes);
          break;
        case r'eligible_review_count':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.eligibleReviewCount = valueDes;
          break;
        case r'exposure_count':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.exposureCount = valueDes;
          break;
        case r'is_comeback':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isComeback = valueDes;
          break;
        case r'is_new_concept':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isNewConcept = valueDes;
          break;
        case r'lapse_count':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.lapseCount = valueDes;
          break;
        case r'last_reviewed_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.lastReviewedAt = valueDes;
          break;
        case r'next_review_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.nextReviewAt = valueDes;
          break;
        case r'review_window':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ConceptProgressItemReviewWindowEnum),
          ) as ConceptProgressItemReviewWindowEnum;
          result.reviewWindow = valueDes;
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
            specifiedType: const FullType(ConceptProgressItemStateBandEnum),
          ) as ConceptProgressItemStateBandEnum;
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
  ConceptProgressItem deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ConceptProgressItemBuilder();
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


class ConceptProgressItemConfidenceBandEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'high')
  static const ConceptProgressItemConfidenceBandEnum high = _$conceptProgressItemConfidenceBandEnum_high;
  @BuiltValueEnumConst(wireName: r'medium')
  static const ConceptProgressItemConfidenceBandEnum medium = _$conceptProgressItemConfidenceBandEnum_medium;
  @BuiltValueEnumConst(wireName: r'low')
  static const ConceptProgressItemConfidenceBandEnum low = _$conceptProgressItemConfidenceBandEnum_low;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const ConceptProgressItemConfidenceBandEnum unknownDefaultOpenApi = _$conceptProgressItemConfidenceBandEnum_unknownDefaultOpenApi;

  static Serializer<ConceptProgressItemConfidenceBandEnum> get serializer => _$conceptProgressItemConfidenceBandEnumSerializer;

  const ConceptProgressItemConfidenceBandEnum._(String name): super(name);

  static BuiltSet<ConceptProgressItemConfidenceBandEnum> get values => _$conceptProgressItemConfidenceBandEnumValues;
  static ConceptProgressItemConfidenceBandEnum valueOf(String name) => _$conceptProgressItemConfidenceBandEnumValueOf(name);
}

class ConceptProgressItemReviewWindowEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'overdue')
  static const ConceptProgressItemReviewWindowEnum overdue = _$conceptProgressItemReviewWindowEnum_overdue;
  @BuiltValueEnumConst(wireName: r'due')
  static const ConceptProgressItemReviewWindowEnum due = _$conceptProgressItemReviewWindowEnum_due;
  @BuiltValueEnumConst(wireName: r'near_due')
  static const ConceptProgressItemReviewWindowEnum nearDue = _$conceptProgressItemReviewWindowEnum_nearDue;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const ConceptProgressItemReviewWindowEnum unknownDefaultOpenApi = _$conceptProgressItemReviewWindowEnum_unknownDefaultOpenApi;

  static Serializer<ConceptProgressItemReviewWindowEnum> get serializer => _$conceptProgressItemReviewWindowEnumSerializer;

  const ConceptProgressItemReviewWindowEnum._(String name): super(name);

  static BuiltSet<ConceptProgressItemReviewWindowEnum> get values => _$conceptProgressItemReviewWindowEnumValues;
  static ConceptProgressItemReviewWindowEnum valueOf(String name) => _$conceptProgressItemReviewWindowEnumValueOf(name);
}

class ConceptProgressItemStateBandEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'fresh')
  static const ConceptProgressItemStateBandEnum fresh = _$conceptProgressItemStateBandEnum_fresh;
  @BuiltValueEnumConst(wireName: r'settling')
  static const ConceptProgressItemStateBandEnum settling = _$conceptProgressItemStateBandEnum_settling;
  @BuiltValueEnumConst(wireName: r'fading')
  static const ConceptProgressItemStateBandEnum fading = _$conceptProgressItemStateBandEnum_fading;
  @BuiltValueEnumConst(wireName: r'critical')
  static const ConceptProgressItemStateBandEnum critical = _$conceptProgressItemStateBandEnum_critical;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const ConceptProgressItemStateBandEnum unknownDefaultOpenApi = _$conceptProgressItemStateBandEnum_unknownDefaultOpenApi;

  static Serializer<ConceptProgressItemStateBandEnum> get serializer => _$conceptProgressItemStateBandEnumSerializer;

  const ConceptProgressItemStateBandEnum._(String name): super(name);

  static BuiltSet<ConceptProgressItemStateBandEnum> get values => _$conceptProgressItemStateBandEnumValues;
  static ConceptProgressItemStateBandEnum valueOf(String name) => _$conceptProgressItemStateBandEnumValueOf(name);
}

