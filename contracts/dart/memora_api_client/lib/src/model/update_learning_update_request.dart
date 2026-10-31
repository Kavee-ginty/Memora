//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:memora_api_client/src/optional.dart';

part 'update_learning_update_request.g.dart';

/// UpdateLearningUpdateRequest
///
/// Properties:
/// * [learnedAt] 
/// * [manualText] 
/// * [version] 
@BuiltValue()
abstract class UpdateLearningUpdateRequest implements Built<UpdateLearningUpdateRequest, UpdateLearningUpdateRequestBuilder> {
  @BuiltValueField(wireName: r'learned_at')
  Optional<DateTime?> get learnedAt;

  @BuiltValueField(wireName: r'manual_text')
  Optional<String?> get manualText;

  @BuiltValueField(wireName: r'version')
  int get version;

  UpdateLearningUpdateRequest._();

  factory UpdateLearningUpdateRequest([void updates(UpdateLearningUpdateRequestBuilder b)]) = _$UpdateLearningUpdateRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateLearningUpdateRequestBuilder b) => b
      ..learnedAt = Optional.absent()
      ..manualText = Optional.absent();

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateLearningUpdateRequest> get serializer => _$UpdateLearningUpdateRequestSerializer();
}

class _$UpdateLearningUpdateRequestSerializer implements PrimitiveSerializer<UpdateLearningUpdateRequest> {
  @override
  final Iterable<Type> types = const [UpdateLearningUpdateRequest, _$UpdateLearningUpdateRequest];

  @override
  final String wireName = r'UpdateLearningUpdateRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateLearningUpdateRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.learnedAt.isPresent) {
      yield r'learned_at';
      final optionalValue = object.learnedAt.value;
      if (optionalValue == null) {
        yield null;
      } else {
        yield serializers.serialize(
          optionalValue,
          specifiedType: const FullType.nullable(DateTime),
        );
      }
    }
    if (object.manualText.isPresent) {
      yield r'manual_text';
      final optionalValue = object.manualText.value;
      if (optionalValue == null) {
        yield null;
      } else {
        yield serializers.serialize(
          optionalValue,
          specifiedType: const FullType.nullable(String),
        );
      }
    }
    yield r'version';
    yield serializers.serialize(
      object.version,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateLearningUpdateRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdateLearningUpdateRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'learned_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          result.learnedAt = Optional.present(valueDes);
          break;
        case r'manual_text':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          result.manualText = Optional.present(valueDes);
          break;
        case r'version':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.version = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UpdateLearningUpdateRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateLearningUpdateRequestBuilder();
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


