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
}

DateTime startOfMonth(DateTime x) {
  return DateTime.utc(x.year, x.month, 1);
}
