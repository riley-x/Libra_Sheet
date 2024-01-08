import 'dart:async';

import 'package:flutter/material.dart';
import 'package:libra_sheet/data/database/category_history.dart';
import 'package:libra_sheet/data/database/rules.dart';
import 'package:libra_sheet/data/database/transactions.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/database/libra_database.dart';
import 'package:sqflite/sqlite_api.dart';

const categoryTable = '`categories`';

const _id = 'key';
const _name = 'name';
const _color = 'colorLong';
const _parent = 'parentKey';
const _index = 'listIndex';

const createCategoryTableSql = "CREATE TABLE IF NOT EXISTS $categoryTable ("
    "`$_id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "
    "`$_name` TEXT NOT NULL, "
    "`$_color` INTEGER NOT NULL, "
    "`$_parent` INTEGER NOT NULL, "
    "`$_index` INTEGER NOT NULL)";

const createDefaultCategories = '''
INSERT INTO $categoryTable ("$_id", "$_name", "$_color", "$_parent", "$_index") VALUES
(1, 'Paycheck', 4279939415, -1, 0),
(2, 'Cash Back', 4278607389, -1, 1),
(3, 'Gifts', 4293828260, -1, 2),
(4, 'Interest', 4285770954, -1, 3),
(5, 'Tax Refund', 4284238947, -1, 4),
(6, 'Household', 4286531083, -2, 4),
(7, 'Utilities', 4293303345, 6, 1),
(8, 'Rent/Mortgage', 4287500554, 6, 0),
(9, 'Supplies', 4290017826, 6, 2),
(10, 'Food', 4283611708, -2, 0),
(11, 'Groceries', 4285851992, 10, 0),
(12, 'Takeout', 4291882280, 10, 1),
(13, 'Restaurants', 4278422059, 10, 2),
(14, 'Snacks', 4285369631, 10, 3),
(15, 'Alcohol', 4287806109, 10, 4),
(16, 'Shopping', 4278434036, -2, 1),
(17, 'Clothes', 4283008198, 16, 0),
(18, 'Electronics', 4282903786, 16, 1),
(19, 'Furniture', 4283925399, 16, 2),
(20, 'Gifts', 4278937202, 16, 3),
(21, 'Entertainment', 4293960260, -2, 2),
(22, 'Subscriptions', 4289683232, 21, 0),
(23, 'Games', 4293907217, 21, 1),
(24, 'Movies & Events', 4292836714, 21, 2),
(25, 'Health', 4291904339, -2, 3),
(26, 'Pharmacy', 4291053104, 25, 0),
(27, 'Beauty', 4294923164, 25, 1),
(28, 'Copays', 4292848559, 25, 2),
(29, 'Insurance', 4288020487, 25, 3),
(30, 'Transportation', 4281353876, -2, 5),
(31, 'Car', 4284443815, 30, 0),
(32, 'Gas', 4283382146, 30, 1),
(33, 'Taxis', 4282349036, 30, 2),
(34, 'Fares', 4289710333, 30, 3),
(35, 'Other', 4287993237, -2, 7),
(36, 'Hotels', 4289619419, 39, 0),
(37, 'Taxes', 4289687417, 35, 0),
(38, 'Services', 4287460443, 35, 1),
(39, 'Vacation', 4291798491, -2, 6),
(40, 'Transportation', 4290074759, 39, 1),
(41, 'Attractions', 4293365977, 39, 2);
''';

extension CategoryDatabaseExtension on DatabaseExecutor {
  Future<int> insertCategory(Category cat, {int? listIndex}) {
    return insert(
      categoryTable,
      cat.toMap(listIndex: listIndex),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateCategory(Category cat, {int? listIndex}) {
    return update(
      categoryTable,
      cat.toMap(listIndex: listIndex),
      where: '`$_id` = ?',
      whereArgs: [cat.key],
    );
  }

  Future<int> shiftCategoryListIndicies(int parentKey, int start, int end, int delta) {
    return rawUpdate(
      "UPDATE $categoryTable "
      "SET $_index = $_index + ? "
      "WHERE $_parent = ? AND $_index >= ? AND $_index < ?",
      [delta, parentKey, start, end],
    );
  }
}

extension CategoryTransactionExtension on Transaction {
  /// This will recurse and delete the sub categories too. Warning, this doesn't modify the list
  /// indexes in the parent list though.
  Future<void> deleteCategory(Category cat) async {
    for (final sub in cat.subCats) {
      await deleteCategory(sub);
    }
    await deleteCategoryNoChildren(cat);
  }

  Future<void> deleteCategoryNoChildren(Category cat) async {
    assert(cat.level > 0);
    await delete(
      categoryTable,
      where: '`$_id` = ?',
      whereArgs: [cat.key],
    );
    await unsetCategoryFromAllTransactions(cat.key);
    await mergeAndDeleteCategoryHistory(cat);
    await deleteRulesWithCategory(cat.key);
  }

  /// Recurses to load each categories children.
  Future<void> loadChildCategories(Category parent) async {
    final List<Map<String, dynamic>> maps = await query(
      categoryTable,
      where: "$_parent = ?",
      whereArgs: [parent.key],
      orderBy: _index,
    );

    for (final map in maps) {
      final cat = Category(
        key: map[_id] as int,
        name: map[_name] as String,
        color: Color(map[_color] as int),
        parent: parent,
      );
      parent.subCats.add(cat);

      if (cat.level <= 1) {
        await loadChildCategories(cat);
      }
    }
  }
}
