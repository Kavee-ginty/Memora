// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_response_config.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const PublicResponseConfigTypeEnum _$publicResponseConfigTypeEnum_singleChoice =
    const PublicResponseConfigTypeEnum._('singleChoice');
const PublicResponseConfigTypeEnum
    _$publicResponseConfigTypeEnum_multipleChoice =
    const PublicResponseConfigTypeEnum._('multipleChoice');
const PublicResponseConfigTypeEnum _$publicResponseConfigTypeEnum_numeric =
    const PublicResponseConfigTypeEnum._('numeric');
const PublicResponseConfigTypeEnum _$publicResponseConfigTypeEnum_shortAnswer =
    const PublicResponseConfigTypeEnum._('shortAnswer');
const PublicResponseConfigTypeEnum
    _$publicResponseConfigTypeEnum_unknownDefaultOpenApi =
    const PublicResponseConfigTypeEnum._('unknownDefaultOpenApi');

PublicResponseConfigTypeEnum _$publicResponseConfigTypeEnumValueOf(
    String name) {
  switch (name) {
    case 'singleChoice':
      return _$publicResponseConfigTypeEnum_singleChoice;
    case 'multipleChoice':
      return _$publicResponseConfigTypeEnum_multipleChoice;
    case 'numeric':
      return _$publicResponseConfigTypeEnum_numeric;
    case 'shortAnswer':
      return _$publicResponseConfigTypeEnum_shortAnswer;
    case 'unknownDefaultOpenApi':
      return _$publicResponseConfigTypeEnum_unknownDefaultOpenApi;
    default:
      return _$publicResponseConfigTypeEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<PublicResponseConfigTypeEnum>
    _$publicResponseConfigTypeEnumValues =
    BuiltSet<PublicResponseConfigTypeEnum>(const <PublicResponseConfigTypeEnum>[
  _$publicResponseConfigTypeEnum_singleChoice,
  _$publicResponseConfigTypeEnum_multipleChoice,
  _$publicResponseConfigTypeEnum_numeric,
  _$publicResponseConfigTypeEnum_shortAnswer,
  _$publicResponseConfigTypeEnum_unknownDefaultOpenApi,
]);

Serializer<PublicResponseConfigTypeEnum>
    _$publicResponseConfigTypeEnumSerializer =
    _$PublicResponseConfigTypeEnumSerializer();

class _$PublicResponseConfigTypeEnumSerializer
    implements PrimitiveSerializer<PublicResponseConfigTypeEnum> {
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
  final Iterable<Type> types = const <Type>[PublicResponseConfigTypeEnum];
  @override
  final String wireName = 'PublicResponseConfigTypeEnum';

  @override
  Object serialize(Serializers serializers, PublicResponseConfigTypeEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  PublicResponseConfigTypeEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      PublicResponseConfigTypeEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$PublicResponseConfig extends PublicResponseConfig {
  @override
  final Optional<String?> inputHint;
  @override
  final Optional<int?> maxCharacters;
  @override
  final Optional<int?> maxSelections;
  @override
  final Optional<int?> minSelections;
  @override
  final PublicResponseConfigTypeEnum type;
  @override
  final Optional<bool?> unitAffordance;
  @override
  final BuiltList<String> unitOptions;

  factory _$PublicResponseConfig(
          [void Function(PublicResponseConfigBuilder)? updates]) =>
      (PublicResponseConfigBuilder()..update(updates))._build();

  _$PublicResponseConfig._(
      {required this.inputHint,
      required this.maxCharacters,
      required this.maxSelections,
      required this.minSelections,
      required this.type,
      required this.unitAffordance,
      required this.unitOptions})
      : super._();
  @override
  PublicResponseConfig rebuild(
          void Function(PublicResponseConfigBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PublicResponseConfigBuilder toBuilder() =>
      PublicResponseConfigBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PublicResponseConfig &&
        inputHint == other.inputHint &&
        maxCharacters == other.maxCharacters &&
        maxSelections == other.maxSelections &&
        minSelections == other.minSelections &&
        type == other.type &&
        unitAffordance == other.unitAffordance &&
        unitOptions == other.unitOptions;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, inputHint.hashCode);
    _$hash = $jc(_$hash, maxCharacters.hashCode);
    _$hash = $jc(_$hash, maxSelections.hashCode);
    _$hash = $jc(_$hash, minSelections.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jc(_$hash, unitAffordance.hashCode);
    _$hash = $jc(_$hash, unitOptions.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PublicResponseConfig')
          ..add('inputHint', inputHint)
          ..add('maxCharacters', maxCharacters)
          ..add('maxSelections', maxSelections)
          ..add('minSelections', minSelections)
          ..add('type', type)
          ..add('unitAffordance', unitAffordance)
          ..add('unitOptions', unitOptions))
        .toString();
  }
}

class PublicResponseConfigBuilder
    implements Builder<PublicResponseConfig, PublicResponseConfigBuilder> {
  _$PublicResponseConfig? _$v;

  Optional<String?>? _inputHint;
  Optional<String?>? get inputHint => _$this._inputHint;
  set inputHint(Optional<String?>? inputHint) => _$this._inputHint = inputHint;

  Optional<int?>? _maxCharacters;
  Optional<int?>? get maxCharacters => _$this._maxCharacters;
  set maxCharacters(Optional<int?>? maxCharacters) =>
      _$this._maxCharacters = maxCharacters;

  Optional<int?>? _maxSelections;
  Optional<int?>? get maxSelections => _$this._maxSelections;
  set maxSelections(Optional<int?>? maxSelections) =>
      _$this._maxSelections = maxSelections;

  Optional<int?>? _minSelections;
  Optional<int?>? get minSelections => _$this._minSelections;
  set minSelections(Optional<int?>? minSelections) =>
      _$this._minSelections = minSelections;

  PublicResponseConfigTypeEnum? _type;
  PublicResponseConfigTypeEnum? get type => _$this._type;
  set type(PublicResponseConfigTypeEnum? type) => _$this._type = type;

  Optional<bool?>? _unitAffordance;
  Optional<bool?>? get unitAffordance => _$this._unitAffordance;
  set unitAffordance(Optional<bool?>? unitAffordance) =>
      _$this._unitAffordance = unitAffordance;

  ListBuilder<String>? _unitOptions;
  ListBuilder<String> get unitOptions =>
      _$this._unitOptions ??= ListBuilder<String>();
  set unitOptions(ListBuilder<String>? unitOptions) =>
      _$this._unitOptions = unitOptions;

  PublicResponseConfigBuilder() {
    PublicResponseConfig._defaults(this);
  }

  PublicResponseConfigBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _inputHint = $v.inputHint;
      _maxCharacters = $v.maxCharacters;
      _maxSelections = $v.maxSelections;
      _minSelections = $v.minSelections;
      _type = $v.type;
      _unitAffordance = $v.unitAffordance;
      _unitOptions = $v.unitOptions.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PublicResponseConfig other) {
    _$v = other as _$PublicResponseConfig;
  }

  @override
  void update(void Function(PublicResponseConfigBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PublicResponseConfig build() => _build();

  _$PublicResponseConfig _build() {
    _$PublicResponseConfig _$result;
    try {
      _$result = _$v ??
          _$PublicResponseConfig._(
            inputHint: BuiltValueNullFieldError.checkNotNull(
                inputHint, r'PublicResponseConfig', 'inputHint'),
            maxCharacters: BuiltValueNullFieldError.checkNotNull(
                maxCharacters, r'PublicResponseConfig', 'maxCharacters'),
            maxSelections: BuiltValueNullFieldError.checkNotNull(
                maxSelections, r'PublicResponseConfig', 'maxSelections'),
            minSelections: BuiltValueNullFieldError.checkNotNull(
                minSelections, r'PublicResponseConfig', 'minSelections'),
            type: BuiltValueNullFieldError.checkNotNull(
                type, r'PublicResponseConfig', 'type'),
            unitAffordance: BuiltValueNullFieldError.checkNotNull(
                unitAffordance, r'PublicResponseConfig', 'unitAffordance'),
            unitOptions: unitOptions.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'unitOptions';
        unitOptions.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'PublicResponseConfig', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
