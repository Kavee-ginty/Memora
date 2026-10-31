//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:memora_api_client/src/optional.dart';

part 'capability_flags.g.dart';

/// CapabilityFlags
///
/// Properties:
/// * [canAddLearningMaterial] 
/// * [canRegisterNotifications] 
/// * [canStartMission] 
@BuiltValue()
abstract class CapabilityFlags implements Built<CapabilityFlags, CapabilityFlagsBuilder> {
  @BuiltValueField(wireName: r'can_add_learning_material')
  bool get canAddLearningMaterial;

  @BuiltValueField(wireName: r'can_register_notifications')
  Optional<bool?> get canRegisterNotifications;

  @BuiltValueField(wireName: r'can_start_mission')
  bool get canStartMission;

  CapabilityFlags._();

  factory CapabilityFlags([void updates(CapabilityFlagsBuilder b)]) = _$CapabilityFlags;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CapabilityFlagsBuilder b) => b
      ..canRegisterNotifications = Optional.absent();

  @BuiltValueSerializer(custom: true)
  static Serializer<CapabilityFlags> get serializer => _$CapabilityFlagsSerializer();
}

class _$CapabilityFlagsSerializer implements PrimitiveSerializer<CapabilityFlags> {
  @override
  final Iterable<Type> types = const [CapabilityFlags, _$CapabilityFlags];

  @override
  final String wireName = r'CapabilityFlags';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CapabilityFlags object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'can_add_learning_material';
    yield serializers.serialize(
      object.canAddLearningMaterial,
      specifiedType: const FullType(bool),
    );
    if (object.canRegisterNotifications.isPresent) {
      yield r'can_register_notifications';
      final optionalValue = object.canRegisterNotifications.value;
      if (optionalValue == null) {
        yield null;
      } else {
        yield serializers.serialize(
          optionalValue,
          specifiedType: const FullType.nullable(bool),
        );
      }
    }
    yield r'can_start_mission';
    yield serializers.serialize(
      object.canStartMission,
      specifiedType: const FullType(bool),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CapabilityFlags object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CapabilityFlagsBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'can_add_learning_material':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.canAddLearningMaterial = valueDes;
          break;
        case r'can_register_notifications':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(bool),
          ) as bool?;
          result.canRegisterNotifications = Optional.present(valueDes);
          break;
        case r'can_start_mission':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.canStartMission = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CapabilityFlags deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CapabilityFlagsBuilder();
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


