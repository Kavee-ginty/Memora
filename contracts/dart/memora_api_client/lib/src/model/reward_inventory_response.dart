//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:memora_api_client/src/model/reward_grant.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'reward_inventory_response.g.dart';

/// RewardInventoryResponse
///
/// Properties:
/// * [items]
@BuiltValue()
abstract class RewardInventoryResponse
    implements Built<RewardInventoryResponse, RewardInventoryResponseBuilder> {
  @BuiltValueField(wireName: r'items')
  BuiltList<RewardGrant> get items;

  RewardInventoryResponse._();

  factory RewardInventoryResponse(
          [void updates(RewardInventoryResponseBuilder b)]) =
      _$RewardInventoryResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RewardInventoryResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<RewardInventoryResponse> get serializer =>
      _$RewardInventoryResponseSerializer();
}

class _$RewardInventoryResponseSerializer
    implements PrimitiveSerializer<RewardInventoryResponse> {
  @override
  final Iterable<Type> types = const [
    RewardInventoryResponse,
    _$RewardInventoryResponse
  ];

  @override
  final String wireName = r'RewardInventoryResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    RewardInventoryResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(RewardGrant)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    RewardInventoryResponse object, {
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
    required RewardInventoryResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(RewardGrant)]),
          ) as BuiltList<RewardGrant>;
          result.items.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  RewardInventoryResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RewardInventoryResponseBuilder();
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
