// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'finalize_upload_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$FinalizeUploadRequest extends FinalizeUploadRequest {
  @override
  final String clientOperationId;
  @override
  final String contentSha256;
  @override
  final int observedSize;

  factory _$FinalizeUploadRequest(
          [void Function(FinalizeUploadRequestBuilder)? updates]) =>
      (FinalizeUploadRequestBuilder()..update(updates))._build();

  _$FinalizeUploadRequest._(
      {required this.clientOperationId,
      required this.contentSha256,
      required this.observedSize})
      : super._();
  @override
  FinalizeUploadRequest rebuild(
          void Function(FinalizeUploadRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  FinalizeUploadRequestBuilder toBuilder() =>
      FinalizeUploadRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is FinalizeUploadRequest &&
        clientOperationId == other.clientOperationId &&
        contentSha256 == other.contentSha256 &&
        observedSize == other.observedSize;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, clientOperationId.hashCode);
    _$hash = $jc(_$hash, contentSha256.hashCode);
    _$hash = $jc(_$hash, observedSize.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'FinalizeUploadRequest')
          ..add('clientOperationId', clientOperationId)
          ..add('contentSha256', contentSha256)
          ..add('observedSize', observedSize))
        .toString();
  }
}

class FinalizeUploadRequestBuilder
    implements Builder<FinalizeUploadRequest, FinalizeUploadRequestBuilder> {
  _$FinalizeUploadRequest? _$v;

  String? _clientOperationId;
  String? get clientOperationId => _$this._clientOperationId;
  set clientOperationId(String? clientOperationId) =>
      _$this._clientOperationId = clientOperationId;

  String? _contentSha256;
  String? get contentSha256 => _$this._contentSha256;
  set contentSha256(String? contentSha256) =>
      _$this._contentSha256 = contentSha256;

  int? _observedSize;
  int? get observedSize => _$this._observedSize;
  set observedSize(int? observedSize) => _$this._observedSize = observedSize;

  FinalizeUploadRequestBuilder() {
    FinalizeUploadRequest._defaults(this);
  }

  FinalizeUploadRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _clientOperationId = $v.clientOperationId;
      _contentSha256 = $v.contentSha256;
      _observedSize = $v.observedSize;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(FinalizeUploadRequest other) {
    _$v = other as _$FinalizeUploadRequest;
  }

  @override
  void update(void Function(FinalizeUploadRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  FinalizeUploadRequest build() => _build();

  _$FinalizeUploadRequest _build() {
    final _$result = _$v ??
        _$FinalizeUploadRequest._(
          clientOperationId: BuiltValueNullFieldError.checkNotNull(
              clientOperationId, r'FinalizeUploadRequest', 'clientOperationId'),
          contentSha256: BuiltValueNullFieldError.checkNotNull(
              contentSha256, r'FinalizeUploadRequest', 'contentSha256'),
          observedSize: BuiltValueNullFieldError.checkNotNull(
              observedSize, r'FinalizeUploadRequest', 'observedSize'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
