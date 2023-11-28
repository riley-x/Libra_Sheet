import 'dart:async';

import 'package:libra_sheet/data/database/database_setup.dart';
import 'package:libra_sheet/data/objects/allocation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:libra_sheet/data/objects/transaction.dart' as lt;

const allocationsTable = "allocations";

const createAllocationsTableSql = "CREATE TABLE IF NOT EXISTS $allocationsTable ("
    "$_key INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "
    "$_name TEXT NOT NULL, "
    "$_transaction INTEGER NOT NULL, "
    "$_category INTEGER NOT NULL, "
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

/// This modifies the allocation's key in-place!
FutureOr<void> insertAllocation(
  lt.Transaction parent,
  Allocation allocation, {
  required int listIndex,
  DatabaseExecutor? database,
}) async {
  database = database ?? libraDatabase;
  if (database == null) return;
  allocation.key = await database.insert(
    allocationsTable,
    _toMap(parent, allocation, listIndex),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
  return;
}
