//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'deletion_status.g.dart';

class DeletionStatus extends EnumClass {

  @BuiltValueEnumConst(wireName: r'not_required')
  static const DeletionStatus notRequired = _$notRequired;
  @BuiltValueEnumConst(wireName: r'pending')
  static const DeletionStatus pending = _$pending;
  @BuiltValueEnumConst(wireName: r'deleted')
  static const DeletionStatus deleted = _$deleted;
  @BuiltValueEnumConst(wireName: r'failed')
  static const DeletionStatus failed = _$failed;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const DeletionStatus unknownDefaultOpenApi = _$unknownDefaultOpenApi;

  static Serializer<DeletionStatus> get serializer => _$deletionStatusSerializer;

  const DeletionStatus._(String name): super(name);

  static BuiltSet<DeletionStatus> get values => _$values;
  static DeletionStatus valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class DeletionStatusMixin = Object with _$DeletionStatusMixin;

