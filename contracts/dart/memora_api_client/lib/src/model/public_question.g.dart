// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_question.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const PublicQuestionQuestionTypeEnum
    _$publicQuestionQuestionTypeEnum_singleChoice =
    const PublicQuestionQuestionTypeEnum._('singleChoice');
const PublicQuestionQuestionTypeEnum
    _$publicQuestionQuestionTypeEnum_multipleChoice =
    const PublicQuestionQuestionTypeEnum._('multipleChoice');
const PublicQuestionQuestionTypeEnum _$publicQuestionQuestionTypeEnum_numeric =
    const PublicQuestionQuestionTypeEnum._('numeric');
const PublicQuestionQuestionTypeEnum
    _$publicQuestionQuestionTypeEnum_shortAnswer =
    const PublicQuestionQuestionTypeEnum._('shortAnswer');
const PublicQuestionQuestionTypeEnum
    _$publicQuestionQuestionTypeEnum_unknownDefaultOpenApi =
    const PublicQuestionQuestionTypeEnum._('unknownDefaultOpenApi');

PublicQuestionQuestionTypeEnum _$publicQuestionQuestionTypeEnumValueOf(
    String name) {
  switch (name) {
    case 'singleChoice':
      return _$publicQuestionQuestionTypeEnum_singleChoice;
    case 'multipleChoice':
      return _$publicQuestionQuestionTypeEnum_multipleChoice;
    case 'numeric':
      return _$publicQuestionQuestionTypeEnum_numeric;
    case 'shortAnswer':
      return _$publicQuestionQuestionTypeEnum_shortAnswer;
    case 'unknownDefaultOpenApi':
      return _$publicQuestionQuestionTypeEnum_unknownDefaultOpenApi;
    default:
      return _$publicQuestionQuestionTypeEnum_unknownDefaultOpenApi;
  }
}

final BuiltSet<PublicQuestionQuestionTypeEnum>
    _$publicQuestionQuestionTypeEnumValues = BuiltSet<
        PublicQuestionQuestionTypeEnum>(const <PublicQuestionQuestionTypeEnum>[
  _$publicQuestionQuestionTypeEnum_singleChoice,
  _$publicQuestionQuestionTypeEnum_multipleChoice,
  _$publicQuestionQuestionTypeEnum_numeric,
  _$publicQuestionQuestionTypeEnum_shortAnswer,
  _$publicQuestionQuestionTypeEnum_unknownDefaultOpenApi,
]);

Serializer<PublicQuestionQuestionTypeEnum>
    _$publicQuestionQuestionTypeEnumSerializer =
    _$PublicQuestionQuestionTypeEnumSerializer();

