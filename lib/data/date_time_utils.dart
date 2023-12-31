import 'package:intl/intl.dart';

final _dateFormat = DateFormat('M/d/yy');

extension DateTimeUtils2 on DateTime {
  DateTime asLocalDate() {
    return DateTime(year, month, day);
  }

  // ignore: non_constant_identifier_names
  String MMddyy() {
    return _dateFormat.format(this);
  }

  DateTime monthEnd() {
    return DateTime.utc(year, month + 1, 0);
  }

  DateTime nextMonthStart() {
    return DateTime.utc(year, month + 1, 1);
  }

  /// Returns [this] - [other] in months.
  int monthDiff(DateTime other) {
    return 12 * (year - other.year) + (month - other.month);
  }
}

DateTime startOfMonth(DateTime x) {
  return DateTime.utc(x.year, x.month, 1);
}

DateTime min(DateTime x, DateTime y) {
  if (x.compareTo(y) <= 0) return x;
  return y;
}

(DateTime, DateTime) order(DateTime x, DateTime y) {
  if (x.compareTo(y) <= 0) return (x, y);
  return (y, x);
}
