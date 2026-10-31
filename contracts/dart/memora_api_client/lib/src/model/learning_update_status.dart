//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'learning_update_status.g.dart';

class LearningUpdateStatus extends EnumClass {
  @BuiltValueEnumConst(wireName: r'draft')
  static const LearningUpdateStatus draft = _$draft;
  @BuiltValueEnumConst(wireName: r'uploading')
  static const LearningUpdateStatus uploading = _$uploading;
  @BuiltValueEnumConst(wireName: r'processing')
  static const LearningUpdateStatus processing = _$processing;
  @BuiltValueEnumConst(wireName: r'verification_required')
  static const LearningUpdateStatus verificationRequired =
      _$verificationRequired;
  @BuiltValueEnumConst(wireName: r'committed')
  static const LearningUpdateStatus committed = _$committed;
  @BuiltValueEnumConst(wireName: r'failed')
  static const LearningUpdateStatus failed = _$failed;
  @BuiltValueEnumConst(wireName: r'expired')
  static const LearningUpdateStatus expired = _$expired;
  @BuiltValueEnumConst(wireName: r'deleted')
  static const LearningUpdateStatus deleted = _$deleted;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const LearningUpdateStatus unknownDefaultOpenApi =
      _$unknownDefaultOpenApi;

  static Serializer<LearningUpdateStatus> get serializer =>
      _$learningUpdateStatusSerializer;

  const LearningUpdateStatus._(String name) : super(name);

  static BuiltSet<LearningUpdateStatus> get values => _$values;
  static LearningUpdateStatus valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class LearningUpdateStatusMixin = Object
    with _$LearningUpdateStatusMixin;
