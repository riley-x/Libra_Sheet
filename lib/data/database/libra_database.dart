import 'dart:io';

import 'package:intl/intl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final _backupDateFormat = DateFormat('yyyy-MM-dd_HH-mm-ss');

class LibraDatabase {
  Database? db;

  static final LibraDatabase _instance = LibraDatabase._internal();

  factory LibraDatabase() {
    return _instance;
  }

  LibraDatabase._internal();

  Future<void> backupDatabase() async {
    if (db == null) return;
    File orig = File(db!.path);
    final timestamp = _backupDateFormat.format(DateTime.now());

    String origPath = db!.path;
    String newPath;
    if (origPath.endsWith('.db')) {
      newPath = "${origPath.substring(0, origPath.length - 3)}_$timestamp";
    } else {
      newPath = "${origPath}_$timestamp";
    }
    await orig.copy(newPath);
  }
}