class _$PublicQuestionQuestionTypeEnumSerializer
    implements PrimitiveSerializer<PublicQuestionQuestionTypeEnum> {
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
  final Iterable<Type> types = const <Type>[PublicQuestionQuestionTypeEnum];
  @override
  final String wireName = 'PublicQuestionQuestionTypeEnum';

  @override
  Object serialize(
          Serializers serializers, PublicQuestionQuestionTypeEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  PublicQuestionQuestionTypeEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      PublicQuestionQuestionTypeEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$PublicQuestion extends PublicQuestion {
  @override
  final BuiltList<MediaReference> media;
  @override
  final BuiltList<PublicQuestionOption> options;
  @override
  final String prompt;
  @override
  final PublicQuestionQuestionTypeEnum questionType;
  @override
  final String questionVersionId;
  @override
  final PublicResponseConfig responseConfig;
  @override
  final String trustLabel;

  factory _$PublicQuestion([void Function(PublicQuestionBuilder)? updates]) =>
      (PublicQuestionBuilder()..update(updates))._build();

  _$PublicQuestion._(
      {required this.media,
      required this.options,
      required this.prompt,
      required this.questionType,
      required this.questionVersionId,
      required this.responseConfig,
      required this.trustLabel})
      : super._();
  @override
  PublicQuestion rebuild(void Function(PublicQuestionBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PublicQuestionBuilder toBuilder() => PublicQuestionBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PublicQuestion &&
        media == other.media &&
        options == other.options &&
        prompt == other.prompt &&
        questionType == other.questionType &&
        questionVersionId == other.questionVersionId &&
        responseConfig == other.responseConfig &&
        trustLabel == other.trustLabel;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, media.hashCode);
    _$hash = $jc(_$hash, options.hashCode);
    _$hash = $jc(_$hash, prompt.hashCode);
    _$hash = $jc(_$hash, questionType.hashCode);
    _$hash = $jc(_$hash, questionVersionId.hashCode);
    _$hash = $jc(_$hash, responseConfig.hashCode);
    _$hash = $jc(_$hash, trustLabel.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PublicQuestion')
          ..add('media', media)
          ..add('options', options)
          ..add('prompt', prompt)
          ..add('questionType', questionType)
          ..add('questionVersionId', questionVersionId)
          ..add('responseConfig', responseConfig)
          ..add('trustLabel', trustLabel))
        .toString();
  }
}

class PublicQuestionBuilder
    implements Builder<PublicQuestion, PublicQuestionBuilder> {
  _$PublicQuestion? _$v;

  ListBuilder<MediaReference>? _media;
  ListBuilder<MediaReference> get media =>
      _$this._media ??= ListBuilder<MediaReference>();
  set media(ListBuilder<MediaReference>? media) => _$this._media = media;

  ListBuilder<PublicQuestionOption>? _options;
  ListBuilder<PublicQuestionOption> get options =>
      _$this._options ??= ListBuilder<PublicQuestionOption>();
  set options(ListBuilder<PublicQuestionOption>? options) =>
      _$this._options = options;

  String? _prompt;
  String? get prompt => _$this._prompt;
  set prompt(String? prompt) => _$this._prompt = prompt;

  PublicQuestionQuestionTypeEnum? _questionType;
  PublicQuestionQuestionTypeEnum? get questionType => _$this._questionType;
  set questionType(PublicQuestionQuestionTypeEnum? questionType) =>
      _$this._questionType = questionType;

  String? _questionVersionId;
  String? get questionVersionId => _$this._questionVersionId;
  set questionVersionId(String? questionVersionId) =>
      _$this._questionVersionId = questionVersionId;

  PublicResponseConfigBuilder? _responseConfig;
  PublicResponseConfigBuilder get responseConfig =>
      _$this._responseConfig ??= PublicResponseConfigBuilder();
  set responseConfig(PublicResponseConfigBuilder? responseConfig) =>
      _$this._responseConfig = responseConfig;

  String? _trustLabel;
  String? get trustLabel => _$this._trustLabel;
  set trustLabel(String? trustLabel) => _$this._trustLabel = trustLabel;

  PublicQuestionBuilder() {
    PublicQuestion._defaults(this);
  }

  PublicQuestionBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _media = $v.media.toBuilder();
      _options = $v.options.toBuilder();
      _prompt = $v.prompt;
      _questionType = $v.questionType;
      _questionVersionId = $v.questionVersionId;
      _responseConfig = $v.responseConfig.toBuilder();
      _trustLabel = $v.trustLabel;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PublicQuestion other) {
    _$v = other as _$PublicQuestion;
  }

  @override
  void update(void Function(PublicQuestionBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PublicQuestion build() => _build();

  _$PublicQuestion _build() {
    _$PublicQuestion _$result;
    try {
      _$result = _$v ??
          _$PublicQuestion._(
            media: media.build(),
            options: options.build(),
            prompt: BuiltValueNullFieldError.checkNotNull(
                prompt, r'PublicQuestion', 'prompt'),
            questionType: BuiltValueNullFieldError.checkNotNull(
                questionType, r'PublicQuestion', 'questionType'),
            questionVersionId: BuiltValueNullFieldError.checkNotNull(
                questionVersionId, r'PublicQuestion', 'questionVersionId'),
            responseConfig: responseConfig.build(),
            trustLabel: BuiltValueNullFieldError.checkNotNull(
                trustLabel, r'PublicQuestion', 'trustLabel'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'media';
        media.build();
        _$failedField = 'options';
        options.build();

        _$failedField = 'responseConfig';
        responseConfig.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'PublicQuestion', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
