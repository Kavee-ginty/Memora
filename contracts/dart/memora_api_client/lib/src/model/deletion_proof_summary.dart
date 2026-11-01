//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'deletion_proof_summary.g.dart';

/// DeletionProofSummary
///
/// Properties:
/// * [id]
/// * [provider]
/// * [result]
/// * [scope]
/// * [targetFingerprint]
/// * [verifiedAt]
@BuiltValue()
abstract class DeletionProofSummary
    implements Built<DeletionProofSummary, DeletionProofSummaryBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'provider')
  String get provider;

  @BuiltValueField(wireName: r'result')
  String get result;

  @BuiltValueField(wireName: r'scope')
  String get scope;

  @BuiltValueField(wireName: r'target_fingerprint')
  String get targetFingerprint;

  @BuiltValueField(wireName: r'verified_at')
  String get verifiedAt;

  DeletionProofSummary._();

  factory DeletionProofSummary([void updates(DeletionProofSummaryBuilder b)]) =
      _$DeletionProofSummary;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DeletionProofSummaryBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DeletionProofSummary> get serializer =>
      _$DeletionProofSummarySerializer();
}

class _$DeletionProofSummarySerializer
    implements PrimitiveSerializer<DeletionProofSummary> {
  @override
  final Iterable<Type> types = const [
    DeletionProofSummary,
    _$DeletionProofSummary
  ];

  @override
  final String wireName = r'DeletionProofSummary';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DeletionProofSummary object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'provider';
    yield serializers.serialize(
      object.provider,
      specifiedType: const FullType(String),
    );
    yield r'result';
    yield serializers.serialize(
      object.result,
      specifiedType: const FullType(String),
    );
    yield r'scope';
    yield serializers.serialize(
      object.scope,
      specifiedType: const FullType(String),
    );
    yield r'target_fingerprint';
    yield serializers.serialize(
      object.targetFingerprint,
      specifiedType: const FullType(String),
    );
    yield r'verified_at';
    yield serializers.serialize(
      object.verifiedAt,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    DeletionProofSummary object, {
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
    required DeletionProofSummaryBuilder result,
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
        case r'provider':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.provider = valueDes;
          break;
        case r'result':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.result = valueDes;
          break;
        case r'scope':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.scope = valueDes;
          break;
        case r'target_fingerprint':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.targetFingerprint = valueDes;
          break;
        case r'verified_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.verifiedAt = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DeletionProofSummary deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DeletionProofSummaryBuilder();
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
