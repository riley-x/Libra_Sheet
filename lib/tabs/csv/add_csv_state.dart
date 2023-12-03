import 'dart:math';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/enums.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/data/date_time_utils.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/objects/transaction.dart';

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
  final LibraAppState appState;
  AddCsvState(this.appState);

  //---------------------------------------------------------------------------
  // Fields
  //---------------------------------------------------------------------------
  Account? account;
  DateFormat? dateFormat;
  String errorMsg = '';

  XFile? file;
  List<List<String>> rawLines = [];
  int nCols = 0;
  List<CsvField> columnTypes = [];

  List<bool> rowOk = [];
  int nRowsOk = 0;

  List<Transaction> transactions = [];
  int focusedTransIndex = -1;

  // TODO may want to elevate the CSV state so that it doesn't get lost when switching tabs. But
  // need to be really careful, since if you i.e. delete a category, the links in the csv state
  // won't be invalidated...
  void reset() {
    account = null;
    dateFormat = null;
    errorMsg = '';
    file = null;
    rawLines = [];
    nCols = 0;
    columnTypes = [];
    rowOk = [];
    nRowsOk = 0;
    transactions = [];
    focusedTransIndex = -1;
  }

  //---------------------------------------------------------------------------
  // File Processing
  //---------------------------------------------------------------------------
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
    nCols = rawLines.fold(0, (m, it) => max(m, it.length));

    rowOk = List.filled(rawLines.length, false);
    nRowsOk = 0;
    columnTypes = List.filled(nCols, CsvField.none);
    errorMsg = '';
    notifyListeners();
  }

  //---------------------------------------------------------------------------
  // Setter Callbacks
  //---------------------------------------------------------------------------
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

  //---------------------------------------------------------------------------
  // Validating
  //---------------------------------------------------------------------------
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
        return text.toIntDollar() != null;
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

  //---------------------------------------------------------------------------
  // Transactions
  //---------------------------------------------------------------------------
  void createTransactions() {
    transactions.clear();
    for (int row = 0; row < rowOk.length; row++) {
      if (!rowOk[row]) continue;

      String name = '';
      String note = '';
      DateTime? date;
      int? value;

      for (int col = 0; col < columnTypes.length; col++) {
        if (col >= rawLines[row].length) continue;
        final text = rawLines[row][col];
        switch (columnTypes[col]) {
          case CsvField.date:
            date = _parseDate(text);
          case CsvField.value:
            value = text.toIntDollar();
          case CsvField.name:
            if (name.isNotEmpty) {
              name += ' $text';
            } else {
              name = text;
            }
          case CsvField.note:
            if (note.isNotEmpty) {
              note += ' $text';
            } else {
              note = text;
            }
          case CsvField.none:
        }
      }

      if (date == null || value == null) continue;
      final rule = appState.rules.match(
        name,
        (value < 0) ? ExpenseType.expense : ExpenseType.income,
      );
      Transaction t = Transaction(
        name: name,
        date: date,
        value: value,
        account: account,
        category: rule?.category ?? ((value > 0) ? Category.income : Category.expense),
        note: note,
      );
      transactions.add(t);
    }
    notifyListeners();
  }

  void clearTransactions() {
    transactions.clear();
    notifyListeners();
  }

  void focusTransaction(int i) {
    focusedTransIndex = i;
    notifyListeners();
  }

  void saveTransaction(Transaction? old, Transaction t) {
    transactions[focusedTransIndex] = t;
    focusedTransIndex = -1;
    notifyListeners();
  }

  void deleteTransaction() {
    transactions.removeAt(focusedTransIndex);
    focusedTransIndex = -1;
    notifyListeners();
  }

  //---------------------------------------------------------------------------
  // Saving
  //---------------------------------------------------------------------------
  void saveAll() {
    appState.popBackStack();
    appState.transactions.addAll(transactions);
    var csvFormat = columnTypes.map((e) => e.name).join(',');
    if (csvFormat != account!.csvFormat) {
      account!.csvFormat = csvFormat;
      appState.notifyUpdateAccount(account!);
    }
  }
}
