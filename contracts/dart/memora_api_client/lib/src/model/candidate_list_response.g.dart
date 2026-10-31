// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'candidate_list_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CandidateListResponse extends CandidateListResponse {
  @override
  final bool hasMore;
  @override
  final BuiltList<CandidateResponse> items;
  @override
  final String? nextCursor;

  factory _$CandidateListResponse(
          [void Function(CandidateListResponseBuilder)? updates]) =>
      (CandidateListResponseBuilder()..update(updates))._build();

  _$CandidateListResponse._(
      {required this.hasMore, required this.items, this.nextCursor})
      : super._();
  @override
  CandidateListResponse rebuild(
          void Function(CandidateListResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CandidateListResponseBuilder toBuilder() =>
      CandidateListResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CandidateListResponse &&
        hasMore == other.hasMore &&
        items == other.items &&
        nextCursor == other.nextCursor;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, hasMore.hashCode);
    _$hash = $jc(_$hash, items.hashCode);
    _$hash = $jc(_$hash, nextCursor.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CandidateListResponse')
          ..add('hasMore', hasMore)
          ..add('items', items)
          ..add('nextCursor', nextCursor))
        .toString();
  }
}

class CandidateListResponseBuilder
    implements Builder<CandidateListResponse, CandidateListResponseBuilder> {
  _$CandidateListResponse? _$v;

  bool? _hasMore;
  bool? get hasMore => _$this._hasMore;
  set hasMore(bool? hasMore) => _$this._hasMore = hasMore;

  ListBuilder<CandidateResponse>? _items;
  ListBuilder<CandidateResponse> get items =>
      _$this._items ??= ListBuilder<CandidateResponse>();
  set items(ListBuilder<CandidateResponse>? items) => _$this._items = items;

  String? _nextCursor;
  String? get nextCursor => _$this._nextCursor;
  set nextCursor(String? nextCursor) => _$this._nextCursor = nextCursor;

  CandidateListResponseBuilder() {
    CandidateListResponse._defaults(this);
  }

  CandidateListResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _hasMore = $v.hasMore;
      _items = $v.items.toBuilder();
      _nextCursor = $v.nextCursor;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CandidateListResponse other) {
    _$v = other as _$CandidateListResponse;
  }

  @override
  void update(void Function(CandidateListResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CandidateListResponse build() => _build();

  _$CandidateListResponse _build() {
    _$CandidateListResponse _$result;
    try {
      _$result = _$v ??
          _$CandidateListResponse._(
            hasMore: BuiltValueNullFieldError.checkNotNull(
                hasMore, r'CandidateListResponse', 'hasMore'),
            items: items.build(),
            nextCursor: nextCursor,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'items';
        items.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'CandidateListResponse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
