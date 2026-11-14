//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:memora_api_client/src/model/seabed_reef.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'seabed_response.g.dart';

/// SeabedResponse
///
/// Properties:
/// * [projectionVersion]
/// * [reefs]
@BuiltValue()
abstract class SeabedResponse
    implements Built<SeabedResponse, SeabedResponseBuilder> {
  @BuiltValueField(wireName: r'projection_version')
  String get projectionVersion;

  @BuiltValueField(wireName: r'reefs')
  BuiltList<SeabedReef> get reefs;

  SeabedResponse._();

  factory SeabedResponse([void updates(SeabedResponseBuilder b)]) =
      _$SeabedResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SeabedResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SeabedResponse> get serializer =>
      _$SeabedResponseSerializer();
}

class _$SeabedResponseSerializer
    implements PrimitiveSerializer<SeabedResponse> {
  @override
  final Iterable<Type> types = const [SeabedResponse, _$SeabedResponse];

  @override
  final String wireName = r'SeabedResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SeabedResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'projection_version';
    yield serializers.serialize(
      object.projectionVersion,
      specifiedType: const FullType(String),
    );
    yield r'reefs';
    yield serializers.serialize(
      object.reefs,
      specifiedType: const FullType(BuiltList, [FullType(SeabedReef)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    SeabedResponse object, {
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
    required SeabedResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'projection_version':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.projectionVersion = valueDes;
          break;
        case r'reefs':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(SeabedReef)]),
          ) as BuiltList<SeabedReef>;
          result.reefs.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SeabedResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SeabedResponseBuilder();
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
