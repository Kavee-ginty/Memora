// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'learning_path_preview_concept.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$LearningPathPreviewConcept extends LearningPathPreviewConcept {
  @override
  final String candidateId;
  @override
  final String candidateType;
  @override
  final String? conceptId;
  @override
  final String? conceptVersionId;
  @override
  final String title;

  factory _$LearningPathPreviewConcept(
          [void Function(LearningPathPreviewConceptBuilder)? updates]) =>
      (LearningPathPreviewConceptBuilder()..update(updates))._build();

  _$LearningPathPreviewConcept._(
      {required this.candidateId,
      required this.candidateType,
      this.conceptId,
      this.conceptVersionId,
      required this.title})
      : super._();
  @override
  LearningPathPreviewConcept rebuild(
          void Function(LearningPathPreviewConceptBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  LearningPathPreviewConceptBuilder toBuilder() =>
      LearningPathPreviewConceptBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is LearningPathPreviewConcept &&
        candidateId == other.candidateId &&
        candidateType == other.candidateType &&
        conceptId == other.conceptId &&
        conceptVersionId == other.conceptVersionId &&
        title == other.title;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, candidateId.hashCode);
    _$hash = $jc(_$hash, candidateType.hashCode);
    _$hash = $jc(_$hash, conceptId.hashCode);
    _$hash = $jc(_$hash, conceptVersionId.hashCode);
    _$hash = $jc(_$hash, title.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'LearningPathPreviewConcept')
          ..add('candidateId', candidateId)
          ..add('candidateType', candidateType)
          ..add('conceptId', conceptId)
          ..add('conceptVersionId', conceptVersionId)
          ..add('title', title))
        .toString();
  }
}

class LearningPathPreviewConceptBuilder
    implements
        Builder<LearningPathPreviewConcept, LearningPathPreviewConceptBuilder> {
  _$LearningPathPreviewConcept? _$v;

  String? _candidateId;
  String? get candidateId => _$this._candidateId;
  set candidateId(String? candidateId) => _$this._candidateId = candidateId;

  String? _candidateType;
  String? get candidateType => _$this._candidateType;
  set candidateType(String? candidateType) =>
      _$this._candidateType = candidateType;

  String? _conceptId;
  String? get conceptId => _$this._conceptId;
  set conceptId(String? conceptId) => _$this._conceptId = conceptId;

  String? _conceptVersionId;
  String? get conceptVersionId => _$this._conceptVersionId;
  set conceptVersionId(String? conceptVersionId) =>
      _$this._conceptVersionId = conceptVersionId;

  String? _title;
  String? get title => _$this._title;
  set title(String? title) => _$this._title = title;

  LearningPathPreviewConceptBuilder() {
    LearningPathPreviewConcept._defaults(this);
  }

  LearningPathPreviewConceptBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _candidateId = $v.candidateId;
      _candidateType = $v.candidateType;
      _conceptId = $v.conceptId;
      _conceptVersionId = $v.conceptVersionId;
      _title = $v.title;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(LearningPathPreviewConcept other) {
    _$v = other as _$LearningPathPreviewConcept;
  }

  @override
  void update(void Function(LearningPathPreviewConceptBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  LearningPathPreviewConcept build() => _build();

  _$LearningPathPreviewConcept _build() {
    final _$result = _$v ??
        _$LearningPathPreviewConcept._(
          candidateId: BuiltValueNullFieldError.checkNotNull(
              candidateId, r'LearningPathPreviewConcept', 'candidateId'),
          candidateType: BuiltValueNullFieldError.checkNotNull(
              candidateType, r'LearningPathPreviewConcept', 'candidateType'),
          conceptId: conceptId,
          conceptVersionId: conceptVersionId,
          title: BuiltValueNullFieldError.checkNotNull(
              title, r'LearningPathPreviewConcept', 'title'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
