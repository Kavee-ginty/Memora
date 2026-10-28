//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'candidate_status.g.dart';

class CandidateStatus extends EnumClass {
  @BuiltValueEnumConst(wireName: r'candidate')
  static const CandidateStatus candidate = _$candidate;
  @BuiltValueEnumConst(wireName: r'needs_verification')
  static const CandidateStatus needsVerification = _$needsVerification;
  @BuiltValueEnumConst(wireName: r'accepted')
  static const CandidateStatus accepted = _$accepted;
  @BuiltValueEnumConst(wireName: r'rejected')
  static const CandidateStatus rejected = _$rejected;
  @BuiltValueEnumConst(wireName: r'committed')
  static const CandidateStatus committed = _$committed;
  @BuiltValueEnumConst(wireName: r'expired')
  static const CandidateStatus expired = _$expired;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const CandidateStatus unknownDefaultOpenApi = _$unknownDefaultOpenApi;

  static Serializer<CandidateStatus> get serializer =>
      _$candidateStatusSerializer;

  const CandidateStatus._(String name) : super(name);

  static BuiltSet<CandidateStatus> get values => _$values;
  static CandidateStatus valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class CandidateStatusMixin = Object with _$CandidateStatusMixin;
