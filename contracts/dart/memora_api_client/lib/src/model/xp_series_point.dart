//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:memora_api_client/src/model/date.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'xp_series_point.g.dart';

/// XpSeriesPoint
///
/// Properties:
/// * [day]
/// * [xp]
@BuiltValue()
abstract class XpSeriesPoint
    implements Built<XpSeriesPoint, XpSeriesPointBuilder> {
  @BuiltValueField(wireName: r'day')
  Date get day;

  @BuiltValueField(wireName: r'xp')
  int get xp;

  XpSeriesPoint._();

  factory XpSeriesPoint([void updates(XpSeriesPointBuilder b)]) =
      _$XpSeriesPoint;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(XpSeriesPointBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<XpSeriesPoint> get serializer =>
      _$XpSeriesPointSerializer();
}

class _$XpSeriesPointSerializer implements PrimitiveSerializer<XpSeriesPoint> {
  @override
  final Iterable<Type> types = const [XpSeriesPoint, _$XpSeriesPoint];

  @override
  final String wireName = r'XpSeriesPoint';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    XpSeriesPoint object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'day';
    yield serializers.serialize(
      object.day,
      specifiedType: const FullType(Date),
    );
    yield r'xp';
    yield serializers.serialize(
      object.xp,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    XpSeriesPoint object, {
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
    required XpSeriesPointBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'day':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Date),
          ) as Date;
          result.day = valueDes;
          break;
        case r'xp':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.xp = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  XpSeriesPoint deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = XpSeriesPointBuilder();
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
