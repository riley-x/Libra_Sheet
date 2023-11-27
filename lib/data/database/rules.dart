import 'dart:async';
import 'dart:ui';
import 'package:libra_sheet/data/database/database_setup.dart';
import 'package:libra_sheet/data/enums.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/objects/category_rule.dart';
import 'package:libra_sheet/data/objects/tag.dart';
import 'package:sqflite/sqlite_api.dart';

const rulesTable = '`rules`';

const _key = "key";
const _pattern = "pattern";
const _category = "categoryKey";
const _account = "accountKey";
const _type = "type";
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
    _type: rule.category?.type ?? ExpenseType.expense.name,
  };
  if (rule.key != 0) {
    map[_key] = rule.key;
  }
  if (listIndex != null) {
    map[_index] = listIndex;
  }
  return map;
}

CategoryRule _fromMap(Map<String, dynamic> map, Map<int, Category> categoryMap) {
  return CategoryRule(
    key: map[_key],
    pattern: map[_pattern],
    category: categoryMap[map[_category]],
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

Future<void> updateRule(CategoryRule rule, {int? listIndex}) async {
  await libraDatabase?.update(
    rulesTable,
    _toMap(rule, listIndex),
    where: '$_key = ?',
    whereArgs: [rule.key],
  );
}

Future<void> deleteRule(CategoryRule rule) async {
  await libraDatabase?.delete(
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
    orderBy: _index,
  );
  return List.generate(
    maps.length,
    (i) => _fromMap(maps[i], categoryMap),
  );
}
