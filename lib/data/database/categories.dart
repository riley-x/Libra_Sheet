import 'dart:async';

import 'package:flutter/material.dart';
import 'package:libra_sheet/data/category.dart';
import 'package:libra_sheet/data/database/database_setup.dart';
import 'package:libra_sheet/data/enums.dart';
import 'package:sqflite/sqlite_api.dart';

const categoryTable = '`categories`';

FutureOr<int> insertCategory(
  Category cat, {
  int? listIndex,
  DatabaseExecutor? db,
}) async {
  db = db ?? libraDatabase;
  if (db == null) return 0;
  return db.insert(
    categoryTable,
    cat.toMap(listIndex: listIndex),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

FutureOr<int> updateCategory(
  Category cat, {
  int? listIndex,
  DatabaseExecutor? db,
}) async {
  db = db ?? libraDatabase;
  if (db == null) return 0;
  return db.update(
    categoryTable,
    cat.toMap(listIndex: listIndex),
    where: '`key` = ?',
    whereArgs: [cat.key],
  );
}

FutureOr<int> shiftListIndicies(
  int parentKey,
  int start,
  int end,
  int delta, {
  DatabaseExecutor? db,
}) async {
  db = db ?? libraDatabase;
  if (db == null) return 0;
  return db.rawUpdate(
    "UPDATE $categoryTable "
    "SET listIndex = listIndex + ? "
    "WHERE parentKey = ? AND listIndex >= ? AND listIndex < ?",
    [delta, parentKey, start, end],
  );
}

/// Must be called from inside a transaction. Recurses to load each categories children.
FutureOr<void> loadChildCategories(Transaction txn, Category parent) async {
  final List<Map<String, dynamic>> maps = await txn.query(
    categoryTable,
    where: "parentKey = ?",
    whereArgs: [parent.key],
    orderBy: "listIndex",
  );

  for (final map in maps) {
    final cat = Category(
      key: map['key'] as int,
      name: map['name'] as String,
      color: Color(map['colorLong'] as int),
      parent: parent,
    );
    parent.subCats.add(cat);

    if (cat.level <= 1) {
      await loadChildCategories(txn, cat);
    }
  }
}
