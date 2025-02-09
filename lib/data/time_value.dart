import 'package:libra_sheet/data/date_time_utils.dart';
import 'package:libra_sheet/data/int_dollar.dart';

class TimeIntValue {
  final DateTime time;
  final int value;

  const TimeIntValue({required this.time, required this.value});

  TimeIntValue copyWith({DateTime? time, int? value}) => TimeIntValue(
        time: time ?? this.time,
        value: value ?? this.value,
      );

  TimeIntValue withTime(DateTime Function(DateTime it) newTime) =>
      TimeIntValue(time: newTime(time), value: value);
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
  /// If [this] is missing a value, it will add an entry with value 0.
  ///
  /// If [cumulate], the returned values are replaced with the cumulative sum starting from the
  /// beginning.
  ///
  /// This function assumes [this] and [times] are sorted by time value already!
  ///
  /// [trimStart] will ignore leading 0's in the output array.
  List<TimeIntValue> withAlignedTimes(
    List<DateTime> times, {
    bool cumulate = false,
    bool trimStart = false,
  }) {
    List<TimeIntValue> out = [];
    int iOrig = 0;
    int iTime = 0;
    bool isLeadingZero = true;

    int cumValue() => cumulate ? (out.lastOrNull?.value ?? 0) : 0;

    void addValue(DateTime time, int value) {
      if (value != 0) {
        isLeadingZero = false;
        out.add(TimeIntValue(time: time, value: value));
      } else if (!trimStart || !isLeadingZero) {
        out.add(TimeIntValue(time: time, value: value));
      }
    }

    while (iOrig < length && iTime < times.length) {
      final orig = this[iOrig];
      final time = times[iTime];
      if (orig.time.isAtSameMomentAs(time)) {
        addValue(time, orig.value + cumValue());
        iOrig++;
        iTime++;
      } else if (orig.time.isBefore(time)) {
        /// Skip this entry, was not part of [times]
        iOrig++;
      } else {
        /// Date from [times] missing in [this], add placeholder (cumulative) value
        addValue(time, cumValue());
        iTime++;
      }
    }

    /// Wrap up any other missing values from [times]
    while (iTime < times.length) {
      addValue(times[iTime], cumValue());
      iTime++;
    }

    return out;
  }

  /// See [withAlignedTimes], but only the values.
  List<int> alignValues(
    List<DateTime> times, {
    bool cumulate = false,
    bool trimStart = false,
  }) {
    final vals = withAlignedTimes(times, cumulate: cumulate, trimStart: trimStart);
    return [
      for (final val in vals) val.value,
    ];
  }

  /// Assuming [this] uses UTC dates, replaces the times with local timezone dates. This is needed
  /// for Syncfusion datetime charts since they assume dates are in the local timezone.
  List<TimeIntValue> fixedForSyncfusion({bool absValues = false}) {
    return [
      for (final tv in this)
        TimeIntValue(
          time: tv.time.asLocalDate(),
          value: (absValues) ? tv.value.abs() : tv.value,
        ),
    ];
  }

  int sum() {
    var total = 0;
    for (final x in this) {
      total += x.value;
    }
    return total;
  }

  double dollarAverage() {
    return sum().asDollarDouble() / length;
  }
}

extension ListUtils<T> on List<T> {
  List<T> looseRange((int, int)? range) {
    if (range == null) return this;
    return looseSublist(range.$1, range.$2);
  }

  /// Like [List.sublist] but will never throw an exception, instead clamping [start] and [end] to
  /// their limiting values.
  List<T> looseSublist(int start, [int? end]) {
    if (start < 0) start = 0;
    if (start > length) start = length;
    end ??= length;
    if (end < start) end = start;
    if (end > length) end = length;
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

  List<int> invert() {
    final out = <int>[];
    for (var x in this) {
      out.add(-x);
    }
    return out;
  }

  int max({bool abs = false}) {
    if (isEmpty) return 0;
    var current = abs ? first.abs() : first;
    for (int i = 1; i < length; i++) {
      final next = abs ? this[i].abs() : this[i];
      if (next > current) current = next;
    }
    return current;
  }

  bool hasNegative() {
    for (final x in this) {
      if (x < 0) return true;
    }
    return false;
  }

  bool hasPositive() {
    for (final x in this) {
      if (x > 0) return true;
    }
    return false;
  }
}
