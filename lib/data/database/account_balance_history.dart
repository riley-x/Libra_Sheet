import 'dart:async';

import 'package:libra_sheet/data/date_time_utils.dart';
import 'package:libra_sheet/data/time_value.dart';
import 'package:sqflite/sqlite_api.dart';

const String accountBalanceHistoryTable = "account_balance_history";

const String _account = "account_id";
const String _date = "date";
const String _value = "value";

const String createAccountBalanceHistoryTableSql =
    "CREATE TABLE IF NOT EXISTS $accountBalanceHistoryTable ("
    "$_account INTEGER NOT NULL, "
    "$_date INTEGER NOT NULL, "
    "$_value INTEGER NOT NULL, "
    "PRIMARY KEY($_account, $_date))";

//----------------------------------------------------------------------------------
// Helper utils
//----------------------------------------------------------------------------------

class _AccountBalanceHistory {
  final int account;
  final DateTime date;
  final int delta;

  _AccountBalanceHistory({required this.account, required this.date, required this.delta});
}

//----------------------------------------------------------------------------------
// Setters
//----------------------------------------------------------------------------------
extension AccountBalanceHistoryExtensionT on Transaction {
  /// Creates and updates the account balance history using the month from [date].
  Future<int> updateAccountBalanceHistory({
    required int account,
    required DateTime date,
    required int delta,
  }) {
    return updateAccountBalanceHistoryForMigration(
      this,
      account: account,
      date: date,
      delta: delta,
    );
  }
}

//----------------------------------------------------------------------------------
// Getters
//----------------------------------------------------------------------------------
extension AccountBalanceHistoryExtension on DatabaseExecutor {
  /// Returns a map of the monthly balance delta for each account.
  Future<Map<int, List<TimeIntValue>>> getAllHistory() async {
    final maps = await query(
      accountBalanceHistoryTable,
      columns: [_date, _account, _value],
      where: "$_value != 0",
      orderBy: "$_account, $_date",
    );

    final Map<int, List<TimeIntValue>> out = {};
    for (final map in maps) {
      final account = map[_account] as int;
      final vals = out.putIfAbsent(account, () => []);
      vals.add(
        TimeIntValue(
          time: DateTime.fromMillisecondsSinceEpoch(map[_date] as int, isUtc: true),
          value: map[_value] as int,
        ),
      );
    }
    return out;
  }
}

/// Inserts an account balance history entry with value = 0. Will ignore conflicts, so useful to
/// make sure an entry exists already.
Future<int> _insertAccountBalanceHistory(DatabaseExecutor txn, _AccountBalanceHistory data) async {
  return txn.insert(accountBalanceHistoryTable, {
    _account: data.account,
    _date: data.date.millisecondsSinceEpoch,
    _value: 0,
  }, conflictAlgorithm: ConflictAlgorithm.ignore);
}

/// Updates the account balance history using the month from [date].
Future<int> _updateAccountBalanceHistory(DatabaseExecutor txn, _AccountBalanceHistory data) async {
  return txn.rawUpdate(
    "UPDATE $accountBalanceHistoryTable SET $_value = $_value + ?"
    " WHERE $_account = ? AND $_date = ?",
    [data.delta, data.account, data.date.millisecondsSinceEpoch],
  );
}

// Should be in transaction but the onUpdate method only supplies a DatabaseExecutor
Future<int> updateAccountBalanceHistoryForMigration(
  DatabaseExecutor txn, {
  required int account,
  required DateTime date,
  required int delta,
}) async {
  final data = _AccountBalanceHistory(account: account, date: startOfMonth(date), delta: delta);
  await _insertAccountBalanceHistory(txn, data);
  return await _updateAccountBalanceHistory(txn, data);
}
