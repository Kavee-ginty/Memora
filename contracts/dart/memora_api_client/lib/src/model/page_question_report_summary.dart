//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:memora_api_client/src/model/question_report_summary.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'page_question_report_summary.g.dart';

/// PageQuestionReportSummary
///
/// Properties:
/// * [hasMore] 
/// * [items] 
/// * [nextCursor] 
@BuiltValue()
abstract class PageQuestionReportSummary implements Built<PageQuestionReportSummary, PageQuestionReportSummaryBuilder> {
  @BuiltValueField(wireName: r'has_more')
  bool get hasMore;

  @BuiltValueField(wireName: r'items')
  BuiltList<QuestionReportSummary> get items;

  @BuiltValueField(wireName: r'next_cursor')
  String? get nextCursor;

  PageQuestionReportSummary._();

  factory PageQuestionReportSummary([void updates(PageQuestionReportSummaryBuilder b)]) = _$PageQuestionReportSummary;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PageQuestionReportSummaryBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PageQuestionReportSummary> get serializer => _$PageQuestionReportSummarySerializer();
}

class _$PageQuestionReportSummarySerializer implements PrimitiveSerializer<PageQuestionReportSummary> {
  @override
  final Iterable<Type> types = const [PageQuestionReportSummary, _$PageQuestionReportSummary];

  @override
  final String wireName = r'PageQuestionReportSummary';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PageQuestionReportSummary object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'has_more';
    yield serializers.serialize(
      object.hasMore,
      specifiedType: const FullType(bool),
    );
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(QuestionReportSummary)]),
    );
    yield r'next_cursor';
    yield object.nextCursor == null ? null : serializers.serialize(
      object.nextCursor,
      specifiedType: const FullType.nullable(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PageQuestionReportSummary object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PageQuestionReportSummaryBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'has_more':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.hasMore = valueDes;
          break;
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(QuestionReportSummary)]),
          ) as BuiltList<QuestionReportSummary>;
          result.items.replace(valueDes);
          break;
        case r'next_cursor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.nextCursor = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PageQuestionReportSummary deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PageQuestionReportSummaryBuilder();
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


