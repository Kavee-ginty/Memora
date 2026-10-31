//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'retry_learning_update_request.g.dart';

/// RetryLearningUpdateRequest
///
/// Properties:
/// * [stage] 
@BuiltValue()
abstract class RetryLearningUpdateRequest implements Built<RetryLearningUpdateRequest, RetryLearningUpdateRequestBuilder> {
  @BuiltValueField(wireName: r'stage')
  RetryLearningUpdateRequestStageEnum get stage;
  // enum stageEnum {  extraction,  deletion,  };

  RetryLearningUpdateRequest._();

  factory RetryLearningUpdateRequest([void updates(RetryLearningUpdateRequestBuilder b)]) = _$RetryLearningUpdateRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RetryLearningUpdateRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<RetryLearningUpdateRequest> get serializer => _$RetryLearningUpdateRequestSerializer();
}

class _$RetryLearningUpdateRequestSerializer implements PrimitiveSerializer<RetryLearningUpdateRequest> {
  @override
  final Iterable<Type> types = const [RetryLearningUpdateRequest, _$RetryLearningUpdateRequest];

  @override
  final String wireName = r'RetryLearningUpdateRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    RetryLearningUpdateRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'stage';
    yield serializers.serialize(
      object.stage,
      specifiedType: const FullType(RetryLearningUpdateRequestStageEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    RetryLearningUpdateRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required RetryLearningUpdateRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'stage':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(RetryLearningUpdateRequestStageEnum),
          ) as RetryLearningUpdateRequestStageEnum;
          result.stage = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  RetryLearningUpdateRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RetryLearningUpdateRequestBuilder();
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


class RetryLearningUpdateRequestStageEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'extraction')
  static const RetryLearningUpdateRequestStageEnum extraction = _$retryLearningUpdateRequestStageEnum_extraction;
  @BuiltValueEnumConst(wireName: r'deletion')
  static const RetryLearningUpdateRequestStageEnum deletion = _$retryLearningUpdateRequestStageEnum_deletion;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const RetryLearningUpdateRequestStageEnum unknownDefaultOpenApi = _$retryLearningUpdateRequestStageEnum_unknownDefaultOpenApi;

  static Serializer<RetryLearningUpdateRequestStageEnum> get serializer => _$retryLearningUpdateRequestStageEnumSerializer;

  const RetryLearningUpdateRequestStageEnum._(String name): super(name);

  static BuiltSet<RetryLearningUpdateRequestStageEnum> get values => _$retryLearningUpdateRequestStageEnumValues;
  static RetryLearningUpdateRequestStageEnum valueOf(String name) => _$retryLearningUpdateRequestStageEnumValueOf(name);
}

