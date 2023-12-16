import 'package:intl/intl.dart';

extension DateTimeUtils on DateFormat {
  DateTime? tryParse(String? text, {bool strict = false}) {
    if (text == null || text.isEmpty) return null;
    try {
      return (strict) ? parseStrict(text, true) : parse(text, true);
    } on FormatException {
      return null;
    }
  }
}

final _dateFormat = DateFormat('M/d/yy');

extension DateTimeUtils2 on DateTime {
  DateTime asLocalDate() {
    return DateTime(year, month, day);
  }

  // ignore: non_constant_identifier_names
  String MMddyy() {
    return _dateFormat.format(this);
  }
}

DateTime startOfMonth(DateTime x) {
  return DateTime.utc(x.year, x.month, 1);
}
