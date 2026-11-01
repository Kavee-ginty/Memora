// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_question_option.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PublicQuestionOption extends PublicQuestionOption {
  @override
  final String? accessibleImageRef;
  @override
  final int displayOrder;
  @override
  final String displayText;
  @override
  final String optionKey;

  factory _$PublicQuestionOption(
          [void Function(PublicQuestionOptionBuilder)? updates]) =>
      (PublicQuestionOptionBuilder()..update(updates))._build();

  _$PublicQuestionOption._(
      {this.accessibleImageRef,
      required this.displayOrder,
      required this.displayText,
      required this.optionKey})
      : super._();
  @override
  PublicQuestionOption rebuild(
          void Function(PublicQuestionOptionBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PublicQuestionOptionBuilder toBuilder() =>
      PublicQuestionOptionBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PublicQuestionOption &&
        accessibleImageRef == other.accessibleImageRef &&
        displayOrder == other.displayOrder &&
        displayText == other.displayText &&
        optionKey == other.optionKey;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, accessibleImageRef.hashCode);
    _$hash = $jc(_$hash, displayOrder.hashCode);
    _$hash = $jc(_$hash, displayText.hashCode);
    _$hash = $jc(_$hash, optionKey.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PublicQuestionOption')
          ..add('accessibleImageRef', accessibleImageRef)
          ..add('displayOrder', displayOrder)
          ..add('displayText', displayText)
          ..add('optionKey', optionKey))
        .toString();
  }
}

class PublicQuestionOptionBuilder
    implements Builder<PublicQuestionOption, PublicQuestionOptionBuilder> {
  _$PublicQuestionOption? _$v;

  String? _accessibleImageRef;
  String? get accessibleImageRef => _$this._accessibleImageRef;
  set accessibleImageRef(String? accessibleImageRef) =>
      _$this._accessibleImageRef = accessibleImageRef;

  int? _displayOrder;
  int? get displayOrder => _$this._displayOrder;
  set displayOrder(int? displayOrder) => _$this._displayOrder = displayOrder;

  String? _displayText;
  String? get displayText => _$this._displayText;
  set displayText(String? displayText) => _$this._displayText = displayText;

  String? _optionKey;
  String? get optionKey => _$this._optionKey;
  set optionKey(String? optionKey) => _$this._optionKey = optionKey;

  PublicQuestionOptionBuilder() {
    PublicQuestionOption._defaults(this);
  }

  PublicQuestionOptionBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _accessibleImageRef = $v.accessibleImageRef;
      _displayOrder = $v.displayOrder;
      _displayText = $v.displayText;
      _optionKey = $v.optionKey;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PublicQuestionOption other) {
    _$v = other as _$PublicQuestionOption;
  }

  @override
  void update(void Function(PublicQuestionOptionBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PublicQuestionOption build() => _build();

  _$PublicQuestionOption _build() {
    final _$result = _$v ??
        _$PublicQuestionOption._(
          accessibleImageRef: accessibleImageRef,
          displayOrder: BuiltValueNullFieldError.checkNotNull(
              displayOrder, r'PublicQuestionOption', 'displayOrder'),
          displayText: BuiltValueNullFieldError.checkNotNull(
              displayText, r'PublicQuestionOption', 'displayText'),
          optionKey: BuiltValueNullFieldError.checkNotNull(
              optionKey, r'PublicQuestionOption', 'optionKey'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
