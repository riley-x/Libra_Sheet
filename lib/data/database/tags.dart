import 'dart:async';
import 'dart:ui';
import 'package:libra_sheet/data/database/libra_database.dart';
import 'package:libra_sheet/data/objects/tag.dart';
import 'package:libra_sheet/data/objects/transaction.dart' as lt;
import 'package:sqflite/sqlite_api.dart';

const tagsTable = '`tags`';
const tagJoinTable = '`tag_join`';

const tagKey = _key;

const _key = "id";
const _name = "name";
const _color = "color";
const _index = "list_index";

const createTagsTableSql = "CREATE TABLE IF NOT EXISTS $tagsTable ("
    "$_key INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "
    "$_name TEXT NOT NULL, "
    "$_color INTEGER NOT NULL, "
    "$_index INTEGER NOT NULL DEFAULT -1)";

const tagJoinTag = "tag_id";
const tagJoinTrans = "transaction_id";

const createTagJoinTableSql = "CREATE TABLE IF NOT EXISTS $tagJoinTable ("
    "$tagJoinTrans INTEGER NOT NULL, "
    "$tagJoinTag INTEGER NOT NULL, "
    "PRIMARY KEY($tagJoinTrans, $tagJoinTag))";

const createTestTagsSql = '''
INSERT INTO $tagsTable ($_key, $_name, $_color, $_index) VALUES
(1, 'Tag 1', 4283934904, -1),
(2, 'Taggier 2', 4292463774, -1),
(3, 'Tagalicious 3', 4291442848, -1);
''';

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

extension Tags on DatabaseExecutor {
  Future<int> insertTag(Tag tag) {
    LibraDatabase.tallyBackup(1);
    return insert(
      tagsTable,
      _toMap(tag),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateTag(Tag tag) {
    LibraDatabase.tallyBackup(1);
    return update(
      tagsTable,
      _toMap(tag),
      where: '$_key = ?',
      whereArgs: [tag.key],
    );
  }

  Future<void> deleteTag(Tag tag) async {
    if (this is Database) {
      (this as Database).transaction((txn) => txn.deleteTag(tag));
      return;
    }
    LibraDatabase.backup();
    await delete(
      tagsTable,
      where: '$_key = ?',
      whereArgs: [tag.key],
    );
    await delete(
      tagJoinTable,
      where: "tag_id = ?",
      whereArgs: [tag.key],
    );
  }

  Future<List<Tag>> getAllTags() async {
    final List<Map<String, dynamic>> maps = await query(
      tagsTable,
      orderBy: "$_key DESC",
    );
    return List.generate(
      maps.length,
      (i) => _fromMap(maps[i]),
    );
  }

  Future<int> insertTagJoin(lt.Transaction trans, Tag tag) {
    LibraDatabase.tallyBackup(1);
    return insert(
      tagJoinTable,
      {
        "transaction_id": trans.key,
        "tag_id": tag.key,
      },
    );
  }

  Future<int> deleteTagJoin(lt.Transaction trans, Tag tag) {
    LibraDatabase.tallyBackup(1);
    return delete(
      tagJoinTable,
      where: "transaction_id = ? AND tag_id = ?",
      whereArgs: [trans.key, tag.key],
    );
  }

  Future<int> removeAllTagsFrom(lt.Transaction trans) {
    LibraDatabase.tallyBackup(3);
    return delete(
      tagJoinTable,
      where: "transaction_id = ?",
      whereArgs: [trans.key],
    );
  }
}
