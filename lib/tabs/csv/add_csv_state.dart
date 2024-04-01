import 'dart:math';

import 'package:csv/csv_settings_autodetection.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/enums.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/objects/category_rule.dart';
import 'package:libra_sheet/data/objects/transaction.dart';
import 'package:libra_sheet/tabs/csv/auto_identify_csv.dart';

import 'csv_field.dart';

class AddCsvState extends ChangeNotifier {
  final LibraAppState appState;
  AddCsvState({required this.appState, this.account});

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

  /// This list is parallel to [rawLines], i.e. the rows of the CSV, and is used to
  /// highlight correctly parsed rows.
  List<bool> rowOk = [];

  /// List of transactions in the preview screen. This list is populated after
  /// any field is edited and [_validate] is called, and is displayed in the
  /// [PreviewTransactionsScreen] where the transactions can be further edited.
  /// These are not committed to the database until another confirmation.
  List<Transaction> transactions = [];

  bool previewScreen = false;

  /// Selected transaction index in the [PreviewTransactionsScreen]. We keep the
  ///  index to easily delete transactions.
  int focusedTransIndex = -1;

  void reset() {
    account = null;
    dateFormat = null;
    errorMsg = '';
    file = null;
    rawLines = [];
    nCols = 0;
    columnTypes = [];
    rowOk = [];
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
      csvSettingsDetector: FirstOccurrenceSettingsDetector(eols: ['\r\n', '\n']),
    );
    rawLines = converter.convert(input);
    nCols = rawLines.fold(0, (m, it) => max(m, it.length));

    rowOk = List.filled(rawLines.length, false);
    columnTypes = List.filled(nCols, CsvNone());
    errorMsg = '';
    notifyListeners();

    if (!_setHeadersFromAccountCsvFormat()) {
      _autoIdentifyCsv();
    }
  }

  void _autoIdentifyCsv() {
    final fields = autoIdentifyCsv(rawLines, nCols);
    if (fields != null) {
      assert(fields.length == nCols);
      columnTypes = fields;
      _validate();
    }
  }

  //---------------------------------------------------------------------------
  // Setter Callbacks
  //---------------------------------------------------------------------------
  bool _setHeadersFromAccountCsvFormat() {
    if (account?.csvFormat.isNotEmpty != true) return false;
    final fields = account!.csvFormat.split(',');
    if (fields.length != nCols) return false;

    final types = <CsvField>[];
    for (final name in fields) {
      final type = CsvField.fromName(name);
      types.add(type);
    }

    for (int column = 0; column < nCols; column++) {
      if (columnTypes[column] is CsvNone) {
        columnTypes[column] = types[column];
      }
    }
    notifyListeners();
    _validate();
    return true;
  }

  void setAccount(Account? acc) {
    account = acc;
    _setHeadersFromAccountCsvFormat();
    notifyListeners();
    _validate();
  }

  void setColumn(int column, CsvField type) {
    if (column >= columnTypes.length) return;
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
    transactions.clear();
    if (!_validateFields()) {
      rowOk = List.filled(rawLines.length, false);
      notifyListeners();
    } else {
      _createTransactions();
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
        case CsvDate():
          nDate++;
        case CsvAmount():
          nValue++;
        case CsvNegAmount():
          nValue++;
        case CsvName():
          nName++;
        default:
      }
    }
    if (nDate != 1) {
      errorMsg = 'Must have exactly one "Date" column';
      return false;
    }
    if (nValue == 0) {
      errorMsg = 'Must have at least one "Amount" or "Negative Amount" column';
      return false;
    }
    if (nName == 0) {
      errorMsg = 'Must have at least one "Name" column';
      return false;
    }

    errorMsg = '';
    return true;
  }

  /// Returns true if this cell is parseable, false if there is an error, or null if there is
  /// nothing to parse.
  bool? tryParse(String text, int column) {
    final type = columnTypes[column];
    switch (type) {
      case CsvDate():
        return _parseDate(text) != null;
      case CsvAmount():
        return text.toIntDollar() != null;
      case CsvNegAmount():
        return text.toIntDollar() != null;
      case CsvMatch():
        return text.isEmpty || text == type.match;
      case CsvDebitCreditSwitch():
        return _parseDebit(text) != null;
      default:
        return null;
    }
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

  DateTime? _parseDate(String text) {
    if (dateFormat != null) {
      return dateFormat!.tryParse(text, true);
    } else {
      for (final format in _dateFormats) {
        final dt = format.tryParseStrict(text, true);
        if (dt != null) return dt;
      }
      final dt = DateFormat('MMM dd, yy').tryParseLoose(text, true);
      return dt;
    }
  }

  /// Returns true if this is a debit (need to negate), false if this is a credit, and null on error.
  bool? _parseDebit(String text) {
    if (text.toLowerCase() == "debit") return true;
    if (text.toLowerCase() == "credit") return false;
    return null;
  }

  //---------------------------------------------------------------------------
  // Transactions
  //---------------------------------------------------------------------------
  void _createTransactions() {
    transactions.clear();
    for (int row = 0; row < rowOk.length; row++) {
      String name = '';
      String note = '';
      DateTime? date;
      int? value;
      bool negateValue = false;
      bool ok = true;

      for (int col = 0; col < columnTypes.length; col++) {
        if (col >= rawLines[row].length) continue;
        var text = rawLines[row][col];
        switch (columnTypes[col]) {
          case CsvDate():
            date = _parseDate(text);
          case CsvAmount():
            int? val = text.toIntDollar();
            if (val == null) continue;
            value = (value == null) ? val : value + val;
          case CsvNegAmount():
            int? val = text.toIntDollar();
            if (val == null) continue;
            value = (value == null) ? -val : value - val;
          case CsvName():
            if (name.isNotEmpty) {
              name += ' $text';
            } else {
              name = text;
            }
          case CsvNote():
            if (note.isNotEmpty) {
              note += ' $text';
            } else {
              note = text;
            }
          case CsvDebitCreditSwitch():
            final res = _parseDebit(text);
            if (res == true) {
              negateValue = true;
            } else if (res == null) {
              ok = false;
            }
          case CsvMatch():
            if (tryParse(text, col) == false) ok = false;
          case CsvNone():
        }
      }

      if (date == null || value == null || !ok) {
        rowOk[row] = false;
        continue;
      }
      if (negateValue) value = -value;
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
      rowOk[row] = true;
    }
    if (transactions.isEmpty) {
      errorMsg = 'No valid rows (check your fields are set correctly)';
    } else {
      errorMsg = '';
    }
    notifyListeners();
  }

  void previewTransactions() {
    previewScreen = true;
    notifyListeners();
    var csvFormat = columnTypes.map((e) => e.saveName).join(',');
    if (csvFormat != account!.csvFormat) {
      account!.csvFormat = csvFormat;
      appState.accounts.notifyUpdate(account!);
    }
  }

  void cancelPreviewTransactions() {
    _createTransactions(); // recreate to reset
    previewScreen = false;
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

  /// Called when a preview transaction is saved with a new rule. This will set
  /// all matching uncategorized transactions to this category.
  void reprocessRule(CategoryRule rule) {
    for (final t in transactions) {
      if (t.category.isUncategorized &&
          ExpenseType.from(t.value) == rule.type &&
          t.name.contains(rule.pattern)) {
        t.category = rule.category ?? Category.empty;
        // We can edit the transactions in place here because they are uniquely in memory in the CSV state
      }
    }
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
    appState.transactions.addAll(transactions);
  }
}
