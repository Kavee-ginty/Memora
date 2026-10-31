//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:memora_api_client/src/model/session_revocation_scope.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:memora_api_client/src/optional.dart';

part 'session_revoke_request.g.dart';

/// SessionRevokeRequest
///
/// Properties:
/// * [scope] 
@BuiltValue()
abstract class SessionRevokeRequest implements Built<SessionRevokeRequest, SessionRevokeRequestBuilder> {
  @BuiltValueField(wireName: r'scope')
  Optional<SessionRevocationScope?> get scope;
  // enum scopeEnum {  current,  other_sessions,  all,  };

  SessionRevokeRequest._();

  factory SessionRevokeRequest([void updates(SessionRevokeRequestBuilder b)]) = _$SessionRevokeRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SessionRevokeRequestBuilder b) => b
      ..scope = Optional.absent();

  @BuiltValueSerializer(custom: true)
  static Serializer<SessionRevokeRequest> get serializer => _$SessionRevokeRequestSerializer();
}

class _$SessionRevokeRequestSerializer implements PrimitiveSerializer<SessionRevokeRequest> {
  @override
  final Iterable<Type> types = const [SessionRevokeRequest, _$SessionRevokeRequest];

  @override
  final String wireName = r'SessionRevokeRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SessionRevokeRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.scope.isPresent) {
      yield r'scope';
      final optionalValue = object.scope.value;
      if (optionalValue == null) {
        yield null;
      } else {
        yield serializers.serialize(
          optionalValue,
          specifiedType: const FullType.nullable(SessionRevocationScope),
        );
      }
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    SessionRevokeRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SessionRevokeRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'scope':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(SessionRevocationScope),
          ) as SessionRevocationScope?;
          result.scope = Optional.present(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SessionRevokeRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SessionRevokeRequestBuilder();
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


