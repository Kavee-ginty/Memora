// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_learning_update_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreateLearningUpdateRequest extends CreateLearningUpdateRequest {
  @override
  final String clientOperationId;
  @override
  final BuiltList<DeclaredFile> files;
  @override
  final InputType inputType;
  @override
  final DateTime learnedAt;
  @override
  final Optional<String?> manualText;
  @override
  final String subjectId;

  factory _$CreateLearningUpdateRequest(
          [void Function(CreateLearningUpdateRequestBuilder)? updates]) =>
      (CreateLearningUpdateRequestBuilder()..update(updates))._build();

  _$CreateLearningUpdateRequest._(
      {required this.clientOperationId,
      required this.files,
      required this.inputType,
      required this.learnedAt,
      required this.manualText,
      required this.subjectId})
      : super._();
  @override
  CreateLearningUpdateRequest rebuild(
          void Function(CreateLearningUpdateRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CreateLearningUpdateRequestBuilder toBuilder() =>
      CreateLearningUpdateRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateLearningUpdateRequest &&
        clientOperationId == other.clientOperationId &&
        files == other.files &&
        inputType == other.inputType &&
        learnedAt == other.learnedAt &&
        manualText == other.manualText &&
        subjectId == other.subjectId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, clientOperationId.hashCode);
    _$hash = $jc(_$hash, files.hashCode);
    _$hash = $jc(_$hash, inputType.hashCode);
    _$hash = $jc(_$hash, learnedAt.hashCode);
    _$hash = $jc(_$hash, manualText.hashCode);
    _$hash = $jc(_$hash, subjectId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CreateLearningUpdateRequest')
          ..add('clientOperationId', clientOperationId)
          ..add('files', files)
          ..add('inputType', inputType)
          ..add('learnedAt', learnedAt)
          ..add('manualText', manualText)
          ..add('subjectId', subjectId))
        .toString();
  }
}

class CreateLearningUpdateRequestBuilder
    implements
        Builder<CreateLearningUpdateRequest,
            CreateLearningUpdateRequestBuilder> {
  _$CreateLearningUpdateRequest? _$v;

  String? _clientOperationId;
  String? get clientOperationId => _$this._clientOperationId;
  set clientOperationId(String? clientOperationId) =>
      _$this._clientOperationId = clientOperationId;

  ListBuilder<DeclaredFile>? _files;
  ListBuilder<DeclaredFile> get files =>
      _$this._files ??= ListBuilder<DeclaredFile>();
  set files(ListBuilder<DeclaredFile>? files) => _$this._files = files;

  InputType? _inputType;
  InputType? get inputType => _$this._inputType;
  set inputType(InputType? inputType) => _$this._inputType = inputType;

  DateTime? _learnedAt;
  DateTime? get learnedAt => _$this._learnedAt;
  set learnedAt(DateTime? learnedAt) => _$this._learnedAt = learnedAt;

  Optional<String?>? _manualText;
  Optional<String?>? get manualText => _$this._manualText;
  set manualText(Optional<String?>? manualText) =>
      _$this._manualText = manualText;

  String? _subjectId;
  String? get subjectId => _$this._subjectId;
  set subjectId(String? subjectId) => _$this._subjectId = subjectId;

  CreateLearningUpdateRequestBuilder() {
    CreateLearningUpdateRequest._defaults(this);
  }

  CreateLearningUpdateRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _clientOperationId = $v.clientOperationId;
      _files = $v.files.toBuilder();
      _inputType = $v.inputType;
      _learnedAt = $v.learnedAt;
      _manualText = $v.manualText;
      _subjectId = $v.subjectId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreateLearningUpdateRequest other) {
    _$v = other as _$CreateLearningUpdateRequest;
  }

  @override
  void update(void Function(CreateLearningUpdateRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateLearningUpdateRequest build() => _build();

  _$CreateLearningUpdateRequest _build() {
    _$CreateLearningUpdateRequest _$result;
    try {
      _$result = _$v ??
          _$CreateLearningUpdateRequest._(
            clientOperationId: BuiltValueNullFieldError.checkNotNull(
                clientOperationId,
                r'CreateLearningUpdateRequest',
                'clientOperationId'),
            files: files.build(),
            inputType: BuiltValueNullFieldError.checkNotNull(
                inputType, r'CreateLearningUpdateRequest', 'inputType'),
            learnedAt: BuiltValueNullFieldError.checkNotNull(
                learnedAt, r'CreateLearningUpdateRequest', 'learnedAt'),
            manualText: BuiltValueNullFieldError.checkNotNull(
                manualText, r'CreateLearningUpdateRequest', 'manualText'),
            subjectId: BuiltValueNullFieldError.checkNotNull(
                subjectId, r'CreateLearningUpdateRequest', 'subjectId'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'files';
        files.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'CreateLearningUpdateRequest', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
