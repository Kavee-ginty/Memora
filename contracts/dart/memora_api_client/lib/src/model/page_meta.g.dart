// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page_meta.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PageMeta extends PageMeta {
  @override
  final bool hasMore;
  @override
  final String? nextCursor;

  factory _$PageMeta([void Function(PageMetaBuilder)? updates]) =>
      (PageMetaBuilder()..update(updates))._build();

  _$PageMeta._({required this.hasMore, this.nextCursor}) : super._();
  @override
  PageMeta rebuild(void Function(PageMetaBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PageMetaBuilder toBuilder() => PageMetaBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PageMeta &&
        hasMore == other.hasMore &&
        nextCursor == other.nextCursor;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, hasMore.hashCode);
    _$hash = $jc(_$hash, nextCursor.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PageMeta')
          ..add('hasMore', hasMore)
          ..add('nextCursor', nextCursor))
        .toString();
  }
}

class PageMetaBuilder implements Builder<PageMeta, PageMetaBuilder> {
  _$PageMeta? _$v;

  bool? _hasMore;
  bool? get hasMore => _$this._hasMore;
  set hasMore(bool? hasMore) => _$this._hasMore = hasMore;

  String? _nextCursor;
  String? get nextCursor => _$this._nextCursor;
  set nextCursor(String? nextCursor) => _$this._nextCursor = nextCursor;

  PageMetaBuilder() {
    PageMeta._defaults(this);
  }

  PageMetaBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _hasMore = $v.hasMore;
      _nextCursor = $v.nextCursor;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PageMeta other) {
    _$v = other as _$PageMeta;
  }

  @override
  void update(void Function(PageMetaBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PageMeta build() => _build();

  _$PageMeta _build() {
    final _$result = _$v ??
        _$PageMeta._(
          hasMore: BuiltValueNullFieldError.checkNotNull(
              hasMore, r'PageMeta', 'hasMore'),
          nextCursor: nextCursor,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
