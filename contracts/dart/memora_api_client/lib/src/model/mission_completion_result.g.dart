// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mission_completion_result.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const MissionCompletionResultEngagementStatusEnum
    _$missionCompletionResultEngagementStatusEnum_pending =
    const MissionCompletionResultEngagementStatusEnum._('pending');
const MissionCompletionResultEngagementStatusEnum
    _$missionCompletionResultEngagementStatusEnum_applied =
    const MissionCompletionResultEngagementStatusEnum._('applied');
const MissionCompletionResultEngagementStatusEnum
    _$missionCompletionResultEngagementStatusEnum_unknownDefaultOpenApi =
    const MissionCompletionResultEngagementStatusEnum._(
        'unknownDefaultOpenApi');

MissionCompletionResultEngagementStatusEnum
    _$missionCompletionResultEngagementStatusEnumValueOf(String name) {
  switch (name) {
    case 'pending':
      return _$missionCompletionResultEngagementStatusEnum_pending;
    case 'applied':
      return _$missionCompletionResultEngagementStatusEnum_applied;
    case 'unknownDefaultOpenApi':
      return _$missionCompletionResultEngagementStatusEnum_unknownDefaultOpenApi;
    default:
      return _$missionCompletionResultEngagementStatusEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<MissionCompletionResultEngagementStatusEnum>
    _$missionCompletionResultEngagementStatusEnumValues = BuiltSet<
        MissionCompletionResultEngagementStatusEnum>(const <MissionCompletionResultEngagementStatusEnum>[
  _$missionCompletionResultEngagementStatusEnum_pending,
  _$missionCompletionResultEngagementStatusEnum_applied,
  _$missionCompletionResultEngagementStatusEnum_unknownDefaultOpenApi,
]);

const MissionCompletionResultNextSuggestedActionEnum
    _$missionCompletionResultNextSuggestedActionEnum_home =
    const MissionCompletionResultNextSuggestedActionEnum._('home');
const MissionCompletionResultNextSuggestedActionEnum
    _$missionCompletionResultNextSuggestedActionEnum_progress =
    const MissionCompletionResultNextSuggestedActionEnum._('progress');
const MissionCompletionResultNextSuggestedActionEnum
    _$missionCompletionResultNextSuggestedActionEnum_unknownDefaultOpenApi =
    const MissionCompletionResultNextSuggestedActionEnum._(
        'unknownDefaultOpenApi');

MissionCompletionResultNextSuggestedActionEnum
    _$missionCompletionResultNextSuggestedActionEnumValueOf(String name) {
  switch (name) {
    case 'home':
      return _$missionCompletionResultNextSuggestedActionEnum_home;
    case 'progress':
      return _$missionCompletionResultNextSuggestedActionEnum_progress;
    case 'unknownDefaultOpenApi':
      return _$missionCompletionResultNextSuggestedActionEnum_unknownDefaultOpenApi;
    default:
      return _$missionCompletionResultNextSuggestedActionEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<MissionCompletionResultNextSuggestedActionEnum>
    _$missionCompletionResultNextSuggestedActionEnumValues = BuiltSet<
        MissionCompletionResultNextSuggestedActionEnum>(const <MissionCompletionResultNextSuggestedActionEnum>[
  _$missionCompletionResultNextSuggestedActionEnum_home,
  _$missionCompletionResultNextSuggestedActionEnum_progress,
  _$missionCompletionResultNextSuggestedActionEnum_unknownDefaultOpenApi,
]);

const MissionCompletionResultStatusEnum
    _$missionCompletionResultStatusEnum_completed =
    const MissionCompletionResultStatusEnum._('completed');
const MissionCompletionResultStatusEnum
    _$missionCompletionResultStatusEnum_unknownDefaultOpenApi =
    const MissionCompletionResultStatusEnum._('unknownDefaultOpenApi');

MissionCompletionResultStatusEnum _$missionCompletionResultStatusEnumValueOf(
    String name) {
  switch (name) {
    case 'completed':
      return _$missionCompletionResultStatusEnum_completed;
    case 'unknownDefaultOpenApi':
      return _$missionCompletionResultStatusEnum_unknownDefaultOpenApi;
    default:
      return _$missionCompletionResultStatusEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<MissionCompletionResultStatusEnum>
    _$missionCompletionResultStatusEnumValues = BuiltSet<
        MissionCompletionResultStatusEnum>(const <MissionCompletionResultStatusEnum>[
  _$missionCompletionResultStatusEnum_completed,
  _$missionCompletionResultStatusEnum_unknownDefaultOpenApi,
]);

Serializer<MissionCompletionResultEngagementStatusEnum>
    _$missionCompletionResultEngagementStatusEnumSerializer =
    _$MissionCompletionResultEngagementStatusEnumSerializer();
Serializer<MissionCompletionResultNextSuggestedActionEnum>
    _$missionCompletionResultNextSuggestedActionEnumSerializer =
    _$MissionCompletionResultNextSuggestedActionEnumSerializer();
Serializer<MissionCompletionResultStatusEnum>
    _$missionCompletionResultStatusEnumSerializer =
    _$MissionCompletionResultStatusEnumSerializer();

class _$MissionCompletionResultEngagementStatusEnumSerializer
    implements
        PrimitiveSerializer<MissionCompletionResultEngagementStatusEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'pending': 'pending',
    'applied': 'applied',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'pending': 'pending',
    'applied': 'applied',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[
    MissionCompletionResultEngagementStatusEnum
  ];
  @override
  final String wireName = 'MissionCompletionResultEngagementStatusEnum';

  @override
  Object serialize(Serializers serializers,
          MissionCompletionResultEngagementStatusEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  MissionCompletionResultEngagementStatusEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      MissionCompletionResultEngagementStatusEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$MissionCompletionResultNextSuggestedActionEnumSerializer
    implements
        PrimitiveSerializer<MissionCompletionResultNextSuggestedActionEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'home': 'home',
    'progress': 'progress',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'home': 'home',
    'progress': 'progress',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[
    MissionCompletionResultNextSuggestedActionEnum
  ];
  @override
  final String wireName = 'MissionCompletionResultNextSuggestedActionEnum';

  @override
  Object serialize(Serializers serializers,
          MissionCompletionResultNextSuggestedActionEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  MissionCompletionResultNextSuggestedActionEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      MissionCompletionResultNextSuggestedActionEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$MissionCompletionResultStatusEnumSerializer
    implements PrimitiveSerializer<MissionCompletionResultStatusEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'completed': 'completed',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'completed': 'completed',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[MissionCompletionResultStatusEnum];
  @override
  final String wireName = 'MissionCompletionResultStatusEnum';

  @override
  Object serialize(
          Serializers serializers, MissionCompletionResultStatusEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  MissionCompletionResultStatusEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      MissionCompletionResultStatusEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$MissionCompletionResult extends MissionCompletionResult {
  @override
  final String completedAt;
  @override
  final MissionCompletionResultEngagementStatusEnum engagementStatus;
  @override
  final String missionId;
  @override
  final MissionCompletionResultNextSuggestedActionEnum nextSuggestedAction;
  @override
  final int protectedCount;
  @override
  final Optional<MissionReefResult?> reefAfter;
  @override
  final Optional<MissionReefResult?> reefBefore;
  @override
  final int repairedCount;
  @override
  final BuiltList<MissionRewardGrant> rewardGrants;
  @override
  final int skippedCount;
  @override
  final MissionCompletionResultStatusEnum status;
  @override
  final Optional<MissionStreakResult?> streak;
  @override
  final Optional<int?> xpBalance;
  @override
  final Optional<int?> xpDelta;

  factory _$MissionCompletionResult(
          [void Function(MissionCompletionResultBuilder)? updates]) =>
      (MissionCompletionResultBuilder()..update(updates))._build();

  _$MissionCompletionResult._(
      {required this.completedAt,
      required this.engagementStatus,
      required this.missionId,
      required this.nextSuggestedAction,
      required this.protectedCount,
      required this.reefAfter,
      required this.reefBefore,
      required this.repairedCount,
      required this.rewardGrants,
      required this.skippedCount,
      required this.status,
      required this.streak,
      required this.xpBalance,
      required this.xpDelta})
      : super._();
  @override
  MissionCompletionResult rebuild(
          void Function(MissionCompletionResultBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MissionCompletionResultBuilder toBuilder() =>
      MissionCompletionResultBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MissionCompletionResult &&
        completedAt == other.completedAt &&
        engagementStatus == other.engagementStatus &&
        missionId == other.missionId &&
        nextSuggestedAction == other.nextSuggestedAction &&
        protectedCount == other.protectedCount &&
        reefAfter == other.reefAfter &&
        reefBefore == other.reefBefore &&
        repairedCount == other.repairedCount &&
        rewardGrants == other.rewardGrants &&
        skippedCount == other.skippedCount &&
        status == other.status &&
        streak == other.streak &&
        xpBalance == other.xpBalance &&
        xpDelta == other.xpDelta;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, completedAt.hashCode);
    _$hash = $jc(_$hash, engagementStatus.hashCode);
    _$hash = $jc(_$hash, missionId.hashCode);
    _$hash = $jc(_$hash, nextSuggestedAction.hashCode);
    _$hash = $jc(_$hash, protectedCount.hashCode);
    _$hash = $jc(_$hash, reefAfter.hashCode);
    _$hash = $jc(_$hash, reefBefore.hashCode);
    _$hash = $jc(_$hash, repairedCount.hashCode);
    _$hash = $jc(_$hash, rewardGrants.hashCode);
    _$hash = $jc(_$hash, skippedCount.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, streak.hashCode);
    _$hash = $jc(_$hash, xpBalance.hashCode);
    _$hash = $jc(_$hash, xpDelta.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'MissionCompletionResult')
          ..add('completedAt', completedAt)
          ..add('engagementStatus', engagementStatus)
          ..add('missionId', missionId)
          ..add('nextSuggestedAction', nextSuggestedAction)
          ..add('protectedCount', protectedCount)
          ..add('reefAfter', reefAfter)
          ..add('reefBefore', reefBefore)
          ..add('repairedCount', repairedCount)
          ..add('rewardGrants', rewardGrants)
          ..add('skippedCount', skippedCount)
          ..add('status', status)
          ..add('streak', streak)
          ..add('xpBalance', xpBalance)
          ..add('xpDelta', xpDelta))
        .toString();
  }
}

class MissionCompletionResultBuilder
    implements
        Builder<MissionCompletionResult, MissionCompletionResultBuilder> {
  _$MissionCompletionResult? _$v;

  String? _completedAt;
  String? get completedAt => _$this._completedAt;
  set completedAt(String? completedAt) => _$this._completedAt = completedAt;

  MissionCompletionResultEngagementStatusEnum? _engagementStatus;
  MissionCompletionResultEngagementStatusEnum? get engagementStatus =>
      _$this._engagementStatus;
  set engagementStatus(
          MissionCompletionResultEngagementStatusEnum? engagementStatus) =>
      _$this._engagementStatus = engagementStatus;

  String? _missionId;
  String? get missionId => _$this._missionId;
  set missionId(String? missionId) => _$this._missionId = missionId;

  MissionCompletionResultNextSuggestedActionEnum? _nextSuggestedAction;
  MissionCompletionResultNextSuggestedActionEnum? get nextSuggestedAction =>
      _$this._nextSuggestedAction;
  set nextSuggestedAction(
          MissionCompletionResultNextSuggestedActionEnum?
              nextSuggestedAction) =>
      _$this._nextSuggestedAction = nextSuggestedAction;

  int? _protectedCount;
  int? get protectedCount => _$this._protectedCount;
  set protectedCount(int? protectedCount) =>
      _$this._protectedCount = protectedCount;

  Optional<MissionReefResult?>? _reefAfter;
  Optional<MissionReefResult?>? get reefAfter => _$this._reefAfter;
  set reefAfter(Optional<MissionReefResult?>? reefAfter) =>
      _$this._reefAfter = reefAfter;

  Optional<MissionReefResult?>? _reefBefore;
  Optional<MissionReefResult?>? get reefBefore => _$this._reefBefore;
  set reefBefore(Optional<MissionReefResult?>? reefBefore) =>
      _$this._reefBefore = reefBefore;

  int? _repairedCount;
  int? get repairedCount => _$this._repairedCount;
  set repairedCount(int? repairedCount) =>
      _$this._repairedCount = repairedCount;

  ListBuilder<MissionRewardGrant>? _rewardGrants;
  ListBuilder<MissionRewardGrant> get rewardGrants =>
      _$this._rewardGrants ??= ListBuilder<MissionRewardGrant>();
  set rewardGrants(ListBuilder<MissionRewardGrant>? rewardGrants) =>
      _$this._rewardGrants = rewardGrants;

  int? _skippedCount;
  int? get skippedCount => _$this._skippedCount;
  set skippedCount(int? skippedCount) => _$this._skippedCount = skippedCount;

  MissionCompletionResultStatusEnum? _status;
  MissionCompletionResultStatusEnum? get status => _$this._status;
  set status(MissionCompletionResultStatusEnum? status) =>
      _$this._status = status;

  Optional<MissionStreakResult?>? _streak;
  Optional<MissionStreakResult?>? get streak => _$this._streak;
  set streak(Optional<MissionStreakResult?>? streak) => _$this._streak = streak;

  Optional<int?>? _xpBalance;
  Optional<int?>? get xpBalance => _$this._xpBalance;
  set xpBalance(Optional<int?>? xpBalance) => _$this._xpBalance = xpBalance;

  Optional<int?>? _xpDelta;
  Optional<int?>? get xpDelta => _$this._xpDelta;
  set xpDelta(Optional<int?>? xpDelta) => _$this._xpDelta = xpDelta;

  MissionCompletionResultBuilder() {
    MissionCompletionResult._defaults(this);
  }

  MissionCompletionResultBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _completedAt = $v.completedAt;
      _engagementStatus = $v.engagementStatus;
      _missionId = $v.missionId;
      _nextSuggestedAction = $v.nextSuggestedAction;
      _protectedCount = $v.protectedCount;
      _reefAfter = $v.reefAfter;
      _reefBefore = $v.reefBefore;
      _repairedCount = $v.repairedCount;
      _rewardGrants = $v.rewardGrants.toBuilder();
      _skippedCount = $v.skippedCount;
      _status = $v.status;
      _streak = $v.streak;
      _xpBalance = $v.xpBalance;
      _xpDelta = $v.xpDelta;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MissionCompletionResult other) {
    _$v = other as _$MissionCompletionResult;
  }

  @override
  void update(void Function(MissionCompletionResultBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MissionCompletionResult build() => _build();

  _$MissionCompletionResult _build() {
    _$MissionCompletionResult _$result;
    try {
      _$result = _$v ??
          _$MissionCompletionResult._(
            completedAt: BuiltValueNullFieldError.checkNotNull(
                completedAt, r'MissionCompletionResult', 'completedAt'),
            engagementStatus: BuiltValueNullFieldError.checkNotNull(
                engagementStatus,
                r'MissionCompletionResult',
                'engagementStatus'),
            missionId: BuiltValueNullFieldError.checkNotNull(
                missionId, r'MissionCompletionResult', 'missionId'),
            nextSuggestedAction: BuiltValueNullFieldError.checkNotNull(
                nextSuggestedAction,
                r'MissionCompletionResult',
                'nextSuggestedAction'),
            protectedCount: BuiltValueNullFieldError.checkNotNull(
                protectedCount, r'MissionCompletionResult', 'protectedCount'),
            reefAfter: BuiltValueNullFieldError.checkNotNull(
                reefAfter, r'MissionCompletionResult', 'reefAfter'),
            reefBefore: BuiltValueNullFieldError.checkNotNull(
                reefBefore, r'MissionCompletionResult', 'reefBefore'),
            repairedCount: BuiltValueNullFieldError.checkNotNull(
                repairedCount, r'MissionCompletionResult', 'repairedCount'),
            rewardGrants: rewardGrants.build(),
            skippedCount: BuiltValueNullFieldError.checkNotNull(
                skippedCount, r'MissionCompletionResult', 'skippedCount'),
            status: BuiltValueNullFieldError.checkNotNull(
                status, r'MissionCompletionResult', 'status'),
            streak: BuiltValueNullFieldError.checkNotNull(
                streak, r'MissionCompletionResult', 'streak'),
            xpBalance: BuiltValueNullFieldError.checkNotNull(
                xpBalance, r'MissionCompletionResult', 'xpBalance'),
            xpDelta: BuiltValueNullFieldError.checkNotNull(
                xpDelta, r'MissionCompletionResult', 'xpDelta'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'rewardGrants';
        rewardGrants.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'MissionCompletionResult', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
