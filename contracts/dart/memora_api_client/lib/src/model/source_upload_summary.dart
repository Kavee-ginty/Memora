//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:memora_api_client/src/model/deletion_status.dart';
import 'package:memora_api_client/src/model/upload_status.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'source_upload_summary.g.dart';

/// SourceUploadSummary
///
/// Properties:
/// * [byteSize] 
/// * [declaredMediaType] 
/// * [declaredName] 
/// * [deletedAt] 
/// * [deletionStatus] 
/// * [detectedMediaType] 
/// * [expiresAt] 
/// * [id] 
/// * [status] 
@BuiltValue()
abstract class SourceUploadSummary implements Built<SourceUploadSummary, SourceUploadSummaryBuilder> {
  @BuiltValueField(wireName: r'byte_size')
  int get byteSize;

  @BuiltValueField(wireName: r'declared_media_type')
  String get declaredMediaType;

  @BuiltValueField(wireName: r'declared_name')
  String get declaredName;

  @BuiltValueField(wireName: r'deleted_at')
  String? get deletedAt;

  @BuiltValueField(wireName: r'deletion_status')
  DeletionStatus get deletionStatus;
  // enum deletionStatusEnum {  not_required,  pending,  deleted,  failed,  };

  @BuiltValueField(wireName: r'detected_media_type')
  String? get detectedMediaType;

  @BuiltValueField(wireName: r'expires_at')
  String get expiresAt;

  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'status')
  UploadStatus get status;
  // enum statusEnum {  authorized,  uploaded,  validated,  processing,  deleting,  deleted,  rejected,  expired,  };

  SourceUploadSummary._();

  factory SourceUploadSummary([void updates(SourceUploadSummaryBuilder b)]) = _$SourceUploadSummary;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SourceUploadSummaryBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SourceUploadSummary> get serializer => _$SourceUploadSummarySerializer();
}

class _$SourceUploadSummarySerializer implements PrimitiveSerializer<SourceUploadSummary> {
  @override
  final Iterable<Type> types = const [SourceUploadSummary, _$SourceUploadSummary];

  @override
  final String wireName = r'SourceUploadSummary';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SourceUploadSummary object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'byte_size';
    yield serializers.serialize(
      object.byteSize,
      specifiedType: const FullType(int),
    );
    yield r'declared_media_type';
    yield serializers.serialize(
      object.declaredMediaType,
      specifiedType: const FullType(String),
    );
    yield r'declared_name';
    yield serializers.serialize(
      object.declaredName,
      specifiedType: const FullType(String),
    );
    yield r'deleted_at';
    yield object.deletedAt == null ? null : serializers.serialize(
      object.deletedAt,
      specifiedType: const FullType.nullable(String),
    );
    yield r'deletion_status';
    yield serializers.serialize(
      object.deletionStatus,
      specifiedType: const FullType(DeletionStatus),
    );
    yield r'detected_media_type';
    yield object.detectedMediaType == null ? null : serializers.serialize(
      object.detectedMediaType,
      specifiedType: const FullType.nullable(String),
    );
    yield r'expires_at';
    yield serializers.serialize(
      object.expiresAt,
      specifiedType: const FullType(String),
    );
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(UploadStatus),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    SourceUploadSummary object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SourceUploadSummaryBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'byte_size':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.byteSize = valueDes;
          break;
        case r'declared_media_type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.declaredMediaType = valueDes;
          break;
        case r'declared_name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.declaredName = valueDes;
          break;
        case r'deleted_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.deletedAt = valueDes;
          break;
        case r'deletion_status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DeletionStatus),
          ) as DeletionStatus;
          result.deletionStatus = valueDes;
          break;
        case r'detected_media_type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.detectedMediaType = valueDes;
          break;
        case r'expires_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.expiresAt = valueDes;
          break;
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(UploadStatus),
          ) as UploadStatus;
          result.status = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SourceUploadSummary deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SourceUploadSummaryBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}


