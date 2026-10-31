//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:memora_api_client/src/model/input_type.dart';
import 'package:memora_api_client/src/model/declared_file.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:memora_api_client/src/optional.dart';

part 'create_learning_update_request.g.dart';

/// CreateLearningUpdateRequest
///
/// Properties:
/// * [clientOperationId] 
/// * [files] 
/// * [inputType] 
/// * [learnedAt] 
/// * [manualText] 
/// * [subjectId] 
@BuiltValue()
abstract class CreateLearningUpdateRequest implements Built<CreateLearningUpdateRequest, CreateLearningUpdateRequestBuilder> {
  @BuiltValueField(wireName: r'client_operation_id')
  String get clientOperationId;

  @BuiltValueField(wireName: r'files')
  BuiltList<DeclaredFile> get files;

  @BuiltValueField(wireName: r'input_type')
  InputType get inputType;
  // enum inputTypeEnum {  manual_text,  pdf,  image,  mixed,  };

  @BuiltValueField(wireName: r'learned_at')
  DateTime get learnedAt;

  @BuiltValueField(wireName: r'manual_text')
  Optional<String?> get manualText;

  @BuiltValueField(wireName: r'subject_id')
  String get subjectId;

  CreateLearningUpdateRequest._();

  factory CreateLearningUpdateRequest([void updates(CreateLearningUpdateRequestBuilder b)]) = _$CreateLearningUpdateRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateLearningUpdateRequestBuilder b) => b
      ..files = ListBuilder()
      ..manualText = Optional.absent();

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateLearningUpdateRequest> get serializer => _$CreateLearningUpdateRequestSerializer();
}

class _$CreateLearningUpdateRequestSerializer implements PrimitiveSerializer<CreateLearningUpdateRequest> {
  @override
  final Iterable<Type> types = const [CreateLearningUpdateRequest, _$CreateLearningUpdateRequest];

  @override
  final String wireName = r'CreateLearningUpdateRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateLearningUpdateRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'client_operation_id';
    yield serializers.serialize(
      object.clientOperationId,
      specifiedType: const FullType(String),
    );
    yield r'files';
    yield serializers.serialize(
      object.files,
      specifiedType: const FullType(BuiltList, [FullType(DeclaredFile)]),
    );
    yield r'input_type';
    yield serializers.serialize(
      object.inputType,
      specifiedType: const FullType(InputType),
    );
    yield r'learned_at';
    yield serializers.serialize(
      object.learnedAt,
      specifiedType: const FullType(DateTime),
    );
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
    yield r'subject_id';
    yield serializers.serialize(
      object.subjectId,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CreateLearningUpdateRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreateLearningUpdateRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'client_operation_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.clientOperationId = valueDes;
          break;
        case r'files':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(DeclaredFile)]),
          ) as BuiltList<DeclaredFile>;
          result.files.replace(valueDes);
          break;
        case r'input_type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(InputType),
          ) as InputType;
          result.inputType = valueDes;
          break;
        case r'learned_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.learnedAt = valueDes;
          break;
        case r'manual_text':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          result.manualText = Optional.present(valueDes);
          break;
        case r'subject_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.subjectId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CreateLearningUpdateRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateLearningUpdateRequestBuilder();
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


