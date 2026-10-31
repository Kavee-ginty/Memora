//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:memora_api_client/src/optional.dart';

part 'accessibility_preferences.g.dart';

/// AccessibilityPreferences
///
/// Properties:
/// * [hapticsEnabled]
/// * [highContrast]
/// * [reducedMotion]
/// * [schemaVersion]
/// * [soundEnabled]
/// * [timerVisible]
@BuiltValue()
abstract class AccessibilityPreferences
    implements
        Built<AccessibilityPreferences, AccessibilityPreferencesBuilder> {
  @BuiltValueField(wireName: r'haptics_enabled')
  Optional<bool?> get hapticsEnabled;

  @BuiltValueField(wireName: r'high_contrast')
  Optional<bool?> get highContrast;

  @BuiltValueField(wireName: r'reduced_motion')
  Optional<bool?> get reducedMotion;

  @BuiltValueField(wireName: r'schema_version')
  Optional<String?> get schemaVersion;

  @BuiltValueField(wireName: r'sound_enabled')
  Optional<bool?> get soundEnabled;

  @BuiltValueField(wireName: r'timer_visible')
  Optional<bool?> get timerVisible;

  AccessibilityPreferences._();

  factory AccessibilityPreferences(
          [void updates(AccessibilityPreferencesBuilder b)]) =
      _$AccessibilityPreferences;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AccessibilityPreferencesBuilder b) => b
    ..hapticsEnabled = Optional.absent()
    ..highContrast = Optional.absent()
    ..reducedMotion = Optional.absent()
    ..schemaVersion = Optional.absent()
    ..soundEnabled = Optional.absent()
    ..timerVisible = Optional.absent();

  @BuiltValueSerializer(custom: true)
  static Serializer<AccessibilityPreferences> get serializer =>
      _$AccessibilityPreferencesSerializer();
}

class _$AccessibilityPreferencesSerializer
    implements PrimitiveSerializer<AccessibilityPreferences> {
  @override
  final Iterable<Type> types = const [
    AccessibilityPreferences,
    _$AccessibilityPreferences
  ];

  @override
  final String wireName = r'AccessibilityPreferences';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AccessibilityPreferences object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.hapticsEnabled.isPresent) {
      yield r'haptics_enabled';
      final optionalValue = object.hapticsEnabled.value;
      if (optionalValue == null) {
        yield null;
      } else {
        yield serializers.serialize(
          optionalValue,
          specifiedType: const FullType.nullable(bool),
        );
      }
    }
    if (object.highContrast.isPresent) {
      yield r'high_contrast';
      final optionalValue = object.highContrast.value;
      if (optionalValue == null) {
        yield null;
      } else {
        yield serializers.serialize(
          optionalValue,
          specifiedType: const FullType.nullable(bool),
        );
      }
    }
    if (object.reducedMotion.isPresent) {
      yield r'reduced_motion';
      final optionalValue = object.reducedMotion.value;
      if (optionalValue == null) {
        yield null;
      } else {
        yield serializers.serialize(
          optionalValue,
          specifiedType: const FullType.nullable(bool),
        );
      }
    }
    if (object.schemaVersion.isPresent) {
      yield r'schema_version';
      final optionalValue = object.schemaVersion.value;
      if (optionalValue == null) {
        yield null;
      } else {
        yield serializers.serialize(
          optionalValue,
          specifiedType: const FullType.nullable(String),
        );
      }
    }
    if (object.soundEnabled.isPresent) {
      yield r'sound_enabled';
      final optionalValue = object.soundEnabled.value;
      if (optionalValue == null) {
        yield null;
      } else {
        yield serializers.serialize(
          optionalValue,
          specifiedType: const FullType.nullable(bool),
        );
      }
    }
    if (object.timerVisible.isPresent) {
      yield r'timer_visible';
      final optionalValue = object.timerVisible.value;
      if (optionalValue == null) {
        yield null;
      } else {
        yield serializers.serialize(
          optionalValue,
          specifiedType: const FullType.nullable(bool),
        );
      }
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    AccessibilityPreferences object, {
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
    required AccessibilityPreferencesBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'haptics_enabled':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(bool),
          ) as bool?;
          result.hapticsEnabled = Optional.present(valueDes);
          break;
        case r'high_contrast':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(bool),
          ) as bool?;
          result.highContrast = Optional.present(valueDes);
          break;
        case r'reduced_motion':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(bool),
          ) as bool?;
          result.reducedMotion = Optional.present(valueDes);
          break;
        case r'schema_version':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          result.schemaVersion = Optional.present(valueDes);
          break;
        case r'sound_enabled':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(bool),
          ) as bool?;
          result.soundEnabled = Optional.present(valueDes);
          break;
        case r'timer_visible':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(bool),
          ) as bool?;
          result.timerVisible = Optional.present(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  AccessibilityPreferences deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AccessibilityPreferencesBuilder();
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
