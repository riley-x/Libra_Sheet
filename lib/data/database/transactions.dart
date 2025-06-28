/// This file contains database query/manipulation functions related to transactions.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filters.dart';
import 'package:libra_sheet/data/database/allocations.dart';
import 'package:libra_sheet/data/database/category_history.dart';
import 'package:libra_sheet/data/database/reimbursements.dart';
import 'package:libra_sheet/data/database/tags.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/objects/tag.dart';
import 'package:libra_sheet/data/objects/transaction.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as db;

const transactionsTable = "`transactions_table`";

/// Column names
const _key = "id";
const _name = "name";
const _date = "date";
const _value = "value";
const _note = "note";
const _account = "account_id";
const _category = "category_id";

const _allocCategoryKeys = "alloc_categories";
const _allocValues = "alloc_values";
const _allocNames = "alloc_names";
const _reimbTotal = "reimb_total";

/// Public alias column names
const transactionKey = _key;
const transactionName = _name;
const transactionDate = _date;
const transactionValue = _value;
const transactionNote = _note;
const transactionAccount = _account;
const transactionCategory = _category;

const createTransactionsTableSql =
    "CREATE TABLE IF NOT EXISTS $transactionsTable ("
    "$_key INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "
    "$_name TEXT NOT NULL, "
    "$_date INTEGER NOT NULL, "
    "$_note TEXT NOT NULL, "
    "$_value INTEGER NOT NULL, "
    "$_account INTEGER NOT NULL, "
    "$_category INTEGER NOT NULL)";

//----------------------------------------------------------------------
// Sqflite conversions
//----------------------------------------------------------------------
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

List<Tag> parseTags(String? string, Map<int, Tag>? tags) {
  List<Tag> tagList = [];
  if (string == null) return tagList;
  if (tags == null) return tagList;
  for (final strkey in string.split(',')) {
    final intKey = int.tryParse(strkey);
    if (intKey == null) continue;
    final tag = tags[intKey];
    if (tag == null) continue;
    tagList.add(tag);
  }
  return tagList;
}

List<SoftAllocation> parseAllocs(Map<String, dynamic> map, Map<int, Category>? categories) {
  String? categoryKeysStr = map[_allocCategoryKeys];
  String? valuesStr = map[_allocValues];
  if (categoryKeysStr == null || valuesStr == null) return const [];

  final categoryKeys = categoryKeysStr.split(',');
  final values = valuesStr.split(',');

  if (categoryKeys.length != values.length) {
    assert(false);
    return [];
  }

  final out = <SoftAllocation>[];
  for (int i = 0; i < values.length; i++) {
    final key = int.tryParse(categoryKeys[i]);
    assert(key != null);
    if (key == null) continue;

    final category = categories?[key];
    assert(category != null);
    if (category == null) continue;

    final value = int.tryParse(values[i]);
    assert(value != null);
    if (value == null) continue;

    out.add(SoftAllocation(category: category, value: value));
  }
  return out;
}

Transaction transactionFromMap(
  Map<String, dynamic> map, {
  Map<int, Account>? accounts,
  Map<int, Category>? categories,
  Map<int, Tag>? tags,
}) {
  return Transaction(
    key: map[_key],
    name: map[_name],
    date: DateTime.fromMillisecondsSinceEpoch(map[_date], isUtc: true),
    note: map[_note],
    value: map[_value],
    account: accounts?[map[_account]],
    category: categories?[map[_category]] ?? Category.empty,
    tags: parseTags(map['tags'], tags),
    softAllocations: parseAllocs(map, categories),
    totalReimbusrements: map[_reimbTotal] ?? 0,
  );
}

//----------------------------------------------------------------------
// Modify a single transaction
//----------------------------------------------------------------------

