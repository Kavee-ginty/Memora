//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:memora_api_client/src/model/accessibility_preferences.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:memora_api_client/src/optional.dart';

part 'profile_preferences_update_request.g.dart';

/// ProfilePreferencesUpdateRequest
///
/// Properties:
/// * [accessibility] 
/// * [lockScreenDetail] 
/// * [maxDailyReminders] 
/// * [missionEnabled] 
/// * [notificationsEnabled] 
/// * [preferredWindowEndLocal] 
/// * [preferredWindowStartLocal] 
/// * [quietEndLocal] 
/// * [quietStartLocal] 
/// * [rewardEnabled] 
/// * [streakEnabled] 
/// * [timezone] 
/// * [version] 
@BuiltValue()
abstract class ProfilePreferencesUpdateRequest implements Built<ProfilePreferencesUpdateRequest, ProfilePreferencesUpdateRequestBuilder> {
  @BuiltValueField(wireName: r'accessibility')
  Optional<AccessibilityPreferences?> get accessibility;

  @BuiltValueField(wireName: r'lock_screen_detail')
  Optional<String?> get lockScreenDetail;

  @BuiltValueField(wireName: r'max_daily_reminders')
  Optional<int?> get maxDailyReminders;

  @BuiltValueField(wireName: r'mission_enabled')
  Optional<bool?> get missionEnabled;

  @BuiltValueField(wireName: r'notifications_enabled')
  Optional<bool?> get notificationsEnabled;

  @BuiltValueField(wireName: r'preferred_window_end_local')
  Optional<String?> get preferredWindowEndLocal;

  @BuiltValueField(wireName: r'preferred_window_start_local')
  Optional<String?> get preferredWindowStartLocal;

  @BuiltValueField(wireName: r'quiet_end_local')
  Optional<String?> get quietEndLocal;

  @BuiltValueField(wireName: r'quiet_start_local')
  Optional<String?> get quietStartLocal;

  @BuiltValueField(wireName: r'reward_enabled')
  Optional<bool?> get rewardEnabled;

  @BuiltValueField(wireName: r'streak_enabled')
  Optional<bool?> get streakEnabled;

  @BuiltValueField(wireName: r'timezone')
  Optional<String?> get timezone;

  @BuiltValueField(wireName: r'version')
  int get version;

  ProfilePreferencesUpdateRequest._();

  factory ProfilePreferencesUpdateRequest([void updates(ProfilePreferencesUpdateRequestBuilder b)]) = _$ProfilePreferencesUpdateRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ProfilePreferencesUpdateRequestBuilder b) => b
      ..accessibility = Optional.absent()
      ..lockScreenDetail = Optional.absent()
      ..maxDailyReminders = Optional.absent()
      ..missionEnabled = Optional.absent()
      ..notificationsEnabled = Optional.absent()
      ..preferredWindowEndLocal = Optional.absent()
      ..preferredWindowStartLocal = Optional.absent()
      ..quietEndLocal = Optional.absent()
      ..quietStartLocal = Optional.absent()
      ..rewardEnabled = Optional.absent()
      ..streakEnabled = Optional.absent()
      ..timezone = Optional.absent();

  @BuiltValueSerializer(custom: true)
  static Serializer<ProfilePreferencesUpdateRequest> get serializer => _$ProfilePreferencesUpdateRequestSerializer();
}

class _$ProfilePreferencesUpdateRequestSerializer implements PrimitiveSerializer<ProfilePreferencesUpdateRequest> {
  @override
  final Iterable<Type> types = const [ProfilePreferencesUpdateRequest, _$ProfilePreferencesUpdateRequest];

