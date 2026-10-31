// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'submit_verification_decisions_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SubmitVerificationDecisionsResponse
    extends SubmitVerificationDecisionsResponse {
  @override
  final LearningUpdateResponse learningUpdate;
  @override
  final BuiltList<VerificationDecisionResult> results;

  factory _$SubmitVerificationDecisionsResponse(
          [void Function(SubmitVerificationDecisionsResponseBuilder)?
              updates]) =>
      (SubmitVerificationDecisionsResponseBuilder()..update(updates))._build();

  _$SubmitVerificationDecisionsResponse._(
      {required this.learningUpdate, required this.results})
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
        learningUpdate == other.learningUpdate &&
        results == other.results;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, learningUpdate.hashCode);
    _$hash = $jc(_$hash, results.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SubmitVerificationDecisionsResponse')
          ..add('learningUpdate', learningUpdate)
          ..add('results', results))
        .toString();
  }
}

class SubmitVerificationDecisionsResponseBuilder
    implements
        Builder<SubmitVerificationDecisionsResponse,
            SubmitVerificationDecisionsResponseBuilder> {
  _$SubmitVerificationDecisionsResponse? _$v;

  LearningUpdateResponseBuilder? _learningUpdate;
  LearningUpdateResponseBuilder get learningUpdate =>
      _$this._learningUpdate ??= LearningUpdateResponseBuilder();
  set learningUpdate(LearningUpdateResponseBuilder? learningUpdate) =>
      _$this._learningUpdate = learningUpdate;

  ListBuilder<VerificationDecisionResult>? _results;
  ListBuilder<VerificationDecisionResult> get results =>
      _$this._results ??= ListBuilder<VerificationDecisionResult>();
  set results(ListBuilder<VerificationDecisionResult>? results) =>
      _$this._results = results;

  SubmitVerificationDecisionsResponseBuilder() {
    SubmitVerificationDecisionsResponse._defaults(this);
  }

  SubmitVerificationDecisionsResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _learningUpdate = $v.learningUpdate.toBuilder();
      _results = $v.results.toBuilder();
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
            learningUpdate: learningUpdate.build(),
            results: results.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'learningUpdate';
        learningUpdate.build();
        _$failedField = 'results';
        results.build();
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
