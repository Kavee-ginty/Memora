// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'learning_update_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$LearningUpdateResponse extends LearningUpdateResponse {
  @override
  final String createdAt;
  @override
  final String curriculumVersionId;
  @override
  final String? expiresAt;
  @override
  final String? failureCode;
  @override
  final bool hasManualText;
  @override
  final String id;
  @override
  final InputType inputType;
  @override
  final String learnedAt;
  @override
  final int rowVersion;
  @override
  final DeletionStatus sourceDeletionStatus;
  @override
  final LearningUpdateStatus status;
  @override
  final String subjectId;
  @override
  final String updatedAt;
  @override
  final BuiltList<SourceUploadSummary> uploads;

  factory _$LearningUpdateResponse(
          [void Function(LearningUpdateResponseBuilder)? updates]) =>
      (LearningUpdateResponseBuilder()..update(updates))._build();

  _$LearningUpdateResponse._(
      {required this.createdAt,
      required this.curriculumVersionId,
      this.expiresAt,
      this.failureCode,
      required this.hasManualText,
      required this.id,
      required this.inputType,
      required this.learnedAt,
      required this.rowVersion,
      required this.sourceDeletionStatus,
      required this.status,
      required this.subjectId,
      required this.updatedAt,
      required this.uploads})
      : super._();
  @override
  LearningUpdateResponse rebuild(
          void Function(LearningUpdateResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  LearningUpdateResponseBuilder toBuilder() =>
      LearningUpdateResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is LearningUpdateResponse &&
        createdAt == other.createdAt &&
        curriculumVersionId == other.curriculumVersionId &&
        expiresAt == other.expiresAt &&
        failureCode == other.failureCode &&
        hasManualText == other.hasManualText &&
        id == other.id &&
        inputType == other.inputType &&
        learnedAt == other.learnedAt &&
        rowVersion == other.rowVersion &&
        sourceDeletionStatus == other.sourceDeletionStatus &&
        status == other.status &&
        subjectId == other.subjectId &&
        updatedAt == other.updatedAt &&
        uploads == other.uploads;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, curriculumVersionId.hashCode);
    _$hash = $jc(_$hash, expiresAt.hashCode);
    _$hash = $jc(_$hash, failureCode.hashCode);
    _$hash = $jc(_$hash, hasManualText.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, inputType.hashCode);
    _$hash = $jc(_$hash, learnedAt.hashCode);
    _$hash = $jc(_$hash, rowVersion.hashCode);
    _$hash = $jc(_$hash, sourceDeletionStatus.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, subjectId.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jc(_$hash, uploads.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'LearningUpdateResponse')
          ..add('createdAt', createdAt)
          ..add('curriculumVersionId', curriculumVersionId)
          ..add('expiresAt', expiresAt)
          ..add('failureCode', failureCode)
          ..add('hasManualText', hasManualText)
          ..add('id', id)
          ..add('inputType', inputType)
          ..add('learnedAt', learnedAt)
          ..add('rowVersion', rowVersion)
          ..add('sourceDeletionStatus', sourceDeletionStatus)
          ..add('status', status)
          ..add('subjectId', subjectId)
          ..add('updatedAt', updatedAt)
          ..add('uploads', uploads))
        .toString();
  }
}

