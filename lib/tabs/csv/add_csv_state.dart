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
  String errorMsg = '';

  XFile? file;
  List<List<String>> rawLines = [];
  int nCols = 0;
  List<CsvField> columnTypes = [];

  List<bool> rowOk = [];
  int nRowsOk = 0;

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
    _validate();
  }

  Future<void> _processFile() async {
    if (file == null) return;
    final input = await file!.readAsString();
    const converter = CsvToListConverter(
      shouldParseNumbers: false,
    );
    rawLines = converter.convert(input);
    rowOk = List.filled(rawLines.length, false);
    nRowsOk = 0;
    nCols = rawLines.firstOrNull?.length ?? 0;
    columnTypes = List.filled(nCols, CsvField.none);
    errorMsg = '';
    notifyListeners();
  }

  void setAccount(Account? acc) {
    account = acc;
    notifyListeners();
    _validate();
  }

  void setColumn(int column, CsvField? type) {
    if (type == null || column >= columnTypes.length) return;
    columnTypes[column] = type;
    notifyListeners();
    _validate();
  }

  void setDateFormat(String? text) {
    if (text == null || text.isEmpty) {
      dateFormat = null;
    } else {
      dateFormat = DateFormat(text);
    }
    _validate();
  }

  void _validate() {
    if (!_validateFields()) {
      notifyListeners();
    } else {
      _validateRows();
    }
  }

  bool _validateFields() {
    /// Account ///
    if (account == null) {
      errorMsg = "Please set an account";
      return false;
    }

    /// Column check ///
    int nDate = 0;
    int nValue = 0;
    int nName = 0;
    for (final type in columnTypes) {
      switch (type) {
        case CsvField.date:
          nDate++;
        case CsvField.value:
          nValue++;
        case CsvField.name:
          nName++;
        default:
      }
    }
    if (nDate != 1) {
      errorMsg = "Must have exactly one date column";
      return false;
    }
    if (nValue != 1) {
      errorMsg = "Must have exactly one value column";
      return false;
    }
    if (nName == 0) {
      errorMsg = "Must have at least one name column";
      return false;
    }

    errorMsg = '';
    return true;
  }

  void _validateRows() async {
    nRowsOk = 0;
    for (int row = 0; row < rowOk.length; row++) {
      bool ok = true;
      for (int col = 0; col < columnTypes.length; col++) {
        if (tryParse(rawLines[row][col], col) == false) {
          ok = false;
          break;
        }
      }
      rowOk[row] = ok;
      if (ok) nRowsOk++;
    }
    notifyListeners();
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
