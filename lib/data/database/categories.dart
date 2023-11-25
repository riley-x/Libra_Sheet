import 'dart:async';

import 'package:libra_sheet/data/category.dart';
import 'package:libra_sheet/data/database/database_setup.dart';
import 'package:sqflite/sqlite_api.dart';

const categoryTable = '`categories`';

FutureOr<int> insertCategory(Category cat, {int? listIndex}) async {
  if (libraDatabase == null) return 0;
  return libraDatabase!.insert(
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
