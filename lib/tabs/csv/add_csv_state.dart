import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/data/date_time_utils.dart';

enum CsvField {
  date('Date'),
  name('Name'),
  value('Value'),
  note('Note'),
  none('None');

  const CsvField(this.title);

  final String title;
}

final List<DateFormat> _dateFormats = [
  DateFormat('MM/dd/yyyy'),
];

class AddCsvState extends ChangeNotifier {
  Account? account;
  DateFormat? dateFormat;

  XFile? file;
  List<List<String>> rawLines = [];
  int nCols = 0;
  List<CsvField> columnTypes = [];

  void selectFile() async {
    const XTypeGroup typeGroup = XTypeGroup(
      label: 'CSV Files',
      extensions: <String>['csv'],
    );
    file = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
    if (file == null) return;
    debugPrint("AddCsvState::selectFile() opened file ${file!.path}");
    notifyListeners();
    await _processFile();
  }

  Future<void> _processFile() async {
    if (file == null) return;
    final input = await file!.readAsString();
    const converter = CsvToListConverter(
      shouldParseNumbers: false,
    );
    rawLines = converter.convert(input);
    nCols = rawLines.firstOrNull?.length ?? 0;
    columnTypes = List.filled(nCols, CsvField.none);
    notifyListeners();
  }

  void setAccount(Account? acc) {
    account = acc;
    notifyListeners();
  }

  void setColumn(int column, CsvField? type) {
    if (type == null || column >= columnTypes.length) return;
    columnTypes[column] = type;
    notifyListeners();
  }

  void setDateFormat(String? text) {
    if (text == null || text.isEmpty) {
      dateFormat = null;
    } else {
      dateFormat = DateFormat(text);
    }
    // TODO reparse date column
  }

  bool? tryParse(String text, int column) {
    switch (columnTypes[column]) {
      case CsvField.date:
        return _parseDate(text) != null;
      case CsvField.value:
        return double.tryParse(text) != null;
      default:
        return null;
    }
  }

  DateTime? _parseDate(String text) {
    if (dateFormat != null) {
      return dateFormat!.tryParse(text);
    } else {
      for (final format in _dateFormats) {
        final dt = format.tryParse(text);
        if (dt != null) return dt;
      }
      return null;
    }
  }
}
