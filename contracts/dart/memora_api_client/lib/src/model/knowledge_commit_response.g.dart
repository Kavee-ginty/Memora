// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'knowledge_commit_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$KnowledgeCommitResponse extends KnowledgeCommitResponse {
  @override
  final int commitVersion;
  @override
  final BuiltMap<String, int> committedCounts;
  @override
  final BuiltList<LearningPathPreviewConcept> conceptMappings;
  @override
  final Optional<FirstMissionSummary?> firstMission;
  @override
  final String knowledgeCommitId;
  @override
  final LearningUpdateResponse learningUpdate;
  @override
  final int privateKnowledgeCount;
  @override
  final DeletionStatus sourceDeletionStatus;

  factory _$KnowledgeCommitResponse(
          [void Function(KnowledgeCommitResponseBuilder)? updates]) =>
      (KnowledgeCommitResponseBuilder()..update(updates))._build();

  _$KnowledgeCommitResponse._(
      {required this.commitVersion,
      required this.committedCounts,
      required this.conceptMappings,
      required this.firstMission,
      required this.knowledgeCommitId,
      required this.learningUpdate,
      required this.privateKnowledgeCount,
      required this.sourceDeletionStatus})
      : super._();
  @override
  KnowledgeCommitResponse rebuild(
          void Function(KnowledgeCommitResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  KnowledgeCommitResponseBuilder toBuilder() =>
      KnowledgeCommitResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is KnowledgeCommitResponse &&
        commitVersion == other.commitVersion &&
        committedCounts == other.committedCounts &&
        conceptMappings == other.conceptMappings &&
        firstMission == other.firstMission &&
        knowledgeCommitId == other.knowledgeCommitId &&
        learningUpdate == other.learningUpdate &&
        privateKnowledgeCount == other.privateKnowledgeCount &&
        sourceDeletionStatus == other.sourceDeletionStatus;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, commitVersion.hashCode);
    _$hash = $jc(_$hash, committedCounts.hashCode);
    _$hash = $jc(_$hash, conceptMappings.hashCode);
    _$hash = $jc(_$hash, firstMission.hashCode);
    _$hash = $jc(_$hash, knowledgeCommitId.hashCode);
    _$hash = $jc(_$hash, learningUpdate.hashCode);
    _$hash = $jc(_$hash, privateKnowledgeCount.hashCode);
    _$hash = $jc(_$hash, sourceDeletionStatus.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'KnowledgeCommitResponse')
          ..add('commitVersion', commitVersion)
          ..add('committedCounts', committedCounts)
          ..add('conceptMappings', conceptMappings)
          ..add('firstMission', firstMission)
          ..add('knowledgeCommitId', knowledgeCommitId)
          ..add('learningUpdate', learningUpdate)
          ..add('privateKnowledgeCount', privateKnowledgeCount)
          ..add('sourceDeletionStatus', sourceDeletionStatus))
        .toString();
  }
}

class KnowledgeCommitResponseBuilder
    implements
        Builder<KnowledgeCommitResponse, KnowledgeCommitResponseBuilder> {
  _$KnowledgeCommitResponse? _$v;

  int? _commitVersion;
  int? get commitVersion => _$this._commitVersion;
  set commitVersion(int? commitVersion) =>
      _$this._commitVersion = commitVersion;

  MapBuilder<String, int>? _committedCounts;
  MapBuilder<String, int> get committedCounts =>
      _$this._committedCounts ??= MapBuilder<String, int>();
  set committedCounts(MapBuilder<String, int>? committedCounts) =>
      _$this._committedCounts = committedCounts;

  ListBuilder<LearningPathPreviewConcept>? _conceptMappings;
  ListBuilder<LearningPathPreviewConcept> get conceptMappings =>
      _$this._conceptMappings ??= ListBuilder<LearningPathPreviewConcept>();
  set conceptMappings(
          ListBuilder<LearningPathPreviewConcept>? conceptMappings) =>
      _$this._conceptMappings = conceptMappings;

  Optional<FirstMissionSummary?>? _firstMission;
  Optional<FirstMissionSummary?>? get firstMission => _$this._firstMission;
  set firstMission(Optional<FirstMissionSummary?>? firstMission) =>
      _$this._firstMission = firstMission;

  String? _knowledgeCommitId;
  String? get knowledgeCommitId => _$this._knowledgeCommitId;
  set knowledgeCommitId(String? knowledgeCommitId) =>
      _$this._knowledgeCommitId = knowledgeCommitId;

  LearningUpdateResponseBuilder? _learningUpdate;
  LearningUpdateResponseBuilder get learningUpdate =>
      _$this._learningUpdate ??= LearningUpdateResponseBuilder();
  set learningUpdate(LearningUpdateResponseBuilder? learningUpdate) =>
      _$this._learningUpdate = learningUpdate;

  int? _privateKnowledgeCount;
  int? get privateKnowledgeCount => _$this._privateKnowledgeCount;
  set privateKnowledgeCount(int? privateKnowledgeCount) =>
      _$this._privateKnowledgeCount = privateKnowledgeCount;

  DeletionStatus? _sourceDeletionStatus;
  DeletionStatus? get sourceDeletionStatus => _$this._sourceDeletionStatus;
  set sourceDeletionStatus(DeletionStatus? sourceDeletionStatus) =>
      _$this._sourceDeletionStatus = sourceDeletionStatus;

  KnowledgeCommitResponseBuilder() {
    KnowledgeCommitResponse._defaults(this);
  }

  KnowledgeCommitResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _commitVersion = $v.commitVersion;
      _committedCounts = $v.committedCounts.toBuilder();
      _conceptMappings = $v.conceptMappings.toBuilder();
      _firstMission = $v.firstMission;
      _knowledgeCommitId = $v.knowledgeCommitId;
      _learningUpdate = $v.learningUpdate.toBuilder();
      _privateKnowledgeCount = $v.privateKnowledgeCount;
      _sourceDeletionStatus = $v.sourceDeletionStatus;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(KnowledgeCommitResponse other) {
    _$v = other as _$KnowledgeCommitResponse;
  }

  @override
  void update(void Function(KnowledgeCommitResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  KnowledgeCommitResponse build() => _build();

  _$KnowledgeCommitResponse _build() {
    _$KnowledgeCommitResponse _$result;
    try {
      _$result = _$v ??
          _$KnowledgeCommitResponse._(
            commitVersion: BuiltValueNullFieldError.checkNotNull(
                commitVersion, r'KnowledgeCommitResponse', 'commitVersion'),
            committedCounts: committedCounts.build(),
            conceptMappings: conceptMappings.build(),
            firstMission: BuiltValueNullFieldError.checkNotNull(
                firstMission, r'KnowledgeCommitResponse', 'firstMission'),
            knowledgeCommitId: BuiltValueNullFieldError.checkNotNull(
                knowledgeCommitId,
                r'KnowledgeCommitResponse',
                'knowledgeCommitId'),
            learningUpdate: learningUpdate.build(),
            privateKnowledgeCount: BuiltValueNullFieldError.checkNotNull(
                privateKnowledgeCount,
                r'KnowledgeCommitResponse',
                'privateKnowledgeCount'),
            sourceDeletionStatus: BuiltValueNullFieldError.checkNotNull(
                sourceDeletionStatus,
                r'KnowledgeCommitResponse',
                'sourceDeletionStatus'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'committedCounts';
        committedCounts.build();
        _$failedField = 'conceptMappings';
        conceptMappings.build();

        _$failedField = 'learningUpdate';
        learningUpdate.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'KnowledgeCommitResponse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
