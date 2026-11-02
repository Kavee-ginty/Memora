//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'finalize_upload_request.g.dart';

/// FinalizeUploadRequest
///
/// Properties:
/// * [clientOperationId]
/// * [contentSha256]
/// * [observedSize]
@BuiltValue()
abstract class FinalizeUploadRequest
    implements Built<FinalizeUploadRequest, FinalizeUploadRequestBuilder> {
  @BuiltValueField(wireName: r'client_operation_id')
  String get clientOperationId;

  @BuiltValueField(wireName: r'content_sha256')
  String get contentSha256;

  @BuiltValueField(wireName: r'observed_size')
  int get observedSize;

  FinalizeUploadRequest._();

  factory FinalizeUploadRequest(
      [void updates(FinalizeUploadRequestBuilder b)]) = _$FinalizeUploadRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(FinalizeUploadRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<FinalizeUploadRequest> get serializer =>
      _$FinalizeUploadRequestSerializer();
}

class _$FinalizeUploadRequestSerializer
    implements PrimitiveSerializer<FinalizeUploadRequest> {
  @override
  final Iterable<Type> types = const [
    FinalizeUploadRequest,
    _$FinalizeUploadRequest
  ];

  @override
  final String wireName = r'FinalizeUploadRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    FinalizeUploadRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'client_operation_id';
    yield serializers.serialize(
      object.clientOperationId,
      specifiedType: const FullType(String),
    );
    yield r'content_sha256';
    yield serializers.serialize(
      object.contentSha256,
      specifiedType: const FullType(String),
    );
    yield r'observed_size';
    yield serializers.serialize(
      object.observedSize,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    FinalizeUploadRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object,
            specifiedType: specifiedType)
        .toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required FinalizeUploadRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'client_operation_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.clientOperationId = valueDes;
          break;
        case r'content_sha256':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.contentSha256 = valueDes;
          break;
        case r'observed_size':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.observedSize = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  FinalizeUploadRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = FinalizeUploadRequestBuilder();
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
