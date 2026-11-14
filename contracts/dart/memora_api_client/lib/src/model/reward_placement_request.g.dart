// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reward_placement_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$RewardPlacementRequest extends RewardPlacementRequest {
  @override
  final Optional<String?> placementSlot;
  @override
  final Optional<String?> subjectId;
  @override
  final int version;

  factory _$RewardPlacementRequest(
          [void Function(RewardPlacementRequestBuilder)? updates]) =>
      (RewardPlacementRequestBuilder()..update(updates))._build();

  _$RewardPlacementRequest._(
      {required this.placementSlot,
      required this.subjectId,
      required this.version})
      : super._();
  @override
  RewardPlacementRequest rebuild(
          void Function(RewardPlacementRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RewardPlacementRequestBuilder toBuilder() =>
      RewardPlacementRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RewardPlacementRequest &&
        placementSlot == other.placementSlot &&
        subjectId == other.subjectId &&
        version == other.version;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, placementSlot.hashCode);
    _$hash = $jc(_$hash, subjectId.hashCode);
    _$hash = $jc(_$hash, version.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'RewardPlacementRequest')
          ..add('placementSlot', placementSlot)
          ..add('subjectId', subjectId)
          ..add('version', version))
        .toString();
  }
}

class RewardPlacementRequestBuilder
    implements Builder<RewardPlacementRequest, RewardPlacementRequestBuilder> {
  _$RewardPlacementRequest? _$v;

  Optional<String?>? _placementSlot;
  Optional<String?>? get placementSlot => _$this._placementSlot;
  set placementSlot(Optional<String?>? placementSlot) =>
      _$this._placementSlot = placementSlot;

  Optional<String?>? _subjectId;
  Optional<String?>? get subjectId => _$this._subjectId;
  set subjectId(Optional<String?>? subjectId) => _$this._subjectId = subjectId;

  int? _version;
  int? get version => _$this._version;
  set version(int? version) => _$this._version = version;

  RewardPlacementRequestBuilder() {
    RewardPlacementRequest._defaults(this);
  }

  RewardPlacementRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _placementSlot = $v.placementSlot;
      _subjectId = $v.subjectId;
      _version = $v.version;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RewardPlacementRequest other) {
    _$v = other as _$RewardPlacementRequest;
  }

  @override
  void update(void Function(RewardPlacementRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RewardPlacementRequest build() => _build();

  _$RewardPlacementRequest _build() {
    final _$result = _$v ??
        _$RewardPlacementRequest._(
          placementSlot: BuiltValueNullFieldError.checkNotNull(
              placementSlot, r'RewardPlacementRequest', 'placementSlot'),
          subjectId: BuiltValueNullFieldError.checkNotNull(
              subjectId, r'RewardPlacementRequest', 'subjectId'),
          version: BuiltValueNullFieldError.checkNotNull(
              version, r'RewardPlacementRequest', 'version'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
