import 'dart:async';

import 'package:libra_sheet/data/database/category_history.dart';
import 'package:libra_sheet/data/date_time_utils.dart';
import 'package:libra_sheet/data/enums.dart';
import 'package:libra_sheet/data/objects/allocation.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:libra_sheet/data/objects/transaction.dart' as lt;

const allocationsTable = "allocations";

const createAllocationsTableSql =
    "CREATE TABLE IF NOT EXISTS $allocationsTable ("
    "$_key INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "
    "$_name TEXT NOT NULL, "
    "$_transaction INTEGER NOT NULL, " // id into transaction table
    "$_category INTEGER NOT NULL, " // id into category table
    "$_value INTEGER NOT NULL, "
    "$_index INTEGER NOT NULL)";
const addAllocationTimestampColumnSql =
    "ALTER TABLE $allocationsTable ADD COLUMN $_timestamp INTEGER";

const _key = "id";
const _name = "name";
const _transaction = "transactionId";
const _category = "categoryId";
const _value = "value";
const _index = "listIndex";

/// The timestamp (millis from epoch) to which this allocation should apply.
/// If null, defaults to the transaction's timestamp.
const _timestamp = "timestamp";

const allocationsKey = _key;
const allocationsName = _name;
const allocationsTransaction = _transaction;
const allocationsCategory = _category;
const allocationsValue = _value;

Map<String, dynamic> _toMap(lt.Transaction parent, Allocation a, int listIndex) {
  assert(parent.key != 0 && a.category != null);
  final map = {
    _name: a.name,
    _transaction: parent.key,
    _category: a.category?.key ?? 0,
    _value: a.value,
    _index: listIndex,
    _timestamp: a.timestamp?.millisecondsSinceEpoch,
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
    timestamp: fromTimestamp(map[_timestamp]),
  );
}

extension AllocationsTransactionExtension on Transaction {
  /// This modifies the allocation's key in-place!
  Future<void> _insertAllocation({
    required lt.Transaction parent,
    required Allocation allocation,
    required int listIndex,
  }) async {
    allocation.key = await insert(
      allocationsTable,
      _toMap(parent, allocation, listIndex),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> _deleteAllocation(Allocation allocation) {
    return delete(allocationsTable, where: "$_key = ?", whereArgs: [allocation.key]);
  }

  /// This modifies the allocation's key in-place!
  Future<void> addAllocation({required lt.Transaction parent, required int index}) async {
    if (parent.account == null) return;
    if (parent.allocations == null) return;
    if (index >= parent.allocations!.length) return;
    final alloc = parent.allocations![index];
    if (alloc.category == null) return;

    await _insertAllocation(parent: parent, allocation: alloc, listIndex: index);

    final signedValue = (parent.value < 0) ? -alloc.value : alloc.value;
    await updateCategoryHistory(
      account: parent.account!.key,
      category: parent.category.key,
      date: alloc.timestamp ?? parent.date,
      delta: -signedValue,
    );
    await updateCategoryHistory(
      account: parent.account!.key,
      category: alloc.category!.key,
      date: alloc.timestamp ?? parent.date,
      delta: signedValue,
    );
  }

  Future<void> deleteAllocation({required lt.Transaction parent, required int index}) async {
    if (parent.account == null) return;
    if (parent.allocations == null) return;
    if (index >= parent.allocations!.length) return;
    final alloc = parent.allocations![index];
    if (alloc.category == null) return;

    await _deleteAllocation(alloc);

    await shiftAllocationListIndicies(
      transKey: parent.key,
      start: index,
      end: parent.allocations!.length,
      delta: -1,
    );

    final signedValue = (parent.value < 0) ? -alloc.value : alloc.value;
    await updateCategoryHistory(
      account: parent.account!.key,
      category: parent.category.key,
      date: alloc.timestamp ?? parent.date,
      delta: signedValue,
    );
    await updateCategoryHistory(
      account: parent.account!.key,
      category: alloc.category!.key,
      date: alloc.timestamp ?? parent.date,
      delta: -signedValue,
    );
  }

  /// Start is inclusive, end is exclusive
  Future<int> shiftAllocationListIndicies({
    required int transKey,
    required int start,
    required int end,
    required int delta,
  }) {
    return rawUpdate(
      "UPDATE $allocationsTable "
      "SET $_index = $_index + ? "
      "WHERE $_transaction = ? AND $_index >= ? AND $_index < ?",
      [delta, transKey, start, end],
    );
  }

  Future<void> unsetCategoryFromAllAllocations(Category cat) async {
    final superKey = cat.type == ExpenseFilterType.income
        ? Category.income.key
        : Category.expense.key;
    await rawUpdate(
      "UPDATE $allocationsTable "
      "SET $_category = $superKey "
      "WHERE $_category = ${cat.key}",
    );
  }
}

extension AllocationsDatabaseExtension on DatabaseExecutor {
  Future<List<Allocation>> loadAllocations(
    int transactionKey,
    Map<int, Category> categories,
  ) async {
    final maps = await query(
      allocationsTable,
      where: "$_transaction = ?",
      whereArgs: [transactionKey],
      orderBy: _index,
    );
    return [for (final map in maps) _fromMap(categories, map)];
  }

  /// Returns every allocation as a map from transaction key to the allocations. Probably excessive...
  Future<Map<int, List<Allocation>>> loadAllAllocations(Map<int, Category> categories) async {
    final out = <int, List<Allocation>>{};

    final maps = await query(allocationsTable, orderBy: "$_transaction, $_index");

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
}
