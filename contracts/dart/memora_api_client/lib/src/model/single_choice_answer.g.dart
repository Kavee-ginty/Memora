// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'single_choice_answer.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const SingleChoiceAnswerTypeEnum _$singleChoiceAnswerTypeEnum_singleChoice =
    const SingleChoiceAnswerTypeEnum._('singleChoice');
const SingleChoiceAnswerTypeEnum
    _$singleChoiceAnswerTypeEnum_unknownDefaultOpenApi =
    const SingleChoiceAnswerTypeEnum._('unknownDefaultOpenApi');

SingleChoiceAnswerTypeEnum _$singleChoiceAnswerTypeEnumValueOf(String name) {
  switch (name) {
    case 'singleChoice':
      return _$singleChoiceAnswerTypeEnum_singleChoice;
    case 'unknownDefaultOpenApi':
      return _$singleChoiceAnswerTypeEnum_unknownDefaultOpenApi;
    default:
      return _$singleChoiceAnswerTypeEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<SingleChoiceAnswerTypeEnum> _$singleChoiceAnswerTypeEnumValues =
    BuiltSet<SingleChoiceAnswerTypeEnum>(const <SingleChoiceAnswerTypeEnum>[
  _$singleChoiceAnswerTypeEnum_singleChoice,
  _$singleChoiceAnswerTypeEnum_unknownDefaultOpenApi,
]);

Serializer<SingleChoiceAnswerTypeEnum> _$singleChoiceAnswerTypeEnumSerializer =
    _$SingleChoiceAnswerTypeEnumSerializer();

class _$SingleChoiceAnswerTypeEnumSerializer
    implements PrimitiveSerializer<SingleChoiceAnswerTypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'singleChoice': 'single_choice',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'single_choice': 'singleChoice',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[SingleChoiceAnswerTypeEnum];
  @override
  final String wireName = 'SingleChoiceAnswerTypeEnum';

  @override
  Object serialize(Serializers serializers, SingleChoiceAnswerTypeEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  SingleChoiceAnswerTypeEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      SingleChoiceAnswerTypeEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$SingleChoiceAnswer extends SingleChoiceAnswer {
  @override
  final BuiltList<String> optionKeys;
  @override
  final SingleChoiceAnswerTypeEnum type;

  factory _$SingleChoiceAnswer(
          [void Function(SingleChoiceAnswerBuilder)? updates]) =>
      (SingleChoiceAnswerBuilder()..update(updates))._build();

  _$SingleChoiceAnswer._({required this.optionKeys, required this.type})
      : super._();
  @override
  SingleChoiceAnswer rebuild(
          void Function(SingleChoiceAnswerBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SingleChoiceAnswerBuilder toBuilder() =>
      SingleChoiceAnswerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SingleChoiceAnswer &&
        optionKeys == other.optionKeys &&
        type == other.type;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, optionKeys.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SingleChoiceAnswer')
          ..add('optionKeys', optionKeys)
          ..add('type', type))
        .toString();
  }
}

class SingleChoiceAnswerBuilder
    implements Builder<SingleChoiceAnswer, SingleChoiceAnswerBuilder> {
  _$SingleChoiceAnswer? _$v;

  ListBuilder<String>? _optionKeys;
  ListBuilder<String> get optionKeys =>
      _$this._optionKeys ??= ListBuilder<String>();
  set optionKeys(ListBuilder<String>? optionKeys) =>
      _$this._optionKeys = optionKeys;

  SingleChoiceAnswerTypeEnum? _type;
  SingleChoiceAnswerTypeEnum? get type => _$this._type;
  set type(SingleChoiceAnswerTypeEnum? type) => _$this._type = type;

  SingleChoiceAnswerBuilder() {
    SingleChoiceAnswer._defaults(this);
  }

  SingleChoiceAnswerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _optionKeys = $v.optionKeys.toBuilder();
      _type = $v.type;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SingleChoiceAnswer other) {
    _$v = other as _$SingleChoiceAnswer;
  }

  @override
  void update(void Function(SingleChoiceAnswerBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SingleChoiceAnswer build() => _build();

  _$SingleChoiceAnswer _build() {
    _$SingleChoiceAnswer _$result;
    try {
      _$result = _$v ??
          _$SingleChoiceAnswer._(
            optionKeys: optionKeys.build(),
            type: BuiltValueNullFieldError.checkNotNull(
                type, r'SingleChoiceAnswer', 'type'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'optionKeys';
        optionKeys.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'SingleChoiceAnswer', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
