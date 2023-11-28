import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';

class AddCsvState extends ChangeNotifier {
  XFile? file;
  List<List<String>> rawLines = [];

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
    notifyListeners();
  }
}
