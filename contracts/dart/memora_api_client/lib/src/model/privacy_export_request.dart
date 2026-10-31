//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:memora_api_client/src/optional.dart';

part 'privacy_export_request.g.dart';

/// PrivacyExportRequest
///
/// Properties:
/// * [format]
@BuiltValue()
abstract class PrivacyExportRequest
    implements Built<PrivacyExportRequest, PrivacyExportRequestBuilder> {
  @BuiltValueField(wireName: r'format')
  Optional<String?> get format;

  PrivacyExportRequest._();

  factory PrivacyExportRequest([void updates(PrivacyExportRequestBuilder b)]) =
      _$PrivacyExportRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PrivacyExportRequestBuilder b) =>
      b..format = Optional.absent();

  @BuiltValueSerializer(custom: true)
  static Serializer<PrivacyExportRequest> get serializer =>
      _$PrivacyExportRequestSerializer();
}

class _$PrivacyExportRequestSerializer
    implements PrimitiveSerializer<PrivacyExportRequest> {
  @override
  final Iterable<Type> types = const [
    PrivacyExportRequest,
    _$PrivacyExportRequest
  ];

  @override
  final String wireName = r'PrivacyExportRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PrivacyExportRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.format.isPresent) {
      yield r'format';
      final optionalValue = object.format.value;
      if (optionalValue == null) {
        yield null;
      } else {
        yield serializers.serialize(
          optionalValue,
          specifiedType: const FullType.nullable(String),
        );
      }
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    PrivacyExportRequest object, {
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
    required PrivacyExportRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'format':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          result.format = Optional.present(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PrivacyExportRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PrivacyExportRequestBuilder();
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
