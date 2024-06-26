import 'dart:async';
import 'dart:ui';
import 'package:libra_sheet/data/objects/tag.dart';
import 'package:libra_sheet/data/objects/transaction.dart' as lt;
import 'package:sqflite/sqlite_api.dart';

const tagsTable = '`tags`';
const tagJoinTable = '`tag_join`';

const tagKey = _key;

const _key = "id";
const _name = "name";
const _color = "color";
const _index = "listIndex";

const createTagsTableSql = "CREATE TABLE IF NOT EXISTS $tagsTable ("
    "$_key INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "
    "$_name TEXT NOT NULL, "
    "$_color INTEGER NOT NULL, "
    "$_index INTEGER NOT NULL)";

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

Map<String, dynamic> _toMap(Tag tag, {int? listIndex}) {
  final map = {
    _name: tag.name,
    _color: tag.color.value,
  };

  /// For auto-incrementing keys, make sure they are NOT in the map supplied to sqflite.
  if (tag.key != 0) {
    map[_key] = tag.key;
  }
  if (listIndex != null) {
    map[_index] = listIndex;
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

extension TagsDatabaseExtension on DatabaseExecutor {
  Future<int> insertTag(Tag tag, {int? listIndex}) {
    return insert(
      tagsTable,
      _toMap(tag, listIndex: listIndex),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateTag(Tag tag, {int? listIndex}) {
    return update(
      tagsTable,
      _toMap(tag, listIndex: listIndex),
      where: '$_key = ?',
      whereArgs: [tag.key],
    );
  }

  Future<int> countTags() async {
    final maps = await query(
      tagsTable,
      columns: ['COUNT($_key) as count'],
    );
    return maps[0]['count'] as int? ?? 0;
  }

  Future<List<Tag>> getAllTags() async {
    final List<Map<String, dynamic>> maps = await query(
      tagsTable,
      orderBy: _index,
    );
    return List.generate(
      maps.length,
      (i) => _fromMap(maps[i]),
    );
  }

  Future<int> shiftTagIndicies(int start, int end, int delta) {
    return rawUpdate(
      "UPDATE $tagsTable "
      "SET $_index = $_index + ? "
      "WHERE $_index >= ? AND $_index < ?",
      [delta, start, end],
    );
  }

  Future<int> insertTagJoin(lt.Transaction trans, Tag tag) {
    return insert(
      tagJoinTable,
      {
        "transaction_id": trans.key,
        "tag_id": tag.key,
      },
    );
  }

  Future<int> deleteTagJoin(lt.Transaction trans, Tag tag) {
    return delete(
      tagJoinTable,
      where: "transaction_id = ? AND tag_id = ?",
      whereArgs: [trans.key, tag.key],
    );
  }

  Future<int> removeAllTagsFrom(lt.Transaction trans) {
    return delete(
      tagJoinTable,
      where: "transaction_id = ?",
      whereArgs: [trans.key],
    );
  }
}

extension TagsTransactionExtension on Transaction {
  Future<void> deleteTag(Tag tag) async {
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
}
