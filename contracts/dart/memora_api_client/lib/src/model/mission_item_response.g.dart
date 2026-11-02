// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mission_item_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const MissionItemResponseMissionTypeEnum
    _$missionItemResponseMissionTypeEnum_protect =
    const MissionItemResponseMissionTypeEnum._('protect');
const MissionItemResponseMissionTypeEnum
    _$missionItemResponseMissionTypeEnum_repair =
    const MissionItemResponseMissionTypeEnum._('repair');
const MissionItemResponseMissionTypeEnum
    _$missionItemResponseMissionTypeEnum_recover =
    const MissionItemResponseMissionTypeEnum._('recover');
const MissionItemResponseMissionTypeEnum
    _$missionItemResponseMissionTypeEnum_discover =
    const MissionItemResponseMissionTypeEnum._('discover');
const MissionItemResponseMissionTypeEnum
    _$missionItemResponseMissionTypeEnum_challenge =
    const MissionItemResponseMissionTypeEnum._('challenge');
const MissionItemResponseMissionTypeEnum
    _$missionItemResponseMissionTypeEnum_unknownDefaultOpenApi =
    const MissionItemResponseMissionTypeEnum._('unknownDefaultOpenApi');

MissionItemResponseMissionTypeEnum _$missionItemResponseMissionTypeEnumValueOf(
    String name) {
  switch (name) {
    case 'protect':
      return _$missionItemResponseMissionTypeEnum_protect;
    case 'repair':
      return _$missionItemResponseMissionTypeEnum_repair;
    case 'recover':
      return _$missionItemResponseMissionTypeEnum_recover;
    case 'discover':
      return _$missionItemResponseMissionTypeEnum_discover;
    case 'challenge':
      return _$missionItemResponseMissionTypeEnum_challenge;
    case 'unknownDefaultOpenApi':
      return _$missionItemResponseMissionTypeEnum_unknownDefaultOpenApi;
    default:
      return _$missionItemResponseMissionTypeEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<MissionItemResponseMissionTypeEnum>
    _$missionItemResponseMissionTypeEnumValues = BuiltSet<
        MissionItemResponseMissionTypeEnum>(const <MissionItemResponseMissionTypeEnum>[
  _$missionItemResponseMissionTypeEnum_protect,
  _$missionItemResponseMissionTypeEnum_repair,
  _$missionItemResponseMissionTypeEnum_recover,
  _$missionItemResponseMissionTypeEnum_discover,
  _$missionItemResponseMissionTypeEnum_challenge,
  _$missionItemResponseMissionTypeEnum_unknownDefaultOpenApi,
]);

const MissionItemResponseStatusEnum _$missionItemResponseStatusEnum_pending =
    const MissionItemResponseStatusEnum._('pending');
const MissionItemResponseStatusEnum _$missionItemResponseStatusEnum_presented =
    const MissionItemResponseStatusEnum._('presented');
const MissionItemResponseStatusEnum _$missionItemResponseStatusEnum_answered =
    const MissionItemResponseStatusEnum._('answered');
const MissionItemResponseStatusEnum _$missionItemResponseStatusEnum_skipped =
    const MissionItemResponseStatusEnum._('skipped');
const MissionItemResponseStatusEnum _$missionItemResponseStatusEnum_cancelled =
    const MissionItemResponseStatusEnum._('cancelled');
const MissionItemResponseStatusEnum
    _$missionItemResponseStatusEnum_unknownDefaultOpenApi =
    const MissionItemResponseStatusEnum._('unknownDefaultOpenApi');

MissionItemResponseStatusEnum _$missionItemResponseStatusEnumValueOf(
    String name) {
  switch (name) {
    case 'pending':
      return _$missionItemResponseStatusEnum_pending;
    case 'presented':
      return _$missionItemResponseStatusEnum_presented;
    case 'answered':
      return _$missionItemResponseStatusEnum_answered;
    case 'skipped':
      return _$missionItemResponseStatusEnum_skipped;
    case 'cancelled':
      return _$missionItemResponseStatusEnum_cancelled;
    case 'unknownDefaultOpenApi':
      return _$missionItemResponseStatusEnum_unknownDefaultOpenApi;
    default:
      return _$missionItemResponseStatusEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<MissionItemResponseStatusEnum>
    _$missionItemResponseStatusEnumValues = BuiltSet<
        MissionItemResponseStatusEnum>(const <MissionItemResponseStatusEnum>[
  _$missionItemResponseStatusEnum_pending,
  _$missionItemResponseStatusEnum_presented,
  _$missionItemResponseStatusEnum_answered,
  _$missionItemResponseStatusEnum_skipped,
  _$missionItemResponseStatusEnum_cancelled,
  _$missionItemResponseStatusEnum_unknownDefaultOpenApi,
]);

Serializer<MissionItemResponseMissionTypeEnum>
    _$missionItemResponseMissionTypeEnumSerializer =
    _$MissionItemResponseMissionTypeEnumSerializer();
Serializer<MissionItemResponseStatusEnum>
    _$missionItemResponseStatusEnumSerializer =
    _$MissionItemResponseStatusEnumSerializer();

class _$MissionItemResponseMissionTypeEnumSerializer
    implements PrimitiveSerializer<MissionItemResponseMissionTypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'protect': 'protect',
    'repair': 'repair',
    'recover': 'recover',
    'discover': 'discover',
    'challenge': 'challenge',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'protect': 'protect',
    'repair': 'repair',
    'recover': 'recover',
    'discover': 'discover',
    'challenge': 'challenge',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[MissionItemResponseMissionTypeEnum];
  @override
  final String wireName = 'MissionItemResponseMissionTypeEnum';

  @override
  Object serialize(
          Serializers serializers, MissionItemResponseMissionTypeEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  MissionItemResponseMissionTypeEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      MissionItemResponseMissionTypeEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$MissionItemResponseStatusEnumSerializer
    implements PrimitiveSerializer<MissionItemResponseStatusEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'pending': 'pending',
    'presented': 'presented',
    'answered': 'answered',
    'skipped': 'skipped',
    'cancelled': 'cancelled',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'pending': 'pending',
    'presented': 'presented',
    'answered': 'answered',
    'skipped': 'skipped',
    'cancelled': 'cancelled',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[MissionItemResponseStatusEnum];
  @override
  final String wireName = 'MissionItemResponseStatusEnum';

  @override
  Object serialize(
          Serializers serializers, MissionItemResponseStatusEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  MissionItemResponseStatusEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      MissionItemResponseStatusEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$MissionItemResponse extends MissionItemResponse {
  @override
  final String dueReason;
  @override
  final String id;
  @override
  final String missionId;
  @override
  final MissionItemResponseMissionTypeEnum missionType;
  @override
  final int position;
  @override
  final PublicQuestion question;
  @override
  final AttemptResult? result;
  @override
  final BuiltList<String> selectionReasonCodes;
  @override
  final MissionItemResponseStatusEnum status;

  factory _$MissionItemResponse(
          [void Function(MissionItemResponseBuilder)? updates]) =>
      (MissionItemResponseBuilder()..update(updates))._build();

  _$MissionItemResponse._(
      {required this.dueReason,
      required this.id,
      required this.missionId,
      required this.missionType,
      required this.position,
      required this.question,
      this.result,
      required this.selectionReasonCodes,
      required this.status})
      : super._();
  @override
  MissionItemResponse rebuild(
          void Function(MissionItemResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MissionItemResponseBuilder toBuilder() =>
      MissionItemResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MissionItemResponse &&
        dueReason == other.dueReason &&
        id == other.id &&
        missionId == other.missionId &&
        missionType == other.missionType &&
        position == other.position &&
        question == other.question &&
        result == other.result &&
        selectionReasonCodes == other.selectionReasonCodes &&
        status == other.status;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, dueReason.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, missionId.hashCode);
    _$hash = $jc(_$hash, missionType.hashCode);
    _$hash = $jc(_$hash, position.hashCode);
    _$hash = $jc(_$hash, question.hashCode);
    _$hash = $jc(_$hash, result.hashCode);
    _$hash = $jc(_$hash, selectionReasonCodes.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'MissionItemResponse')
          ..add('dueReason', dueReason)
          ..add('id', id)
          ..add('missionId', missionId)
          ..add('missionType', missionType)
          ..add('position', position)
          ..add('question', question)
          ..add('result', result)
          ..add('selectionReasonCodes', selectionReasonCodes)
          ..add('status', status))
        .toString();
  }
}

class MissionItemResponseBuilder
    implements Builder<MissionItemResponse, MissionItemResponseBuilder> {
  _$MissionItemResponse? _$v;

  String? _dueReason;
  String? get dueReason => _$this._dueReason;
  set dueReason(String? dueReason) => _$this._dueReason = dueReason;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _missionId;
  String? get missionId => _$this._missionId;
  set missionId(String? missionId) => _$this._missionId = missionId;

  MissionItemResponseMissionTypeEnum? _missionType;
  MissionItemResponseMissionTypeEnum? get missionType => _$this._missionType;
  set missionType(MissionItemResponseMissionTypeEnum? missionType) =>
      _$this._missionType = missionType;

  int? _position;
  int? get position => _$this._position;
  set position(int? position) => _$this._position = position;

  PublicQuestionBuilder? _question;
  PublicQuestionBuilder get question =>
      _$this._question ??= PublicQuestionBuilder();
  set question(PublicQuestionBuilder? question) => _$this._question = question;

  AttemptResultBuilder? _result;
  AttemptResultBuilder get result => _$this._result ??= AttemptResultBuilder();
  set result(AttemptResultBuilder? result) => _$this._result = result;

  ListBuilder<String>? _selectionReasonCodes;
  ListBuilder<String> get selectionReasonCodes =>
      _$this._selectionReasonCodes ??= ListBuilder<String>();
  set selectionReasonCodes(ListBuilder<String>? selectionReasonCodes) =>
      _$this._selectionReasonCodes = selectionReasonCodes;

  MissionItemResponseStatusEnum? _status;
  MissionItemResponseStatusEnum? get status => _$this._status;
  set status(MissionItemResponseStatusEnum? status) => _$this._status = status;

  MissionItemResponseBuilder() {
    MissionItemResponse._defaults(this);
  }

  MissionItemResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _dueReason = $v.dueReason;
      _id = $v.id;
      _missionId = $v.missionId;
      _missionType = $v.missionType;
      _position = $v.position;
      _question = $v.question.toBuilder();
      _result = $v.result?.toBuilder();
      _selectionReasonCodes = $v.selectionReasonCodes.toBuilder();
      _status = $v.status;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MissionItemResponse other) {
    _$v = other as _$MissionItemResponse;
  }

  @override
  void update(void Function(MissionItemResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MissionItemResponse build() => _build();

  _$MissionItemResponse _build() {
    _$MissionItemResponse _$result;
    try {
      _$result = _$v ??
          _$MissionItemResponse._(
            dueReason: BuiltValueNullFieldError.checkNotNull(
                dueReason, r'MissionItemResponse', 'dueReason'),
            id: BuiltValueNullFieldError.checkNotNull(
                id, r'MissionItemResponse', 'id'),
            missionId: BuiltValueNullFieldError.checkNotNull(
                missionId, r'MissionItemResponse', 'missionId'),
            missionType: BuiltValueNullFieldError.checkNotNull(
                missionType, r'MissionItemResponse', 'missionType'),
            position: BuiltValueNullFieldError.checkNotNull(
                position, r'MissionItemResponse', 'position'),
            question: question.build(),
            result: _result?.build(),
            selectionReasonCodes: selectionReasonCodes.build(),
            status: BuiltValueNullFieldError.checkNotNull(
                status, r'MissionItemResponse', 'status'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'question';
        question.build();
        _$failedField = 'result';
        _result?.build();
        _$failedField = 'selectionReasonCodes';
        selectionReasonCodes.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'MissionItemResponse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
