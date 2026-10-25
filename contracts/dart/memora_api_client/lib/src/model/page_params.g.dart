// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page_params.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PageParams extends PageParams {
  @override
  final Optional<String?> cursor;
  @override
  final Optional<int?> limit;

  factory _$PageParams([void Function(PageParamsBuilder)? updates]) =>
      (PageParamsBuilder()..update(updates))._build();

  _$PageParams._({required this.cursor, required this.limit}) : super._();
  @override
  PageParams rebuild(void Function(PageParamsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PageParamsBuilder toBuilder() => PageParamsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PageParams &&
        cursor == other.cursor &&
        limit == other.limit;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, cursor.hashCode);
    _$hash = $jc(_$hash, limit.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PageParams')
          ..add('cursor', cursor)
          ..add('limit', limit))
        .toString();
  }
}

class PageParamsBuilder implements Builder<PageParams, PageParamsBuilder> {
  _$PageParams? _$v;

  Optional<String?>? _cursor;
  Optional<String?>? get cursor => _$this._cursor;
  set cursor(Optional<String?>? cursor) => _$this._cursor = cursor;

  Optional<int?>? _limit;
  Optional<int?>? get limit => _$this._limit;
  set limit(Optional<int?>? limit) => _$this._limit = limit;

  PageParamsBuilder() {
    PageParams._defaults(this);
  }

  PageParamsBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _cursor = $v.cursor;
      _limit = $v.limit;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PageParams other) {
    _$v = other as _$PageParams;
  }

  @override
  void update(void Function(PageParamsBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PageParams build() => _build();

  _$PageParams _build() {
    final _$result = _$v ??
        _$PageParams._(
          cursor: BuiltValueNullFieldError.checkNotNull(
              cursor, r'PageParams', 'cursor'),
          limit: BuiltValueNullFieldError.checkNotNull(
              limit, r'PageParams', 'limit'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
