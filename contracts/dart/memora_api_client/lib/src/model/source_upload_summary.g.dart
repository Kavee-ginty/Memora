// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'source_upload_summary.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SourceUploadSummary extends SourceUploadSummary {
  @override
  final int byteSize;
  @override
  final String declaredMediaType;
  @override
  final String declaredName;
  @override
  final String? deletedAt;
  @override
  final DeletionStatus deletionStatus;
  @override
  final String? detectedMediaType;
  @override
  final String expiresAt;
  @override
  final String id;
  @override
  final UploadStatus status;

  factory _$SourceUploadSummary(
          [void Function(SourceUploadSummaryBuilder)? updates]) =>
      (SourceUploadSummaryBuilder()..update(updates))._build();

  _$SourceUploadSummary._(
      {required this.byteSize,
      required this.declaredMediaType,
      required this.declaredName,
      this.deletedAt,
      required this.deletionStatus,
      this.detectedMediaType,
      required this.expiresAt,
      required this.id,
      required this.status})
      : super._();
  @override
  SourceUploadSummary rebuild(
          void Function(SourceUploadSummaryBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SourceUploadSummaryBuilder toBuilder() =>
      SourceUploadSummaryBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SourceUploadSummary &&
        byteSize == other.byteSize &&
        declaredMediaType == other.declaredMediaType &&
        declaredName == other.declaredName &&
        deletedAt == other.deletedAt &&
        deletionStatus == other.deletionStatus &&
        detectedMediaType == other.detectedMediaType &&
        expiresAt == other.expiresAt &&
        id == other.id &&
        status == other.status;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, byteSize.hashCode);
    _$hash = $jc(_$hash, declaredMediaType.hashCode);
    _$hash = $jc(_$hash, declaredName.hashCode);
    _$hash = $jc(_$hash, deletedAt.hashCode);
    _$hash = $jc(_$hash, deletionStatus.hashCode);
    _$hash = $jc(_$hash, detectedMediaType.hashCode);
    _$hash = $jc(_$hash, expiresAt.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SourceUploadSummary')
          ..add('byteSize', byteSize)
          ..add('declaredMediaType', declaredMediaType)
          ..add('declaredName', declaredName)
          ..add('deletedAt', deletedAt)
          ..add('deletionStatus', deletionStatus)
          ..add('detectedMediaType', detectedMediaType)
          ..add('expiresAt', expiresAt)
          ..add('id', id)
          ..add('status', status))
        .toString();
  }
}

class SourceUploadSummaryBuilder
    implements Builder<SourceUploadSummary, SourceUploadSummaryBuilder> {
  _$SourceUploadSummary? _$v;

  int? _byteSize;
  int? get byteSize => _$this._byteSize;
  set byteSize(int? byteSize) => _$this._byteSize = byteSize;

  String? _declaredMediaType;
  String? get declaredMediaType => _$this._declaredMediaType;
  set declaredMediaType(String? declaredMediaType) =>
      _$this._declaredMediaType = declaredMediaType;

  String? _declaredName;
  String? get declaredName => _$this._declaredName;
  set declaredName(String? declaredName) => _$this._declaredName = declaredName;

  String? _deletedAt;
  String? get deletedAt => _$this._deletedAt;
  set deletedAt(String? deletedAt) => _$this._deletedAt = deletedAt;

  DeletionStatus? _deletionStatus;
  DeletionStatus? get deletionStatus => _$this._deletionStatus;
  set deletionStatus(DeletionStatus? deletionStatus) =>
      _$this._deletionStatus = deletionStatus;

  String? _detectedMediaType;
  String? get detectedMediaType => _$this._detectedMediaType;
  set detectedMediaType(String? detectedMediaType) =>
      _$this._detectedMediaType = detectedMediaType;

  String? _expiresAt;
  String? get expiresAt => _$this._expiresAt;
  set expiresAt(String? expiresAt) => _$this._expiresAt = expiresAt;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  UploadStatus? _status;
  UploadStatus? get status => _$this._status;
  set status(UploadStatus? status) => _$this._status = status;

  SourceUploadSummaryBuilder() {
    SourceUploadSummary._defaults(this);
  }

  SourceUploadSummaryBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _byteSize = $v.byteSize;
      _declaredMediaType = $v.declaredMediaType;
      _declaredName = $v.declaredName;
      _deletedAt = $v.deletedAt;
      _deletionStatus = $v.deletionStatus;
      _detectedMediaType = $v.detectedMediaType;
      _expiresAt = $v.expiresAt;
      _id = $v.id;
      _status = $v.status;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SourceUploadSummary other) {
    _$v = other as _$SourceUploadSummary;
  }

  @override
  void update(void Function(SourceUploadSummaryBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SourceUploadSummary build() => _build();

  _$SourceUploadSummary _build() {
    final _$result = _$v ??
        _$SourceUploadSummary._(
          byteSize: BuiltValueNullFieldError.checkNotNull(
              byteSize, r'SourceUploadSummary', 'byteSize'),
          declaredMediaType: BuiltValueNullFieldError.checkNotNull(
              declaredMediaType, r'SourceUploadSummary', 'declaredMediaType'),
          declaredName: BuiltValueNullFieldError.checkNotNull(
              declaredName, r'SourceUploadSummary', 'declaredName'),
          deletedAt: deletedAt,
          deletionStatus: BuiltValueNullFieldError.checkNotNull(
              deletionStatus, r'SourceUploadSummary', 'deletionStatus'),
          detectedMediaType: detectedMediaType,
          expiresAt: BuiltValueNullFieldError.checkNotNull(
              expiresAt, r'SourceUploadSummary', 'expiresAt'),
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'SourceUploadSummary', 'id'),
          status: BuiltValueNullFieldError.checkNotNull(
              status, r'SourceUploadSummary', 'status'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
