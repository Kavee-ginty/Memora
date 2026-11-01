// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'submit_verification_decisions_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SubmitVerificationDecisionsRequest
    extends SubmitVerificationDecisionsRequest {
  @override
  final BuiltList<VerificationDecision> decisions;

  factory _$SubmitVerificationDecisionsRequest(
          [void Function(SubmitVerificationDecisionsRequestBuilder)?
              updates]) =>
      (SubmitVerificationDecisionsRequestBuilder()..update(updates))._build();

  _$SubmitVerificationDecisionsRequest._({required this.decisions}) : super._();
  @override
  SubmitVerificationDecisionsRequest rebuild(
          void Function(SubmitVerificationDecisionsRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SubmitVerificationDecisionsRequestBuilder toBuilder() =>
      SubmitVerificationDecisionsRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SubmitVerificationDecisionsRequest &&
        decisions == other.decisions;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, decisions.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SubmitVerificationDecisionsRequest')
          ..add('decisions', decisions))
        .toString();
  }
}

class SubmitVerificationDecisionsRequestBuilder
    implements
        Builder<SubmitVerificationDecisionsRequest,
            SubmitVerificationDecisionsRequestBuilder> {
  _$SubmitVerificationDecisionsRequest? _$v;

  ListBuilder<VerificationDecision>? _decisions;
  ListBuilder<VerificationDecision> get decisions =>
      _$this._decisions ??= ListBuilder<VerificationDecision>();
  set decisions(ListBuilder<VerificationDecision>? decisions) =>
      _$this._decisions = decisions;

  SubmitVerificationDecisionsRequestBuilder() {
    SubmitVerificationDecisionsRequest._defaults(this);
  }

  SubmitVerificationDecisionsRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _decisions = $v.decisions.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SubmitVerificationDecisionsRequest other) {
    _$v = other as _$SubmitVerificationDecisionsRequest;
  }

  @override
  void update(
      void Function(SubmitVerificationDecisionsRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SubmitVerificationDecisionsRequest build() => _build();

  _$SubmitVerificationDecisionsRequest _build() {
    _$SubmitVerificationDecisionsRequest _$result;
    try {
      _$result = _$v ??
          _$SubmitVerificationDecisionsRequest._(
            decisions: decisions.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'decisions';
        decisions.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'SubmitVerificationDecisionsRequest', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
