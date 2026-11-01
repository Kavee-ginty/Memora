// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'privacy_deletion_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PrivacyDeletionRequest extends PrivacyDeletionRequest {
  @override
  final Optional<bool?> confirmed;

  factory _$PrivacyDeletionRequest(
          [void Function(PrivacyDeletionRequestBuilder)? updates]) =>
      (PrivacyDeletionRequestBuilder()..update(updates))._build();

  _$PrivacyDeletionRequest._({required this.confirmed}) : super._();
  @override
  PrivacyDeletionRequest rebuild(
          void Function(PrivacyDeletionRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PrivacyDeletionRequestBuilder toBuilder() =>
      PrivacyDeletionRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PrivacyDeletionRequest && confirmed == other.confirmed;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, confirmed.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PrivacyDeletionRequest')
          ..add('confirmed', confirmed))
        .toString();
  }
}

class PrivacyDeletionRequestBuilder
    implements Builder<PrivacyDeletionRequest, PrivacyDeletionRequestBuilder> {
  _$PrivacyDeletionRequest? _$v;

  Optional<bool?>? _confirmed;
  Optional<bool?>? get confirmed => _$this._confirmed;
  set confirmed(Optional<bool?>? confirmed) => _$this._confirmed = confirmed;

  PrivacyDeletionRequestBuilder() {
    PrivacyDeletionRequest._defaults(this);
  }

  PrivacyDeletionRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _confirmed = $v.confirmed;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PrivacyDeletionRequest other) {
    _$v = other as _$PrivacyDeletionRequest;
  }

  @override
  void update(void Function(PrivacyDeletionRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PrivacyDeletionRequest build() => _build();

  _$PrivacyDeletionRequest _build() {
    final _$result = _$v ??
        _$PrivacyDeletionRequest._(
          confirmed: BuiltValueNullFieldError.checkNotNull(
              confirmed, r'PrivacyDeletionRequest', 'confirmed'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
