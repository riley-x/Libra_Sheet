import 'dart:async';

import 'package:libra_sheet/data/database/accounts.dart';
import 'package:libra_sheet/data/database/allocations.dart';
import 'package:libra_sheet/data/database/category_history.dart';
import 'package:libra_sheet/data/database/database_setup.dart';
import 'package:libra_sheet/data/database/reimbursements.dart';
import 'package:libra_sheet/data/database/tags.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/objects/tag.dart';
import 'package:libra_sheet/data/objects/transaction.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filter_state.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as db;

const transactionsTable = "`transactions_table`";

const _key = "id";
const _name = "name";
const _date = "date";
const _value = "value";
const _note = "note";
const _account = "account_id";
const _category = "category_id";

const transactionKey = _key;
const transactionName = _name;
const transactionDate = _date;
const transactionValue = _value;
const transactionNote = _note;
const transactionAccount = _account;
const transactionCategory = _category;

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
  Map<int, Tag>? tags,
}) {
  String? tagString = map['tags'];
  List<Tag> tagList = [];
  if (tags != null && tagString != null) {
    for (final strkey in tagString.split(',')) {
      final intKey = int.tryParse(strkey);
      if (intKey == null) continue;
      final tag = tags[intKey];
      if (tag == null) continue;
      tagList.add(tag);
    }
  }

  final value = map[_value];

  /// This can happen if the category has been deleted.
  final defaultCategory = (value > 0) ? Category.income : Category.expense;

  return Transaction(
    key: map[_key],
    name: map[_name],
    date: DateTime.fromMillisecondsSinceEpoch(map[_date], isUtc: true),
    note: map[_note],
    value: value,
    account: accounts?[map[_account]],
    category: categories?[map[_category]] ?? defaultCategory,
    tags: tagList,
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
  await updateBalance(t.account!.key, t.value, db: txn);
  await updateCategoryHistory(
    account: t.account!.key,
    category: t.category!.key,
    date: t.date,
    delta: t.value,
    txn: txn,
  );

  if (t.tags != null) {
    for (final tag in t.tags!) {
      await insertTagJoin(t, tag, db: txn);
    }
  }
  if (t.allocations != null) {
    for (int i = 0; i < t.allocations!.length; i++) {
      await addAllocation(parent: t, index: i, txn: txn);
    }
  }
  if (t.reimbursements != null) {
    for (final r in t.reimbursements!) {
      await addReimbursement(r, parent: t, txn: txn);
    }
  }
}

Future<void> deleteTransaction(Transaction t, {db.Transaction? txn}) async {
  if (txn == null) {
    return libraDatabase?.transaction((txn) async => await deleteTransaction(t, txn: txn));
  }

  if (t.reimbursements != null) {
    for (final r in t.reimbursements!) {
      await deleteReimbursement(r, parent: t, txn: txn);
    }
  }
  if (t.allocations != null) {
    for (int i = 0; i < t.allocations!.length; i++) {
      await deleteAllocation(parent: t, index: i, txn: txn);
    }
  }
  await deleteAllTags(t, db: txn);

  if (t.account != null) {
    // TODO this can happen if the account is deleted, should delete all corresponding transactions
    await updateBalance(t.account!.key, -t.value, db: txn);
  }
  if (t.account != null && t.category != null) {
    // TODO this can happen if the category is deleted, should switch all affected transactions/allocs
    // to default category (in database? or soft?). And delete all rules.
    await updateCategoryHistory(
      account: t.account!.key,
      category: t.category!.key,
      date: t.date,
      delta: -t.value,
      txn: txn,
    );
  }
  await txn.delete(
    transactionsTable,
    where: "$_key = ?",
    whereArgs: [t.key],
  );
}

Future<void> updateTransaction(Transaction old, Transaction nu, {db.Transaction? txn}) async {
  if (txn == null) {
    return libraDatabase?.transaction((txn) async => await updateTransaction(old, nu, txn: txn));
  }
  await deleteTransaction(old, txn: txn);
  await insertTransaction(nu, txn: txn);
}

/// Note that this leaves the following null:
///     account, if not present in [accounts]
///     category, if not present in [categories]
///     tags[i], for each tag not present in [tags]
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
  Map<int, Tag>? tags,
}) async {
  List<Transaction> out = [];
  if (libraDatabase == null) return out;

  final q = _createQuery(filters);
  final rows = await libraDatabase!.transaction((txn) async {
    return await txn.rawQuery(q.$1, q.$2);
  });

  for (final row in rows) {
    out.add(_fromMap(
      row,
      accounts: accounts,
      categories: categories,
      tags: tags,
    ));
  }

  return out;
}

/// Loads the allocations and reimbursements for this transaction, modifies in-place.
Future<void> loadTransactionRelations(Transaction t, Map<int, Category> categories) async {
  await libraDatabase!.transaction((txn) async {
    t.allocations = await loadAllocations(t.key, categories, txn);
    t.reimbursements = await loadReimbursements(t, categories, txn);
  });
}

(String, List) _createQuery(TransactionFilters filters) {
  var q = '''
    SELECT 
      t.*,
      GROUP_CONCAT(tag.$tagKey) as tags,
      COUNT(a.$allocationsKey) as nAllocs
    FROM 
      $transactionsTable t
    LEFT OUTER JOIN 
      $tagJoinTable tag_join on tag_join.$tagJoinTrans = t.$_key
    LEFT OUTER JOIN
      $tagsTable tag on tag.$tagKey = tag_join.$tagJoinTag
    LEFT OUTER JOIN 
      $allocationsTable a on a.$allocationsTransaction = t.$_key
  ''';

  List args = [];

  /// Add a single query to a global WHERE-AND clause ///
  var firstWhere = true;
  void add(String query) {
    if (firstWhere) {
      q += " WHERE t.$query";
      firstWhere = false;
    } else {
      q += " AND t.$query";
    }
  }

  /// Basic filters ///
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
  if (filters.accounts.isNotEmpty) {
    add("$_account in (${List.filled(filters.accounts.length, '?').join(',')})");
    args.addAll(filters.accounts.map((e) => e.key));
  }

  /// Group by transaction (so aggregate the tags/allocs per transaction) ///
  q += " GROUP BY t.$_key";

  /// Tags and Categories ///
  // Here rows with the correct tag/alloc are assigned 1, and then we max over each transaction to
  // see if there was at least one 1.
  final categories = filters.categories.activeKeys();
  bool firstHaving = true;
  if (categories.isNotEmpty) {
    firstHaving = false;

    /// When transaction category is in the list
    q += " HAVING (t.$_category in (${List.filled(categories.length, '?').join(',')})";
    args.addAll(categories);

    /// When transaction has an allocation category in the list
    q += " OR max(CASE a.$allocationsCategory";
    for (final cat in categories) {
      q += " WHEN ? THEN 1";
      args.add(cat);
    }
    q += " ELSE 0 END) = 1)";
  }

  if (filters.tags.isNotEmpty) {
    if (firstHaving) {
      firstHaving = false;
      q += " HAVING";
    } else {
      q += " AND";
    }
    q += " max( CASE tag.$tagKey";
    for (final tag in filters.tags) {
      q += " WHEN ? THEN 1";
      args.add(tag.key);
    }
    q += " ELSE 0 END ) = 1";
  }

  /// Order and limit ///
  q += " ORDER BY date DESC";
  if (filters.limit != null) {
    q += " LIMIT ?";
    args.add(filters.limit);
  }
  return (q, args);
}
