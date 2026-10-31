//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:memora_api_client/src/model/accessibility_preferences.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'profile_preferences_response.g.dart';

/// ProfilePreferencesResponse
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
abstract class ProfilePreferencesResponse
    implements
        Built<ProfilePreferencesResponse, ProfilePreferencesResponseBuilder> {
  @BuiltValueField(wireName: r'accessibility')
  AccessibilityPreferences get accessibility;

  @BuiltValueField(wireName: r'lock_screen_detail')
  ProfilePreferencesResponseLockScreenDetailEnum get lockScreenDetail;
  // enum lockScreenDetailEnum {  minimal,  subject,  detailed,  };

  @BuiltValueField(wireName: r'max_daily_reminders')
  int get maxDailyReminders;

  @BuiltValueField(wireName: r'mission_enabled')
  bool get missionEnabled;

  @BuiltValueField(wireName: r'notifications_enabled')
  bool get notificationsEnabled;

  @BuiltValueField(wireName: r'preferred_window_end_local')
  String? get preferredWindowEndLocal;

  @BuiltValueField(wireName: r'preferred_window_start_local')
  String? get preferredWindowStartLocal;

  @BuiltValueField(wireName: r'quiet_end_local')
  String? get quietEndLocal;

  @BuiltValueField(wireName: r'quiet_start_local')
  String? get quietStartLocal;

  @BuiltValueField(wireName: r'reward_enabled')
  bool get rewardEnabled;

  @BuiltValueField(wireName: r'streak_enabled')
  bool get streakEnabled;

  @BuiltValueField(wireName: r'timezone')
  String get timezone;

  @BuiltValueField(wireName: r'version')
  int get version;

  ProfilePreferencesResponse._();

  factory ProfilePreferencesResponse(
          [void updates(ProfilePreferencesResponseBuilder b)]) =
      _$ProfilePreferencesResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ProfilePreferencesResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ProfilePreferencesResponse> get serializer =>
      _$ProfilePreferencesResponseSerializer();
}

class _$ProfilePreferencesResponseSerializer
    implements PrimitiveSerializer<ProfilePreferencesResponse> {
  @override
  final Iterable<Type> types = const [
    ProfilePreferencesResponse,
    _$ProfilePreferencesResponse
  ];

  @override
  final String wireName = r'ProfilePreferencesResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ProfilePreferencesResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'accessibility';
    yield serializers.serialize(
      object.accessibility,
      specifiedType: const FullType(AccessibilityPreferences),
    );
    yield r'lock_screen_detail';
    yield serializers.serialize(
      object.lockScreenDetail,
      specifiedType:
          const FullType(ProfilePreferencesResponseLockScreenDetailEnum),
    );
    yield r'max_daily_reminders';
    yield serializers.serialize(
      object.maxDailyReminders,
      specifiedType: const FullType(int),
    );
    yield r'mission_enabled';
    yield serializers.serialize(
      object.missionEnabled,
      specifiedType: const FullType(bool),
    );
    yield r'notifications_enabled';
    yield serializers.serialize(
      object.notificationsEnabled,
      specifiedType: const FullType(bool),
    );
    yield r'preferred_window_end_local';
    yield object.preferredWindowEndLocal == null
        ? null
        : serializers.serialize(
            object.preferredWindowEndLocal,
            specifiedType: const FullType.nullable(String),
          );
    yield r'preferred_window_start_local';
    yield object.preferredWindowStartLocal == null
        ? null
        : serializers.serialize(
            object.preferredWindowStartLocal,
            specifiedType: const FullType.nullable(String),
          );
    yield r'quiet_end_local';
    yield object.quietEndLocal == null
        ? null
        : serializers.serialize(
            object.quietEndLocal,
            specifiedType: const FullType.nullable(String),
          );
    yield r'quiet_start_local';
    yield object.quietStartLocal == null
        ? null
        : serializers.serialize(
            object.quietStartLocal,
            specifiedType: const FullType.nullable(String),
          );
    yield r'reward_enabled';
    yield serializers.serialize(
      object.rewardEnabled,
      specifiedType: const FullType(bool),
    );
    yield r'streak_enabled';
    yield serializers.serialize(
      object.streakEnabled,
      specifiedType: const FullType(bool),
    );
    yield r'timezone';
    yield serializers.serialize(
      object.timezone,
      specifiedType: const FullType(String),
    );
    yield r'version';
    yield serializers.serialize(
      object.version,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ProfilePreferencesResponse object, {
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
    required ProfilePreferencesResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'accessibility':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(AccessibilityPreferences),
          ) as AccessibilityPreferences;
          result.accessibility.replace(valueDes);
          break;
        case r'lock_screen_detail':
          final valueDes = serializers.deserialize(
            value,
            specifiedType:
                const FullType(ProfilePreferencesResponseLockScreenDetailEnum),
          ) as ProfilePreferencesResponseLockScreenDetailEnum;
          result.lockScreenDetail = valueDes;
          break;
        case r'max_daily_reminders':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.maxDailyReminders = valueDes;
          break;
        case r'mission_enabled':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.missionEnabled = valueDes;
          break;
        case r'notifications_enabled':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.notificationsEnabled = valueDes;
          break;
        case r'preferred_window_end_local':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.preferredWindowEndLocal = valueDes;
          break;
        case r'preferred_window_start_local':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.preferredWindowStartLocal = valueDes;
          break;
        case r'quiet_end_local':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.quietEndLocal = valueDes;
          break;
        case r'quiet_start_local':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.quietStartLocal = valueDes;
          break;
        case r'reward_enabled':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.rewardEnabled = valueDes;
          break;
        case r'streak_enabled':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.streakEnabled = valueDes;
          break;
        case r'timezone':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.timezone = valueDes;
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
  ProfilePreferencesResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ProfilePreferencesResponseBuilder();
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

class ProfilePreferencesResponseLockScreenDetailEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'minimal')
  static const ProfilePreferencesResponseLockScreenDetailEnum minimal =
      _$profilePreferencesResponseLockScreenDetailEnum_minimal;
  @BuiltValueEnumConst(wireName: r'subject')
  static const ProfilePreferencesResponseLockScreenDetailEnum subject =
      _$profilePreferencesResponseLockScreenDetailEnum_subject;
  @BuiltValueEnumConst(wireName: r'detailed')
  static const ProfilePreferencesResponseLockScreenDetailEnum detailed =
      _$profilePreferencesResponseLockScreenDetailEnum_detailed;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const ProfilePreferencesResponseLockScreenDetailEnum
      unknownDefaultOpenApi =
      _$profilePreferencesResponseLockScreenDetailEnum_unknownDefaultOpenApi;

  static Serializer<ProfilePreferencesResponseLockScreenDetailEnum>
      get serializer =>
          _$profilePreferencesResponseLockScreenDetailEnumSerializer;

  const ProfilePreferencesResponseLockScreenDetailEnum._(String name)
      : super(name);

  static BuiltSet<ProfilePreferencesResponseLockScreenDetailEnum> get values =>
      _$profilePreferencesResponseLockScreenDetailEnumValues;
  static ProfilePreferencesResponseLockScreenDetailEnum valueOf(String name) =>
      _$profilePreferencesResponseLockScreenDetailEnumValueOf(name);
}
