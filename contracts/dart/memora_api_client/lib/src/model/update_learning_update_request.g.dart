// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_learning_update_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdateLearningUpdateRequest extends UpdateLearningUpdateRequest {
  @override
  final Optional<DateTime?> learnedAt;
  @override
  final Optional<String?> manualText;
  @override
  final int version;

  factory _$UpdateLearningUpdateRequest(
          [void Function(UpdateLearningUpdateRequestBuilder)? updates]) =>
      (UpdateLearningUpdateRequestBuilder()..update(updates))._build();

  _$UpdateLearningUpdateRequest._(
      {required this.learnedAt,
      required this.manualText,
      required this.version})
      : super._();
  @override
  UpdateLearningUpdateRequest rebuild(
          void Function(UpdateLearningUpdateRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UpdateLearningUpdateRequestBuilder toBuilder() =>
      UpdateLearningUpdateRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateLearningUpdateRequest &&
        learnedAt == other.learnedAt &&
        manualText == other.manualText &&
        version == other.version;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, learnedAt.hashCode);
    _$hash = $jc(_$hash, manualText.hashCode);
    _$hash = $jc(_$hash, version.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateLearningUpdateRequest')
          ..add('learnedAt', learnedAt)
          ..add('manualText', manualText)
          ..add('version', version))
        .toString();
  }
}

class UpdateLearningUpdateRequestBuilder
    implements
        Builder<UpdateLearningUpdateRequest,
            UpdateLearningUpdateRequestBuilder> {
  _$UpdateLearningUpdateRequest? _$v;

  Optional<DateTime?>? _learnedAt;
  Optional<DateTime?>? get learnedAt => _$this._learnedAt;
  set learnedAt(Optional<DateTime?>? learnedAt) =>
      _$this._learnedAt = learnedAt;

  Optional<String?>? _manualText;
  Optional<String?>? get manualText => _$this._manualText;
  set manualText(Optional<String?>? manualText) =>
      _$this._manualText = manualText;

  int? _version;
  int? get version => _$this._version;
  set version(int? version) => _$this._version = version;

  UpdateLearningUpdateRequestBuilder() {
    UpdateLearningUpdateRequest._defaults(this);
  }

  UpdateLearningUpdateRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _learnedAt = $v.learnedAt;
      _manualText = $v.manualText;
      _version = $v.version;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateLearningUpdateRequest other) {
    _$v = other as _$UpdateLearningUpdateRequest;
  }

  @override
  void update(void Function(UpdateLearningUpdateRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateLearningUpdateRequest build() => _build();

  _$UpdateLearningUpdateRequest _build() {
    final _$result = _$v ??
        _$UpdateLearningUpdateRequest._(
          learnedAt: BuiltValueNullFieldError.checkNotNull(
              learnedAt, r'UpdateLearningUpdateRequest', 'learnedAt'),
          manualText: BuiltValueNullFieldError.checkNotNull(
              manualText, r'UpdateLearningUpdateRequest', 'manualText'),
          version: BuiltValueNullFieldError.checkNotNull(
              version, r'UpdateLearningUpdateRequest', 'version'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
