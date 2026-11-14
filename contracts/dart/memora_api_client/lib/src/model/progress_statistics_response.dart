//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:memora_api_client/src/model/date.dart';
import 'package:memora_api_client/src/model/xp_series_point.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'progress_statistics_response.g.dart';

/// ProgressStatisticsResponse
///
/// Properties:
/// * [activeDays]
/// * [memoriesProtected]
/// * [memoriesRepaired]
/// * [missionsCompleted]
/// * [periodEnd]
/// * [periodStart]
/// * [summary]
/// * [timezone]
/// * [xpEarned]
/// * [xpSeries]
@BuiltValue()
abstract class ProgressStatisticsResponse
    implements
        Built<ProgressStatisticsResponse, ProgressStatisticsResponseBuilder> {
  @BuiltValueField(wireName: r'active_days')
  int get activeDays;

  @BuiltValueField(wireName: r'memories_protected')
  int get memoriesProtected;

  @BuiltValueField(wireName: r'memories_repaired')
  int get memoriesRepaired;

  @BuiltValueField(wireName: r'missions_completed')
  int get missionsCompleted;

  @BuiltValueField(wireName: r'period_end')
  Date get periodEnd;

  @BuiltValueField(wireName: r'period_start')
  Date get periodStart;

  @BuiltValueField(wireName: r'summary')
  String get summary;

  @BuiltValueField(wireName: r'timezone')
  String get timezone;

  @BuiltValueField(wireName: r'xp_earned')
  int get xpEarned;

  @BuiltValueField(wireName: r'xp_series')
  BuiltList<XpSeriesPoint> get xpSeries;

  ProgressStatisticsResponse._();

  factory ProgressStatisticsResponse(
          [void updates(ProgressStatisticsResponseBuilder b)]) =
      _$ProgressStatisticsResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ProgressStatisticsResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ProgressStatisticsResponse> get serializer =>
      _$ProgressStatisticsResponseSerializer();
}

class _$ProgressStatisticsResponseSerializer
    implements PrimitiveSerializer<ProgressStatisticsResponse> {
  @override
  final Iterable<Type> types = const [
    ProgressStatisticsResponse,
    _$ProgressStatisticsResponse
  ];

  @override
  final String wireName = r'ProgressStatisticsResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ProgressStatisticsResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'active_days';
    yield serializers.serialize(
      object.activeDays,
      specifiedType: const FullType(int),
    );
    yield r'memories_protected';
    yield serializers.serialize(
      object.memoriesProtected,
      specifiedType: const FullType(int),
    );
    yield r'memories_repaired';
    yield serializers.serialize(
      object.memoriesRepaired,
      specifiedType: const FullType(int),
    );
    yield r'missions_completed';
    yield serializers.serialize(
      object.missionsCompleted,
      specifiedType: const FullType(int),
    );
    yield r'period_end';
    yield serializers.serialize(
      object.periodEnd,
      specifiedType: const FullType(Date),
    );
    yield r'period_start';
    yield serializers.serialize(
      object.periodStart,
      specifiedType: const FullType(Date),
    );
    yield r'summary';
    yield serializers.serialize(
      object.summary,
      specifiedType: const FullType(String),
    );
    yield r'timezone';
    yield serializers.serialize(
      object.timezone,
      specifiedType: const FullType(String),
    );
    yield r'xp_earned';
    yield serializers.serialize(
      object.xpEarned,
      specifiedType: const FullType(int),
    );
    yield r'xp_series';
    yield serializers.serialize(
      object.xpSeries,
      specifiedType: const FullType(BuiltList, [FullType(XpSeriesPoint)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ProgressStatisticsResponse object, {
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
    required ProgressStatisticsResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'active_days':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.activeDays = valueDes;
          break;
        case r'memories_protected':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.memoriesProtected = valueDes;
          break;
        case r'memories_repaired':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.memoriesRepaired = valueDes;
          break;
        case r'missions_completed':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.missionsCompleted = valueDes;
          break;
        case r'period_end':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Date),
          ) as Date;
          result.periodEnd = valueDes;
          break;
        case r'period_start':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Date),
          ) as Date;
          result.periodStart = valueDes;
          break;
        case r'summary':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.summary = valueDes;
          break;
        case r'timezone':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.timezone = valueDes;
          break;
        case r'xp_earned':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.xpEarned = valueDes;
          break;
        case r'xp_series':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(XpSeriesPoint)]),
          ) as BuiltList<XpSeriesPoint>;
          result.xpSeries.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ProgressStatisticsResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ProgressStatisticsResponseBuilder();
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
