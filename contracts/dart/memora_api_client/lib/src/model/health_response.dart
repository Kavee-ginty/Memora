//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:memora_api_client/src/model/health_status.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:memora_api_client/src/optional.dart';

part 'health_response.g.dart';

/// HealthResponse
///
/// Properties:
/// * [status]
@BuiltValue()
abstract class HealthResponse
    implements Built<HealthResponse, HealthResponseBuilder> {
  @BuiltValueField(wireName: r'status')
  Optional<HealthStatus?> get status;
  // enum statusEnum {  ok,  };

  HealthResponse._();

  factory HealthResponse([void updates(HealthResponseBuilder b)]) =
      _$HealthResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(HealthResponseBuilder b) =>
      b..status = Optional.absent();

  @BuiltValueSerializer(custom: true)
  static Serializer<HealthResponse> get serializer =>
      _$HealthResponseSerializer();
}

class _$HealthResponseSerializer
    implements PrimitiveSerializer<HealthResponse> {
  @override
  final Iterable<Type> types = const [HealthResponse, _$HealthResponse];

  @override
  final String wireName = r'HealthResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    HealthResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.status.isPresent) {
      yield r'status';
      final optionalValue = object.status.value;
      if (optionalValue == null) {
        yield null;
      } else {
        yield serializers.serialize(
          optionalValue,
          specifiedType: const FullType.nullable(HealthStatus),
        );
      }
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    HealthResponse object, {
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
    required HealthResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(HealthStatus),
          ) as HealthStatus?;
          result.status = Optional.present(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  HealthResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = HealthResponseBuilder();
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
