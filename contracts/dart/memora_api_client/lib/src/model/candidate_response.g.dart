// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'candidate_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const CandidateResponseConfidenceBandEnum
    _$candidateResponseConfidenceBandEnum_high =
    const CandidateResponseConfidenceBandEnum._('high');
const CandidateResponseConfidenceBandEnum
    _$candidateResponseConfidenceBandEnum_medium =
    const CandidateResponseConfidenceBandEnum._('medium');
const CandidateResponseConfidenceBandEnum
    _$candidateResponseConfidenceBandEnum_low =
    const CandidateResponseConfidenceBandEnum._('low');
const CandidateResponseConfidenceBandEnum
    _$candidateResponseConfidenceBandEnum_unknownDefaultOpenApi =
    const CandidateResponseConfidenceBandEnum._('unknownDefaultOpenApi');

CandidateResponseConfidenceBandEnum
    _$candidateResponseConfidenceBandEnumValueOf(String name) {
  switch (name) {
    case 'high':
      return _$candidateResponseConfidenceBandEnum_high;
    case 'medium':
      return _$candidateResponseConfidenceBandEnum_medium;
    case 'low':
      return _$candidateResponseConfidenceBandEnum_low;
    case 'unknownDefaultOpenApi':
      return _$candidateResponseConfidenceBandEnum_unknownDefaultOpenApi;
    default:
      return _$candidateResponseConfidenceBandEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<CandidateResponseConfidenceBandEnum>
    _$candidateResponseConfidenceBandEnumValues = BuiltSet<
        CandidateResponseConfidenceBandEnum>(const <CandidateResponseConfidenceBandEnum>[
  _$candidateResponseConfidenceBandEnum_high,
  _$candidateResponseConfidenceBandEnum_medium,
  _$candidateResponseConfidenceBandEnum_low,
  _$candidateResponseConfidenceBandEnum_unknownDefaultOpenApi,
]);

Serializer<CandidateResponseConfidenceBandEnum>
    _$candidateResponseConfidenceBandEnumSerializer =
    _$CandidateResponseConfidenceBandEnumSerializer();

class _$CandidateResponseConfidenceBandEnumSerializer
    implements PrimitiveSerializer<CandidateResponseConfidenceBandEnum> {
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
    CandidateResponseConfidenceBandEnum
  ];
  @override
  final String wireName = 'CandidateResponseConfidenceBandEnum';

  @override
  Object serialize(
          Serializers serializers, CandidateResponseConfidenceBandEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  CandidateResponseConfidenceBandEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      CandidateResponseConfidenceBandEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$CandidateResponse extends CandidateResponse {
  @override
  final String candidateType;
  @override
  final int candidateVersion;
  @override
  final num confidence;
  @override
  final CandidateResponseConfidenceBandEnum confidenceBand;
  @override
  final String displaySummary;
  @override
  final String displayTitle;
  @override
  final String id;
  @override
  final bool requiresVerification;
  @override
  final BuiltMap<String, JsonObject?> sourceLocator;
  @override
  final CandidateStatus status;

  factory _$CandidateResponse(
          [void Function(CandidateResponseBuilder)? updates]) =>
      (CandidateResponseBuilder()..update(updates))._build();

  _$CandidateResponse._(
      {required this.candidateType,
      required this.candidateVersion,
      required this.confidence,
      required this.confidenceBand,
      required this.displaySummary,
      required this.displayTitle,
      required this.id,
      required this.requiresVerification,
      required this.sourceLocator,
      required this.status})
      : super._();
  @override
  CandidateResponse rebuild(void Function(CandidateResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CandidateResponseBuilder toBuilder() =>
      CandidateResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CandidateResponse &&
        candidateType == other.candidateType &&
        candidateVersion == other.candidateVersion &&
        confidence == other.confidence &&
        confidenceBand == other.confidenceBand &&
        displaySummary == other.displaySummary &&
        displayTitle == other.displayTitle &&
        id == other.id &&
        requiresVerification == other.requiresVerification &&
        sourceLocator == other.sourceLocator &&
        status == other.status;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, candidateType.hashCode);
    _$hash = $jc(_$hash, candidateVersion.hashCode);
    _$hash = $jc(_$hash, confidence.hashCode);
    _$hash = $jc(_$hash, confidenceBand.hashCode);
    _$hash = $jc(_$hash, displaySummary.hashCode);
    _$hash = $jc(_$hash, displayTitle.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, requiresVerification.hashCode);
    _$hash = $jc(_$hash, sourceLocator.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CandidateResponse')
          ..add('candidateType', candidateType)
          ..add('candidateVersion', candidateVersion)
          ..add('confidence', confidence)
          ..add('confidenceBand', confidenceBand)
          ..add('displaySummary', displaySummary)
          ..add('displayTitle', displayTitle)
          ..add('id', id)
          ..add('requiresVerification', requiresVerification)
          ..add('sourceLocator', sourceLocator)
          ..add('status', status))
        .toString();
  }
}

class CandidateResponseBuilder
    implements Builder<CandidateResponse, CandidateResponseBuilder> {
  _$CandidateResponse? _$v;

  String? _candidateType;
  String? get candidateType => _$this._candidateType;
  set candidateType(String? candidateType) =>
      _$this._candidateType = candidateType;

  int? _candidateVersion;
  int? get candidateVersion => _$this._candidateVersion;
  set candidateVersion(int? candidateVersion) =>
      _$this._candidateVersion = candidateVersion;

  num? _confidence;
  num? get confidence => _$this._confidence;
  set confidence(num? confidence) => _$this._confidence = confidence;

  CandidateResponseConfidenceBandEnum? _confidenceBand;
  CandidateResponseConfidenceBandEnum? get confidenceBand =>
      _$this._confidenceBand;
  set confidenceBand(CandidateResponseConfidenceBandEnum? confidenceBand) =>
      _$this._confidenceBand = confidenceBand;

  String? _displaySummary;
  String? get displaySummary => _$this._displaySummary;
  set displaySummary(String? displaySummary) =>
      _$this._displaySummary = displaySummary;

  String? _displayTitle;
  String? get displayTitle => _$this._displayTitle;
  set displayTitle(String? displayTitle) => _$this._displayTitle = displayTitle;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  bool? _requiresVerification;
  bool? get requiresVerification => _$this._requiresVerification;
  set requiresVerification(bool? requiresVerification) =>
      _$this._requiresVerification = requiresVerification;

  MapBuilder<String, JsonObject?>? _sourceLocator;
  MapBuilder<String, JsonObject?> get sourceLocator =>
      _$this._sourceLocator ??= MapBuilder<String, JsonObject?>();
  set sourceLocator(MapBuilder<String, JsonObject?>? sourceLocator) =>
      _$this._sourceLocator = sourceLocator;

  CandidateStatus? _status;
  CandidateStatus? get status => _$this._status;
  set status(CandidateStatus? status) => _$this._status = status;

  CandidateResponseBuilder() {
    CandidateResponse._defaults(this);
  }

  CandidateResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _candidateType = $v.candidateType;
      _candidateVersion = $v.candidateVersion;
      _confidence = $v.confidence;
      _confidenceBand = $v.confidenceBand;
      _displaySummary = $v.displaySummary;
      _displayTitle = $v.displayTitle;
      _id = $v.id;
      _requiresVerification = $v.requiresVerification;
      _sourceLocator = $v.sourceLocator.toBuilder();
      _status = $v.status;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CandidateResponse other) {
    _$v = other as _$CandidateResponse;
  }

  @override
  void update(void Function(CandidateResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CandidateResponse build() => _build();

  _$CandidateResponse _build() {
    _$CandidateResponse _$result;
    try {
      _$result = _$v ??
          _$CandidateResponse._(
            candidateType: BuiltValueNullFieldError.checkNotNull(
                candidateType, r'CandidateResponse', 'candidateType'),
            candidateVersion: BuiltValueNullFieldError.checkNotNull(
                candidateVersion, r'CandidateResponse', 'candidateVersion'),
            confidence: BuiltValueNullFieldError.checkNotNull(
                confidence, r'CandidateResponse', 'confidence'),
            confidenceBand: BuiltValueNullFieldError.checkNotNull(
                confidenceBand, r'CandidateResponse', 'confidenceBand'),
            displaySummary: BuiltValueNullFieldError.checkNotNull(
                displaySummary, r'CandidateResponse', 'displaySummary'),
            displayTitle: BuiltValueNullFieldError.checkNotNull(
                displayTitle, r'CandidateResponse', 'displayTitle'),
            id: BuiltValueNullFieldError.checkNotNull(
                id, r'CandidateResponse', 'id'),
            requiresVerification: BuiltValueNullFieldError.checkNotNull(
                requiresVerification,
                r'CandidateResponse',
                'requiresVerification'),
            sourceLocator: sourceLocator.build(),
            status: BuiltValueNullFieldError.checkNotNull(
                status, r'CandidateResponse', 'status'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'sourceLocator';
        sourceLocator.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'CandidateResponse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
