import 'dart:async';

import 'package:libra_sheet/data/account.dart';
import 'package:libra_sheet/data/database/database_setup.dart';
import 'package:sqflite/sqlite_api.dart';

/// SQL commands related to the "accounts" table.

const accountsTable = '`accounts`';

FutureOr<int> insertAccount(Account acc) async {
  if (database == null) return 0;
  return database!.insert(
    accountsTable,
    acc.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<void> updateAccount(Account acc) async {
  await database?.update(
    accountsTable,
    acc.toMap(),
    where: '`key` = ?',
    whereArgs: [acc.key],
  );
}
