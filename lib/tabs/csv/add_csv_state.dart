import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

class AddCsvState extends ChangeNotifier {
  XFile? file;

  void selectFile() async {
    const XTypeGroup typeGroup = XTypeGroup(
      label: 'CSV Files',
      extensions: <String>['csv'],
    );
    file = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
    if (file == null) return;
  }
}
