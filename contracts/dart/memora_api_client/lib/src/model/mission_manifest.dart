//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:memora_api_client/src/model/mission_manifest_item.dart';
import 'package:built_collection/built_collection.dart';
import 'package:memora_api_client/src/model/mission_summary.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'mission_manifest.g.dart';

/// MissionManifest
///
/// Properties:
/// * [items]
/// * [mission]
@BuiltValue()
abstract class MissionManifest
    implements Built<MissionManifest, MissionManifestBuilder> {
  @BuiltValueField(wireName: r'items')
  BuiltList<MissionManifestItem> get items;

  @BuiltValueField(wireName: r'mission')
  MissionSummary get mission;

  MissionManifest._();

  factory MissionManifest([void updates(MissionManifestBuilder b)]) =
      _$MissionManifest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MissionManifestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<MissionManifest> get serializer =>
      _$MissionManifestSerializer();
}

class _$MissionManifestSerializer
    implements PrimitiveSerializer<MissionManifest> {
  @override
  final Iterable<Type> types = const [MissionManifest, _$MissionManifest];

  @override
  final String wireName = r'MissionManifest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MissionManifest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(MissionManifestItem)]),
    );
    yield r'mission';
    yield serializers.serialize(
      object.mission,
      specifiedType: const FullType(MissionSummary),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    MissionManifest object, {
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
    required MissionManifestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType:
                const FullType(BuiltList, [FullType(MissionManifestItem)]),
          ) as BuiltList<MissionManifestItem>;
          result.items.replace(valueDes);
          break;
        case r'mission':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(MissionSummary),
          ) as MissionSummary;
          result.mission.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  MissionManifest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MissionManifestBuilder();
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
