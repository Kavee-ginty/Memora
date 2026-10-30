//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'evidence_summary.g.dart';

/// Bounded evidence summary; counts only, never payloads or scores.  All counts are lifetime counts, so ``total_events`` always equals ``sum(counts_by_type.values())``. ``recent_events`` is the subset inside ``window_days``; per-type counts are deliberately not windowed so the summary stays additive and cheap to verify.
///
/// Properties:
/// * [confidenceBand] - Banded evidence confidence; raw values are never returned.
/// * [countsByType] - Lifetime event counts per type; sums to total_events.
/// * [eligibleEvents] - Lifetime events that were eligible for scheduling.
/// * [lastObservedAt] - Most recent evidence timestamp, or null when none is recorded.
/// * [recentEvents] - Evidence events observed inside the recency window.
/// * [totalEvents] - Lifetime recorded evidence events.
/// * [windowDays] - Length of the recency window in days.
@BuiltValue()
abstract class EvidenceSummary
    implements Built<EvidenceSummary, EvidenceSummaryBuilder> {
  /// Banded evidence confidence; raw values are never returned.
  @BuiltValueField(wireName: r'confidence_band')
  EvidenceSummaryConfidenceBandEnum get confidenceBand;
  // enum confidenceBandEnum {  high,  medium,  low,  };

  /// Lifetime event counts per type; sums to total_events.
  @BuiltValueField(wireName: r'counts_by_type')
  BuiltMap<String, int> get countsByType;

  /// Lifetime events that were eligible for scheduling.
  @BuiltValueField(wireName: r'eligible_events')
  int get eligibleEvents;

  /// Most recent evidence timestamp, or null when none is recorded.
  @BuiltValueField(wireName: r'last_observed_at')
  String? get lastObservedAt;

  /// Evidence events observed inside the recency window.
  @BuiltValueField(wireName: r'recent_events')
  int get recentEvents;

  /// Lifetime recorded evidence events.
  @BuiltValueField(wireName: r'total_events')
  int get totalEvents;

  /// Length of the recency window in days.
  @BuiltValueField(wireName: r'window_days')
  int get windowDays;

  EvidenceSummary._();

  factory EvidenceSummary([void updates(EvidenceSummaryBuilder b)]) =
      _$EvidenceSummary;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(EvidenceSummaryBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<EvidenceSummary> get serializer =>
      _$EvidenceSummarySerializer();
}

class _$EvidenceSummarySerializer
    implements PrimitiveSerializer<EvidenceSummary> {
  @override
  final Iterable<Type> types = const [EvidenceSummary, _$EvidenceSummary];

  @override
  final String wireName = r'EvidenceSummary';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    EvidenceSummary object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'confidence_band';
    yield serializers.serialize(
      object.confidenceBand,
      specifiedType: const FullType(EvidenceSummaryConfidenceBandEnum),
    );
    yield r'counts_by_type';
    yield serializers.serialize(
      object.countsByType,
      specifiedType:
          const FullType(BuiltMap, [FullType(String), FullType(int)]),
    );
    yield r'eligible_events';
    yield serializers.serialize(
      object.eligibleEvents,
      specifiedType: const FullType(int),
    );
    yield r'last_observed_at';
    yield object.lastObservedAt == null
        ? null
        : serializers.serialize(
            object.lastObservedAt,
            specifiedType: const FullType.nullable(String),
          );
    yield r'recent_events';
    yield serializers.serialize(
      object.recentEvents,
      specifiedType: const FullType(int),
    );
    yield r'total_events';
    yield serializers.serialize(
      object.totalEvents,
      specifiedType: const FullType(int),
    );
    yield r'window_days';
    yield serializers.serialize(
      object.windowDays,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    EvidenceSummary object, {
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
    required EvidenceSummaryBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'confidence_band':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(EvidenceSummaryConfidenceBandEnum),
          ) as EvidenceSummaryConfidenceBandEnum;
          result.confidenceBand = valueDes;
          break;
        case r'counts_by_type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType:
                const FullType(BuiltMap, [FullType(String), FullType(int)]),
          ) as BuiltMap<String, int>;
          result.countsByType.replace(valueDes);
          break;
        case r'eligible_events':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.eligibleEvents = valueDes;
          break;
        case r'last_observed_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.lastObservedAt = valueDes;
          break;
        case r'recent_events':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.recentEvents = valueDes;
          break;
        case r'total_events':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.totalEvents = valueDes;
          break;
        case r'window_days':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.windowDays = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  EvidenceSummary deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = EvidenceSummaryBuilder();
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

/// Banded evidence confidence; raw values are never returned.
class EvidenceSummaryConfidenceBandEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'high')
  static const EvidenceSummaryConfidenceBandEnum high =
      _$evidenceSummaryConfidenceBandEnum_high;
  @BuiltValueEnumConst(wireName: r'medium')
  static const EvidenceSummaryConfidenceBandEnum medium =
      _$evidenceSummaryConfidenceBandEnum_medium;
  @BuiltValueEnumConst(wireName: r'low')
  static const EvidenceSummaryConfidenceBandEnum low =
      _$evidenceSummaryConfidenceBandEnum_low;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const EvidenceSummaryConfidenceBandEnum unknownDefaultOpenApi =
      _$evidenceSummaryConfidenceBandEnum_unknownDefaultOpenApi;

  static Serializer<EvidenceSummaryConfidenceBandEnum> get serializer =>
      _$evidenceSummaryConfidenceBandEnumSerializer;

  const EvidenceSummaryConfidenceBandEnum._(String name) : super(name);

  static BuiltSet<EvidenceSummaryConfidenceBandEnum> get values =>
      _$evidenceSummaryConfidenceBandEnumValues;
  static EvidenceSummaryConfidenceBandEnum valueOf(String name) =>
      _$evidenceSummaryConfidenceBandEnumValueOf(name);
}
