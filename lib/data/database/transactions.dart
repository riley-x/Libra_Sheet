import 'dart:async';

import 'package:libra_sheet/data/database/allocations.dart';
import 'package:libra_sheet/data/database/category_history.dart';
import 'package:libra_sheet/data/database/libra_database.dart';
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

const _reimb_total = "reimb_total";

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
    _category: t.category.key,
  };
  if (t.key != 0) {
    map[_key] = t.key;
  }
  return map;
}

Transaction transactionFromMap(
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
  final defaultCategory = Category.empty;

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
    totalReimbusrements: map[_reimb_total] ?? 0,
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
  await txn.updateCategoryHistory(
    account: t.account!.key,
    category: t.category.key,
    date: t.date,
    delta: t.value,
  );

  for (final tag in t.tags) {
    await txn.insertTagJoin(t, tag);
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
  await txn.removeAllTagsFrom(t);

  if (t.account != null) {
    await txn.updateCategoryHistory(
      account: t.account!.key,
      category: t.category.key,
      date: t.date,
      delta: -t.value,
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

/// When the relevant linking objects are not present in the maps:
///     account => null
///     category => Category.income or Category.expense
///     tag => null
///
/// Also, the following are always null
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
  required Map<int, Account> accounts,
  required Map<int, Category> categories,
  required Map<int, Tag> tags,
}) async {
  List<Transaction> out = [];
  if (libraDatabase == null) return out;

  final q = _createQuery(filters);
  final rows = await libraDatabase!.transaction((txn) async {
    return await txn.rawQuery(q.$1, q.$2);
  });

  for (final row in rows) {
    out.add(transactionFromMap(
      row,
      accounts: accounts,
      categories: categories,
      tags: tags,
    ));
  }

  return out;
}

/// Loads the allocations and reimbursements for this transaction, modifies in-place.
Future<void> loadTransactionRelations(
  Transaction t, {
  required Map<int, Account> accounts,
  required Map<int, Category> categories,
  required Map<int, Tag> tags,
}) async {
  await libraDatabase!.transaction((txn) async {
    if (t.nAllocations > 0) {
      t.allocations = await loadAllocations(t.key, categories, txn);
    } else {
      t.allocations = [];
    }
    if (t.totalReimbusrements > 0) {
      t.reimbursements = await loadReimbursements(
        parent: t,
        accounts: accounts,
        categories: categories,
        tags: tags,
        db: txn,
      );
    } else {
      t.reimbursements = [];
    }
  });
}

(String, List) _createQuery(TransactionFilters filters) {
  /// The GROUP_CONCAT(DISTINCT) is necessary since if you have multiple allocations or reimbursements,
  /// the tags will be duplicated accordingly.
  var q = '''
    SELECT 
      t.*,
      GROUP_CONCAT(DISTINCT tag.$tagKey) as tags,
      COUNT(a.$allocationsKey) as nAllocs,
      SUM(r.$reimbValue) as $_reimb_total
    FROM 
      $transactionsTable t
    LEFT OUTER JOIN 
      $tagJoinTable tag_join ON tag_join.$tagJoinTrans = t.$_key
    LEFT OUTER JOIN
      $tagsTable tag ON tag.$tagKey = tag_join.$tagJoinTag
    LEFT OUTER JOIN 
      $allocationsTable a ON a.$allocationsTransaction = t.$_key
    LEFT OUTER JOIN
      $reimbursementsTable r ON t.$_key = (CASE WHEN (t.$_value > 0) then r.$reimbIncome else r.$reimbExpense END)
  ''';

  List args = [];

  /// Add a single query to a global WHERE-AND clause ///
  var firstWhere = true;
  void add(String query) {
    if (firstWhere) {
      q += " WHERE $query";
      firstWhere = false;
    } else {
      q += " AND $query";
    }
  }

  /// Basic filters ///
  if (filters.name != null && filters.name!.isNotEmpty) {
    add("(UPPER(t.$_name) LIKE UPPER(?) OR UPPER(t.$_note) LIKE UPPER(?))");
    final wc = "%${filters.name}%";
    args.add(wc);
    args.add(wc);
  }
  if (filters.minValue != null) {
    add("t.$_value >= ?");
    args.add(filters.minValue);
  }
  if (filters.maxValue != null) {
    add("t.$_value <= ?");
    args.add(filters.maxValue);
  }
  if (filters.startTime != null) {
    add("t.$_date >= ?");
    args.add(filters.startTime!.millisecondsSinceEpoch);
  }
  if (filters.endTime != null) {
    add("t.$_date <= ?");
    args.add(filters.endTime!.millisecondsSinceEpoch);
  }
  if (filters.accounts.isNotEmpty) {
    add("t.$_account in (${List.filled(filters.accounts.length, '?').join(',')})");
    args.addAll(filters.accounts.map((e) => e.key));
  }

  /// Group by transaction (so aggregate the tags/allocs per transaction) ///
  q += " GROUP BY t.$_key";

  /// Tags and Categories ///
  // Here rows with the correct tag/alloc are assigned 1, and then we max over each transaction to
  // see if there was at least one 1.
  var categories = filters.categories.activeKeys();
  bool firstHaving = true;
  if (categories.isNotEmpty) {
    firstHaving = false;
    if (categories.contains(Category.empty.key)) {
      categories = List.of(categories) + [Category.income.key, Category.expense.key];
    }

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
