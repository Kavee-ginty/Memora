// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'learning_update_list_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$LearningUpdateListResponse extends LearningUpdateListResponse {
  @override
  final bool hasMore;
  @override
  final BuiltList<LearningUpdateResponse> items;
  @override
  final String? nextCursor;

  factory _$LearningUpdateListResponse(
          [void Function(LearningUpdateListResponseBuilder)? updates]) =>
      (LearningUpdateListResponseBuilder()..update(updates))._build();

  _$LearningUpdateListResponse._(
      {required this.hasMore, required this.items, this.nextCursor})
      : super._();
  @override
  LearningUpdateListResponse rebuild(
          void Function(LearningUpdateListResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  LearningUpdateListResponseBuilder toBuilder() =>
      LearningUpdateListResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is LearningUpdateListResponse &&
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
    return (newBuiltValueToStringHelper(r'LearningUpdateListResponse')
          ..add('hasMore', hasMore)
          ..add('items', items)
          ..add('nextCursor', nextCursor))
        .toString();
  }
}

class LearningUpdateListResponseBuilder
    implements
        Builder<LearningUpdateListResponse, LearningUpdateListResponseBuilder> {
  _$LearningUpdateListResponse? _$v;

  bool? _hasMore;
  bool? get hasMore => _$this._hasMore;
  set hasMore(bool? hasMore) => _$this._hasMore = hasMore;

  ListBuilder<LearningUpdateResponse>? _items;
  ListBuilder<LearningUpdateResponse> get items =>
      _$this._items ??= ListBuilder<LearningUpdateResponse>();
  set items(ListBuilder<LearningUpdateResponse>? items) =>
      _$this._items = items;

  String? _nextCursor;
  String? get nextCursor => _$this._nextCursor;
  set nextCursor(String? nextCursor) => _$this._nextCursor = nextCursor;

  LearningUpdateListResponseBuilder() {
    LearningUpdateListResponse._defaults(this);
  }

  LearningUpdateListResponseBuilder get _$this {
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
  void replace(LearningUpdateListResponse other) {
    _$v = other as _$LearningUpdateListResponse;
  }

  @override
  void update(void Function(LearningUpdateListResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  LearningUpdateListResponse build() => _build();

  _$LearningUpdateListResponse _build() {
    _$LearningUpdateListResponse _$result;
    try {
      _$result = _$v ??
          _$LearningUpdateListResponse._(
            hasMore: BuiltValueNullFieldError.checkNotNull(
                hasMore, r'LearningUpdateListResponse', 'hasMore'),
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
            r'LearningUpdateListResponse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
