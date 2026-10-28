// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'submit_verification_decisions_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SubmitVerificationDecisionsResponse
    extends SubmitVerificationDecisionsResponse {
  @override
  final BuiltList<VerificationDecisionResult> results;
  @override
  final LearningUpdateResponse update;

  factory _$SubmitVerificationDecisionsResponse(
          [void Function(SubmitVerificationDecisionsResponseBuilder)?
              updates]) =>
      (SubmitVerificationDecisionsResponseBuilder()..update(updates))._build();

  _$SubmitVerificationDecisionsResponse._(
      {required this.results, required this.update})
      : super._();
  @override
  SubmitVerificationDecisionsResponse rebuild(
          void Function(SubmitVerificationDecisionsResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SubmitVerificationDecisionsResponseBuilder toBuilder() =>
      SubmitVerificationDecisionsResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SubmitVerificationDecisionsResponse &&
        results == other.results &&
        update == other.update;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, results.hashCode);
    _$hash = $jc(_$hash, update.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SubmitVerificationDecisionsResponse')
          ..add('results', results)
          ..add('update', update))
        .toString();
  }
}

class SubmitVerificationDecisionsResponseBuilder
    implements
        Builder<SubmitVerificationDecisionsResponse,
            SubmitVerificationDecisionsResponseBuilder> {
  _$SubmitVerificationDecisionsResponse? _$v;

  ListBuilder<VerificationDecisionResult>? _results;
  ListBuilder<VerificationDecisionResult> get results =>
      _$this._results ??= ListBuilder<VerificationDecisionResult>();
  set results(ListBuilder<VerificationDecisionResult>? results) =>
      _$this._results = results;

  LearningUpdateResponseBuilder? _update;
  LearningUpdateResponseBuilder get update =>
      _$this._update ??= LearningUpdateResponseBuilder();
  set update(LearningUpdateResponseBuilder? update) => _$this._update = update;

  SubmitVerificationDecisionsResponseBuilder() {
    SubmitVerificationDecisionsResponse._defaults(this);
  }

  SubmitVerificationDecisionsResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _results = $v.results.toBuilder();
      _update = $v.update.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SubmitVerificationDecisionsResponse other) {
    _$v = other as _$SubmitVerificationDecisionsResponse;
  }

  @override
  void update(
      void Function(SubmitVerificationDecisionsResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SubmitVerificationDecisionsResponse build() => _build();

  _$SubmitVerificationDecisionsResponse _build() {
    _$SubmitVerificationDecisionsResponse _$result;
    try {
      _$result = _$v ??
          _$SubmitVerificationDecisionsResponse._(
            results: results.build(),
            update: update.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'results';
        results.build();
        _$failedField = 'update';
        update.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(r'SubmitVerificationDecisionsResponse',
            _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
