//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'session_revocation_scope.g.dart';

class SessionRevocationScope extends EnumClass {

  @BuiltValueEnumConst(wireName: r'current')
  static const SessionRevocationScope current = _$current;
  @BuiltValueEnumConst(wireName: r'other_sessions')
  static const SessionRevocationScope otherSessions = _$otherSessions;
  @BuiltValueEnumConst(wireName: r'all')
  static const SessionRevocationScope all = _$all;
  @BuiltValueEnumConst(wireName: r'unknown_default_open_api', fallback: true)
  static const SessionRevocationScope unknownDefaultOpenApi = _$unknownDefaultOpenApi;

  static Serializer<SessionRevocationScope> get serializer => _$sessionRevocationScopeSerializer;

  const SessionRevocationScope._(String name): super(name);

  static BuiltSet<SessionRevocationScope> get values => _$values;
  static SessionRevocationScope valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class SessionRevocationScopeMixin = Object with _$SessionRevocationScopeMixin;

