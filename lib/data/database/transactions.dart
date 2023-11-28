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
      await insertAllocation(t, t.allocations![i], listIndex: i);
    }
  }

  // reimbursements
}

Map<int, Transaction> load(TransactionFilters filters) {
  Map<int, Transaction> out = {};
  final q = _createQuery(filters);

  libraDatabase?.transaction((txn) async {
    final rows = txn.rawQuery(q.$1, q.$2);
    print(rows);
  });
  return out;
}

class TransactionFilters {
  int? minValue;
  int? maxValue;
  DateTime? startDate;
  DateTime? endDate;
  Account? account;
  Category? category;
  int? limit;

  TransactionFilters({
    this.minValue,
    this.maxValue,
    this.startDate,
    this.endDate,
    this.account,
    this.category,
    this.limit = 300,
  });
}

(String, List) _createQuery(TransactionFilters filters) {
  var q = '''
    SELECT 
      t.*,
      GROUP_CONCAT(a.$allocationsKey) 
    FROM 
      $transactionsTable t
    INNER JOIN 
      $allocationsTable a on a.$allocationsTransaction = t.$_key
  ''';

  var firstWhere = true;
  void add(String query) {
    if (firstWhere) {
      q += " WHERE $query";
      firstWhere = false;
    } else {
      q += " AND $query";
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
  if (filters.startDate != null) {
    add("$_date >= ?");
    args.add(filters.startDate!.millisecondsSinceEpoch);
  }
  if (filters.endDate != null) {
    add("$_date <= ?");
    args.add(filters.endDate!.millisecondsSinceEpoch);
  }
  if (filters.account != null) {
    add("$_account = ?");
    args.add(filters.account!.key);
  }
  if (filters.category != null) {
    add("$_category = ?");
    args.add(filters.category!.key);
  }
  q += " GROUP BY a.$allocationsTransaction";

  q += " ORDER BY date DESC";
  if (filters.limit != null) {
    q += " LIMIT ?";
    args.add(filters.limit);
  }
  debugPrint("TransactionFilters::createQuery() $q");
  return (q, args);
}
