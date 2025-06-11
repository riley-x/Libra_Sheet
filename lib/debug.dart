import 'package:flutter/material.dart' show debugPrint, BuildContext;
import 'package:libra_sheet/components/dialogs/confirmation_dialog.dart';
import 'package:libra_sheet/data/database/libra_database.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart' show databaseFactoryFfiWeb;

Future<void> debugManualMethod(BuildContext context) async {
  final bytes = await databaseFactoryFfiWeb.readDatabaseBytes(LibraDatabase.databasePath);
  if (!context.mounted) return;
  showConfirmationDialog(context: context, msg: "${bytes.length}");
  debugPrint("$bytes");
}
