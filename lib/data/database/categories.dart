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

FutureOr<int> updateCategory(Category cat, {int? listIndex}) async {
  if (libraDatabase == null) return 0;
  return libraDatabase!.update(
    categoryTable,
    cat.toMap(listIndex: listIndex),
    where: '`key` = ?',
    whereArgs: [cat.key],
  );
}

FutureOr<int> shiftListIndicies(int parentKey, int start, int delta) async {
  if (libraDatabase == null) return 0;
  return libraDatabase!.rawUpdate(
    "UPDATE $categoryTable "
    "SET listIndex = listIndex + ? "
    "WHERE parentKey = ? AND listIndex > ?",
    [delta, parentKey, start],
  );
}
