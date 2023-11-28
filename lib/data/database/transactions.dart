import 'dart:async';

import 'package:flutter/material.dart';
import 'package:libra_sheet/data/database/allocations.dart';
import 'package:libra_sheet/data/database/database_setup.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/objects/transaction.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as db;

const transactionsTable = "`transactions_table`";

const _key = "id";
const _name = "name";
const _date = "date";
const _value = "value";
const _note = "note";
const _account = "account_id";
const _category = "category_id";

const createTransactionsTableSql = "CREATE TABLE IF NOT EXISTS $transactionsTable ("
    "$_key INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "
    "$_name TEXT NOT NULL, "
    "$_date INTEGER NOT NULL, "
    "$_note TEXT NOT NULL, "
    "$_value INTEGER NOT NULL, "
    "$_account INTEGER NOT NULL, "
    "$_category INTEGER NOT NULL)";

Map<String, dynamic> _toMap(Transaction t) {
  final map = {
    _name: t.name,
    _date: t.date.millisecondsSinceEpoch,
    _value: t.value,
    _note: t.note,
    _account: t.account?.key ?? 0,
    _category: t.category?.key ?? 0,
  };
  if (t.key != 0) {
    map[_key] = t.key;
  }
  return map;
}

Transaction _fromMap(
  Map<String, dynamic> map, {
  Map<int, Account>? accounts,
  Map<int, Category>? categories,
}) {
  return Transaction(
    key: map[_key],
    name: map[_name],
    date: DateTime.fromMillisecondsSinceEpoch(map[_date]),
    note: map[_note],
    value: map[_value],
    account: accounts?[map[_account]],
    category: categories?[map[_category]],
    nAllocations: map["nAllocs"],
  );
}

/// Inserts a transaction with its tags, allocations, and reimbursements. Note this function will
/// set the transaction's key in-place!
FutureOr<void> insertTransaction(Transaction t, {db.Transaction? txn}) async {
  if (txn == null) {
    return libraDatabase?.transaction((txn) async => await insertTransaction(t, txn: txn));
  }

  t.key = await txn.insert(
    transactionsTable,
    _toMap(t),
    conflictAlgorithm: db.ConflictAlgorithm.replace,
  );

  // update balance
  // update category history

  if (t.allocations != null) {
    for (int i = 0; i < (t.allocations!.length); i++) {
      await insertAllocation(t, t.allocations![i], listIndex: i, database: txn);
    }
  }

  // reimbursements
}

/// Note that this leaves the following null:
///     account, if not present in [accounts]
///     category, if not present in [categories]
///     tags
///     allocations (but sets nAllocs)
///     reimbursements (but sets nReimbs)
///
/// WARNING! Do not attempt to change this to an isolate using `compute()`. The database can't be
/// accessed. Looks like will have to live with jank for now...could maybe move the _fromMap
/// stuff to an isolate though.
///
/// https://stackoverflow.com/questions/56343611/insert-sqlite-flutter-without-freezing-the-interface
/// https://github.com/flutter/flutter/issues/13937
Future<List<Transaction>> loadTransactions(
  TransactionFilters filters, {
  Map<int, Account>? accounts,
  Map<int, Category>? categories,
}) async {
  List<Transaction> out = [];
  if (libraDatabase == null) return out;

  final q = _createQuery(filters);
  final rows = await libraDatabase!.transaction((txn) async {
    return await txn.rawQuery(q.$1, q.$2);
  });

  for (final row in rows) {
    out.add(_fromMap(row, accounts: accounts, categories: categories));
  }

  return out;
}

class TransactionFilters {
  int? minValue;
  int? maxValue;
  DateTime? startTime;
  DateTime? endTime;
  Account? account;
  Iterable<int>? categories;
  int? limit;

  TransactionFilters({
    this.minValue,
    this.maxValue,
    this.startTime,
    this.endTime,
    this.account,
    this.categories,
    this.limit = 300,
  });
}

(String, List) _createQuery(TransactionFilters filters) {
  var q = '''
    SELECT 
      t.*,
      COUNT(a.$allocationsKey) as nAllocs
    FROM 
      $transactionsTable t
    LEFT OUTER JOIN 
      $allocationsTable a on a.$allocationsTransaction = t.$_key
  ''';
  // GROUP_CONCAT(a.$allocationsKey) as allocs --> null or "1,2,3"

  var firstWhere = true;
  void add(String query) {
    if (firstWhere) {
      q += " WHERE t.$query";
      firstWhere = false;
    } else {
      q += " AND t.$query";
    }
  }

  List args = [];
  if (filters.minValue != null) {
    add("$_value >= ?");
    args.add(filters.minValue);
  }
  if (filters.maxValue != null) {
    add("$_value <= ?");
    args.add(filters.maxValue);
  }
  if (filters.startTime != null) {
    add("$_date >= ?");
    args.add(filters.startTime!.millisecondsSinceEpoch);
  }
  if (filters.endTime != null) {
    add("$_date <= ?");
    args.add(filters.endTime!.millisecondsSinceEpoch);
  }
  if (filters.account != null) {
    add("$_account = ?");
    args.add(filters.account!.key);
  }
  if (filters.categories != null && filters.categories!.isNotEmpty) {
    /// No list support in sqflite
    final n = filters.categories!.length;
    add("$_category in (${List.filled(n, '?').join(',')})");
    args.addAll(filters.categories!);
  }
  q += " GROUP BY t.$_key";

  q += " ORDER BY date DESC";
  if (filters.limit != null) {
    q += " LIMIT ?";
    args.add(filters.limit);
  }
  // debugPrint("TransactionFilters::createQuery() $q");
  return (q, args);
}
