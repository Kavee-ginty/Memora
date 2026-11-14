// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reward_grant.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const RewardGrantPermittedActionsEnum _$rewardGrantPermittedActionsEnum_place =
    const RewardGrantPermittedActionsEnum._('place');
const RewardGrantPermittedActionsEnum _$rewardGrantPermittedActionsEnum_move =
    const RewardGrantPermittedActionsEnum._('move');
const RewardGrantPermittedActionsEnum _$rewardGrantPermittedActionsEnum_remove =
    const RewardGrantPermittedActionsEnum._('remove');
const RewardGrantPermittedActionsEnum
    _$rewardGrantPermittedActionsEnum_unknownDefaultOpenApi =
    const RewardGrantPermittedActionsEnum._('unknownDefaultOpenApi');

RewardGrantPermittedActionsEnum _$rewardGrantPermittedActionsEnumValueOf(
    String name) {
  switch (name) {
    case 'place':
      return _$rewardGrantPermittedActionsEnum_place;
    case 'move':
      return _$rewardGrantPermittedActionsEnum_move;
    case 'remove':
      return _$rewardGrantPermittedActionsEnum_remove;
    case 'unknownDefaultOpenApi':
      return _$rewardGrantPermittedActionsEnum_unknownDefaultOpenApi;
    default:
      return _$rewardGrantPermittedActionsEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<RewardGrantPermittedActionsEnum>
    _$rewardGrantPermittedActionsEnumValues = BuiltSet<
        RewardGrantPermittedActionsEnum>(const <RewardGrantPermittedActionsEnum>[
  _$rewardGrantPermittedActionsEnum_place,
  _$rewardGrantPermittedActionsEnum_move,
  _$rewardGrantPermittedActionsEnum_remove,
  _$rewardGrantPermittedActionsEnum_unknownDefaultOpenApi,
]);

const RewardGrantPlacementStateEnum _$rewardGrantPlacementStateEnum_unplaced =
    const RewardGrantPlacementStateEnum._('unplaced');
const RewardGrantPlacementStateEnum _$rewardGrantPlacementStateEnum_placed =
    const RewardGrantPlacementStateEnum._('placed');
const RewardGrantPlacementStateEnum
    _$rewardGrantPlacementStateEnum_unknownDefaultOpenApi =
    const RewardGrantPlacementStateEnum._('unknownDefaultOpenApi');

RewardGrantPlacementStateEnum _$rewardGrantPlacementStateEnumValueOf(
    String name) {
  switch (name) {
    case 'unplaced':
      return _$rewardGrantPlacementStateEnum_unplaced;
    case 'placed':
      return _$rewardGrantPlacementStateEnum_placed;
    case 'unknownDefaultOpenApi':
      return _$rewardGrantPlacementStateEnum_unknownDefaultOpenApi;
    default:
      return _$rewardGrantPlacementStateEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<RewardGrantPlacementStateEnum>
    _$rewardGrantPlacementStateEnumValues = BuiltSet<
        RewardGrantPlacementStateEnum>(const <RewardGrantPlacementStateEnum>[
  _$rewardGrantPlacementStateEnum_unplaced,
  _$rewardGrantPlacementStateEnum_placed,
  _$rewardGrantPlacementStateEnum_unknownDefaultOpenApi,
]);

const RewardGrantRewardTypeEnum _$rewardGrantRewardTypeEnum_decoration =
    const RewardGrantRewardTypeEnum._('decoration');
const RewardGrantRewardTypeEnum _$rewardGrantRewardTypeEnum_moraCosmetic =
    const RewardGrantRewardTypeEnum._('moraCosmetic');
const RewardGrantRewardTypeEnum
    _$rewardGrantRewardTypeEnum_unknownDefaultOpenApi =
    const RewardGrantRewardTypeEnum._('unknownDefaultOpenApi');

RewardGrantRewardTypeEnum _$rewardGrantRewardTypeEnumValueOf(String name) {
  switch (name) {
    case 'decoration':
      return _$rewardGrantRewardTypeEnum_decoration;
    case 'moraCosmetic':
      return _$rewardGrantRewardTypeEnum_moraCosmetic;
    case 'unknownDefaultOpenApi':
      return _$rewardGrantRewardTypeEnum_unknownDefaultOpenApi;
    default:
      return _$rewardGrantRewardTypeEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<RewardGrantRewardTypeEnum> _$rewardGrantRewardTypeEnumValues =
    BuiltSet<RewardGrantRewardTypeEnum>(const <RewardGrantRewardTypeEnum>[
  _$rewardGrantRewardTypeEnum_decoration,
  _$rewardGrantRewardTypeEnum_moraCosmetic,
  _$rewardGrantRewardTypeEnum_unknownDefaultOpenApi,
]);

Serializer<RewardGrantPermittedActionsEnum>
    _$rewardGrantPermittedActionsEnumSerializer =
    _$RewardGrantPermittedActionsEnumSerializer();
Serializer<RewardGrantPlacementStateEnum>
    _$rewardGrantPlacementStateEnumSerializer =
    _$RewardGrantPlacementStateEnumSerializer();
Serializer<RewardGrantRewardTypeEnum> _$rewardGrantRewardTypeEnumSerializer =
    _$RewardGrantRewardTypeEnumSerializer();

class _$RewardGrantPermittedActionsEnumSerializer
    implements PrimitiveSerializer<RewardGrantPermittedActionsEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'place': 'place',
    'move': 'move',
    'remove': 'remove',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'place': 'place',
    'move': 'move',
    'remove': 'remove',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[RewardGrantPermittedActionsEnum];
  @override
  final String wireName = 'RewardGrantPermittedActionsEnum';

  @override
  Object serialize(
          Serializers serializers, RewardGrantPermittedActionsEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  RewardGrantPermittedActionsEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      RewardGrantPermittedActionsEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$RewardGrantPlacementStateEnumSerializer
    implements PrimitiveSerializer<RewardGrantPlacementStateEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'unplaced': 'unplaced',
    'placed': 'placed',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'unplaced': 'unplaced',
    'placed': 'placed',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[RewardGrantPlacementStateEnum];
  @override
  final String wireName = 'RewardGrantPlacementStateEnum';

  @override
  Object serialize(
          Serializers serializers, RewardGrantPlacementStateEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  RewardGrantPlacementStateEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      RewardGrantPlacementStateEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$RewardGrantRewardTypeEnumSerializer
    implements PrimitiveSerializer<RewardGrantRewardTypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'decoration': 'decoration',
    'moraCosmetic': 'mora_cosmetic',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'decoration': 'decoration',
    'mora_cosmetic': 'moraCosmetic',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[RewardGrantRewardTypeEnum];
  @override
  final String wireName = 'RewardGrantRewardTypeEnum';

  @override
  Object serialize(Serializers serializers, RewardGrantRewardTypeEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  RewardGrantRewardTypeEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      RewardGrantRewardTypeEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$RewardGrant extends RewardGrant {
  @override
  final String assetKey;
  @override
  final String grantId;
  @override
  final String grantedAt;
  @override
  final BuiltList<RewardGrantPermittedActionsEnum> permittedActions;
  @override
  final String? placedSubjectId;
  @override
  final String? placementSlot;
  @override
  final RewardGrantPlacementStateEnum placementState;
  @override
  final String rewardCode;
  @override
  final RewardGrantRewardTypeEnum rewardType;
  @override
  final String title;
  @override
  final int version;

  factory _$RewardGrant([void Function(RewardGrantBuilder)? updates]) =>
      (RewardGrantBuilder()..update(updates))._build();

  _$RewardGrant._(
      {required this.assetKey,
      required this.grantId,
      required this.grantedAt,
      required this.permittedActions,
      this.placedSubjectId,
      this.placementSlot,
      required this.placementState,
      required this.rewardCode,
      required this.rewardType,
      required this.title,
      required this.version})
      : super._();
  @override
  RewardGrant rebuild(void Function(RewardGrantBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RewardGrantBuilder toBuilder() => RewardGrantBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RewardGrant &&
        assetKey == other.assetKey &&
        grantId == other.grantId &&
        grantedAt == other.grantedAt &&
        permittedActions == other.permittedActions &&
        placedSubjectId == other.placedSubjectId &&
        placementSlot == other.placementSlot &&
        placementState == other.placementState &&
        rewardCode == other.rewardCode &&
        rewardType == other.rewardType &&
        title == other.title &&
        version == other.version;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, assetKey.hashCode);
    _$hash = $jc(_$hash, grantId.hashCode);
    _$hash = $jc(_$hash, grantedAt.hashCode);
    _$hash = $jc(_$hash, permittedActions.hashCode);
    _$hash = $jc(_$hash, placedSubjectId.hashCode);
    _$hash = $jc(_$hash, placementSlot.hashCode);
    _$hash = $jc(_$hash, placementState.hashCode);
    _$hash = $jc(_$hash, rewardCode.hashCode);
    _$hash = $jc(_$hash, rewardType.hashCode);
    _$hash = $jc(_$hash, title.hashCode);
    _$hash = $jc(_$hash, version.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'RewardGrant')
          ..add('assetKey', assetKey)
          ..add('grantId', grantId)
          ..add('grantedAt', grantedAt)
          ..add('permittedActions', permittedActions)
          ..add('placedSubjectId', placedSubjectId)
          ..add('placementSlot', placementSlot)
          ..add('placementState', placementState)
          ..add('rewardCode', rewardCode)
          ..add('rewardType', rewardType)
          ..add('title', title)
          ..add('version', version))
        .toString();
  }
}

class RewardGrantBuilder implements Builder<RewardGrant, RewardGrantBuilder> {
  _$RewardGrant? _$v;

  String? _assetKey;
  String? get assetKey => _$this._assetKey;
  set assetKey(String? assetKey) => _$this._assetKey = assetKey;

  String? _grantId;
  String? get grantId => _$this._grantId;
  set grantId(String? grantId) => _$this._grantId = grantId;

  String? _grantedAt;
  String? get grantedAt => _$this._grantedAt;
  set grantedAt(String? grantedAt) => _$this._grantedAt = grantedAt;

  ListBuilder<RewardGrantPermittedActionsEnum>? _permittedActions;
  ListBuilder<RewardGrantPermittedActionsEnum> get permittedActions =>
      _$this._permittedActions ??=
          ListBuilder<RewardGrantPermittedActionsEnum>();
  set permittedActions(
          ListBuilder<RewardGrantPermittedActionsEnum>? permittedActions) =>
      _$this._permittedActions = permittedActions;

  String? _placedSubjectId;
  String? get placedSubjectId => _$this._placedSubjectId;
  set placedSubjectId(String? placedSubjectId) =>
      _$this._placedSubjectId = placedSubjectId;

  String? _placementSlot;
  String? get placementSlot => _$this._placementSlot;
  set placementSlot(String? placementSlot) =>
      _$this._placementSlot = placementSlot;

  RewardGrantPlacementStateEnum? _placementState;
  RewardGrantPlacementStateEnum? get placementState => _$this._placementState;
  set placementState(RewardGrantPlacementStateEnum? placementState) =>
      _$this._placementState = placementState;

  String? _rewardCode;
  String? get rewardCode => _$this._rewardCode;
  set rewardCode(String? rewardCode) => _$this._rewardCode = rewardCode;

  RewardGrantRewardTypeEnum? _rewardType;
  RewardGrantRewardTypeEnum? get rewardType => _$this._rewardType;
  set rewardType(RewardGrantRewardTypeEnum? rewardType) =>
      _$this._rewardType = rewardType;

  String? _title;
  String? get title => _$this._title;
  set title(String? title) => _$this._title = title;

  int? _version;
  int? get version => _$this._version;
  set version(int? version) => _$this._version = version;

  RewardGrantBuilder() {
    RewardGrant._defaults(this);
  }

  RewardGrantBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _assetKey = $v.assetKey;
      _grantId = $v.grantId;
      _grantedAt = $v.grantedAt;
      _permittedActions = $v.permittedActions.toBuilder();
      _placedSubjectId = $v.placedSubjectId;
      _placementSlot = $v.placementSlot;
      _placementState = $v.placementState;
      _rewardCode = $v.rewardCode;
      _rewardType = $v.rewardType;
      _title = $v.title;
      _version = $v.version;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RewardGrant other) {
    _$v = other as _$RewardGrant;
  }

  @override
  void update(void Function(RewardGrantBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RewardGrant build() => _build();

  _$RewardGrant _build() {
    _$RewardGrant _$result;
    try {
      _$result = _$v ??
          _$RewardGrant._(
            assetKey: BuiltValueNullFieldError.checkNotNull(
                assetKey, r'RewardGrant', 'assetKey'),
            grantId: BuiltValueNullFieldError.checkNotNull(
                grantId, r'RewardGrant', 'grantId'),
            grantedAt: BuiltValueNullFieldError.checkNotNull(
                grantedAt, r'RewardGrant', 'grantedAt'),
            permittedActions: permittedActions.build(),
            placedSubjectId: placedSubjectId,
            placementSlot: placementSlot,
            placementState: BuiltValueNullFieldError.checkNotNull(
                placementState, r'RewardGrant', 'placementState'),
            rewardCode: BuiltValueNullFieldError.checkNotNull(
                rewardCode, r'RewardGrant', 'rewardCode'),
            rewardType: BuiltValueNullFieldError.checkNotNull(
                rewardType, r'RewardGrant', 'rewardType'),
            title: BuiltValueNullFieldError.checkNotNull(
                title, r'RewardGrant', 'title'),
            version: BuiltValueNullFieldError.checkNotNull(
                version, r'RewardGrant', 'version'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'permittedActions';
        permittedActions.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'RewardGrant', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
