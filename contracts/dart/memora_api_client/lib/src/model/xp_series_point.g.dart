// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'xp_series_point.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$XpSeriesPoint extends XpSeriesPoint {
  @override
  final Date day;
  @override
  final int xp;

  factory _$XpSeriesPoint([void Function(XpSeriesPointBuilder)? updates]) =>
      (XpSeriesPointBuilder()..update(updates))._build();

  _$XpSeriesPoint._({required this.day, required this.xp}) : super._();
  @override
  XpSeriesPoint rebuild(void Function(XpSeriesPointBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  XpSeriesPointBuilder toBuilder() => XpSeriesPointBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is XpSeriesPoint && day == other.day && xp == other.xp;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, day.hashCode);
    _$hash = $jc(_$hash, xp.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'XpSeriesPoint')
          ..add('day', day)
          ..add('xp', xp))
        .toString();
  }
}

class XpSeriesPointBuilder
    implements Builder<XpSeriesPoint, XpSeriesPointBuilder> {
  _$XpSeriesPoint? _$v;

  Date? _day;
  Date? get day => _$this._day;
  set day(Date? day) => _$this._day = day;

  int? _xp;
  int? get xp => _$this._xp;
  set xp(int? xp) => _$this._xp = xp;

  XpSeriesPointBuilder() {
    XpSeriesPoint._defaults(this);
  }

  XpSeriesPointBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _day = $v.day;
      _xp = $v.xp;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(XpSeriesPoint other) {
    _$v = other as _$XpSeriesPoint;
  }

  @override
  void update(void Function(XpSeriesPointBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  XpSeriesPoint build() => _build();

  _$XpSeriesPoint _build() {
    final _$result = _$v ??
        _$XpSeriesPoint._(
          day: BuiltValueNullFieldError.checkNotNull(
              day, r'XpSeriesPoint', 'day'),
          xp: BuiltValueNullFieldError.checkNotNull(xp, r'XpSeriesPoint', 'xp'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
