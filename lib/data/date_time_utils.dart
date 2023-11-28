import 'package:intl/intl.dart';

extension DateTimeUtils on DateFormat {
  DateTime? tryParse(String? text) {
    if (text == null || text.isEmpty) return null;
    try {
      return parse(text);
    } on FormatException {
      return null;
    }
  }
}
