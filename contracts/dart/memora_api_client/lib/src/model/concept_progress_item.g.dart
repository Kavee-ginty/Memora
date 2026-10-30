// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'concept_progress_item.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const ConceptProgressItemConfidenceBandEnum
    _$conceptProgressItemConfidenceBandEnum_high =
    const ConceptProgressItemConfidenceBandEnum._('high');
const ConceptProgressItemConfidenceBandEnum
    _$conceptProgressItemConfidenceBandEnum_medium =
    const ConceptProgressItemConfidenceBandEnum._('medium');
const ConceptProgressItemConfidenceBandEnum
    _$conceptProgressItemConfidenceBandEnum_low =
    const ConceptProgressItemConfidenceBandEnum._('low');
const ConceptProgressItemConfidenceBandEnum
    _$conceptProgressItemConfidenceBandEnum_unknownDefaultOpenApi =
    const ConceptProgressItemConfidenceBandEnum._('unknownDefaultOpenApi');

ConceptProgressItemConfidenceBandEnum
    _$conceptProgressItemConfidenceBandEnumValueOf(String name) {
  switch (name) {
    case 'high':
      return _$conceptProgressItemConfidenceBandEnum_high;
    case 'medium':
      return _$conceptProgressItemConfidenceBandEnum_medium;
    case 'low':
      return _$conceptProgressItemConfidenceBandEnum_low;
    case 'unknownDefaultOpenApi':
      return _$conceptProgressItemConfidenceBandEnum_unknownDefaultOpenApi;
    default:
      return _$conceptProgressItemConfidenceBandEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<ConceptProgressItemConfidenceBandEnum>
    _$conceptProgressItemConfidenceBandEnumValues = BuiltSet<
        ConceptProgressItemConfidenceBandEnum>(const <ConceptProgressItemConfidenceBandEnum>[
  _$conceptProgressItemConfidenceBandEnum_high,
  _$conceptProgressItemConfidenceBandEnum_medium,
  _$conceptProgressItemConfidenceBandEnum_low,
  _$conceptProgressItemConfidenceBandEnum_unknownDefaultOpenApi,
]);

const ConceptProgressItemReviewWindowEnum
    _$conceptProgressItemReviewWindowEnum_overdue =
    const ConceptProgressItemReviewWindowEnum._('overdue');
const ConceptProgressItemReviewWindowEnum
    _$conceptProgressItemReviewWindowEnum_due =
    const ConceptProgressItemReviewWindowEnum._('due');
const ConceptProgressItemReviewWindowEnum
    _$conceptProgressItemReviewWindowEnum_nearDue =
    const ConceptProgressItemReviewWindowEnum._('nearDue');
const ConceptProgressItemReviewWindowEnum
    _$conceptProgressItemReviewWindowEnum_unknownDefaultOpenApi =
    const ConceptProgressItemReviewWindowEnum._('unknownDefaultOpenApi');

ConceptProgressItemReviewWindowEnum
    _$conceptProgressItemReviewWindowEnumValueOf(String name) {
  switch (name) {
    case 'overdue':
      return _$conceptProgressItemReviewWindowEnum_overdue;
    case 'due':
      return _$conceptProgressItemReviewWindowEnum_due;
    case 'nearDue':
      return _$conceptProgressItemReviewWindowEnum_nearDue;
    case 'unknownDefaultOpenApi':
      return _$conceptProgressItemReviewWindowEnum_unknownDefaultOpenApi;
    default:
      return _$conceptProgressItemReviewWindowEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<ConceptProgressItemReviewWindowEnum>
    _$conceptProgressItemReviewWindowEnumValues = BuiltSet<
        ConceptProgressItemReviewWindowEnum>(const <ConceptProgressItemReviewWindowEnum>[
  _$conceptProgressItemReviewWindowEnum_overdue,
  _$conceptProgressItemReviewWindowEnum_due,
  _$conceptProgressItemReviewWindowEnum_nearDue,
  _$conceptProgressItemReviewWindowEnum_unknownDefaultOpenApi,
]);

const ConceptProgressItemStateBandEnum
    _$conceptProgressItemStateBandEnum_fresh =
    const ConceptProgressItemStateBandEnum._('fresh');
const ConceptProgressItemStateBandEnum
    _$conceptProgressItemStateBandEnum_settling =
    const ConceptProgressItemStateBandEnum._('settling');
const ConceptProgressItemStateBandEnum
    _$conceptProgressItemStateBandEnum_fading =
    const ConceptProgressItemStateBandEnum._('fading');
const ConceptProgressItemStateBandEnum
    _$conceptProgressItemStateBandEnum_critical =
    const ConceptProgressItemStateBandEnum._('critical');
const ConceptProgressItemStateBandEnum
    _$conceptProgressItemStateBandEnum_unknownDefaultOpenApi =
    const ConceptProgressItemStateBandEnum._('unknownDefaultOpenApi');

ConceptProgressItemStateBandEnum _$conceptProgressItemStateBandEnumValueOf(
    String name) {
  switch (name) {
    case 'fresh':
      return _$conceptProgressItemStateBandEnum_fresh;
    case 'settling':
      return _$conceptProgressItemStateBandEnum_settling;
    case 'fading':
      return _$conceptProgressItemStateBandEnum_fading;
    case 'critical':
      return _$conceptProgressItemStateBandEnum_critical;
    case 'unknownDefaultOpenApi':
      return _$conceptProgressItemStateBandEnum_unknownDefaultOpenApi;
    default:
      return _$conceptProgressItemStateBandEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<ConceptProgressItemStateBandEnum>
    _$conceptProgressItemStateBandEnumValues = BuiltSet<
        ConceptProgressItemStateBandEnum>(const <ConceptProgressItemStateBandEnum>[
  _$conceptProgressItemStateBandEnum_fresh,
  _$conceptProgressItemStateBandEnum_settling,
  _$conceptProgressItemStateBandEnum_fading,
  _$conceptProgressItemStateBandEnum_critical,
  _$conceptProgressItemStateBandEnum_unknownDefaultOpenApi,
]);

Serializer<ConceptProgressItemConfidenceBandEnum>
    _$conceptProgressItemConfidenceBandEnumSerializer =
    _$ConceptProgressItemConfidenceBandEnumSerializer();
Serializer<ConceptProgressItemReviewWindowEnum>
    _$conceptProgressItemReviewWindowEnumSerializer =
    _$ConceptProgressItemReviewWindowEnumSerializer();
Serializer<ConceptProgressItemStateBandEnum>
    _$conceptProgressItemStateBandEnumSerializer =
    _$ConceptProgressItemStateBandEnumSerializer();

class _$ConceptProgressItemConfidenceBandEnumSerializer
    implements PrimitiveSerializer<ConceptProgressItemConfidenceBandEnum> {
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
  final Iterable<Type> types = const <Type>[
    ConceptProgressItemConfidenceBandEnum
  ];
  @override
  final String wireName = 'ConceptProgressItemConfidenceBandEnum';

  @override
  Object serialize(
          Serializers serializers, ConceptProgressItemConfidenceBandEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  ConceptProgressItemConfidenceBandEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      ConceptProgressItemConfidenceBandEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$ConceptProgressItemReviewWindowEnumSerializer
    implements PrimitiveSerializer<ConceptProgressItemReviewWindowEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'overdue': 'overdue',
    'due': 'due',
    'nearDue': 'near_due',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'overdue': 'overdue',
    'due': 'due',
    'near_due': 'nearDue',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[
    ConceptProgressItemReviewWindowEnum
  ];
  @override
  final String wireName = 'ConceptProgressItemReviewWindowEnum';

  @override
  Object serialize(
          Serializers serializers, ConceptProgressItemReviewWindowEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  ConceptProgressItemReviewWindowEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      ConceptProgressItemReviewWindowEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$ConceptProgressItemStateBandEnumSerializer
    implements PrimitiveSerializer<ConceptProgressItemStateBandEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'fresh': 'fresh',
    'settling': 'settling',
    'fading': 'fading',
    'critical': 'critical',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'fresh': 'fresh',
    'settling': 'settling',
    'fading': 'fading',
    'critical': 'critical',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[ConceptProgressItemStateBandEnum];
  @override
  final String wireName = 'ConceptProgressItemStateBandEnum';

  @override
  Object serialize(
          Serializers serializers, ConceptProgressItemStateBandEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  ConceptProgressItemStateBandEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      ConceptProgressItemStateBandEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$ConceptProgressItem extends ConceptProgressItem {
  @override
  final String conceptId;
  @override
  final String conceptVersionId;
  @override
  final ConceptProgressItemConfidenceBandEnum confidenceBand;
  @override
  final DueReasonExplanation dueReason;
  @override
  final int eligibleReviewCount;
  @override
  final int exposureCount;
  @override
  final bool isComeback;
  @override
  final bool isNewConcept;
  @override
  final int lapseCount;
  @override
  final String? lastReviewedAt;
  @override
  final String nextReviewAt;
  @override
  final ConceptProgressItemReviewWindowEnum reviewWindow;
  @override
  final String stableCode;
  @override
  final ConceptProgressItemStateBandEnum stateBand;
  @override
  final String title;

  factory _$ConceptProgressItem(
          [void Function(ConceptProgressItemBuilder)? updates]) =>
      (ConceptProgressItemBuilder()..update(updates))._build();

  _$ConceptProgressItem._(
      {required this.conceptId,
      required this.conceptVersionId,
      required this.confidenceBand,
      required this.dueReason,
      required this.eligibleReviewCount,
      required this.exposureCount,
      required this.isComeback,
      required this.isNewConcept,
      required this.lapseCount,
      this.lastReviewedAt,
      required this.nextReviewAt,
      required this.reviewWindow,
      required this.stableCode,
      required this.stateBand,
      required this.title})
      : super._();
  @override
  ConceptProgressItem rebuild(
          void Function(ConceptProgressItemBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ConceptProgressItemBuilder toBuilder() =>
      ConceptProgressItemBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ConceptProgressItem &&
        conceptId == other.conceptId &&
        conceptVersionId == other.conceptVersionId &&
        confidenceBand == other.confidenceBand &&
        dueReason == other.dueReason &&
        eligibleReviewCount == other.eligibleReviewCount &&
        exposureCount == other.exposureCount &&
        isComeback == other.isComeback &&
        isNewConcept == other.isNewConcept &&
        lapseCount == other.lapseCount &&
        lastReviewedAt == other.lastReviewedAt &&
        nextReviewAt == other.nextReviewAt &&
        reviewWindow == other.reviewWindow &&
        stableCode == other.stableCode &&
        stateBand == other.stateBand &&
        title == other.title;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, conceptId.hashCode);
    _$hash = $jc(_$hash, conceptVersionId.hashCode);
    _$hash = $jc(_$hash, confidenceBand.hashCode);
    _$hash = $jc(_$hash, dueReason.hashCode);
    _$hash = $jc(_$hash, eligibleReviewCount.hashCode);
    _$hash = $jc(_$hash, exposureCount.hashCode);
    _$hash = $jc(_$hash, isComeback.hashCode);
    _$hash = $jc(_$hash, isNewConcept.hashCode);
    _$hash = $jc(_$hash, lapseCount.hashCode);
    _$hash = $jc(_$hash, lastReviewedAt.hashCode);
    _$hash = $jc(_$hash, nextReviewAt.hashCode);
    _$hash = $jc(_$hash, reviewWindow.hashCode);
    _$hash = $jc(_$hash, stableCode.hashCode);
    _$hash = $jc(_$hash, stateBand.hashCode);
    _$hash = $jc(_$hash, title.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ConceptProgressItem')
          ..add('conceptId', conceptId)
          ..add('conceptVersionId', conceptVersionId)
          ..add('confidenceBand', confidenceBand)
          ..add('dueReason', dueReason)
          ..add('eligibleReviewCount', eligibleReviewCount)
          ..add('exposureCount', exposureCount)
          ..add('isComeback', isComeback)
          ..add('isNewConcept', isNewConcept)
          ..add('lapseCount', lapseCount)
          ..add('lastReviewedAt', lastReviewedAt)
          ..add('nextReviewAt', nextReviewAt)
          ..add('reviewWindow', reviewWindow)
          ..add('stableCode', stableCode)
          ..add('stateBand', stateBand)
          ..add('title', title))
        .toString();
  }
}

class ConceptProgressItemBuilder
    implements Builder<ConceptProgressItem, ConceptProgressItemBuilder> {
  _$ConceptProgressItem? _$v;

  String? _conceptId;
  String? get conceptId => _$this._conceptId;
  set conceptId(String? conceptId) => _$this._conceptId = conceptId;

  String? _conceptVersionId;
  String? get conceptVersionId => _$this._conceptVersionId;
  set conceptVersionId(String? conceptVersionId) =>
      _$this._conceptVersionId = conceptVersionId;

  ConceptProgressItemConfidenceBandEnum? _confidenceBand;
  ConceptProgressItemConfidenceBandEnum? get confidenceBand =>
      _$this._confidenceBand;
  set confidenceBand(ConceptProgressItemConfidenceBandEnum? confidenceBand) =>
      _$this._confidenceBand = confidenceBand;

  DueReasonExplanationBuilder? _dueReason;
  DueReasonExplanationBuilder get dueReason =>
      _$this._dueReason ??= DueReasonExplanationBuilder();
  set dueReason(DueReasonExplanationBuilder? dueReason) =>
      _$this._dueReason = dueReason;

  int? _eligibleReviewCount;
  int? get eligibleReviewCount => _$this._eligibleReviewCount;
  set eligibleReviewCount(int? eligibleReviewCount) =>
      _$this._eligibleReviewCount = eligibleReviewCount;

  int? _exposureCount;
  int? get exposureCount => _$this._exposureCount;
  set exposureCount(int? exposureCount) =>
      _$this._exposureCount = exposureCount;

  bool? _isComeback;
  bool? get isComeback => _$this._isComeback;
  set isComeback(bool? isComeback) => _$this._isComeback = isComeback;

  bool? _isNewConcept;
  bool? get isNewConcept => _$this._isNewConcept;
  set isNewConcept(bool? isNewConcept) => _$this._isNewConcept = isNewConcept;

  int? _lapseCount;
  int? get lapseCount => _$this._lapseCount;
  set lapseCount(int? lapseCount) => _$this._lapseCount = lapseCount;

  String? _lastReviewedAt;
  String? get lastReviewedAt => _$this._lastReviewedAt;
  set lastReviewedAt(String? lastReviewedAt) =>
      _$this._lastReviewedAt = lastReviewedAt;

  String? _nextReviewAt;
  String? get nextReviewAt => _$this._nextReviewAt;
  set nextReviewAt(String? nextReviewAt) => _$this._nextReviewAt = nextReviewAt;

  ConceptProgressItemReviewWindowEnum? _reviewWindow;
  ConceptProgressItemReviewWindowEnum? get reviewWindow => _$this._reviewWindow;
  set reviewWindow(ConceptProgressItemReviewWindowEnum? reviewWindow) =>
      _$this._reviewWindow = reviewWindow;

  String? _stableCode;
  String? get stableCode => _$this._stableCode;
  set stableCode(String? stableCode) => _$this._stableCode = stableCode;

  ConceptProgressItemStateBandEnum? _stateBand;
  ConceptProgressItemStateBandEnum? get stateBand => _$this._stateBand;
  set stateBand(ConceptProgressItemStateBandEnum? stateBand) =>
      _$this._stateBand = stateBand;

  String? _title;
  String? get title => _$this._title;
  set title(String? title) => _$this._title = title;

  ConceptProgressItemBuilder() {
    ConceptProgressItem._defaults(this);
  }

  ConceptProgressItemBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _conceptId = $v.conceptId;
      _conceptVersionId = $v.conceptVersionId;
      _confidenceBand = $v.confidenceBand;
      _dueReason = $v.dueReason.toBuilder();
      _eligibleReviewCount = $v.eligibleReviewCount;
      _exposureCount = $v.exposureCount;
      _isComeback = $v.isComeback;
      _isNewConcept = $v.isNewConcept;
      _lapseCount = $v.lapseCount;
      _lastReviewedAt = $v.lastReviewedAt;
      _nextReviewAt = $v.nextReviewAt;
      _reviewWindow = $v.reviewWindow;
      _stableCode = $v.stableCode;
      _stateBand = $v.stateBand;
      _title = $v.title;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ConceptProgressItem other) {
    _$v = other as _$ConceptProgressItem;
  }

  @override
  void update(void Function(ConceptProgressItemBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ConceptProgressItem build() => _build();

  _$ConceptProgressItem _build() {
    _$ConceptProgressItem _$result;
    try {
      _$result = _$v ??
          _$ConceptProgressItem._(
            conceptId: BuiltValueNullFieldError.checkNotNull(
                conceptId, r'ConceptProgressItem', 'conceptId'),
            conceptVersionId: BuiltValueNullFieldError.checkNotNull(
                conceptVersionId, r'ConceptProgressItem', 'conceptVersionId'),
            confidenceBand: BuiltValueNullFieldError.checkNotNull(
                confidenceBand, r'ConceptProgressItem', 'confidenceBand'),
            dueReason: dueReason.build(),
            eligibleReviewCount: BuiltValueNullFieldError.checkNotNull(
                eligibleReviewCount,
                r'ConceptProgressItem',
                'eligibleReviewCount'),
            exposureCount: BuiltValueNullFieldError.checkNotNull(
                exposureCount, r'ConceptProgressItem', 'exposureCount'),
            isComeback: BuiltValueNullFieldError.checkNotNull(
                isComeback, r'ConceptProgressItem', 'isComeback'),
            isNewConcept: BuiltValueNullFieldError.checkNotNull(
                isNewConcept, r'ConceptProgressItem', 'isNewConcept'),
            lapseCount: BuiltValueNullFieldError.checkNotNull(
                lapseCount, r'ConceptProgressItem', 'lapseCount'),
            lastReviewedAt: lastReviewedAt,
            nextReviewAt: BuiltValueNullFieldError.checkNotNull(
                nextReviewAt, r'ConceptProgressItem', 'nextReviewAt'),
            reviewWindow: BuiltValueNullFieldError.checkNotNull(
                reviewWindow, r'ConceptProgressItem', 'reviewWindow'),
            stableCode: BuiltValueNullFieldError.checkNotNull(
                stableCode, r'ConceptProgressItem', 'stableCode'),
            stateBand: BuiltValueNullFieldError.checkNotNull(
                stateBand, r'ConceptProgressItem', 'stateBand'),
            title: BuiltValueNullFieldError.checkNotNull(
                title, r'ConceptProgressItem', 'title'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'dueReason';
        dueReason.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'ConceptProgressItem', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
