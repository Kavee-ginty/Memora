// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reward_inventory_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$RewardInventoryResponse extends RewardInventoryResponse {
  @override
  final BuiltList<RewardGrant> items;

  factory _$RewardInventoryResponse(
          [void Function(RewardInventoryResponseBuilder)? updates]) =>
      (RewardInventoryResponseBuilder()..update(updates))._build();

  _$RewardInventoryResponse._({required this.items}) : super._();
  @override
  RewardInventoryResponse rebuild(
          void Function(RewardInventoryResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RewardInventoryResponseBuilder toBuilder() =>
      RewardInventoryResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RewardInventoryResponse && items == other.items;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, items.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'RewardInventoryResponse')
          ..add('items', items))
        .toString();
  }
}

class RewardInventoryResponseBuilder
    implements
        Builder<RewardInventoryResponse, RewardInventoryResponseBuilder> {
  _$RewardInventoryResponse? _$v;

  ListBuilder<RewardGrant>? _items;
  ListBuilder<RewardGrant> get items =>
      _$this._items ??= ListBuilder<RewardGrant>();
  set items(ListBuilder<RewardGrant>? items) => _$this._items = items;

  RewardInventoryResponseBuilder() {
    RewardInventoryResponse._defaults(this);
  }

  RewardInventoryResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RewardInventoryResponse other) {
    _$v = other as _$RewardInventoryResponse;
  }

  @override
  void update(void Function(RewardInventoryResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RewardInventoryResponse build() => _build();

  _$RewardInventoryResponse _build() {
    _$RewardInventoryResponse _$result;
    try {
      _$result = _$v ??
          _$RewardInventoryResponse._(
            items: items.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'items';
        items.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'RewardInventoryResponse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
