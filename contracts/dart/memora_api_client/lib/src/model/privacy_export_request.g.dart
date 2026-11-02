// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'privacy_export_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PrivacyExportRequest extends PrivacyExportRequest {
  @override
  final Optional<String?> format;

  factory _$PrivacyExportRequest(
          [void Function(PrivacyExportRequestBuilder)? updates]) =>
      (PrivacyExportRequestBuilder()..update(updates))._build();

  _$PrivacyExportRequest._({required this.format}) : super._();
  @override
  PrivacyExportRequest rebuild(
          void Function(PrivacyExportRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PrivacyExportRequestBuilder toBuilder() =>
      PrivacyExportRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PrivacyExportRequest && format == other.format;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, format.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PrivacyExportRequest')
          ..add('format', format))
        .toString();
  }
}

class PrivacyExportRequestBuilder
    implements Builder<PrivacyExportRequest, PrivacyExportRequestBuilder> {
  _$PrivacyExportRequest? _$v;

  Optional<String?>? _format;
  Optional<String?>? get format => _$this._format;
  set format(Optional<String?>? format) => _$this._format = format;

  PrivacyExportRequestBuilder() {
    PrivacyExportRequest._defaults(this);
  }

  PrivacyExportRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _format = $v.format;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PrivacyExportRequest other) {
    _$v = other as _$PrivacyExportRequest;
  }

  @override
  void update(void Function(PrivacyExportRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PrivacyExportRequest build() => _build();

  _$PrivacyExportRequest _build() {
    final _$result = _$v ??
        _$PrivacyExportRequest._(
          format: BuiltValueNullFieldError.checkNotNull(
              format, r'PrivacyExportRequest', 'format'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
