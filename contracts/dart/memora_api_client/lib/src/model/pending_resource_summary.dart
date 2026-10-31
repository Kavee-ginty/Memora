//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'pending_resource_summary.g.dart';

/// PendingResourceSummary
///
/// Properties:
/// * [id] 
/// * [status] 
/// * [updatedAt] 
@BuiltValue()
abstract class PendingResourceSummary implements Built<PendingResourceSummary, PendingResourceSummaryBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'status')
  String get status;

  @BuiltValueField(wireName: r'updated_at')
  DateTime get updatedAt;

  PendingResourceSummary._();

  factory PendingResourceSummary([void updates(PendingResourceSummaryBuilder b)]) = _$PendingResourceSummary;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PendingResourceSummaryBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PendingResourceSummary> get serializer => _$PendingResourceSummarySerializer();
}

class _$PendingResourceSummarySerializer implements PrimitiveSerializer<PendingResourceSummary> {
  @override
  final Iterable<Type> types = const [PendingResourceSummary, _$PendingResourceSummary];

  @override
  final String wireName = r'PendingResourceSummary';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PendingResourceSummary object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(String),
    );
    yield r'updated_at';
    yield serializers.serialize(
      object.updatedAt,
      specifiedType: const FullType(DateTime),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PendingResourceSummary object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PendingResourceSummaryBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
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
            specifiedType: const FullType(String),
          ) as String;
          result.status = valueDes;
          break;
        case r'updated_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.updatedAt = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PendingResourceSummary deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PendingResourceSummaryBuilder();
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


