import 'package:libra_sheet/data/account.dart';
import 'package:libra_sheet/data/database/database_setup.dart';
import 'package:sqflite/sqlite_api.dart';

/// SQL commands related to the "accounts" table.

const accountsTable = '`accounts`';

Future<void> insertAccount(Account acc) async {
  await database?.insert(
    accountsTable,
    acc.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}
