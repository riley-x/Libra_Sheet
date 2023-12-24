import 'dart:async';
import 'dart:ui';

import 'package:libra_sheet/data/database/category_history.dart';
import 'package:libra_sheet/data/database/transactions.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/data/database/libra_database.dart';
import 'package:sqflite/sqlite_api.dart';

const accountsTable = 'accounts';

const _key = "id";
const _balance = "current_balance";
const _index = "listIndex";

const createAccountsTableSql = "CREATE TABLE IF NOT EXISTS `accounts` ("
    "$_key INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "
    "`name` TEXT NOT NULL, "
    "`description` TEXT NOT NULL, "
    "`type` TEXT NOT NULL, "
    "`csvPattern` TEXT NOT NULL DEFAULT '', "
    "`screenReaderAlias` TEXT NOT NULL DEFAULT '', "
    "`colorLong` INTEGER NOT NULL, "
    "$_index INTEGER NOT NULL)";

const createTestAccountsSql = '''
INSERT INTO $accountsTable ($_key, "name", "description", "type", "csvPattern", "screenReaderAlias", "colorLong", "listIndex") VALUES
(1, 'Cash', '', 'Cash', '', '', 4279542308, 0),
(2, 'Checkings', '', 'Bank', '', '', 4280391411, 1),
(3, 'Savings', '', 'Bank', '', '', 4290126323, 2);
''';

Map<String, dynamic> _toMap(Account acc, {int? listIndex}) {
  final out = {
    'name': acc.name,
    'description': acc.description,
    'type': acc.type.label,
    'csvPattern': acc.csvFormat,
    'colorLong': acc.color.value,
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
  int? lastUpdated = map['last_updated'];
  return Account(
    type: AccountType.fromString(map['type']),
    key: map[_key],
    name: map['name'],
    balance: map[_balance] ?? 0,
    description: map['description'],
    color: Color(map['colorLong']),
    csvFormat: map['csvPattern'],
    lastUpdated: (lastUpdated == null)
        ? null
        : DateTime.fromMillisecondsSinceEpoch(lastUpdated, isUtc: true),
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

Future<List<Account>> getAccounts() async {
  final List<Map<String, dynamic>> maps = await libraDatabase!.rawQuery(
    """
    SELECT
      a.*,
      t.last_updated,
      h.$_balance
    FROM
      $accountsTable a
    LEFT OUTER JOIN
      (SELECT $transactionAccount, MAX($transactionDate) as last_updated
        FROM $transactionsTable
        GROUP BY $transactionAccount) t
      ON t.$transactionAccount = a.$_key
    LEFT OUTER JOIN
      (SELECT $historyAccount, SUM($historyValue) as $_balance
        FROM $categoryHistoryTable
        GROUP BY $historyAccount) h
      ON h.$historyAccount = a.$_key
    ORDER BY a.$_index
    """,
  );
  return List.generate(maps.length, (i) => _fromMap(maps[i]));
}

extension AccountDatabaseExtension on DatabaseExecutor {
  Future<int> updateAccount(Account acc, {int? listIndex}) {
    return update(
      accountsTable,
      _toMap(acc, listIndex: listIndex),
      where: '$_key = ?',
      whereArgs: [acc.key],
    );
  }

  Future<int> shiftAccountIndicies(int start, int end, int delta) {
    return rawUpdate(
      "UPDATE $accountsTable "
      "SET $_index = $_index + ? "
      "WHERE $_index >= ? AND $_index < ?",
      [delta, start, end],
    );
  }
}
