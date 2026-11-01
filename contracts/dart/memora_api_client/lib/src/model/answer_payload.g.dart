// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'answer_payload.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const AnswerPayloadTypeEnum _$answerPayloadTypeEnum_singleChoice =
    const AnswerPayloadTypeEnum._('singleChoice');
const AnswerPayloadTypeEnum _$answerPayloadTypeEnum_multipleChoice =
    const AnswerPayloadTypeEnum._('multipleChoice');
const AnswerPayloadTypeEnum _$answerPayloadTypeEnum_numeric =
    const AnswerPayloadTypeEnum._('numeric');
const AnswerPayloadTypeEnum _$answerPayloadTypeEnum_shortAnswer =
    const AnswerPayloadTypeEnum._('shortAnswer');
const AnswerPayloadTypeEnum _$answerPayloadTypeEnum_unknownDefaultOpenApi =
    const AnswerPayloadTypeEnum._('unknownDefaultOpenApi');

AnswerPayloadTypeEnum _$answerPayloadTypeEnumValueOf(String name) {
  switch (name) {
    case 'singleChoice':
      return _$answerPayloadTypeEnum_singleChoice;
    case 'multipleChoice':
      return _$answerPayloadTypeEnum_multipleChoice;
    case 'numeric':
      return _$answerPayloadTypeEnum_numeric;
    case 'shortAnswer':
      return _$answerPayloadTypeEnum_shortAnswer;
    case 'unknownDefaultOpenApi':
      return _$answerPayloadTypeEnum_unknownDefaultOpenApi;
    default:
      return _$answerPayloadTypeEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<AnswerPayloadTypeEnum> _$answerPayloadTypeEnumValues =
    BuiltSet<AnswerPayloadTypeEnum>(const <AnswerPayloadTypeEnum>[
  _$answerPayloadTypeEnum_singleChoice,
  _$answerPayloadTypeEnum_multipleChoice,
  _$answerPayloadTypeEnum_numeric,
  _$answerPayloadTypeEnum_shortAnswer,
  _$answerPayloadTypeEnum_unknownDefaultOpenApi,
]);

Serializer<AnswerPayloadTypeEnum> _$answerPayloadTypeEnumSerializer =
    _$AnswerPayloadTypeEnumSerializer();

class _$AnswerPayloadTypeEnumSerializer
    implements PrimitiveSerializer<AnswerPayloadTypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'singleChoice': 'single_choice',
    'multipleChoice': 'multiple_choice',
    'numeric': 'numeric',
    'shortAnswer': 'short_answer',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'single_choice': 'singleChoice',
    'multiple_choice': 'multipleChoice',
    'numeric': 'numeric',
    'short_answer': 'shortAnswer',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[AnswerPayloadTypeEnum];
  @override
  final String wireName = 'AnswerPayloadTypeEnum';

  @override
  Object serialize(Serializers serializers, AnswerPayloadTypeEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  AnswerPayloadTypeEnum deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      AnswerPayloadTypeEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$AnswerPayload extends AnswerPayload {
  @override
  final OneOf oneOf;

  factory _$AnswerPayload([void Function(AnswerPayloadBuilder)? updates]) =>
      (AnswerPayloadBuilder()..update(updates))._build();

  _$AnswerPayload._({required this.oneOf}) : super._();
  @override
  AnswerPayload rebuild(void Function(AnswerPayloadBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AnswerPayloadBuilder toBuilder() => AnswerPayloadBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AnswerPayload && oneOf == other.oneOf;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, oneOf.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AnswerPayload')..add('oneOf', oneOf))
        .toString();
  }
}

class AnswerPayloadBuilder
    implements Builder<AnswerPayload, AnswerPayloadBuilder> {
  _$AnswerPayload? _$v;

  OneOf? _oneOf;
  OneOf? get oneOf => _$this._oneOf;
  set oneOf(OneOf? oneOf) => _$this._oneOf = oneOf;

  AnswerPayloadBuilder() {
    AnswerPayload._defaults(this);
  }

  AnswerPayloadBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _oneOf = $v.oneOf;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AnswerPayload other) {
    _$v = other as _$AnswerPayload;
  }

  @override
  void update(void Function(AnswerPayloadBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AnswerPayload build() => _build();

  _$AnswerPayload _build() {
    final _$result = _$v ??
        _$AnswerPayload._(
          oneOf: BuiltValueNullFieldError.checkNotNull(
              oneOf, r'AnswerPayload', 'oneOf'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
