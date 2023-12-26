import 'dart:async';
import 'package:libra_sheet/data/database/libra_database.dart';
import 'package:libra_sheet/data/enums.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/objects/category_rule.dart';
import 'package:sqflite/sqlite_api.dart';

const rulesTable = '`rules`';

const _key = "key";
const _pattern = "pattern";
const _category = "categoryKey";
const _type = "type";

@Deprecated("Rule account is not used")
const _account = "accountKey";
@Deprecated("Rule list order is no longer used or relevant")
const _index = "listIndex";

const createRulesTableSql = "CREATE TABLE IF NOT EXISTS $rulesTable ("
    "$_key INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "
    "$_pattern TEXT NOT NULL, "
    "$_category INTEGER NOT NULL, "
    "$_account INTEGER NOT NULL, "
    "$_type TEXT NOT NULL, " // this enables easy searching, but is linked to the category in memory
    "$_index INTEGER NOT NULL)";

Map<String, dynamic> _toMap(CategoryRule rule, [int? listIndex]) {
  final map = {
    _pattern: rule.pattern,
    _category: rule.category?.key ?? 0,
    _account: rule.account?.key ?? 0,
    _type: rule.type.name,
  };
  if (rule.key != 0) {
    map[_key] = rule.key;
  }
  if (listIndex != null) {
    map[_index] = listIndex;
  }
  return map;
}

CategoryRule? _fromMap(Map<String, dynamic> map, Map<int, Category> categoryMap, ExpenseType type) {
  final cat = categoryMap[map[_category]];
  if (cat == null) return null;
  return CategoryRule(
    key: map[_key],
    pattern: map[_pattern],
    category: cat,
    type: type,
  );
}

Future<int> insertRule(CategoryRule rule, {required int listIndex}) async {
  if (libraDatabase == null) return 0;
  return libraDatabase!.insert(
    rulesTable,
    _toMap(rule, listIndex),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<int> updateRule(CategoryRule rule, {int? listIndex, DatabaseExecutor? db}) async {
  db = db ?? libraDatabase;
  if (db == null) return 0;
  return db.update(
    rulesTable,
    _toMap(rule, listIndex),
    where: '$_key = ?',
    whereArgs: [rule.key],
  );
}

Future<int> deleteRule(CategoryRule rule, {DatabaseExecutor? db}) async {
  db = db ?? libraDatabase;
  if (db == null) return 0;
  return db.delete(
    rulesTable,
    where: '$_key = ?',
    whereArgs: [rule.key],
  );
}

Future<List<CategoryRule>> getRules(ExpenseType type, Map<int, Category> categoryMap) async {
  final List<Map<String, dynamic>> maps = await libraDatabase!.query(
    rulesTable,
    where: '$_type = ?',
    whereArgs: [type.name],
    orderBy: _pattern,
  );
  final out = <CategoryRule>[];
  for (final map in maps) {
    final r = _fromMap(map, categoryMap, type);
    if (r != null) out.add(r);
  }
  return out;
}

Future<int> shiftRuleIndicies(
  ExpenseType type,
  int start,
  int end,
  int delta, {
  DatabaseExecutor? db,
}) async {
  db = db ?? libraDatabase;
  if (db == null) return 0;
  return db.rawUpdate(
    "UPDATE $rulesTable "
    "SET $_index = $_index + ? "
    "WHERE $_type = ? AND $_index >= ? AND $_index < ?",
    [delta, type.name, start, end],
  );
}
