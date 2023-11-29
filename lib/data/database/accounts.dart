import 'dart:async';
import 'dart:ui';

import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/data/database/database_setup.dart';
import 'package:sqflite/sqlite_api.dart';

const accountsTable = '`accounts`';

const _key = "id";
const _balance = "balance";

const createAccountsTableSql = "CREATE TABLE IF NOT EXISTS `accounts` ("
    "$_key INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "
    "`name` TEXT NOT NULL, "
    "`description` TEXT NOT NULL, "
    "`type` TEXT NOT NULL, "
    "`csvPattern` TEXT NOT NULL DEFAULT '', "
    "`screenReaderAlias` TEXT NOT NULL DEFAULT '', "
    "`colorLong` INTEGER NOT NULL, "
    "`listIndex` INTEGER NOT NULL, "
    "$_balance INTEGER NOT NULL)";

Map<String, dynamic> _toMap(Account acc, {int? listIndex}) {
  final out = {
    'name': acc.name,
    'description': acc.description,
    'type': acc.type.label,
    'csvPattern': acc.csvFormat,
    'colorLong': acc.color?.value ?? 0,
    'balance': acc.balance,
  };

  /// For auto-incrementing keys, make sure they are NOT in the map supplied to sqflite.
  if (acc.key != 0) {
    out[_key] = acc.key;
  }
  if (listIndex != null) {
    out['listIndex'] = listIndex;
  }
  return out;
}

Account _fromMap(Map<String, dynamic> map) {
  return Account(
    type: AccountType.fromString(map['type']),
    key: map[_key],
    name: map['name'],
    balance: map['balance'],
    description: map['description'],
    color: Color(map['colorLong']),
    csvFormat: map['csvPattern'],
  );
}

FutureOr<int> insertAccount(Account acc, {int? listIndex}) async {
  if (libraDatabase == null) return 0;
  return libraDatabase!.insert(
    accountsTable,
    _toMap(acc, listIndex: listIndex),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<void> updateAccount(Account acc, {int? listIndex}) async {
  await libraDatabase?.update(
    accountsTable,
    _toMap(acc, listIndex: listIndex),
    where: '$_key = ?',
    whereArgs: [acc.key],
  );
}

Future<List<Account>> getAccounts() async {
  final List<Map<String, dynamic>> maps = await libraDatabase!.query(
    accountsTable,
    orderBy: "listIndex",
  );
  return List.generate(maps.length, (i) => _fromMap(maps[i]));
}

Future<int> updateBalance(int account, int delta, {DatabaseExecutor? db}) async {
  db = db ?? libraDatabase;
  if (db == null) return 0;
  return db.rawUpdate(
    "UPDATE $accountsTable SET $_balance = $_balance + ? WHERE $_key = ?",
    [delta, account],
  );
}
