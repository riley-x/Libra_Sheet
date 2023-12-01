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

/// Returns a list based on [original] but with padded entries so that they align with [times].
/// If [original] is missing a value, it will add an entry with value 0 or a cumulative value if
/// [cumulate]. This function assumes [original] and [times] are sorted by time value already!
List<TimeIntValue> alignTimes(
  List<TimeIntValue> original,
  List<DateTime> times, {
  bool cumulate = false,
}) {
  List<TimeIntValue> out = [];
  int iOrig = 0;
  int iTime = 0;

  while (iOrig < original.length && iTime < times.length) {
    final orig = original[iOrig];
    final time = times[iTime];
    if (orig.time.isAtSameMomentAs(time)) {
      if (cumulate) {
        out.add(TimeIntValue(
          time: time,
          value: orig.value + (out.lastOrNull?.value ?? 0),
        ));
      } else {
        out.add(orig);
      }
      iOrig++;
      iTime++;
    } else if (orig.time.isBefore(time)) {
      // Skip this entry, was not part of [times]
      iOrig++;
    } else {
      // Pad with this current time value
      final val = (cumulate) ? out.lastOrNull?.value ?? 0 : 0;
      out.add(TimeIntValue(time: time, value: val));
      iTime++;
    }
  }

  while (iTime < times.length) {
    final val = (cumulate) ? out.lastOrNull?.value ?? 0 : 0;
    out.add(TimeIntValue(time: times[iTime], value: val));
    iTime++;
  }

  return out;
}

/// Assuming [original] uses UTC dates, replaces the times with local timezone dates. This is needed
/// for Syncfusion datetime charts since they assume dates are in the local timezone.
List<TimeIntValue> replaceWithLocalDates(List<TimeIntValue> original) {
  return [
    for (final tv in original) TimeIntValue(time: tv.time.asLocalDate(), value: tv.value),
  ];
}
