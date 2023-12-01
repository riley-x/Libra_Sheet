import 'package:intl/intl.dart';

extension DateTimeUtils on DateFormat {
  DateTime? tryParse(String? text) {
    if (text == null || text.isEmpty) return null;
    try {
      return parse(text, true);
    } on FormatException {
      return null;
    }
  }
}

extension DateTimeUtils2 on DateTime {
  DateTime asLocalDate() {
    return DateTime(year, month, day);
  }
}

DateTime startOfMonth(DateTime x) {
  return DateTime.utc(x.year, x.month, 1);
}
