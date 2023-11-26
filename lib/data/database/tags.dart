import 'dart:async';
import 'dart:ui';

import 'package:libra_sheet/data/account.dart';
import 'package:libra_sheet/data/database/database_setup.dart';
import 'package:libra_sheet/data/tag.dart';
import 'package:sqflite/sqlite_api.dart';

const tagsTable = '`tags`';

const _key = "`key`";
const _name = "`name`";
const _color = "`color`";

const createTagsTableSql = "CREATE TABLE IF NOT EXISTS $tagsTable ("
    "$_key INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "
    "$_name TEXT NOT NULL, "
    "$_color INTEGER NOT NULL, "
    "`listIndex` INTEGER NOT NULL)";

Map<String, dynamic> _toMap(Tag tag) {
  return {
    _key: tag.key,
    _name: tag.name,
    _color: tag.color,
  };
}

Future<int> insertTag(Tag tag) async {
  if (libraDatabase == null) return 0;
  return libraDatabase!.insert(
    tagsTable,
    _toMap(tag),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<void> updateTag(Tag tag) async {
  await libraDatabase?.update(
    tagsTable,
    _toMap(tag),
    where: '$_key = ?',
    whereArgs: [tag.key],
  );
}

Future<void> deleteTag(Tag tag) async {
  await libraDatabase?.update(
    tagsTable,
    _toMap(tag),
    where: '$_key = ?',
    whereArgs: [tag.key],
  );
}
