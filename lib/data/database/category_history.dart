import 'dart:async';

import 'package:libra_sheet/data/database/libra_database.dart';
import 'package:libra_sheet/data/date_time_utils.dart';
import 'package:libra_sheet/data/time_value.dart';
import 'package:sqflite/sqlite_api.dart';

const String categoryHistoryTable = "category_history";

const String _account = "account_id";
const String _category = "category_id";
const String _date = "date";
const String _value = "value";

const String historyAccount = _account;
const String historyValue = _value;

const String createCategoryHistoryTableSql = "CREATE TABLE IF NOT EXISTS $categoryHistoryTable ("
    "$_account INTEGER NOT NULL, "
    "$_category INTEGER NOT NULL, "
    "$_date INTEGER NOT NULL, "
    "$_value INTEGER NOT NULL, "
    "PRIMARY KEY($_account, $_category, $_date))";

class _CategoryHistory {
  final int account;
  final int category;
  final DateTime date;
  final int delta;

  _CategoryHistory({
    required this.account,
    required this.category,
    required this.date,
    required this.delta,
  });
}

FutureOr<DateTime?> getEarliestMonth() async {
  final out = await libraDatabase!.query(
    categoryHistoryTable,
    columns: ["MIN($_date) as $_date"],
    where: "$_value != 0",
  );
  if (out.first[_date] == null) return null; // This happens when the database is empty
  return DateTime.fromMillisecondsSinceEpoch(out.first[_date] as int, isUtc: true);
}

/// Inserts a category history entry with value = 0. Will ignore conflicts, so useful to make sure
/// an entry exists already.
Future<int> _insertCategoryHistory(_CategoryHistory data, DatabaseExecutor db) async {
  return db.insert(
    categoryHistoryTable,
    {
      _account: data.account,
      _category: data.category,
      _date: data.date.millisecondsSinceEpoch,
      _value: 0,
    },
    conflictAlgorithm: ConflictAlgorithm.ignore,
  );
}

/// Updates the category history using the month from [date].
Future<int> _updateCategoryHistory(_CategoryHistory data, DatabaseExecutor db) async {
  return db.rawUpdate(
    "UPDATE $categoryHistoryTable SET $_value = $_value + ?"
    " WHERE $_account = ? AND $_category = ? AND $_date = ?",
    [data.delta, data.account, data.category, data.date.millisecondsSinceEpoch],
  );
}

/// Creates and updates the category history using the month from [date].
FutureOr<int> updateCategoryHistory({
  required int account,
  required int category,
  required DateTime date,
  required int delta,
  required Transaction txn,
}) async {
  final data = _CategoryHistory(
    account: account,
    category: category,
    date: startOfMonth(date),
    delta: delta,
  );
  await _insertCategoryHistory(data, txn);
  return await _updateCategoryHistory(data, txn);
}

/// Returns the monthly net change across all acounts or [accoundId].
Future<List<TimeIntValue>> getMonthlyNet({int? accountId}) async {
  final List<Map<String, dynamic>> maps = await libraDatabase!.query(
    categoryHistoryTable,
    columns: [_date, "SUM($_value) as $_value"],
    where: "$_value != 0${(accountId != null) ? " AND $_account = ?" : ""}",
    whereArgs: (accountId != null) ? [accountId] : null,
    groupBy: _date,
    orderBy: _date,
  );

  return List.generate(maps.length, (i) {
    return TimeIntValue(
      time: DateTime.fromMillisecondsSinceEpoch(maps[i][_date], isUtc: true),
      value: maps[i][_value],
    );
  });
}

/// Returns the monthly net change for the sum of certain categories
Future<List<TimeIntValue>> getCategoryHistorySum(List<int> categories) async {
  final List<Map<String, dynamic>> maps = await libraDatabase!.query(
    categoryHistoryTable,
    columns: [_date, "SUM($_value) as $_value"],
    where: "$_value != 0 AND $_category in (${List.filled(categories.length, '?').join(',')})",
    whereArgs: categories,
    groupBy: _date,
    orderBy: _date,
  );

  return List.generate(maps.length, (i) {
    return TimeIntValue(
      time: DateTime.fromMillisecondsSinceEpoch(maps[i][_date], isUtc: true),
      value: maps[i][_value],
    );
  });
}

/// Returns a map: category -> list of the value history in that month. This function does not pad
/// the lists to equal length or accumulate them. You can specify [callback] to handle some common
/// processing options easily though.
///
/// Returns the categories in [categories], or all categories if the list is empty.
Future<Map<int, List<TimeIntValue>>> getCategoryHistory({
  List<int> categories = const [],
  List<TimeIntValue> Function(int category, List<TimeIntValue> history)? callback,
}) async {
  if (libraDatabase == null) return {};

  var where = "$_value != 0";
  List? whereArgs;
  if (categories.isNotEmpty) {
    where += " AND $_category in (${List.filled(categories.length, '?').join(',')})";
    whereArgs = categories;
  }

  final rows = await libraDatabase!.query(
    categoryHistoryTable,
    columns: [_date, _category, "SUM($_value) as $_value"],
    where: where,
    whereArgs: whereArgs,
    groupBy: "$_date, $_category",
    orderBy: "$_category, $_date",
  );

  Map<int, List<TimeIntValue>> out = {};
  if (rows.isEmpty) return out;

  /// Per-entry accumulators ///
  int currentCategory = rows[0][_category] as int;
  var currentValues = <TimeIntValue>[];
  void _addEntry() {
    if (callback != null) {
      currentValues = callback(currentCategory, currentValues);
    }
    out[currentCategory] = currentValues;
  }

  /// Loop per category ///
  for (final row in rows) {
    final cat = row[_category] as int;
    if (cat != currentCategory) {
      _addEntry();
      currentValues = [];
      currentCategory = cat;
    }
    currentValues.add(TimeIntValue(
      time: DateTime.fromMillisecondsSinceEpoch(row[_date] as int, isUtc: true),
      value: row[_value] as int,
    ));
  }
  _addEntry(); // last category is dangling, so add here
  return out;
}

/// Returns a map categoryId -> total, from the given [start] time (inclusive) and [accounts].
Future<Map<int, int>> getCategoryTotals({
  DateTime? start,
  Iterable<int>? accounts,
  Iterable<int>? tags, // TODO not sorted by tag...manually add transactions?
}) async {
  String where = "";
  List args = <dynamic>[];
  if (start != null) {
    where = "$_date >= ?";
    args.add(start.millisecondsSinceEpoch);
  }
  if (accounts != null && accounts.isNotEmpty) {
    if (where.isNotEmpty) where += " AND ";
    where += "$_account in (${List.filled(accounts.length, '?').join(',')})";
    args.addAll(accounts);
  }

  final maps = await libraDatabase!.query(
    categoryHistoryTable,
    columns: [_category, "SUM($_value) as $_value"],
    where: (where.isNotEmpty) ? where : null,
    whereArgs: args,
    groupBy: _category,
  );

  final out = <int, int>{};
  for (final map in maps) {
    out[map[_category] as int] = map[_value] as int;
  }
  return out;
}
