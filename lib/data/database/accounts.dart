import 'dart:async';

import 'package:libra_sheet/data/account.dart';
import 'package:libra_sheet/data/database/database_setup.dart';
import 'package:sqflite/sqlite_api.dart';

/// SQL commands related to the "accounts" table.

const accountsTable = '`accounts`';

FutureOr<int> insertAccount(Account acc, {int? listIndex}) async {
  if (database == null) return 0;
  return database!.insert(
    accountsTable,
    acc.toMap(listIndex: listIndex),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<void> updateAccount(Account acc, {int? listIndex}) async {
  await database?.update(
    accountsTable,
    acc.toMap(listIndex: listIndex),
    where: '`key` = ?',
    whereArgs: [acc.key],
  );
}
