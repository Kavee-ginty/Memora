// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'learning_path_preview_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$LearningPathPreviewResponse extends LearningPathPreviewResponse {
  @override
  final String? blockedReason;
  @override
  final bool canCommit;
  @override
  final int conceptCount;
  @override
  final int? estimatedFirstMissionMinutes;
  @override
  final BuiltList<LearningPathPreviewConcept> firstConcepts;
  @override
  final LearningUpdateStatus status;
  @override
  final String updateId;

  factory _$LearningPathPreviewResponse(
          [void Function(LearningPathPreviewResponseBuilder)? updates]) =>
      (LearningPathPreviewResponseBuilder()..update(updates))._build();

  _$LearningPathPreviewResponse._(
      {this.blockedReason,
      required this.canCommit,
      required this.conceptCount,
      this.estimatedFirstMissionMinutes,
      required this.firstConcepts,
      required this.status,
      required this.updateId})
      : super._();
  @override
  LearningPathPreviewResponse rebuild(
          void Function(LearningPathPreviewResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  LearningPathPreviewResponseBuilder toBuilder() =>
      LearningPathPreviewResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is LearningPathPreviewResponse &&
        blockedReason == other.blockedReason &&
        canCommit == other.canCommit &&
        conceptCount == other.conceptCount &&
        estimatedFirstMissionMinutes == other.estimatedFirstMissionMinutes &&
        firstConcepts == other.firstConcepts &&
        status == other.status &&
        updateId == other.updateId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, blockedReason.hashCode);
    _$hash = $jc(_$hash, canCommit.hashCode);
    _$hash = $jc(_$hash, conceptCount.hashCode);
    _$hash = $jc(_$hash, estimatedFirstMissionMinutes.hashCode);
    _$hash = $jc(_$hash, firstConcepts.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, updateId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'LearningPathPreviewResponse')
          ..add('blockedReason', blockedReason)
          ..add('canCommit', canCommit)
          ..add('conceptCount', conceptCount)
          ..add('estimatedFirstMissionMinutes', estimatedFirstMissionMinutes)
          ..add('firstConcepts', firstConcepts)
          ..add('status', status)
          ..add('updateId', updateId))
        .toString();
  }
}

class LearningPathPreviewResponseBuilder
    implements
        Builder<LearningPathPreviewResponse,
            LearningPathPreviewResponseBuilder> {
  _$LearningPathPreviewResponse? _$v;

  String? _blockedReason;
  String? get blockedReason => _$this._blockedReason;
  set blockedReason(String? blockedReason) =>
      _$this._blockedReason = blockedReason;

  bool? _canCommit;
  bool? get canCommit => _$this._canCommit;
  set canCommit(bool? canCommit) => _$this._canCommit = canCommit;

  int? _conceptCount;
  int? get conceptCount => _$this._conceptCount;
  set conceptCount(int? conceptCount) => _$this._conceptCount = conceptCount;

  int? _estimatedFirstMissionMinutes;
  int? get estimatedFirstMissionMinutes => _$this._estimatedFirstMissionMinutes;
  set estimatedFirstMissionMinutes(int? estimatedFirstMissionMinutes) =>
      _$this._estimatedFirstMissionMinutes = estimatedFirstMissionMinutes;

  ListBuilder<LearningPathPreviewConcept>? _firstConcepts;
  ListBuilder<LearningPathPreviewConcept> get firstConcepts =>
      _$this._firstConcepts ??= ListBuilder<LearningPathPreviewConcept>();
  set firstConcepts(ListBuilder<LearningPathPreviewConcept>? firstConcepts) =>
      _$this._firstConcepts = firstConcepts;

  LearningUpdateStatus? _status;
  LearningUpdateStatus? get status => _$this._status;
  set status(LearningUpdateStatus? status) => _$this._status = status;

  String? _updateId;
  String? get updateId => _$this._updateId;
  set updateId(String? updateId) => _$this._updateId = updateId;

  LearningPathPreviewResponseBuilder() {
    LearningPathPreviewResponse._defaults(this);
  }

  LearningPathPreviewResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _blockedReason = $v.blockedReason;
      _canCommit = $v.canCommit;
      _conceptCount = $v.conceptCount;
      _estimatedFirstMissionMinutes = $v.estimatedFirstMissionMinutes;
      _firstConcepts = $v.firstConcepts.toBuilder();
      _status = $v.status;
      _updateId = $v.updateId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(LearningPathPreviewResponse other) {
    _$v = other as _$LearningPathPreviewResponse;
  }

  @override
  void update(void Function(LearningPathPreviewResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  LearningPathPreviewResponse build() => _build();

  _$LearningPathPreviewResponse _build() {
    _$LearningPathPreviewResponse _$result;
    try {
      _$result = _$v ??
          _$LearningPathPreviewResponse._(
            blockedReason: blockedReason,
            canCommit: BuiltValueNullFieldError.checkNotNull(
                canCommit, r'LearningPathPreviewResponse', 'canCommit'),
            conceptCount: BuiltValueNullFieldError.checkNotNull(
                conceptCount, r'LearningPathPreviewResponse', 'conceptCount'),
            estimatedFirstMissionMinutes: estimatedFirstMissionMinutes,
            firstConcepts: firstConcepts.build(),
            status: BuiltValueNullFieldError.checkNotNull(
                status, r'LearningPathPreviewResponse', 'status'),
            updateId: BuiltValueNullFieldError.checkNotNull(
                updateId, r'LearningPathPreviewResponse', 'updateId'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'firstConcepts';
        firstConcepts.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'LearningPathPreviewResponse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
