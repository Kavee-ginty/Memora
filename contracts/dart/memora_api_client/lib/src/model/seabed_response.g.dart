// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seabed_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SeabedResponse extends SeabedResponse {
  @override
  final String projectionVersion;
  @override
  final BuiltList<SeabedReef> reefs;

  factory _$SeabedResponse([void Function(SeabedResponseBuilder)? updates]) =>
      (SeabedResponseBuilder()..update(updates))._build();

  _$SeabedResponse._({required this.projectionVersion, required this.reefs})
      : super._();
  @override
  SeabedResponse rebuild(void Function(SeabedResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SeabedResponseBuilder toBuilder() => SeabedResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SeabedResponse &&
        projectionVersion == other.projectionVersion &&
        reefs == other.reefs;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, projectionVersion.hashCode);
    _$hash = $jc(_$hash, reefs.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SeabedResponse')
          ..add('projectionVersion', projectionVersion)
          ..add('reefs', reefs))
        .toString();
  }
}

class SeabedResponseBuilder
    implements Builder<SeabedResponse, SeabedResponseBuilder> {
  _$SeabedResponse? _$v;

  String? _projectionVersion;
  String? get projectionVersion => _$this._projectionVersion;
  set projectionVersion(String? projectionVersion) =>
      _$this._projectionVersion = projectionVersion;

  ListBuilder<SeabedReef>? _reefs;
  ListBuilder<SeabedReef> get reefs =>
      _$this._reefs ??= ListBuilder<SeabedReef>();
  set reefs(ListBuilder<SeabedReef>? reefs) => _$this._reefs = reefs;

  SeabedResponseBuilder() {
    SeabedResponse._defaults(this);
  }

  SeabedResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _projectionVersion = $v.projectionVersion;
      _reefs = $v.reefs.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SeabedResponse other) {
    _$v = other as _$SeabedResponse;
  }

  @override
  void update(void Function(SeabedResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SeabedResponse build() => _build();

  _$SeabedResponse _build() {
    _$SeabedResponse _$result;
    try {
      _$result = _$v ??
          _$SeabedResponse._(
            projectionVersion: BuiltValueNullFieldError.checkNotNull(
                projectionVersion, r'SeabedResponse', 'projectionVersion'),
            reefs: reefs.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'reefs';
        reefs.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'SeabedResponse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
