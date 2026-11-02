//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'first_mission_summary.g.dart';

/// FirstMissionSummary
///
/// Properties:
/// * [missionId]
/// * [status]
@BuiltValue()
abstract class FirstMissionSummary
    implements Built<FirstMissionSummary, FirstMissionSummaryBuilder> {
  @BuiltValueField(wireName: r'mission_id')
  String get missionId;

  @BuiltValueField(wireName: r'status')
  String get status;

  FirstMissionSummary._();

  factory FirstMissionSummary([void updates(FirstMissionSummaryBuilder b)]) =
      _$FirstMissionSummary;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(FirstMissionSummaryBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<FirstMissionSummary> get serializer =>
      _$FirstMissionSummarySerializer();
}

class _$FirstMissionSummarySerializer
    implements PrimitiveSerializer<FirstMissionSummary> {
  @override
  final Iterable<Type> types = const [
    FirstMissionSummary,
    _$FirstMissionSummary
  ];

  @override
  final String wireName = r'FirstMissionSummary';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    FirstMissionSummary object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'mission_id';
    yield serializers.serialize(
      object.missionId,
      specifiedType: const FullType(String),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    FirstMissionSummary object, {
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
    required FirstMissionSummaryBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'mission_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.missionId = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.status = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  FirstMissionSummary deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = FirstMissionSummaryBuilder();
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
