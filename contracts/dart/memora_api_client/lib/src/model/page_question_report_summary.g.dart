// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page_question_report_summary.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PageQuestionReportSummary extends PageQuestionReportSummary {
  @override
  final bool hasMore;
  @override
  final BuiltList<QuestionReportSummary> items;
  @override
  final String? nextCursor;

  factory _$PageQuestionReportSummary(
          [void Function(PageQuestionReportSummaryBuilder)? updates]) =>
      (PageQuestionReportSummaryBuilder()..update(updates))._build();

  _$PageQuestionReportSummary._(
      {required this.hasMore, required this.items, this.nextCursor})
      : super._();
  @override
  PageQuestionReportSummary rebuild(
          void Function(PageQuestionReportSummaryBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PageQuestionReportSummaryBuilder toBuilder() =>
      PageQuestionReportSummaryBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PageQuestionReportSummary &&
        hasMore == other.hasMore &&
        items == other.items &&
        nextCursor == other.nextCursor;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, hasMore.hashCode);
    _$hash = $jc(_$hash, items.hashCode);
    _$hash = $jc(_$hash, nextCursor.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PageQuestionReportSummary')
          ..add('hasMore', hasMore)
          ..add('items', items)
          ..add('nextCursor', nextCursor))
        .toString();
  }
}

class PageQuestionReportSummaryBuilder
    implements
        Builder<PageQuestionReportSummary, PageQuestionReportSummaryBuilder> {
  _$PageQuestionReportSummary? _$v;

  bool? _hasMore;
  bool? get hasMore => _$this._hasMore;
  set hasMore(bool? hasMore) => _$this._hasMore = hasMore;

  ListBuilder<QuestionReportSummary>? _items;
  ListBuilder<QuestionReportSummary> get items =>
      _$this._items ??= ListBuilder<QuestionReportSummary>();
  set items(ListBuilder<QuestionReportSummary>? items) => _$this._items = items;

  String? _nextCursor;
  String? get nextCursor => _$this._nextCursor;
  set nextCursor(String? nextCursor) => _$this._nextCursor = nextCursor;

  PageQuestionReportSummaryBuilder() {
    PageQuestionReportSummary._defaults(this);
  }

  PageQuestionReportSummaryBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _hasMore = $v.hasMore;
      _items = $v.items.toBuilder();
      _nextCursor = $v.nextCursor;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PageQuestionReportSummary other) {
    _$v = other as _$PageQuestionReportSummary;
  }

  @override
  void update(void Function(PageQuestionReportSummaryBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PageQuestionReportSummary build() => _build();

  _$PageQuestionReportSummary _build() {
    _$PageQuestionReportSummary _$result;
    try {
      _$result = _$v ??
          _$PageQuestionReportSummary._(
            hasMore: BuiltValueNullFieldError.checkNotNull(
                hasMore, r'PageQuestionReportSummary', 'hasMore'),
            items: items.build(),
            nextCursor: nextCursor,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'items';
        items.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'PageQuestionReportSummary', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
