// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'evidence_summary.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const EvidenceSummaryConfidenceBandEnum
    _$evidenceSummaryConfidenceBandEnum_high =
    const EvidenceSummaryConfidenceBandEnum._('high');
const EvidenceSummaryConfidenceBandEnum
    _$evidenceSummaryConfidenceBandEnum_medium =
    const EvidenceSummaryConfidenceBandEnum._('medium');
const EvidenceSummaryConfidenceBandEnum
    _$evidenceSummaryConfidenceBandEnum_low =
    const EvidenceSummaryConfidenceBandEnum._('low');
const EvidenceSummaryConfidenceBandEnum
    _$evidenceSummaryConfidenceBandEnum_unknownDefaultOpenApi =
    const EvidenceSummaryConfidenceBandEnum._('unknownDefaultOpenApi');

EvidenceSummaryConfidenceBandEnum _$evidenceSummaryConfidenceBandEnumValueOf(
    String name) {
  switch (name) {
    case 'high':
      return _$evidenceSummaryConfidenceBandEnum_high;
    case 'medium':
      return _$evidenceSummaryConfidenceBandEnum_medium;
    case 'low':
      return _$evidenceSummaryConfidenceBandEnum_low;
    case 'unknownDefaultOpenApi':
      return _$evidenceSummaryConfidenceBandEnum_unknownDefaultOpenApi;
    default:
      return _$evidenceSummaryConfidenceBandEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<EvidenceSummaryConfidenceBandEnum>
    _$evidenceSummaryConfidenceBandEnumValues = BuiltSet<
        EvidenceSummaryConfidenceBandEnum>(const <EvidenceSummaryConfidenceBandEnum>[
  _$evidenceSummaryConfidenceBandEnum_high,
  _$evidenceSummaryConfidenceBandEnum_medium,
  _$evidenceSummaryConfidenceBandEnum_low,
  _$evidenceSummaryConfidenceBandEnum_unknownDefaultOpenApi,
]);

Serializer<EvidenceSummaryConfidenceBandEnum>
    _$evidenceSummaryConfidenceBandEnumSerializer =
    _$EvidenceSummaryConfidenceBandEnumSerializer();

class _$EvidenceSummaryConfidenceBandEnumSerializer
    implements PrimitiveSerializer<EvidenceSummaryConfidenceBandEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'high': 'high',
    'medium': 'medium',
    'low': 'low',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'high': 'high',
    'medium': 'medium',
    'low': 'low',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[EvidenceSummaryConfidenceBandEnum];
  @override
  final String wireName = 'EvidenceSummaryConfidenceBandEnum';

  @override
  Object serialize(
          Serializers serializers, EvidenceSummaryConfidenceBandEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  EvidenceSummaryConfidenceBandEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      EvidenceSummaryConfidenceBandEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$EvidenceSummary extends EvidenceSummary {
  @override
  final EvidenceSummaryConfidenceBandEnum confidenceBand;
  @override
  final BuiltMap<String, int> countsByType;
  @override
  final int eligibleEvents;
  @override
  final String? lastObservedAt;
  @override
  final int recentEvents;
  @override
  final int totalEvents;
  @override
  final int windowDays;

  factory _$EvidenceSummary([void Function(EvidenceSummaryBuilder)? updates]) =>
      (EvidenceSummaryBuilder()..update(updates))._build();

  _$EvidenceSummary._(
      {required this.confidenceBand,
      required this.countsByType,
      required this.eligibleEvents,
      this.lastObservedAt,
      required this.recentEvents,
      required this.totalEvents,
      required this.windowDays})
      : super._();
  @override
  EvidenceSummary rebuild(void Function(EvidenceSummaryBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  EvidenceSummaryBuilder toBuilder() => EvidenceSummaryBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is EvidenceSummary &&
        confidenceBand == other.confidenceBand &&
        countsByType == other.countsByType &&
        eligibleEvents == other.eligibleEvents &&
        lastObservedAt == other.lastObservedAt &&
        recentEvents == other.recentEvents &&
        totalEvents == other.totalEvents &&
        windowDays == other.windowDays;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, confidenceBand.hashCode);
    _$hash = $jc(_$hash, countsByType.hashCode);
    _$hash = $jc(_$hash, eligibleEvents.hashCode);
    _$hash = $jc(_$hash, lastObservedAt.hashCode);
    _$hash = $jc(_$hash, recentEvents.hashCode);
    _$hash = $jc(_$hash, totalEvents.hashCode);
    _$hash = $jc(_$hash, windowDays.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'EvidenceSummary')
          ..add('confidenceBand', confidenceBand)
          ..add('countsByType', countsByType)
          ..add('eligibleEvents', eligibleEvents)
          ..add('lastObservedAt', lastObservedAt)
          ..add('recentEvents', recentEvents)
          ..add('totalEvents', totalEvents)
          ..add('windowDays', windowDays))
        .toString();
  }
}

class EvidenceSummaryBuilder
    implements Builder<EvidenceSummary, EvidenceSummaryBuilder> {
  _$EvidenceSummary? _$v;

  EvidenceSummaryConfidenceBandEnum? _confidenceBand;
  EvidenceSummaryConfidenceBandEnum? get confidenceBand =>
      _$this._confidenceBand;
  set confidenceBand(EvidenceSummaryConfidenceBandEnum? confidenceBand) =>
      _$this._confidenceBand = confidenceBand;

  MapBuilder<String, int>? _countsByType;
  MapBuilder<String, int> get countsByType =>
      _$this._countsByType ??= MapBuilder<String, int>();
  set countsByType(MapBuilder<String, int>? countsByType) =>
      _$this._countsByType = countsByType;

  int? _eligibleEvents;
  int? get eligibleEvents => _$this._eligibleEvents;
  set eligibleEvents(int? eligibleEvents) =>
      _$this._eligibleEvents = eligibleEvents;

  String? _lastObservedAt;
  String? get lastObservedAt => _$this._lastObservedAt;
  set lastObservedAt(String? lastObservedAt) =>
      _$this._lastObservedAt = lastObservedAt;

  int? _recentEvents;
  int? get recentEvents => _$this._recentEvents;
  set recentEvents(int? recentEvents) => _$this._recentEvents = recentEvents;

  int? _totalEvents;
  int? get totalEvents => _$this._totalEvents;
  set totalEvents(int? totalEvents) => _$this._totalEvents = totalEvents;

  int? _windowDays;
  int? get windowDays => _$this._windowDays;
  set windowDays(int? windowDays) => _$this._windowDays = windowDays;

  EvidenceSummaryBuilder() {
    EvidenceSummary._defaults(this);
  }

  EvidenceSummaryBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _confidenceBand = $v.confidenceBand;
      _countsByType = $v.countsByType.toBuilder();
      _eligibleEvents = $v.eligibleEvents;
      _lastObservedAt = $v.lastObservedAt;
      _recentEvents = $v.recentEvents;
      _totalEvents = $v.totalEvents;
      _windowDays = $v.windowDays;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(EvidenceSummary other) {
    _$v = other as _$EvidenceSummary;
  }

  @override
  void update(void Function(EvidenceSummaryBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  EvidenceSummary build() => _build();

  _$EvidenceSummary _build() {
    _$EvidenceSummary _$result;
    try {
      _$result = _$v ??
          _$EvidenceSummary._(
            confidenceBand: BuiltValueNullFieldError.checkNotNull(
                confidenceBand, r'EvidenceSummary', 'confidenceBand'),
            countsByType: countsByType.build(),
            eligibleEvents: BuiltValueNullFieldError.checkNotNull(
                eligibleEvents, r'EvidenceSummary', 'eligibleEvents'),
            lastObservedAt: lastObservedAt,
            recentEvents: BuiltValueNullFieldError.checkNotNull(
                recentEvents, r'EvidenceSummary', 'recentEvents'),
            totalEvents: BuiltValueNullFieldError.checkNotNull(
                totalEvents, r'EvidenceSummary', 'totalEvents'),
            windowDays: BuiltValueNullFieldError.checkNotNull(
                windowDays, r'EvidenceSummary', 'windowDays'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'countsByType';
        countsByType.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'EvidenceSummary', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
