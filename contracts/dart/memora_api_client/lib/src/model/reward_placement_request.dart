//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:memora_api_client/src/optional.dart';

part 'reward_placement_request.g.dart';

/// RewardPlacementRequest
///
/// Properties:
/// * [placementSlot]
/// * [subjectId]
/// * [version]
@BuiltValue()
abstract class RewardPlacementRequest
    implements Built<RewardPlacementRequest, RewardPlacementRequestBuilder> {
  @BuiltValueField(wireName: r'placement_slot')
  Optional<String?> get placementSlot;

  @BuiltValueField(wireName: r'subject_id')
  Optional<String?> get subjectId;

  @BuiltValueField(wireName: r'version')
  int get version;

  RewardPlacementRequest._();

  factory RewardPlacementRequest(
          [void updates(RewardPlacementRequestBuilder b)]) =
      _$RewardPlacementRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RewardPlacementRequestBuilder b) => b
    ..placementSlot = Optional.absent()
    ..subjectId = Optional.absent();

  @BuiltValueSerializer(custom: true)
  static Serializer<RewardPlacementRequest> get serializer =>
      _$RewardPlacementRequestSerializer();
}

class _$RewardPlacementRequestSerializer
    implements PrimitiveSerializer<RewardPlacementRequest> {
  @override
  final Iterable<Type> types = const [
    RewardPlacementRequest,
    _$RewardPlacementRequest
  ];

  @override
  final String wireName = r'RewardPlacementRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    RewardPlacementRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.placementSlot.isPresent) {
      yield r'placement_slot';
      final optionalValue = object.placementSlot.value;
      if (optionalValue == null) {
        yield null;
      } else {
        yield serializers.serialize(
          optionalValue,
          specifiedType: const FullType.nullable(String),
        );
      }
    }
    if (object.subjectId.isPresent) {
      yield r'subject_id';
      final optionalValue = object.subjectId.value;
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
    RewardPlacementRequest object, {
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
    required RewardPlacementRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'placement_slot':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          result.placementSlot = Optional.present(valueDes);
          break;
        case r'subject_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          result.subjectId = Optional.present(valueDes);
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
  RewardPlacementRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RewardPlacementRequestBuilder();
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
