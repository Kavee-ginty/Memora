// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_resource_summary.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PendingResourceSummary extends PendingResourceSummary {
  @override
  final String id;
  @override
  final String status;
  @override
  final DateTime updatedAt;

  factory _$PendingResourceSummary(
          [void Function(PendingResourceSummaryBuilder)? updates]) =>
      (PendingResourceSummaryBuilder()..update(updates))._build();

  _$PendingResourceSummary._(
      {required this.id, required this.status, required this.updatedAt})
      : super._();
  @override
  PendingResourceSummary rebuild(
          void Function(PendingResourceSummaryBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PendingResourceSummaryBuilder toBuilder() =>
      PendingResourceSummaryBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PendingResourceSummary &&
        id == other.id &&
        status == other.status &&
        updatedAt == other.updatedAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PendingResourceSummary')
          ..add('id', id)
          ..add('status', status)
          ..add('updatedAt', updatedAt))
        .toString();
  }
}

class PendingResourceSummaryBuilder
    implements Builder<PendingResourceSummary, PendingResourceSummaryBuilder> {
  _$PendingResourceSummary? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _status;
  String? get status => _$this._status;
  set status(String? status) => _$this._status = status;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  PendingResourceSummaryBuilder() {
    PendingResourceSummary._defaults(this);
  }

  PendingResourceSummaryBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _status = $v.status;
      _updatedAt = $v.updatedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PendingResourceSummary other) {
    _$v = other as _$PendingResourceSummary;
  }

  @override
  void update(void Function(PendingResourceSummaryBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PendingResourceSummary build() => _build();

  _$PendingResourceSummary _build() {
    final _$result = _$v ??
        _$PendingResourceSummary._(
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'PendingResourceSummary', 'id'),
          status: BuiltValueNullFieldError.checkNotNull(
              status, r'PendingResourceSummary', 'status'),
          updatedAt: BuiltValueNullFieldError.checkNotNull(
              updatedAt, r'PendingResourceSummary', 'updatedAt'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
