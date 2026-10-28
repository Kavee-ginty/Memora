// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'declared_file.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DeclaredFile extends DeclaredFile {
  @override
  final int byteSize;
  @override
  final String contentSha256;
  @override
  final String declaredMediaType;
  @override
  final String declaredName;

  factory _$DeclaredFile([void Function(DeclaredFileBuilder)? updates]) =>
      (DeclaredFileBuilder()..update(updates))._build();

  _$DeclaredFile._(
      {required this.byteSize,
      required this.contentSha256,
      required this.declaredMediaType,
      required this.declaredName})
      : super._();
  @override
  DeclaredFile rebuild(void Function(DeclaredFileBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DeclaredFileBuilder toBuilder() => DeclaredFileBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DeclaredFile &&
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
    return (newBuiltValueToStringHelper(r'DeclaredFile')
          ..add('byteSize', byteSize)
          ..add('contentSha256', contentSha256)
          ..add('declaredMediaType', declaredMediaType)
          ..add('declaredName', declaredName))
        .toString();
  }
}

class DeclaredFileBuilder
    implements Builder<DeclaredFile, DeclaredFileBuilder> {
  _$DeclaredFile? _$v;

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

  DeclaredFileBuilder() {
    DeclaredFile._defaults(this);
  }

  DeclaredFileBuilder get _$this {
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
  void replace(DeclaredFile other) {
    _$v = other as _$DeclaredFile;
  }

  @override
  void update(void Function(DeclaredFileBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DeclaredFile build() => _build();

  _$DeclaredFile _build() {
    final _$result = _$v ??
        _$DeclaredFile._(
          byteSize: BuiltValueNullFieldError.checkNotNull(
              byteSize, r'DeclaredFile', 'byteSize'),
          contentSha256: BuiltValueNullFieldError.checkNotNull(
              contentSha256, r'DeclaredFile', 'contentSha256'),
          declaredMediaType: BuiltValueNullFieldError.checkNotNull(
              declaredMediaType, r'DeclaredFile', 'declaredMediaType'),
          declaredName: BuiltValueNullFieldError.checkNotNull(
              declaredName, r'DeclaredFile', 'declaredName'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
