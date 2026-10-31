//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:memora_api_client/src/model/consent_status.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'consent_response.g.dart';

/// ConsentResponse
///
/// Properties:
/// * [policies]
@BuiltValue()
abstract class ConsentResponse
    implements Built<ConsentResponse, ConsentResponseBuilder> {
  @BuiltValueField(wireName: r'policies')
  BuiltList<ConsentStatus> get policies;

  ConsentResponse._();

  factory ConsentResponse([void updates(ConsentResponseBuilder b)]) =
      _$ConsentResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ConsentResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ConsentResponse> get serializer =>
      _$ConsentResponseSerializer();
}

class _$ConsentResponseSerializer
    implements PrimitiveSerializer<ConsentResponse> {
  @override
  final Iterable<Type> types = const [ConsentResponse, _$ConsentResponse];

  @override
  final String wireName = r'ConsentResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ConsentResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'policies';
    yield serializers.serialize(
      object.policies,
      specifiedType: const FullType(BuiltList, [FullType(ConsentStatus)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ConsentResponse object, {
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
    required ConsentResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'policies':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(ConsentStatus)]),
          ) as BuiltList<ConsentStatus>;
          result.policies.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ConsentResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ConsentResponseBuilder();
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
