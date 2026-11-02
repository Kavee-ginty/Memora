// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'privacy_deletion_cancel_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PrivacyDeletionCancelRequest extends PrivacyDeletionCancelRequest {
  @override
  final Optional<String?> reason;

  factory _$PrivacyDeletionCancelRequest(
          [void Function(PrivacyDeletionCancelRequestBuilder)? updates]) =>
      (PrivacyDeletionCancelRequestBuilder()..update(updates))._build();

  _$PrivacyDeletionCancelRequest._({required this.reason}) : super._();
  @override
  PrivacyDeletionCancelRequest rebuild(
          void Function(PrivacyDeletionCancelRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PrivacyDeletionCancelRequestBuilder toBuilder() =>
      PrivacyDeletionCancelRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PrivacyDeletionCancelRequest && reason == other.reason;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, reason.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PrivacyDeletionCancelRequest')
          ..add('reason', reason))
        .toString();
  }
}

class PrivacyDeletionCancelRequestBuilder
    implements
        Builder<PrivacyDeletionCancelRequest,
            PrivacyDeletionCancelRequestBuilder> {
  _$PrivacyDeletionCancelRequest? _$v;

  Optional<String?>? _reason;
  Optional<String?>? get reason => _$this._reason;
  set reason(Optional<String?>? reason) => _$this._reason = reason;

  PrivacyDeletionCancelRequestBuilder() {
    PrivacyDeletionCancelRequest._defaults(this);
  }

  PrivacyDeletionCancelRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _reason = $v.reason;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PrivacyDeletionCancelRequest other) {
    _$v = other as _$PrivacyDeletionCancelRequest;
  }

  @override
  void update(void Function(PrivacyDeletionCancelRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PrivacyDeletionCancelRequest build() => _build();

  _$PrivacyDeletionCancelRequest _build() {
    final _$result = _$v ??
        _$PrivacyDeletionCancelRequest._(
          reason: BuiltValueNullFieldError.checkNotNull(
              reason, r'PrivacyDeletionCancelRequest', 'reason'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
