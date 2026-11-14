// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_statistics_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ProgressStatisticsResponse extends ProgressStatisticsResponse {
  @override
  final int activeDays;
  @override
  final int memoriesProtected;
  @override
  final int memoriesRepaired;
  @override
  final int missionsCompleted;
  @override
  final Date periodEnd;
  @override
  final Date periodStart;
  @override
  final String summary;
  @override
  final String timezone;
  @override
  final int xpEarned;
  @override
  final BuiltList<XpSeriesPoint> xpSeries;

  factory _$ProgressStatisticsResponse(
          [void Function(ProgressStatisticsResponseBuilder)? updates]) =>
      (ProgressStatisticsResponseBuilder()..update(updates))._build();

  _$ProgressStatisticsResponse._(
      {required this.activeDays,
      required this.memoriesProtected,
      required this.memoriesRepaired,
      required this.missionsCompleted,
      required this.periodEnd,
      required this.periodStart,
      required this.summary,
      required this.timezone,
      required this.xpEarned,
      required this.xpSeries})
      : super._();
  @override
  ProgressStatisticsResponse rebuild(
          void Function(ProgressStatisticsResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ProgressStatisticsResponseBuilder toBuilder() =>
      ProgressStatisticsResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ProgressStatisticsResponse &&
        activeDays == other.activeDays &&
        memoriesProtected == other.memoriesProtected &&
        memoriesRepaired == other.memoriesRepaired &&
        missionsCompleted == other.missionsCompleted &&
        periodEnd == other.periodEnd &&
        periodStart == other.periodStart &&
        summary == other.summary &&
        timezone == other.timezone &&
        xpEarned == other.xpEarned &&
        xpSeries == other.xpSeries;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, activeDays.hashCode);
    _$hash = $jc(_$hash, memoriesProtected.hashCode);
    _$hash = $jc(_$hash, memoriesRepaired.hashCode);
    _$hash = $jc(_$hash, missionsCompleted.hashCode);
    _$hash = $jc(_$hash, periodEnd.hashCode);
    _$hash = $jc(_$hash, periodStart.hashCode);
    _$hash = $jc(_$hash, summary.hashCode);
    _$hash = $jc(_$hash, timezone.hashCode);
    _$hash = $jc(_$hash, xpEarned.hashCode);
    _$hash = $jc(_$hash, xpSeries.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ProgressStatisticsResponse')
          ..add('activeDays', activeDays)
          ..add('memoriesProtected', memoriesProtected)
          ..add('memoriesRepaired', memoriesRepaired)
          ..add('missionsCompleted', missionsCompleted)
          ..add('periodEnd', periodEnd)
          ..add('periodStart', periodStart)
          ..add('summary', summary)
          ..add('timezone', timezone)
          ..add('xpEarned', xpEarned)
          ..add('xpSeries', xpSeries))
        .toString();
  }
}

class ProgressStatisticsResponseBuilder
    implements
        Builder<ProgressStatisticsResponse, ProgressStatisticsResponseBuilder> {
  _$ProgressStatisticsResponse? _$v;

  int? _activeDays;
  int? get activeDays => _$this._activeDays;
  set activeDays(int? activeDays) => _$this._activeDays = activeDays;

  int? _memoriesProtected;
  int? get memoriesProtected => _$this._memoriesProtected;
  set memoriesProtected(int? memoriesProtected) =>
      _$this._memoriesProtected = memoriesProtected;

  int? _memoriesRepaired;
  int? get memoriesRepaired => _$this._memoriesRepaired;
  set memoriesRepaired(int? memoriesRepaired) =>
      _$this._memoriesRepaired = memoriesRepaired;

  int? _missionsCompleted;
  int? get missionsCompleted => _$this._missionsCompleted;
  set missionsCompleted(int? missionsCompleted) =>
      _$this._missionsCompleted = missionsCompleted;

  Date? _periodEnd;
  Date? get periodEnd => _$this._periodEnd;
  set periodEnd(Date? periodEnd) => _$this._periodEnd = periodEnd;

  Date? _periodStart;
  Date? get periodStart => _$this._periodStart;
  set periodStart(Date? periodStart) => _$this._periodStart = periodStart;

  String? _summary;
  String? get summary => _$this._summary;
  set summary(String? summary) => _$this._summary = summary;

  String? _timezone;
  String? get timezone => _$this._timezone;
  set timezone(String? timezone) => _$this._timezone = timezone;

  int? _xpEarned;
  int? get xpEarned => _$this._xpEarned;
  set xpEarned(int? xpEarned) => _$this._xpEarned = xpEarned;

  ListBuilder<XpSeriesPoint>? _xpSeries;
  ListBuilder<XpSeriesPoint> get xpSeries =>
      _$this._xpSeries ??= ListBuilder<XpSeriesPoint>();
  set xpSeries(ListBuilder<XpSeriesPoint>? xpSeries) =>
      _$this._xpSeries = xpSeries;

  ProgressStatisticsResponseBuilder() {
    ProgressStatisticsResponse._defaults(this);
  }

  ProgressStatisticsResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _activeDays = $v.activeDays;
      _memoriesProtected = $v.memoriesProtected;
      _memoriesRepaired = $v.memoriesRepaired;
      _missionsCompleted = $v.missionsCompleted;
      _periodEnd = $v.periodEnd;
      _periodStart = $v.periodStart;
      _summary = $v.summary;
      _timezone = $v.timezone;
      _xpEarned = $v.xpEarned;
      _xpSeries = $v.xpSeries.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ProgressStatisticsResponse other) {
    _$v = other as _$ProgressStatisticsResponse;
  }

  @override
  void update(void Function(ProgressStatisticsResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ProgressStatisticsResponse build() => _build();

  _$ProgressStatisticsResponse _build() {
    _$ProgressStatisticsResponse _$result;
    try {
      _$result = _$v ??
          _$ProgressStatisticsResponse._(
            activeDays: BuiltValueNullFieldError.checkNotNull(
                activeDays, r'ProgressStatisticsResponse', 'activeDays'),
            memoriesProtected: BuiltValueNullFieldError.checkNotNull(
                memoriesProtected,
                r'ProgressStatisticsResponse',
                'memoriesProtected'),
            memoriesRepaired: BuiltValueNullFieldError.checkNotNull(
                memoriesRepaired,
                r'ProgressStatisticsResponse',
                'memoriesRepaired'),
            missionsCompleted: BuiltValueNullFieldError.checkNotNull(
                missionsCompleted,
                r'ProgressStatisticsResponse',
                'missionsCompleted'),
            periodEnd: BuiltValueNullFieldError.checkNotNull(
                periodEnd, r'ProgressStatisticsResponse', 'periodEnd'),
            periodStart: BuiltValueNullFieldError.checkNotNull(
                periodStart, r'ProgressStatisticsResponse', 'periodStart'),
            summary: BuiltValueNullFieldError.checkNotNull(
                summary, r'ProgressStatisticsResponse', 'summary'),
            timezone: BuiltValueNullFieldError.checkNotNull(
                timezone, r'ProgressStatisticsResponse', 'timezone'),
            xpEarned: BuiltValueNullFieldError.checkNotNull(
                xpEarned, r'ProgressStatisticsResponse', 'xpEarned'),
            xpSeries: xpSeries.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'xpSeries';
        xpSeries.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'ProgressStatisticsResponse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