  @override
  final String wireName = r'ProfilePreferencesUpdateRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ProfilePreferencesUpdateRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.accessibility.isPresent) {
      yield r'accessibility';
      final optionalValue = object.accessibility.value;
      if (optionalValue == null) {
        yield null;
      } else {
        yield serializers.serialize(
          optionalValue,
          specifiedType: const FullType.nullable(AccessibilityPreferences),
        );
      }
    }
    if (object.lockScreenDetail.isPresent) {
      yield r'lock_screen_detail';
      final optionalValue = object.lockScreenDetail.value;
      if (optionalValue == null) {
        yield null;
      } else {
        yield serializers.serialize(
          optionalValue,
          specifiedType: const FullType.nullable(String),
        );
      }
    }
    if (object.maxDailyReminders.isPresent) {
      yield r'max_daily_reminders';
      final optionalValue = object.maxDailyReminders.value;
      if (optionalValue == null) {
        yield null;
      } else {
        yield serializers.serialize(
          optionalValue,
          specifiedType: const FullType.nullable(int),
        );
      }
    }
    if (object.missionEnabled.isPresent) {
      yield r'mission_enabled';
      final optionalValue = object.missionEnabled.value;
      if (optionalValue == null) {
        yield null;
      } else {
        yield serializers.serialize(
          optionalValue,
          specifiedType: const FullType.nullable(bool),
        );
      }
    }
    if (object.notificationsEnabled.isPresent) {
      yield r'notifications_enabled';
      final optionalValue = object.notificationsEnabled.value;
      if (optionalValue == null) {
        yield null;
      } else {
        yield serializers.serialize(
          optionalValue,
          specifiedType: const FullType.nullable(bool),
        );
      }
    }
    if (object.preferredWindowEndLocal.isPresent) {
      yield r'preferred_window_end_local';
      final optionalValue = object.preferredWindowEndLocal.value;
      if (optionalValue == null) {
        yield null;
      } else {
        yield serializers.serialize(
          optionalValue,
          specifiedType: const FullType.nullable(String),
        );
      }
    }
    if (object.preferredWindowStartLocal.isPresent) {
      yield r'preferred_window_start_local';
      final optionalValue = object.preferredWindowStartLocal.value;
      if (optionalValue == null) {
        yield null;
      } else {
        yield serializers.serialize(
          optionalValue,
          specifiedType: const FullType.nullable(String),
        );
      }
    }
    if (object.quietEndLocal.isPresent) {
      yield r'quiet_end_local';
      final optionalValue = object.quietEndLocal.value;
      if (optionalValue == null) {
        yield null;
      } else {
        yield serializers.serialize(
          optionalValue,
          specifiedType: const FullType.nullable(String),
        );
      }
    }
    if (object.quietStartLocal.isPresent) {
      yield r'quiet_start_local';
      final optionalValue = object.quietStartLocal.value;
      if (optionalValue == null) {
        yield null;
      } else {
        yield serializers.serialize(
          optionalValue,
          specifiedType: const FullType.nullable(String),
        );
      }
    }
    if (object.rewardEnabled.isPresent) {
      yield r'reward_enabled';
      final optionalValue = object.rewardEnabled.value;
      if (optionalValue == null) {
        yield null;
      } else {
        yield serializers.serialize(
          optionalValue,
          specifiedType: const FullType.nullable(bool),
        );
      }
    }
    if (object.streakEnabled.isPresent) {
      yield r'streak_enabled';
      final optionalValue = object.streakEnabled.value;
      if (optionalValue == null) {
        yield null;
      } else {
        yield serializers.serialize(
          optionalValue,
          specifiedType: const FullType.nullable(bool),
        );
      }
    }
    if (object.timezone.isPresent) {
      yield r'timezone';
      final optionalValue = object.timezone.value;
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
    ProfilePreferencesUpdateRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ProfilePreferencesUpdateRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'accessibility':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(AccessibilityPreferences),
          ) as AccessibilityPreferences?;
          result.accessibility = Optional.present(valueDes);
          break;
        case r'lock_screen_detail':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          result.lockScreenDetail = Optional.present(valueDes);
          break;
        case r'max_daily_reminders':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          result.maxDailyReminders = Optional.present(valueDes);
          break;
        case r'mission_enabled':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(bool),
          ) as bool?;
          result.missionEnabled = Optional.present(valueDes);
          break;
        case r'notifications_enabled':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(bool),
          ) as bool?;
          result.notificationsEnabled = Optional.present(valueDes);
          break;
        case r'preferred_window_end_local':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          result.preferredWindowEndLocal = Optional.present(valueDes);
          break;
        case r'preferred_window_start_local':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          result.preferredWindowStartLocal = Optional.present(valueDes);
          break;
        case r'quiet_end_local':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          result.quietEndLocal = Optional.present(valueDes);
          break;
        case r'quiet_start_local':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          result.quietStartLocal = Optional.present(valueDes);
          break;
        case r'reward_enabled':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(bool),
          ) as bool?;
          result.rewardEnabled = Optional.present(valueDes);
          break;
        case r'streak_enabled':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(bool),
          ) as bool?;
          result.streakEnabled = Optional.present(valueDes);
          break;
        case r'timezone':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          result.timezone = Optional.present(valueDes);
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
  ProfilePreferencesUpdateRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ProfilePreferencesUpdateRequestBuilder();
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


