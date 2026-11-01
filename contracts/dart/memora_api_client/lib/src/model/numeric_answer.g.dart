// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'numeric_answer.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const NumericAnswerTypeEnum _$numericAnswerTypeEnum_numeric =
    const NumericAnswerTypeEnum._('numeric');
const NumericAnswerTypeEnum _$numericAnswerTypeEnum_unknownDefaultOpenApi =
    const NumericAnswerTypeEnum._('unknownDefaultOpenApi');

NumericAnswerTypeEnum _$numericAnswerTypeEnumValueOf(String name) {
  switch (name) {
    case 'numeric':
      return _$numericAnswerTypeEnum_numeric;
    case 'unknownDefaultOpenApi':
      return _$numericAnswerTypeEnum_unknownDefaultOpenApi;
    default:
      return _$numericAnswerTypeEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<NumericAnswerTypeEnum> _$numericAnswerTypeEnumValues =
    BuiltSet<NumericAnswerTypeEnum>(const <NumericAnswerTypeEnum>[
  _$numericAnswerTypeEnum_numeric,
  _$numericAnswerTypeEnum_unknownDefaultOpenApi,
]);

Serializer<NumericAnswerTypeEnum> _$numericAnswerTypeEnumSerializer =
    _$NumericAnswerTypeEnumSerializer();

class _$NumericAnswerTypeEnumSerializer
    implements PrimitiveSerializer<NumericAnswerTypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'numeric': 'numeric',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'numeric': 'numeric',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[NumericAnswerTypeEnum];
  @override
  final String wireName = 'NumericAnswerTypeEnum';

  @override
  Object serialize(Serializers serializers, NumericAnswerTypeEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  NumericAnswerTypeEnum deserialize(Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      NumericAnswerTypeEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$NumericAnswer extends NumericAnswer {
  @override
  final NumericAnswerTypeEnum type;
  @override
  final Optional<String?> unit;
  @override
  final Value value;

  factory _$NumericAnswer([void Function(NumericAnswerBuilder)? updates]) =>
      (NumericAnswerBuilder()..update(updates))._build();

  _$NumericAnswer._(
      {required this.type, required this.unit, required this.value})
      : super._();
  @override
  NumericAnswer rebuild(void Function(NumericAnswerBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  NumericAnswerBuilder toBuilder() => NumericAnswerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is NumericAnswer &&
        type == other.type &&
        unit == other.unit &&
        value == other.value;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jc(_$hash, unit.hashCode);
    _$hash = $jc(_$hash, value.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'NumericAnswer')
          ..add('type', type)
          ..add('unit', unit)
          ..add('value', value))
        .toString();
  }
}

class NumericAnswerBuilder
    implements Builder<NumericAnswer, NumericAnswerBuilder> {
  _$NumericAnswer? _$v;

  NumericAnswerTypeEnum? _type;
  NumericAnswerTypeEnum? get type => _$this._type;
  set type(NumericAnswerTypeEnum? type) => _$this._type = type;

  Optional<String?>? _unit;
  Optional<String?>? get unit => _$this._unit;
  set unit(Optional<String?>? unit) => _$this._unit = unit;

  ValueBuilder? _value;
  ValueBuilder get value => _$this._value ??= ValueBuilder();
  set value(ValueBuilder? value) => _$this._value = value;

  NumericAnswerBuilder() {
    NumericAnswer._defaults(this);
  }

  NumericAnswerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _type = $v.type;
      _unit = $v.unit;
      _value = $v.value.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(NumericAnswer other) {
    _$v = other as _$NumericAnswer;
  }

  @override
  void update(void Function(NumericAnswerBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  NumericAnswer build() => _build();

  _$NumericAnswer _build() {
    _$NumericAnswer _$result;
    try {
      _$result = _$v ??
          _$NumericAnswer._(
            type: BuiltValueNullFieldError.checkNotNull(
                type, r'NumericAnswer', 'type'),
            unit: BuiltValueNullFieldError.checkNotNull(
                unit, r'NumericAnswer', 'unit'),
            value: value.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'value';
        value.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'NumericAnswer', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
