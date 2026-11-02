// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'concept_history_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const ConceptHistoryResponseStateBandEnum
    _$conceptHistoryResponseStateBandEnum_fresh =
    const ConceptHistoryResponseStateBandEnum._('fresh');
const ConceptHistoryResponseStateBandEnum
    _$conceptHistoryResponseStateBandEnum_settling =
    const ConceptHistoryResponseStateBandEnum._('settling');
const ConceptHistoryResponseStateBandEnum
    _$conceptHistoryResponseStateBandEnum_fading =
    const ConceptHistoryResponseStateBandEnum._('fading');
const ConceptHistoryResponseStateBandEnum
    _$conceptHistoryResponseStateBandEnum_critical =
    const ConceptHistoryResponseStateBandEnum._('critical');
const ConceptHistoryResponseStateBandEnum
    _$conceptHistoryResponseStateBandEnum_unknownDefaultOpenApi =
    const ConceptHistoryResponseStateBandEnum._('unknownDefaultOpenApi');

ConceptHistoryResponseStateBandEnum
    _$conceptHistoryResponseStateBandEnumValueOf(String name) {
  switch (name) {
    case 'fresh':
      return _$conceptHistoryResponseStateBandEnum_fresh;
    case 'settling':
      return _$conceptHistoryResponseStateBandEnum_settling;
    case 'fading':
      return _$conceptHistoryResponseStateBandEnum_fading;
    case 'critical':
      return _$conceptHistoryResponseStateBandEnum_critical;
    case 'unknownDefaultOpenApi':
      return _$conceptHistoryResponseStateBandEnum_unknownDefaultOpenApi;
    default:
      return _$conceptHistoryResponseStateBandEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<ConceptHistoryResponseStateBandEnum>
    _$conceptHistoryResponseStateBandEnumValues = BuiltSet<
        ConceptHistoryResponseStateBandEnum>(const <ConceptHistoryResponseStateBandEnum>[
  _$conceptHistoryResponseStateBandEnum_fresh,
  _$conceptHistoryResponseStateBandEnum_settling,
  _$conceptHistoryResponseStateBandEnum_fading,
  _$conceptHistoryResponseStateBandEnum_critical,
  _$conceptHistoryResponseStateBandEnum_unknownDefaultOpenApi,
]);

Serializer<ConceptHistoryResponseStateBandEnum>
    _$conceptHistoryResponseStateBandEnumSerializer =
    _$ConceptHistoryResponseStateBandEnumSerializer();

class _$ConceptHistoryResponseStateBandEnumSerializer
    implements PrimitiveSerializer<ConceptHistoryResponseStateBandEnum> {
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
  final Iterable<Type> types = const <Type>[
    ConceptHistoryResponseStateBandEnum
  ];
  @override
  final String wireName = 'ConceptHistoryResponseStateBandEnum';

  @override
  Object serialize(
          Serializers serializers, ConceptHistoryResponseStateBandEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  ConceptHistoryResponseStateBandEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      ConceptHistoryResponseStateBandEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$ConceptHistoryResponse extends ConceptHistoryResponse {
  @override
  final String conceptId;
  @override
  final String conceptVersionId;
  @override
  final EvidenceSummary evidence;
  @override
  final bool hasMore;
  @override
  final BuiltList<SchedulingExplanation> items;
  @override
  final String? nextCursor;
  @override
  final String nextReviewAt;
  @override
  final String stableCode;
  @override
  final ConceptHistoryResponseStateBandEnum stateBand;
  @override
  final String title;

  factory _$ConceptHistoryResponse(
          [void Function(ConceptHistoryResponseBuilder)? updates]) =>
      (ConceptHistoryResponseBuilder()..update(updates))._build();

  _$ConceptHistoryResponse._(
      {required this.conceptId,
      required this.conceptVersionId,
      required this.evidence,
      required this.hasMore,
      required this.items,
      this.nextCursor,
      required this.nextReviewAt,
      required this.stableCode,
      required this.stateBand,
      required this.title})
      : super._();
  @override
  ConceptHistoryResponse rebuild(
          void Function(ConceptHistoryResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ConceptHistoryResponseBuilder toBuilder() =>
      ConceptHistoryResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ConceptHistoryResponse &&
        conceptId == other.conceptId &&
        conceptVersionId == other.conceptVersionId &&
        evidence == other.evidence &&
        hasMore == other.hasMore &&
        items == other.items &&
        nextCursor == other.nextCursor &&
        nextReviewAt == other.nextReviewAt &&
        stableCode == other.stableCode &&
        stateBand == other.stateBand &&
        title == other.title;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, conceptId.hashCode);
    _$hash = $jc(_$hash, conceptVersionId.hashCode);
    _$hash = $jc(_$hash, evidence.hashCode);
    _$hash = $jc(_$hash, hasMore.hashCode);
    _$hash = $jc(_$hash, items.hashCode);
    _$hash = $jc(_$hash, nextCursor.hashCode);
    _$hash = $jc(_$hash, nextReviewAt.hashCode);
    _$hash = $jc(_$hash, stableCode.hashCode);
    _$hash = $jc(_$hash, stateBand.hashCode);
    _$hash = $jc(_$hash, title.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ConceptHistoryResponse')
          ..add('conceptId', conceptId)
          ..add('conceptVersionId', conceptVersionId)
          ..add('evidence', evidence)
          ..add('hasMore', hasMore)
          ..add('items', items)
          ..add('nextCursor', nextCursor)
          ..add('nextReviewAt', nextReviewAt)
          ..add('stableCode', stableCode)
          ..add('stateBand', stateBand)
          ..add('title', title))
        .toString();
  }
}

class ConceptHistoryResponseBuilder
    implements Builder<ConceptHistoryResponse, ConceptHistoryResponseBuilder> {
  _$ConceptHistoryResponse? _$v;

  String? _conceptId;
  String? get conceptId => _$this._conceptId;
  set conceptId(String? conceptId) => _$this._conceptId = conceptId;

  String? _conceptVersionId;
  String? get conceptVersionId => _$this._conceptVersionId;
  set conceptVersionId(String? conceptVersionId) =>
      _$this._conceptVersionId = conceptVersionId;

  EvidenceSummaryBuilder? _evidence;
  EvidenceSummaryBuilder get evidence =>
      _$this._evidence ??= EvidenceSummaryBuilder();
  set evidence(EvidenceSummaryBuilder? evidence) => _$this._evidence = evidence;

  bool? _hasMore;
  bool? get hasMore => _$this._hasMore;
  set hasMore(bool? hasMore) => _$this._hasMore = hasMore;

  ListBuilder<SchedulingExplanation>? _items;
  ListBuilder<SchedulingExplanation> get items =>
      _$this._items ??= ListBuilder<SchedulingExplanation>();
  set items(ListBuilder<SchedulingExplanation>? items) => _$this._items = items;

  String? _nextCursor;
  String? get nextCursor => _$this._nextCursor;
  set nextCursor(String? nextCursor) => _$this._nextCursor = nextCursor;

  String? _nextReviewAt;
  String? get nextReviewAt => _$this._nextReviewAt;
  set nextReviewAt(String? nextReviewAt) => _$this._nextReviewAt = nextReviewAt;

  String? _stableCode;
  String? get stableCode => _$this._stableCode;
  set stableCode(String? stableCode) => _$this._stableCode = stableCode;

  ConceptHistoryResponseStateBandEnum? _stateBand;
  ConceptHistoryResponseStateBandEnum? get stateBand => _$this._stateBand;
  set stateBand(ConceptHistoryResponseStateBandEnum? stateBand) =>
      _$this._stateBand = stateBand;

  String? _title;
  String? get title => _$this._title;
  set title(String? title) => _$this._title = title;

  ConceptHistoryResponseBuilder() {
    ConceptHistoryResponse._defaults(this);
  }

  ConceptHistoryResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _conceptId = $v.conceptId;
      _conceptVersionId = $v.conceptVersionId;
      _evidence = $v.evidence.toBuilder();
      _hasMore = $v.hasMore;
      _items = $v.items.toBuilder();
      _nextCursor = $v.nextCursor;
      _nextReviewAt = $v.nextReviewAt;
      _stableCode = $v.stableCode;
      _stateBand = $v.stateBand;
      _title = $v.title;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ConceptHistoryResponse other) {
    _$v = other as _$ConceptHistoryResponse;
  }

  @override
  void update(void Function(ConceptHistoryResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ConceptHistoryResponse build() => _build();

  _$ConceptHistoryResponse _build() {
    _$ConceptHistoryResponse _$result;
    try {
      _$result = _$v ??
          _$ConceptHistoryResponse._(
            conceptId: BuiltValueNullFieldError.checkNotNull(
                conceptId, r'ConceptHistoryResponse', 'conceptId'),
            conceptVersionId: BuiltValueNullFieldError.checkNotNull(
                conceptVersionId,
                r'ConceptHistoryResponse',
                'conceptVersionId'),
            evidence: evidence.build(),
            hasMore: BuiltValueNullFieldError.checkNotNull(
                hasMore, r'ConceptHistoryResponse', 'hasMore'),
            items: items.build(),
            nextCursor: nextCursor,
            nextReviewAt: BuiltValueNullFieldError.checkNotNull(
                nextReviewAt, r'ConceptHistoryResponse', 'nextReviewAt'),
            stableCode: BuiltValueNullFieldError.checkNotNull(
                stableCode, r'ConceptHistoryResponse', 'stableCode'),
            stateBand: BuiltValueNullFieldError.checkNotNull(
                stateBand, r'ConceptHistoryResponse', 'stateBand'),
            title: BuiltValueNullFieldError.checkNotNull(
                title, r'ConceptHistoryResponse', 'title'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'evidence';
        evidence.build();

        _$failedField = 'items';
        items.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'ConceptHistoryResponse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
