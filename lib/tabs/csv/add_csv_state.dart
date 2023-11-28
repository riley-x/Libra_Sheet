import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:libra_sheet/data/objects/account.dart';

enum CsvField { date, name, value, note, none }

class AddCsvState extends ChangeNotifier {
  Account? account;

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
}
