//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:memora_api_client/src/model/answer_payload.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:memora_api_client/src/optional.dart';

part 'submit_attempt_request.g.dart';

/// SubmitAttemptRequest
///
/// Properties:
/// * [answeredAt]
/// * [clientOperationId]
/// * [elapsedMs]
/// * [offlineSubmission]
/// * [questionVersionId]
/// * [response]
@BuiltValue()
abstract class SubmitAttemptRequest
    implements Built<SubmitAttemptRequest, SubmitAttemptRequestBuilder> {
  @BuiltValueField(wireName: r'answered_at')
  DateTime get answeredAt;

  @BuiltValueField(wireName: r'client_operation_id')
  String get clientOperationId;

  @BuiltValueField(wireName: r'elapsed_ms')
  Optional<int?> get elapsedMs;

  @BuiltValueField(wireName: r'offline_submission')
  Optional<bool?> get offlineSubmission;

  @BuiltValueField(wireName: r'question_version_id')
  String get questionVersionId;

  @BuiltValueField(wireName: r'response')
  AnswerPayload get response;

  SubmitAttemptRequest._();

  factory SubmitAttemptRequest([void updates(SubmitAttemptRequestBuilder b)]) =
      _$SubmitAttemptRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SubmitAttemptRequestBuilder b) => b
    ..elapsedMs = Optional.absent()
    ..offlineSubmission = Optional.absent();

  @BuiltValueSerializer(custom: true)
  static Serializer<SubmitAttemptRequest> get serializer =>
      _$SubmitAttemptRequestSerializer();
}

class _$SubmitAttemptRequestSerializer
    implements PrimitiveSerializer<SubmitAttemptRequest> {
  @override
  final Iterable<Type> types = const [
    SubmitAttemptRequest,
    _$SubmitAttemptRequest
  ];

  @override
  final String wireName = r'SubmitAttemptRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SubmitAttemptRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'answered_at';
    yield serializers.serialize(
      object.answeredAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'client_operation_id';
    yield serializers.serialize(
      object.clientOperationId,
      specifiedType: const FullType(String),
    );
    if (object.elapsedMs.isPresent) {
      yield r'elapsed_ms';
      final optionalValue = object.elapsedMs.value;
      if (optionalValue == null) {
        yield null;
      } else {
        yield serializers.serialize(
          optionalValue,
          specifiedType: const FullType.nullable(int),
        );
      }
    }
    if (object.offlineSubmission.isPresent) {
      yield r'offline_submission';
      final optionalValue = object.offlineSubmission.value;
      if (optionalValue == null) {
        yield null;
      } else {
        yield serializers.serialize(
          optionalValue,
          specifiedType: const FullType.nullable(bool),
        );
      }
    }
    yield r'question_version_id';
    yield serializers.serialize(
      object.questionVersionId,
      specifiedType: const FullType(String),
    );
    yield r'response';
    yield serializers.serialize(
      object.response,
      specifiedType: const FullType(AnswerPayload),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    SubmitAttemptRequest object, {
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
    required SubmitAttemptRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'answered_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.answeredAt = valueDes;
          break;
        case r'client_operation_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.clientOperationId = valueDes;
          break;
        case r'elapsed_ms':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          result.elapsedMs = Optional.present(valueDes);
          break;
        case r'offline_submission':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(bool),
          ) as bool?;
          result.offlineSubmission = Optional.present(valueDes);
          break;
        case r'question_version_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.questionVersionId = valueDes;
          break;
        case r'response':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(AnswerPayload),
          ) as AnswerPayload;
          result.response.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SubmitAttemptRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SubmitAttemptRequestBuilder();
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