extension TransactionExtension on db.Transaction {
  /// Inserts a transaction with its tags, allocations, and reimbursements. Note this function will
  /// set the transaction's key in-place!
  Future<void> insertTransaction(Transaction t) async {
    t.key = await insert(
      transactionsTable,
      _toMap(t),
      conflictAlgorithm: db.ConflictAlgorithm.replace,
    );
    await updateCategoryHistory(
      account: t.account!.key,
      category: t.category.key,
      date: t.date,
      delta: t.value,
    );

    for (final tag in t.tags) {
      await insertTagJoin(t, tag);
    }
    if (t.allocations != null) {
      for (int i = 0; i < t.allocations!.length; i++) {
        await addAllocation(parent: t, index: i);
      }
    }
    if (t.reimbursements != null) {
      for (final r in t.reimbursements!) {
        await addReimbursement(r, parent: t);
      }
    }
  }

  Future<void> deleteTransaction(Transaction t) async {
    if (t.reimbursements != null) {
      for (final r in t.reimbursements!) {
        await deleteReimbursement(r, parent: t);
      }
    }
    if (t.allocations != null) {
      for (int i = 0; i < t.allocations!.length; i++) {
        await deleteAllocation(parent: t, index: i);
      }
    }
    await removeAllTagsFrom(t);

    if (t.account != null) {
      await updateCategoryHistory(
        account: t.account!.key,
        category: t.category.key,
        date: t.date,
        delta: -t.value,
      );
    }
    await delete(transactionsTable, where: "$_key = ?", whereArgs: [t.key]);
  }

  Future<void> updateTransaction(Transaction old, Transaction nu) async {
    await deleteTransaction(old);
    await insertTransaction(nu);
  }

  /// Loads the allocations and reimbursements for this transaction, modifies in-place.
  Future<void> loadTransactionRelations(
    Transaction t, {
    required Map<int, Account> accounts,
    required Map<int, Category> categories,
    required Map<int, Tag> tags,
  }) async {
    if (t.nAllocations > 0) {
      t.allocations = await loadAllocations(t.key, categories);
    } else {
      t.allocations = [];
    }
    if (t.totalReimbusrements > 0) {
      t.reimbursements = await loadReimbursements(
        parent: t,
        accounts: accounts,
        categories: categories,
        tags: tags,
      );
    } else {
      t.reimbursements = [];
    }
  }
}

extension TransactionDatabaseExtension on db.DatabaseExecutor {
  /// Main function to load transactions given a set of filters.
  ///
  /// When the relevant linking objects are not present in the maps:
  ///     account => null
  ///     category => Category.income or Category.expense
  ///     tag => null
  ///
  /// Also, the following are always null
  ///     allocations (but sets softAllocations)
  ///     reimbursements (but sets totalReimbusrements)
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
    final q = _createQueryFromFilters(filters);
    final rows = await rawQuery(q.$1, q.$2);

