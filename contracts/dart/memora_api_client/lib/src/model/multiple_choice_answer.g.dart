// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'multiple_choice_answer.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const MultipleChoiceAnswerTypeEnum
    _$multipleChoiceAnswerTypeEnum_multipleChoice =
    const MultipleChoiceAnswerTypeEnum._('multipleChoice');
const MultipleChoiceAnswerTypeEnum
    _$multipleChoiceAnswerTypeEnum_unknownDefaultOpenApi =
    const MultipleChoiceAnswerTypeEnum._('unknownDefaultOpenApi');

MultipleChoiceAnswerTypeEnum _$multipleChoiceAnswerTypeEnumValueOf(
    String name) {
  switch (name) {
    case 'multipleChoice':
      return _$multipleChoiceAnswerTypeEnum_multipleChoice;
    case 'unknownDefaultOpenApi':
      return _$multipleChoiceAnswerTypeEnum_unknownDefaultOpenApi;
    default:
      return _$multipleChoiceAnswerTypeEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<MultipleChoiceAnswerTypeEnum>
    _$multipleChoiceAnswerTypeEnumValues =
    BuiltSet<MultipleChoiceAnswerTypeEnum>(const <MultipleChoiceAnswerTypeEnum>[
  _$multipleChoiceAnswerTypeEnum_multipleChoice,
  _$multipleChoiceAnswerTypeEnum_unknownDefaultOpenApi,
]);

Serializer<MultipleChoiceAnswerTypeEnum>
    _$multipleChoiceAnswerTypeEnumSerializer =
    _$MultipleChoiceAnswerTypeEnumSerializer();

class _$MultipleChoiceAnswerTypeEnumSerializer
    implements PrimitiveSerializer<MultipleChoiceAnswerTypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'multipleChoice': 'multiple_choice',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'multiple_choice': 'multipleChoice',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[MultipleChoiceAnswerTypeEnum];
  @override
  final String wireName = 'MultipleChoiceAnswerTypeEnum';

  @override
  Object serialize(Serializers serializers, MultipleChoiceAnswerTypeEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  MultipleChoiceAnswerTypeEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      MultipleChoiceAnswerTypeEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$MultipleChoiceAnswer extends MultipleChoiceAnswer {
  @override
  final BuiltList<String> optionKeys;
  @override
  final MultipleChoiceAnswerTypeEnum type;

  factory _$MultipleChoiceAnswer(
          [void Function(MultipleChoiceAnswerBuilder)? updates]) =>
      (MultipleChoiceAnswerBuilder()..update(updates))._build();

  _$MultipleChoiceAnswer._({required this.optionKeys, required this.type})
      : super._();
  @override
  MultipleChoiceAnswer rebuild(
          void Function(MultipleChoiceAnswerBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MultipleChoiceAnswerBuilder toBuilder() =>
      MultipleChoiceAnswerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MultipleChoiceAnswer &&
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
    return (newBuiltValueToStringHelper(r'MultipleChoiceAnswer')
          ..add('optionKeys', optionKeys)
          ..add('type', type))
        .toString();
  }
}

class MultipleChoiceAnswerBuilder
    implements Builder<MultipleChoiceAnswer, MultipleChoiceAnswerBuilder> {
  _$MultipleChoiceAnswer? _$v;

  ListBuilder<String>? _optionKeys;
  ListBuilder<String> get optionKeys =>
      _$this._optionKeys ??= ListBuilder<String>();
  set optionKeys(ListBuilder<String>? optionKeys) =>
      _$this._optionKeys = optionKeys;

  MultipleChoiceAnswerTypeEnum? _type;
  MultipleChoiceAnswerTypeEnum? get type => _$this._type;
  set type(MultipleChoiceAnswerTypeEnum? type) => _$this._type = type;

  MultipleChoiceAnswerBuilder() {
    MultipleChoiceAnswer._defaults(this);
  }

  MultipleChoiceAnswerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _optionKeys = $v.optionKeys.toBuilder();
      _type = $v.type;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MultipleChoiceAnswer other) {
    _$v = other as _$MultipleChoiceAnswer;
  }

  @override
  void update(void Function(MultipleChoiceAnswerBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MultipleChoiceAnswer build() => _build();

  _$MultipleChoiceAnswer _build() {
    _$MultipleChoiceAnswer _$result;
    try {
      _$result = _$v ??
          _$MultipleChoiceAnswer._(
            optionKeys: optionKeys.build(),
            type: BuiltValueNullFieldError.checkNotNull(
                type, r'MultipleChoiceAnswer', 'type'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'optionKeys';
        optionKeys.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'MultipleChoiceAnswer', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
