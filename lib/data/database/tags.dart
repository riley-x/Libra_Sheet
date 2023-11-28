import 'dart:async';
import 'dart:ui';
import 'package:libra_sheet/data/database/database_setup.dart';
import 'package:libra_sheet/data/objects/tag.dart';
import 'package:libra_sheet/data/objects/transaction.dart' as lt;
import 'package:sqflite/sqlite_api.dart';

const tagsTable = '`tags`';
const tagJoinTable = '`tag_join`';

const _key = "key";
const _name = "name";
const _color = "color";

const createTagsTableSql = "CREATE TABLE IF NOT EXISTS $tagsTable ("
    "$_key INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "
    "$_name TEXT NOT NULL, "
    "$_color INTEGER NOT NULL, "
    "list_index INTEGER NOT NULL DEFAULT -1)";

const createTagJoinTableSql = "CREATE TABLE IF NOT EXISTS $tagJoinTable ("
    "transaction_id INTEGER NOT NULL, "
    "tag_id INTEGER NOT NULL, "
    "PRIMARY KEY(transaction_id, tag_id))";

Map<String, dynamic> _toMap(Tag tag) {
  final map = {
    _name: tag.name,
    _color: tag.color.value,
  };
  if (tag.key != 0) {
    map[_key] = tag.key;
  }
  return map;
}

Tag _fromMap(Map<String, dynamic> map) {
  return Tag(
    name: map[_name],
    color: Color(map[_color]),
    key: map[_key],
  );
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
  await libraDatabase?.delete(
    tagsTable,
    where: '$_key = ?',
    whereArgs: [tag.key],
  );
}

Future<List<Tag>> getTags() async {
  final List<Map<String, dynamic>> maps = await libraDatabase!.query(
    tagsTable,
    orderBy: "$_key DESC",
  );
  return List.generate(
    maps.length,
    (i) => _fromMap(maps[i]),
  );
}

Future<int> insertTagJoin(lt.Transaction trans, Tag tag, {DatabaseExecutor? db}) async {
  db = db ?? libraDatabase;
  if (db == null) return 0;
  return db.insert(
    tagJoinTable,
    {
      "transaction_id": trans.key,
      "tag_id": tag.key,
    },
  );
}