    List<Transaction> out = [];
    for (final row in rows) {
      out.add(transactionFromMap(row, accounts: accounts, categories: categories, tags: tags));
    }
    return out;
  }

  Future<Transaction?> loadTransactionByKey(
    int key, {
    required Map<int, Account> accounts,
    required Map<int, Category> categories,
    required Map<int, Tag> tags,
  }) async {
    final q = createTransactionQuery(tagWhere: "WHERE t.$_key = ?");
    final args = [key];
    final rows = await rawQuery(q, args);

    for (final row in rows) {
      final t = transactionFromMap(row, accounts: accounts, categories: categories, tags: tags);
      if (t.key == key) return t;
    }
    return null;
  }

  /// Loads transactions given a list of [keys] but applies no other filtering.
  Future<Map<int, Transaction>> loadTransactionsByKey(
    Iterable<int> keys, {
    required Map<int, Account> accounts,
    required Map<int, Category> categories,
    required Map<int, Tag> tags,
  }) async {
    final q = createTransactionQuery(
      tagWhere: "WHERE t.$_key in (${List.filled(keys.length, '?').join(',')})",
    );
    final args = List.from(keys);
    final rows = await rawQuery(q, args);

    Map<int, Transaction> out = {};
    for (final row in rows) {
      final t = transactionFromMap(row, accounts: accounts, categories: categories, tags: tags);
      out[t.key] = t;
    }
    return out;
  }

  /// Gets every transaction from the database. To deal with the relations easily, we only load soft
  /// fields in [TransactionWithSoftRelations], containing the info needed for the CSV output.
  Future<List<TransactionWithSoftRelations>> loadAllTransactionsForCsv({
    required Map<int, Account> accounts,
    required Map<int, Category> categories,
    required Map<int, Tag> tags,
  }) async {
    /// To get the soft relation values, we use GROUP_CONCAT on the reimbursements and and allocations.
    /// The target values are:
    ///   - Allocation: name, category, value
    ///   - Reimbursement: other transaction's key, value
    /// The value are separated by a ':' and GROUP_CONCAT defaults to separating each entry with ','.
    /// Thus we need to be extra careful about deal with the commas and colon separators in the
    /// allocation names (the other fields are all ints). Simply replace them with #COLON or #COMMA
    /// as magic texts that hopefully never appear naturally.
    const colonReplacement = '#COLON';
    const commaReplacement = '#COMMA';
    const q =
        '''
        SELECT 
          t.*,
          GROUP_CONCAT(
            (CASE WHEN (t.$_value > 0) then r.$reimbExpense else r.$reimbIncome END) 
            || ':' || r.$reimbValue
          ) as reimbs
        FROM (
          SELECT 
            t.*,
            GROUP_CONCAT(
              REPLACE(REPLACE(a.$allocationsName, ',', '$commaReplacement'), ':', '$colonReplacement') 
              || ':' || a.$allocationsCategory 
              || ':' || a.$allocationsValue
            ) as allocs
          FROM (
            SELECT 
              t.*,
              GROUP_CONCAT(tag.$tagKey) as tags
            FROM 
              $transactionsTable t
            LEFT OUTER JOIN 
              $tagJoinTable tag_join ON tag_join.$tagJoinTrans = t.$_key
            LEFT OUTER JOIN
              $tagsTable tag ON tag.$tagKey = tag_join.$tagJoinTag
            GROUP BY
              t.$_key
          ) t
          LEFT OUTER JOIN 
            $allocationsTable a ON a.$allocationsTransaction = t.$_key
          GROUP BY
            t.$_key
        ) t
        LEFT OUTER JOIN
          $reimbursementsTable r ON t.$_key = (CASE WHEN (t.$_value > 0) then r.$reimbIncome else r.$reimbExpense END)
        GROUP BY
          t.$_key
        ORDER BY date, $_key
    ''';
    final rows = await rawQuery(q);

    TransactionWithSoftRelations transactionFromMapSoft(
      Map<String, dynamic> map, {
      Map<int, Account>? accounts,
      Map<int, Category>? categories,
      Map<int, Tag>? tags,
    }) {
      /// Parse the allocations
      String? allocString = map['allocs'];
      List<CsvAllocation> allocs = [];
      if (allocString != null && categories != null) {
        for (final allocEntry in allocString.split(',')) {
          final fields = allocEntry.split(':');
          if (fields.length != 3) {
            debugPrint("Alloc entry doesn't have 3 fields, transaction:\n\t$map");
            continue;
          }

          final categoryKey = int.tryParse(fields[1]) ?? 0;
          allocs.add(
            CsvAllocation(
              name: fields[0].replaceAll(commaReplacement, ',').replaceAll(colonReplacement, ':'),
              category: categories[categoryKey]?.name ?? 'Unkown',
              value: int.tryParse(fields[2]) ?? 0,
            ),
          );
        }
      }

      /// Parse the reimbursements
      String? reimbString = map['reimbs'];
      List<(int, int)> reimbs = [];
      if (reimbString != null) {
        for (final entry in reimbString.split(',')) {
          final fields = entry.split(':');
          if (fields.length != 2) {
            debugPrint("Reimb entry doesn't have 2 fields, transaction:\n\t$map");
            continue;
          }

          reimbs.add((int.tryParse(fields[0]) ?? 0, int.tryParse(fields[1]) ?? 0));
        }
      }

      return TransactionWithSoftRelations(
        Transaction(
          key: map[_key],
          name: map[_name],
          date: DateTime.fromMillisecondsSinceEpoch(map[_date], isUtc: true),
          note: map[_note],
          value: map[_value],
          account: accounts?[map[_account]],
          category: categories?[map[_category]] ?? Category.empty,
          tags: parseTags(map['tags'], tags),
          totalReimbusrements: 0,
        ),
        allocs,
        reimbs,
      );
    }

    /// Parse final list
    List<TransactionWithSoftRelations> out = [];
    for (final row in rows) {
      final t = transactionFromMapSoft(row, accounts: accounts, categories: categories, tags: tags);
      out.add(t);
    }
    return out;
  }

  /// Sets the category to income/expense for all transactions
  Future<int> unsetCategoryFromAllTransactions(int categoryKey) {
    return rawUpdate(
      "UPDATE $transactionsTable "
      "SET $_category = (CASE WHEN $_value > 0 THEN ${Category.income.key} ELSE ${Category.expense.key} END) "
      "WHERE $_category = ?",
      [categoryKey],
    );
  }
}

