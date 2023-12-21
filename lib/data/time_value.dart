import 'package:libra_sheet/data/date_time_utils.dart';

class TimeIntValue {
  final DateTime time;
  final int value;

  const TimeIntValue({required this.time, required this.value});
}

class TimeValue {
  final DateTime time;
  final double value;

  const TimeValue({required this.time, required this.value});

  factory TimeValue.monthStart(int year, int month, double value) {
    return TimeValue(time: DateTime(year, month, 1), value: value);
  }

  factory TimeValue.monthEnd(int year, int month, double value) {
    return TimeValue(time: DateTime(year, month + 1, 0), value: value);
  }
}

/// Assumes [x] and [y] have the same time entries, and adds their values together
List<TimeIntValue> addParallel(
  List<TimeIntValue> x,
  List<TimeIntValue> y,
) {
  return List.generate(
    x.length,
    (i) => TimeIntValue(
      time: x[i].time,
      value: x[i].value + y[i].value,
    ),
  );
}

extension TimeValueList on List<TimeIntValue> {
  /// Returns a list based on [this] but with padded entries so that they align with [times].
  /// If [this] is missing a value, it will add an entry with value 0 or a cumulative value if
  /// [cumulate]. This function assumes [this] and [times] are sorted by time value already!
  List<int> alignValues(List<DateTime> times, {bool cumulate = false}) {
    List<int> out = [];
    int iOrig = 0;
    int iTime = 0;

    int cumValue() => cumulate ? (out.lastOrNull ?? 0) : 0;

    while (iOrig < length && iTime < times.length) {
      final orig = this[iOrig];
      final time = times[iTime];
      if (orig.time.isAtSameMomentAs(time)) {
        out.add(orig.value + cumValue());
        iOrig++;
        iTime++;
      } else if (orig.time.isBefore(time)) {
        /// Skip this entry, was not part of [times]
        iOrig++;
      } else {
        /// Date from [times] missing in [this], add placeholder (cumulative) value
        out.add(cumValue());
        iTime++;
      }
    }

    /// Wrap up any other missing values from [times]
    while (iTime < times.length) {
      out.add(cumValue());
      iTime++;
    }

    return out;
  }

  /// Returns a list based on [this] but with padded entries so that they align with [times].
  /// If [this] is missing a value, it will add an entry with value 0 or a cumulative value if
  /// [cumulate]. This function assumes [this] and [times] are sorted by time value already!
  List<TimeIntValue> withAlignedTimes(List<DateTime> times, {bool cumulate = false}) {
    final vals = alignValues(times, cumulate: cumulate);
    return [
      for (int i = 0; i < vals.length; i++) TimeIntValue(time: times[i], value: vals[i]),
    ];
  }

  /// Assuming [this] uses UTC dates, replaces the times with local timezone dates. This is needed
  /// for Syncfusion datetime charts since they assume dates are in the local timezone.
  List<TimeIntValue> fixedForCharts({bool absValues = false}) {
    return [
      for (final tv in this)
        TimeIntValue(
          time: tv.time.asLocalDate(),
          value: (absValues) ? tv.value.abs() : tv.value,
        ),
    ];
  }
}

extension ListUtils<T> on List<T> {
  List<T> looseRange((int, int)? range) {
    if (range == null) return this;
    return looseSublist(range.$1, range.$2);
  }

  List<T> looseSublist(int start, [int? end]) {
    if (start < 0) start = 0;
    if (end != null && end > length) end = null;
    return sublist(start, end);
  }
}

extension IntListUtils on List<int> {
  void addElementwise(List<int> other) {
    assert(length == other.length);
    for (int i = 0; i < length; i++) {
      this[i] += other[i];
    }
  }
}
