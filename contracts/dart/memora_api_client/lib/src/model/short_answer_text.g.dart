// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'short_answer_text.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const ShortAnswerTextTypeEnum _$shortAnswerTextTypeEnum_shortAnswer =
    const ShortAnswerTextTypeEnum._('shortAnswer');
const ShortAnswerTextTypeEnum _$shortAnswerTextTypeEnum_unknownDefaultOpenApi =
    const ShortAnswerTextTypeEnum._('unknownDefaultOpenApi');

ShortAnswerTextTypeEnum _$shortAnswerTextTypeEnumValueOf(String name) {
  switch (name) {
    case 'shortAnswer':
      return _$shortAnswerTextTypeEnum_shortAnswer;
    case 'unknownDefaultOpenApi':
      return _$shortAnswerTextTypeEnum_unknownDefaultOpenApi;
    default:
      return _$shortAnswerTextTypeEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<ShortAnswerTextTypeEnum> _$shortAnswerTextTypeEnumValues =
    BuiltSet<ShortAnswerTextTypeEnum>(const <ShortAnswerTextTypeEnum>[
  _$shortAnswerTextTypeEnum_shortAnswer,
  _$shortAnswerTextTypeEnum_unknownDefaultOpenApi,
]);

Serializer<ShortAnswerTextTypeEnum> _$shortAnswerTextTypeEnumSerializer =
    _$ShortAnswerTextTypeEnumSerializer();

class _$ShortAnswerTextTypeEnumSerializer
    implements PrimitiveSerializer<ShortAnswerTextTypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'shortAnswer': 'short_answer',
    'unknownDefaultOpenApi': 'unknown_default_open_api',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'short_answer': 'shortAnswer',
    'unknown_default_open_api': 'unknownDefaultOpenApi',
  };

  @override
  final Iterable<Type> types = const <Type>[ShortAnswerTextTypeEnum];
  @override
  final String wireName = 'ShortAnswerTextTypeEnum';

  @override
  Object serialize(Serializers serializers, ShortAnswerTextTypeEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  ShortAnswerTextTypeEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      ShortAnswerTextTypeEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$ShortAnswerText extends ShortAnswerText {
  @override
  final String text;
  @override
  final ShortAnswerTextTypeEnum type;

  factory _$ShortAnswerText([void Function(ShortAnswerTextBuilder)? updates]) =>
      (ShortAnswerTextBuilder()..update(updates))._build();

  _$ShortAnswerText._({required this.text, required this.type}) : super._();
  @override
  ShortAnswerText rebuild(void Function(ShortAnswerTextBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ShortAnswerTextBuilder toBuilder() => ShortAnswerTextBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ShortAnswerText && text == other.text && type == other.type;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, text.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ShortAnswerText')
          ..add('text', text)
          ..add('type', type))
        .toString();
  }
}

class ShortAnswerTextBuilder
    implements Builder<ShortAnswerText, ShortAnswerTextBuilder> {
  _$ShortAnswerText? _$v;

  String? _text;
  String? get text => _$this._text;
  set text(String? text) => _$this._text = text;

  ShortAnswerTextTypeEnum? _type;
  ShortAnswerTextTypeEnum? get type => _$this._type;
  set type(ShortAnswerTextTypeEnum? type) => _$this._type = type;

  ShortAnswerTextBuilder() {
    ShortAnswerText._defaults(this);
  }

  ShortAnswerTextBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _text = $v.text;
      _type = $v.type;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ShortAnswerText other) {
    _$v = other as _$ShortAnswerText;
  }

  @override
  void update(void Function(ShortAnswerTextBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ShortAnswerText build() => _build();

  _$ShortAnswerText _build() {
    final _$result = _$v ??
        _$ShortAnswerText._(
          text: BuiltValueNullFieldError.checkNotNull(
              text, r'ShortAnswerText', 'text'),
          type: BuiltValueNullFieldError.checkNotNull(
              type, r'ShortAnswerText', 'type'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
