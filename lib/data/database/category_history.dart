import 'dart:async';

import 'package:libra_sheet/data/database/database_setup.dart';
import 'package:libra_sheet/data/date_time_utils.dart';
import 'package:libra_sheet/data/time_value.dart';
import 'package:sqflite/sqlite_api.dart';

const String categoryHistoryTable = "category_history";

const String _account = "account_id";
const String _category = "category_id";
const String _date = "date";
const String _value = "value";

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

// @Query("SELECT MIN(date) FROM $categoryHistoryTable WHERE value != 0")
FutureOr<DateTime> getEarliestMonth() async {
  final out = await libraDatabase!.query(
    categoryHistoryTable,
    columns: ["MIN($_date) as $_date"],
    where: "$_value != 0",
  );
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

/// Returns the monthly net change across all acounts. WARNING: the dates are returned using the
/// local timezone, do not use for anything other than the syncfusion charts. Also, there may be
/// gaps in the timeline.
Future<List<TimeIntValue>> getMonthlyNet() async {
  final List<Map<String, dynamic>> maps = await libraDatabase!.query(
    categoryHistoryTable,
    columns: [_date, "SUM($_value) as $_value"],
    where: "$_value != 0",
    groupBy: _date,
    orderBy: _date,
  );

  return List.generate(maps.length, (i) {
    // The syncfusion charts expect local timezone, so convert manually
    final utcTime = DateTime.fromMillisecondsSinceEpoch(maps[i][_date], isUtc: true);
    final localTime = DateTime(utcTime.year, utcTime.month, utcTime.day);
    return TimeIntValue(
      time: localTime,
      value: maps[i][_value],
    );
  });
}

/// Returns a map: category -> list of the value history in that month. This function does not pad
/// the lists to equal length or accumulate them.
Future<Map<int, List<TimeIntValue>>> getCategoryHistory() async {
  if (libraDatabase == null) return {};

  final rows = await libraDatabase!.query(
    categoryHistoryTable,
    columns: [_date, _category, "SUM($_value) as $_value"],
    where: "$_value != 0",
    groupBy: "$_date, $_category",
    orderBy: "$_category, $_date",
  );

  Map<int, List<TimeIntValue>> out = {};
  if (rows.isEmpty) return out;

  int currentCategory = rows[0][_category] as int;
  var currentValues = <TimeIntValue>[];
  for (final row in rows) {
    final cat = row[_category] as int;
    if (cat != currentCategory) {
      out[currentCategory] = currentValues;
      currentValues = [];
      currentCategory = cat;
    }
    currentValues.add(TimeIntValue(
      time: DateTime.fromMillisecondsSinceEpoch(row[_date] as int, isUtc: true),
      value: row[_value] as int,
    ));
  }
  out[currentCategory] = currentValues;
  return out;
}
