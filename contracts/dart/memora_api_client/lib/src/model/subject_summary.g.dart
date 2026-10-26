// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subject_summary.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SubjectSummary extends SubjectSummary {
  @override
  final String code;
  @override
  final String curriculumEditionCode;
  @override
  final String curriculumVersionId;
  @override
  final String id;
  @override
  final String name;

  factory _$SubjectSummary([void Function(SubjectSummaryBuilder)? updates]) =>
      (SubjectSummaryBuilder()..update(updates))._build();

  _$SubjectSummary._(
      {required this.code,
      required this.curriculumEditionCode,
      required this.curriculumVersionId,
      required this.id,
      required this.name})
      : super._();
  @override
  SubjectSummary rebuild(void Function(SubjectSummaryBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SubjectSummaryBuilder toBuilder() => SubjectSummaryBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SubjectSummary &&
        code == other.code &&
        curriculumEditionCode == other.curriculumEditionCode &&
        curriculumVersionId == other.curriculumVersionId &&
        id == other.id &&
        name == other.name;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, code.hashCode);
    _$hash = $jc(_$hash, curriculumEditionCode.hashCode);
    _$hash = $jc(_$hash, curriculumVersionId.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SubjectSummary')
          ..add('code', code)
          ..add('curriculumEditionCode', curriculumEditionCode)
          ..add('curriculumVersionId', curriculumVersionId)
          ..add('id', id)
          ..add('name', name))
        .toString();
  }
}

class SubjectSummaryBuilder
    implements Builder<SubjectSummary, SubjectSummaryBuilder> {
  _$SubjectSummary? _$v;

  String? _code;
  String? get code => _$this._code;
  set code(String? code) => _$this._code = code;

  String? _curriculumEditionCode;
  String? get curriculumEditionCode => _$this._curriculumEditionCode;
  set curriculumEditionCode(String? curriculumEditionCode) =>
      _$this._curriculumEditionCode = curriculumEditionCode;

  String? _curriculumVersionId;
  String? get curriculumVersionId => _$this._curriculumVersionId;
  set curriculumVersionId(String? curriculumVersionId) =>
      _$this._curriculumVersionId = curriculumVersionId;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  SubjectSummaryBuilder() {
    SubjectSummary._defaults(this);
  }

  SubjectSummaryBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _code = $v.code;
      _curriculumEditionCode = $v.curriculumEditionCode;
      _curriculumVersionId = $v.curriculumVersionId;
      _id = $v.id;
      _name = $v.name;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SubjectSummary other) {
    _$v = other as _$SubjectSummary;
  }

  @override
  void update(void Function(SubjectSummaryBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SubjectSummary build() => _build();

  _$SubjectSummary _build() {
    final _$result = _$v ??
        _$SubjectSummary._(
          code: BuiltValueNullFieldError.checkNotNull(
              code, r'SubjectSummary', 'code'),
          curriculumEditionCode: BuiltValueNullFieldError.checkNotNull(
              curriculumEditionCode,
              r'SubjectSummary',
              'curriculumEditionCode'),
          curriculumVersionId: BuiltValueNullFieldError.checkNotNull(
              curriculumVersionId, r'SubjectSummary', 'curriculumVersionId'),
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'SubjectSummary', 'id'),
          name: BuiltValueNullFieldError.checkNotNull(
              name, r'SubjectSummary', 'name'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
