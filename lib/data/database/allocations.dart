import 'dart:async';

import 'package:libra_sheet/data/database/category_history.dart';
import 'package:libra_sheet/data/database/database_setup.dart';
import 'package:libra_sheet/data/objects/allocation.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:libra_sheet/data/objects/transaction.dart' as lt;

const allocationsTable = "allocations";

const createAllocationsTableSql = "CREATE TABLE IF NOT EXISTS $allocationsTable ("
    "$_key INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "
    "$_name TEXT NOT NULL, "
    "$_transaction INTEGER NOT NULL, " // id into transaction table
    "$_category INTEGER NOT NULL, " // id into category table
    "$_value INTEGER NOT NULL, "
    "$_index INTEGER NOT NULL)";

const _key = "id";
const _name = "name";
const _transaction = "transactionId";
const _category = "categoryId";
const _value = "value";
const _index = "listIndex";

const allocationsKey = _key;
const allocationsTransaction = _transaction;
const allocationsCategory = _category;

Map<String, dynamic> _toMap(lt.Transaction parent, Allocation a, int listIndex) {
  assert(parent.key != 0 && a.category != null);
  final map = {
    _name: a.name,
    _transaction: parent.key,
    _category: a.category?.key ?? 0,
    _value: a.value,
    _index: listIndex,
  };
  if (a.key != 0) {
    map[_key] = a.key;
  }
  return map;
}

Allocation _fromMap(Map<int, Category> categories, Map<String, dynamic> map) {
  return Allocation(
    key: map[_key],
    name: map[_name],
    category: categories[map[_category]] ?? Category.empty,
    value: map[_value],
  );
}

/// This modifies the allocation's key in-place!
FutureOr<void> _insertAllocation({
  required lt.Transaction parent,
  required Allocation allocation,
  required int listIndex,
  required DatabaseExecutor db,
}) async {
  allocation.key = await db.insert(
    allocationsTable,
    _toMap(parent, allocation, listIndex),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
  return;
}

Future<int> _deleteAllocation({
  required Allocation allocation,
  required DatabaseExecutor db,
}) async {
  return db.delete(allocationsTable, where: "$_key = ?", whereArgs: [allocation.key]);
}

/// This modifies the allocation's key in-place!
FutureOr<void> addAllocation({
  required lt.Transaction parent,
  required int index,
  required Transaction txn,
}) async {
  if (parent.account == null) return;
  if (parent.category == null) return;
  if (parent.allocations == null) return;
  if (index >= parent.allocations!.length) return;
  final alloc = parent.allocations![index];
  if (alloc.category == null) return;

  await _insertAllocation(parent: parent, allocation: alloc, listIndex: index, db: txn);

  final signedValue = (parent.value < 0) ? -alloc.value : alloc.value;
  await updateCategoryHistory(
    account: parent.account!.key,
    category: parent.category!.key,
    date: parent.date,
    delta: -signedValue,
    txn: txn,
  );
  await updateCategoryHistory(
    account: parent.account!.key,
    category: alloc.category!.key,
    date: parent.date,
    delta: signedValue,
    txn: txn,
  );
}

FutureOr<void> deleteAllocation({
  required lt.Transaction parent,
  required int index,
  required Transaction txn,
}) async {
  if (parent.account == null) return;
  if (parent.category == null) return;
  if (parent.allocations == null) return;
  if (index >= parent.allocations!.length) return;
  final alloc = parent.allocations![index];
  if (alloc.category == null) return;

  await _deleteAllocation(allocation: alloc, db: txn);

  await shiftAllocationListIndicies(
    transKey: parent.key,
    start: index,
    end: parent.allocations!.length,
    delta: -1,
    txn: txn,
  );

  final signedValue = (parent.value < 0) ? -alloc.value : alloc.value;
  await updateCategoryHistory(
    account: parent.account!.key,
    category: parent.category!.key,
    date: parent.date,
    delta: signedValue,
    txn: txn,
  );
  await updateCategoryHistory(
    account: parent.account!.key,
    category: alloc.category!.key,
    date: parent.date,
    delta: -signedValue,
    txn: txn,
  );
}

Future<List<Allocation>> loadAllocations(
  int transactionKey,
  Map<int, Category> categories,
  DatabaseExecutor db,
) async {
  final maps = await db.query(
    allocationsTable,
    where: "$_transaction = ?",
    whereArgs: [transactionKey],
    orderBy: _index,
  );
  return [for (final map in maps) _fromMap(categories, map)];
}

/// Returns every allocation as a map from transaction key to the allocations. Probably excessive...
Future<Map<int, List<Allocation>>> loadAllAllocations(
  Map<int, Category> categories, {
  DatabaseExecutor? db,
}) async {
  final out = <int, List<Allocation>>{};

  db = db ?? libraDatabase;
  if (db == null) return out;

  final maps = await db.query(
    allocationsTable,
    orderBy: "$_transaction, $_index",
  );

  int currentTransaction = -1;
  List<Allocation> currentList = [];

  void checkSaveList(int nextId) {
    if (currentTransaction != -1 && currentTransaction != nextId) {
      out[currentTransaction] = currentList;
      currentTransaction = nextId;
      currentList = [];
    }
  }

  for (final row in maps) {
    checkSaveList(row[_transaction] as int);
    currentList.add(_fromMap(categories, row));
  }
  checkSaveList(-1);

  return out;
}

/// Start is inclusive, end is exclusive
FutureOr<int> shiftAllocationListIndicies({
  required int transKey,
  required int start,
  required int end,
  required int delta,
  required Transaction txn,
}) async {
  return txn.rawUpdate(
    "UPDATE $allocationsTable "
    "SET $_index = $_index + ? "
    "WHERE $_transaction = ? AND $_index >= ? AND $_index < ?",
    [delta, transKey, start, end],
  );
}
