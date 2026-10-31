//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'upload_status.g.dart';

class UploadStatus extends EnumClass {
  @BuiltValueEnumConst(wireName: r'authorized')
  static const UploadStatus authorized = _$authorized;
  @BuiltValueEnumConst(wireName: r'uploaded')
  static const UploadStatus uploaded = _$uploaded;
  @BuiltValueEnumConst(wireName: r'validated')
  static const UploadStatus validated = _$validated;
  @BuiltValueEnumConst(wireName: r'processing')
  static const UploadStatus processing = _$processing;
  @BuiltValueEnumConst(wireName: r'deleting')
  static const UploadStatus deleting = _$deleting;
  @BuiltValueEnumConst(wireName: r'deleted')
  static const UploadStatus deleted = _$deleted;
  @BuiltValueEnumConst(wireName: r'rejected')
  static const UploadStatus rejected = _$rejected;
  @BuiltValueEnumConst(wireName: r'expired')
  static const UploadStatus expired = _$expired;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const UploadStatus unknownDefaultOpenApi = _$unknownDefaultOpenApi;

  static Serializer<UploadStatus> get serializer => _$uploadStatusSerializer;

  const UploadStatus._(String name) : super(name);

  static BuiltSet<UploadStatus> get values => _$values;
  static UploadStatus valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class UploadStatusMixin = Object with _$UploadStatusMixin;
