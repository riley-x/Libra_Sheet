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

  // ignore: non_constant_identifier_names
  String MMMyy() {
    return DateFormat('MMMyy').format(this);
  }

  // ignore: non_constant_identifier_names
  String MMMMyyyy() {
    return DateFormat('MMMM yyyy').format(this);
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

DateTime? fromTimestamp(int? x) {
  if (x == null) return null;
  return DateTime.fromMillisecondsSinceEpoch(x, isUtc: true);
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

bool differentMonth(DateTime x, DateTime y) {
  return x.month != y.month || x.year != y.year;
}

final List<DateFormat> _dateFormats = [
  /// Make sure the MM/ are before the yyyy/ because the latter WILL parse 12 as year 0012. But
  /// the former will fail because we use parseStrict. Also, make sure the intl package is 0.19.0
  /// or above due to this bug https://github.com/dart-lang/i18n/issues/483 with yy parsing.
  DateFormat('MM/dd/yy'),
  DateFormat('MM-dd-yy'),
  DateFormat('yyyy/MM/dd'),
  DateFormat('yyyy-MM-dd'),
  DateFormat("yyyy-MM-ddTHH:mm:ss"),
  DateFormat(),
];

extension DateTimeStringExtension on String {
  DateTime? parseDate({bool utc = true}) {
    for (final format in _dateFormats) {
      final dt = format.tryParseStrict(this, utc);
      if (dt != null) return dt;
    }
    final dt = DateFormat('MMM dd, yy').tryParseLoose(this, utc);
    return dt;
  }
}