class LearningUpdateResponseBuilder
    implements Builder<LearningUpdateResponse, LearningUpdateResponseBuilder> {
  _$LearningUpdateResponse? _$v;

  String? _createdAt;
  String? get createdAt => _$this._createdAt;
  set createdAt(String? createdAt) => _$this._createdAt = createdAt;

  String? _curriculumVersionId;
  String? get curriculumVersionId => _$this._curriculumVersionId;
  set curriculumVersionId(String? curriculumVersionId) =>
      _$this._curriculumVersionId = curriculumVersionId;

  String? _expiresAt;
  String? get expiresAt => _$this._expiresAt;
  set expiresAt(String? expiresAt) => _$this._expiresAt = expiresAt;

  String? _failureCode;
  String? get failureCode => _$this._failureCode;
  set failureCode(String? failureCode) => _$this._failureCode = failureCode;

  bool? _hasManualText;
  bool? get hasManualText => _$this._hasManualText;
  set hasManualText(bool? hasManualText) =>
      _$this._hasManualText = hasManualText;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  InputType? _inputType;
  InputType? get inputType => _$this._inputType;
  set inputType(InputType? inputType) => _$this._inputType = inputType;

  String? _learnedAt;
  String? get learnedAt => _$this._learnedAt;
  set learnedAt(String? learnedAt) => _$this._learnedAt = learnedAt;

  int? _rowVersion;
  int? get rowVersion => _$this._rowVersion;
  set rowVersion(int? rowVersion) => _$this._rowVersion = rowVersion;

  DeletionStatus? _sourceDeletionStatus;
  DeletionStatus? get sourceDeletionStatus => _$this._sourceDeletionStatus;
  set sourceDeletionStatus(DeletionStatus? sourceDeletionStatus) =>
      _$this._sourceDeletionStatus = sourceDeletionStatus;

  LearningUpdateStatus? _status;
  LearningUpdateStatus? get status => _$this._status;
  set status(LearningUpdateStatus? status) => _$this._status = status;

  String? _subjectId;
  String? get subjectId => _$this._subjectId;
  set subjectId(String? subjectId) => _$this._subjectId = subjectId;

  String? _updatedAt;
  String? get updatedAt => _$this._updatedAt;
  set updatedAt(String? updatedAt) => _$this._updatedAt = updatedAt;

  ListBuilder<SourceUploadSummary>? _uploads;
  ListBuilder<SourceUploadSummary> get uploads =>
      _$this._uploads ??= ListBuilder<SourceUploadSummary>();
  set uploads(ListBuilder<SourceUploadSummary>? uploads) =>
      _$this._uploads = uploads;

  LearningUpdateResponseBuilder() {
    LearningUpdateResponse._defaults(this);
  }

  LearningUpdateResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _createdAt = $v.createdAt;
      _curriculumVersionId = $v.curriculumVersionId;
      _expiresAt = $v.expiresAt;
      _failureCode = $v.failureCode;
      _hasManualText = $v.hasManualText;
      _id = $v.id;
      _inputType = $v.inputType;
      _learnedAt = $v.learnedAt;
      _rowVersion = $v.rowVersion;
      _sourceDeletionStatus = $v.sourceDeletionStatus;
      _status = $v.status;
      _subjectId = $v.subjectId;
      _updatedAt = $v.updatedAt;
      _uploads = $v.uploads.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(LearningUpdateResponse other) {
    _$v = other as _$LearningUpdateResponse;
  }

  @override
  void update(void Function(LearningUpdateResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  LearningUpdateResponse build() => _build();

  _$LearningUpdateResponse _build() {
    _$LearningUpdateResponse _$result;
    try {
      _$result = _$v ??
          _$LearningUpdateResponse._(
            createdAt: BuiltValueNullFieldError.checkNotNull(
                createdAt, r'LearningUpdateResponse', 'createdAt'),
            curriculumVersionId: BuiltValueNullFieldError.checkNotNull(
                curriculumVersionId,
                r'LearningUpdateResponse',
                'curriculumVersionId'),
            expiresAt: expiresAt,
            failureCode: failureCode,
            hasManualText: BuiltValueNullFieldError.checkNotNull(
                hasManualText, r'LearningUpdateResponse', 'hasManualText'),
            id: BuiltValueNullFieldError.checkNotNull(
                id, r'LearningUpdateResponse', 'id'),
            inputType: BuiltValueNullFieldError.checkNotNull(
                inputType, r'LearningUpdateResponse', 'inputType'),
            learnedAt: BuiltValueNullFieldError.checkNotNull(
                learnedAt, r'LearningUpdateResponse', 'learnedAt'),
            rowVersion: BuiltValueNullFieldError.checkNotNull(
                rowVersion, r'LearningUpdateResponse', 'rowVersion'),
            sourceDeletionStatus: BuiltValueNullFieldError.checkNotNull(
                sourceDeletionStatus,
                r'LearningUpdateResponse',
                'sourceDeletionStatus'),
            status: BuiltValueNullFieldError.checkNotNull(
                status, r'LearningUpdateResponse', 'status'),
            subjectId: BuiltValueNullFieldError.checkNotNull(
                subjectId, r'LearningUpdateResponse', 'subjectId'),
            updatedAt: BuiltValueNullFieldError.checkNotNull(
                updatedAt, r'LearningUpdateResponse', 'updatedAt'),
            uploads: uploads.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'uploads';
        uploads.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'LearningUpdateResponse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
