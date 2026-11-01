// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page_concept_progress_item.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PageConceptProgressItem extends PageConceptProgressItem {
  @override
  final bool hasMore;
  @override
  final BuiltList<ConceptProgressItem> items;
  @override
  final String? nextCursor;

  factory _$PageConceptProgressItem(
          [void Function(PageConceptProgressItemBuilder)? updates]) =>
      (PageConceptProgressItemBuilder()..update(updates))._build();

  _$PageConceptProgressItem._(
      {required this.hasMore, required this.items, this.nextCursor})
      : super._();
  @override
  PageConceptProgressItem rebuild(
          void Function(PageConceptProgressItemBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PageConceptProgressItemBuilder toBuilder() =>
      PageConceptProgressItemBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PageConceptProgressItem &&
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
    return (newBuiltValueToStringHelper(r'PageConceptProgressItem')
          ..add('hasMore', hasMore)
          ..add('items', items)
          ..add('nextCursor', nextCursor))
        .toString();
  }
}

class PageConceptProgressItemBuilder
    implements
        Builder<PageConceptProgressItem, PageConceptProgressItemBuilder> {
  _$PageConceptProgressItem? _$v;

  bool? _hasMore;
  bool? get hasMore => _$this._hasMore;
  set hasMore(bool? hasMore) => _$this._hasMore = hasMore;

  ListBuilder<ConceptProgressItem>? _items;
  ListBuilder<ConceptProgressItem> get items =>
      _$this._items ??= ListBuilder<ConceptProgressItem>();
  set items(ListBuilder<ConceptProgressItem>? items) => _$this._items = items;

  String? _nextCursor;
  String? get nextCursor => _$this._nextCursor;
  set nextCursor(String? nextCursor) => _$this._nextCursor = nextCursor;

  PageConceptProgressItemBuilder() {
    PageConceptProgressItem._defaults(this);
  }

  PageConceptProgressItemBuilder get _$this {
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
  void replace(PageConceptProgressItem other) {
    _$v = other as _$PageConceptProgressItem;
  }

  @override
  void update(void Function(PageConceptProgressItemBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PageConceptProgressItem build() => _build();

  _$PageConceptProgressItem _build() {
    _$PageConceptProgressItem _$result;
    try {
      _$result = _$v ??
          _$PageConceptProgressItem._(
            hasMore: BuiltValueNullFieldError.checkNotNull(
                hasMore, r'PageConceptProgressItem', 'hasMore'),
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
            r'PageConceptProgressItem', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
