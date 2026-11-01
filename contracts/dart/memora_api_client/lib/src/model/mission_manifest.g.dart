// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mission_manifest.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$MissionManifest extends MissionManifest {
  @override
  final BuiltList<MissionManifestItem> items;
  @override
  final MissionSummary mission;

  factory _$MissionManifest([void Function(MissionManifestBuilder)? updates]) =>
      (MissionManifestBuilder()..update(updates))._build();

  _$MissionManifest._({required this.items, required this.mission}) : super._();
  @override
  MissionManifest rebuild(void Function(MissionManifestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MissionManifestBuilder toBuilder() => MissionManifestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MissionManifest &&
        items == other.items &&
        mission == other.mission;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, items.hashCode);
    _$hash = $jc(_$hash, mission.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'MissionManifest')
          ..add('items', items)
          ..add('mission', mission))
        .toString();
  }
}

class MissionManifestBuilder
    implements Builder<MissionManifest, MissionManifestBuilder> {
  _$MissionManifest? _$v;

  ListBuilder<MissionManifestItem>? _items;
  ListBuilder<MissionManifestItem> get items =>
      _$this._items ??= ListBuilder<MissionManifestItem>();
  set items(ListBuilder<MissionManifestItem>? items) => _$this._items = items;

  MissionSummaryBuilder? _mission;
  MissionSummaryBuilder get mission =>
      _$this._mission ??= MissionSummaryBuilder();
  set mission(MissionSummaryBuilder? mission) => _$this._mission = mission;

  MissionManifestBuilder() {
    MissionManifest._defaults(this);
  }

  MissionManifestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _items = $v.items.toBuilder();
      _mission = $v.mission.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MissionManifest other) {
    _$v = other as _$MissionManifest;
  }

  @override
  void update(void Function(MissionManifestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MissionManifest build() => _build();

  _$MissionManifest _build() {
    _$MissionManifest _$result;
    try {
      _$result = _$v ??
          _$MissionManifest._(
            items: items.build(),
            mission: mission.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'items';
        items.build();
        _$failedField = 'mission';
        mission.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'MissionManifest', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