/// Creates the base query to fetch a [Transaction] from the [transactionsTable]. The statement
/// consists of three nested select statements, from innermost to outermost:
///   1. [transactionsTable] joined with [tagsTable]; tag keys grouped into "tags" with GROUP_CONCAT
///   2. Above joined with [allocationsTable]; a few fields like [_allocValues] GROUP_CONCAT together.
///   3. Above joined with [reimbursementsTable]; total reimbursements summed into [_reimbTotal]
///
/// The optional parameters can add extra filters. Ensure that you add the SQL keywords though; they
/// are not added automatically!
///
/// [innerTable] replaces the [transactionsTable] statement in (1). Do not set an alias for
///     the replacement, but do add parentheses if it's a nested SELECT.
/// [tagWhere] is the WHERE clause for step (1)
/// [tagHaving] is the HAVING clause for step (1)
/// and so on.
String createTransactionQuery({
  String? innerTable,
  String tagWhere = '',
  String tagHaving = '',
  String allocHaving = '',
  String reimbHaving = '',
  String limit = '',
}) {
  return '''
    SELECT 
      t.*,
      SUM(r.$reimbValue) as $_reimbTotal
    FROM (
      SELECT 
        t.*,
        GROUP_CONCAT(a.$allocationsCategory) as $_allocCategoryKeys,
        GROUP_CONCAT(a.$allocationsValue) as $_allocValues,
        GROUP_CONCAT(a.$allocationsName, 0x1E) as $_allocNames
      FROM (
        SELECT 
          t.*,
          GROUP_CONCAT(tag.$tagKey) as tags
        FROM 
          ${innerTable ?? transactionsTable} t
        LEFT OUTER JOIN 
          $tagJoinTable tag_join ON tag_join.$tagJoinTrans = t.$_key
        LEFT OUTER JOIN
          $tagsTable tag ON tag.$tagKey = tag_join.$tagJoinTag
        $tagWhere
        GROUP BY
          t.$_key
        $tagHaving
      ) t
      LEFT OUTER JOIN 
        $allocationsTable a ON a.$allocationsTransaction = t.$_key
      GROUP BY
        t.$_key
      $allocHaving
    ) t
    LEFT OUTER JOIN
      $reimbursementsTable r ON t.$_key = (CASE WHEN (t.$_value > 0) then r.$reimbIncome else r.$reimbExpense END)
    GROUP BY
      t.$_key
    $reimbHaving
    ORDER BY date DESC, $_key DESC
    $limit
    ''';
}

