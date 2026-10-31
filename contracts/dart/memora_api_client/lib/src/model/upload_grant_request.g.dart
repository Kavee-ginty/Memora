// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upload_grant_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UploadGrantRequest extends UploadGrantRequest {
  @override
  final int byteSize;
  @override
  final String contentSha256;
  @override
  final String declaredMediaType;
  @override
  final String declaredName;

  factory _$UploadGrantRequest(
          [void Function(UploadGrantRequestBuilder)? updates]) =>
      (UploadGrantRequestBuilder()..update(updates))._build();

  _$UploadGrantRequest._(
      {required this.byteSize,
      required this.contentSha256,
      required this.declaredMediaType,
      required this.declaredName})
      : super._();
  @override
  UploadGrantRequest rebuild(
          void Function(UploadGrantRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UploadGrantRequestBuilder toBuilder() =>
      UploadGrantRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UploadGrantRequest &&
        byteSize == other.byteSize &&
        contentSha256 == other.contentSha256 &&
        declaredMediaType == other.declaredMediaType &&
        declaredName == other.declaredName;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, byteSize.hashCode);
    _$hash = $jc(_$hash, contentSha256.hashCode);
    _$hash = $jc(_$hash, declaredMediaType.hashCode);
    _$hash = $jc(_$hash, declaredName.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UploadGrantRequest')
          ..add('byteSize', byteSize)
          ..add('contentSha256', contentSha256)
          ..add('declaredMediaType', declaredMediaType)
          ..add('declaredName', declaredName))
        .toString();
  }
}

class UploadGrantRequestBuilder
    implements Builder<UploadGrantRequest, UploadGrantRequestBuilder> {
  _$UploadGrantRequest? _$v;

  int? _byteSize;
  int? get byteSize => _$this._byteSize;
  set byteSize(int? byteSize) => _$this._byteSize = byteSize;

  String? _contentSha256;
  String? get contentSha256 => _$this._contentSha256;
  set contentSha256(String? contentSha256) =>
      _$this._contentSha256 = contentSha256;

  String? _declaredMediaType;
  String? get declaredMediaType => _$this._declaredMediaType;
  set declaredMediaType(String? declaredMediaType) =>
      _$this._declaredMediaType = declaredMediaType;

  String? _declaredName;
  String? get declaredName => _$this._declaredName;
  set declaredName(String? declaredName) => _$this._declaredName = declaredName;

  UploadGrantRequestBuilder() {
    UploadGrantRequest._defaults(this);
  }

  UploadGrantRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _byteSize = $v.byteSize;
      _contentSha256 = $v.contentSha256;
      _declaredMediaType = $v.declaredMediaType;
      _declaredName = $v.declaredName;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UploadGrantRequest other) {
    _$v = other as _$UploadGrantRequest;
  }

  @override
  void update(void Function(UploadGrantRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UploadGrantRequest build() => _build();

  _$UploadGrantRequest _build() {
    final _$result = _$v ??
        _$UploadGrantRequest._(
          byteSize: BuiltValueNullFieldError.checkNotNull(
              byteSize, r'UploadGrantRequest', 'byteSize'),
          contentSha256: BuiltValueNullFieldError.checkNotNull(
              contentSha256, r'UploadGrantRequest', 'contentSha256'),
          declaredMediaType: BuiltValueNullFieldError.checkNotNull(
              declaredMediaType, r'UploadGrantRequest', 'declaredMediaType'),
          declaredName: BuiltValueNullFieldError.checkNotNull(
              declaredName, r'UploadGrantRequest', 'declaredName'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
