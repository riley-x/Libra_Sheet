import 'dart:async';
import 'dart:ui';

import 'package:libra_sheet/data/account.dart';
import 'package:libra_sheet/data/database/database_setup.dart';
import 'package:libra_sheet/data/time_value.dart';
import 'package:sqflite/sqlite_api.dart';

const accountsTable = '`accounts`';

const createAccountsTableSql = "CREATE TABLE IF NOT EXISTS `accounts` ("
    "`key` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "
    "`name` TEXT NOT NULL, "
    "`description` TEXT NOT NULL, "
    "`type` TEXT NOT NULL, "
    "`csvPattern` TEXT NOT NULL DEFAULT '', "
    "`screenReaderAlias` TEXT NOT NULL DEFAULT '', "
    "`colorLong` INTEGER NOT NULL, "
    "`listIndex` INTEGER NOT NULL, "
    "`balance` INTEGER NOT NULL)";

FutureOr<int> insertAccount(Account acc, {int? listIndex}) async {
  if (libraDatabase == null) return 0;
  return libraDatabase!.insert(
    accountsTable,
    acc.toMap(listIndex: listIndex),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<void> updateAccount(Account acc, {int? listIndex}) async {
  await libraDatabase?.update(
    accountsTable,
    acc.toMap(listIndex: listIndex),
    where: '`key` = ?',
    whereArgs: [acc.key],
  );
}

Future<List<Account>> getAccounts() async {
  final List<Map<String, dynamic>> maps = await libraDatabase!.query(
    accountsTable,
    orderBy: "listIndex",
  );
  return List.generate(
    maps.length,
    (i) => Account(
      type: AccountType.fromString(maps[i]['type']),
      key: maps[i]['key'],
      name: maps[i]['name'],
      balance: maps[i]['balance'],
      description: maps[i]['description'],
      color: Color(maps[i]['colorLong']),
      csvFormat: maps[i]['csvPattern'],
    ),
  );
}