/// Helper for [loadTransactions] that creates the query and args from [filters].
(String, List) _createQueryFromFilters(TransactionFilters filters) {
  List args = [];

  /// Basic filters (innermost where clause) ///
  String tagWhere = '';
  void addTagWhere(String query) {
    if (tagWhere.isEmpty) {
      tagWhere = "WHERE $query";
    } else {
      tagWhere += " AND $query";
    }
  }

  if (filters.minValue != null) {
    addTagWhere("t.$_value >= ?");
    args.add(filters.minValue);
  }
  if (filters.maxValue != null) {
    addTagWhere("t.$_value <= ?");
    args.add(filters.maxValue);
  }
  if (filters.startTime != null) {
    addTagWhere("t.$_date >= ?");
    args.add(filters.startTime!.millisecondsSinceEpoch);
  }
  if (filters.endTime != null) {
    addTagWhere("t.$_date <= ?");
    args.add(filters.endTime!.millisecondsSinceEpoch);
  }
  if (filters.accounts.isNotEmpty) {
    addTagWhere("t.$_account in (${List.filled(filters.accounts.length, '?').join(',')})");
    args.addAll(filters.accounts.map((e) => e.key));
  }

  /// Tags ///
  /// Here rows with the correct tag are assigned 1, and then we max over each transaction to
  /// see if there was at least one 1.
  var tagHaving = '';
  if (filters.tags.isNotEmpty) {
    tagHaving = "HAVING max( CASE tag.$tagKey";
    for (final tag in filters.tags) {
      tagHaving += " WHEN ? THEN 1";
      args.add(tag.key);
    }
    tagHaving += " ELSE 0 END ) = 1";
  }

  /// Categories ///
  /// These must be done together during the allocation group-by HAVING clause.
  var allocHaving = '';
  void addAllocHaving(String query) {
    if (allocHaving.isEmpty) {
      allocHaving = "HAVING $query";
    } else {
      allocHaving += " AND $query";
    }
  }

  var categories = filters.categories.activeKeys();
  if (categories.isNotEmpty) {
    /// Include [Category.income] and [Category.expense] if the filter calls for [Category.empty].
    if (categories.contains(Category.empty.key)) {
      categories = List.of(categories) + [Category.income.key, Category.expense.key];
    }

    /// When transaction category is in the list
    var q = "(t.$_category in (${List.filled(categories.length, '?').join(',')})";
    args.addAll(categories);

    /// When transaction has an allocation category in the list
    q += " OR max(CASE a.$allocationsCategory";
    for (final cat in categories) {
      q += " WHEN ? THEN 1";
      args.add(cat);
    }
    q += " ELSE 0 END) = 1)";

    addAllocHaving(q);
  }

  /// Allocations ///
  if (filters.hasAllocation == true) {
    addAllocHaving("COUNT(a.$allocationsKey) > 0");
  }

  /// Text search ///
  if (filters.name != null && filters.name!.isNotEmpty) {
    addAllocHaving("(t.$_name LIKE ? OR t.$_note LIKE ? OR $_allocNames LIKE ?)");
    final wc = "%${filters.name}%";
    args.add(wc);
    args.add(wc);
    args.add(wc);
  }

  /// Reimbursements ///
  var reimbHaving = '';
  if (filters.hasReimbursement == true) {
    reimbHaving = "HAVING COUNT(r.$reimbIncome) > 0";
  }

  /// Order and limit ///
  String limit = '';
  if (filters.limit != null) {
    limit = " LIMIT ?";
    args.add(filters.limit);
  }

  /// Get query ///
  final q = createTransactionQuery(
    tagWhere: tagWhere,
    tagHaving: tagHaving,
    allocHaving: allocHaving,
    reimbHaving: reimbHaving,
    limit: limit,
  );
  return (q, args);
}
