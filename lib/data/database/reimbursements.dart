import 'package:libra_sheet/data/database/category_history.dart';
import 'package:libra_sheet/data/database/transactions.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/objects/reimbursement.dart';
import 'package:libra_sheet/data/objects/tag.dart';
import 'package:libra_sheet/data/objects/transaction.dart' as lt;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const reimbursementsTable = "reimbursements";

const _expense = "expenseId";
const _income = "incomeId";
const _value = "value";

const reimbExpense = _expense;
const reimbIncome = _income;
const reimbValue = _value;

const createReimbursementsTableSql = "CREATE TABLE IF NOT EXISTS $reimbursementsTable ("
    "$_expense INTEGER NOT NULL, "
    "$_income INTEGER NOT NULL, "
    "$_value INTEGER NOT NULL, "
    "PRIMARY KEY($_expense, $_income))";

Map<String, dynamic> _toMap(lt.Transaction parent, Reimbursement r) {
  return {
    _income: (parent.value > 0) ? parent.key : r.target.key,
    _expense: (parent.value > 0) ? r.target.key : parent.key,
    _value: r.value,
  };
}

extension ReimbursementsTransactionExtension on Transaction {
  Future<int> _insert(
    Reimbursement r, {
    required lt.Transaction parent,
  }) {
    return insert(
      reimbursementsTable,
      _toMap(parent, r),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> _delete(
    Reimbursement r, {
    required lt.Transaction parent,
  }) {
    final income = (parent.value > 0) ? parent.key : r.target.key;
    final expense = (parent.value > 0) ? r.target.key : parent.key;
    return delete(
      reimbursementsTable,
      where: '$_expense = ? AND $_income = ?',
      whereArgs: [expense, income],
    );
  }

  /// This updates [r.commitedValue]!
  Future<void> addReimbursement(
    Reimbursement r, {
    required lt.Transaction parent,
  }) async {
    assert(parent.key != 0);
    assert(r.target.key != 0);
    assert(r.value >= 0);
    if (parent.account == null) throw StateError("addReimbursement() parent account is null");
    if (r.target.account == null) throw StateError("addReimbursement() target account is null");
    if (parent.value * r.target.value > 0) {
      throw StateError("addReimbursement() transactions have same sign");
    }

    await _insert(r, parent: parent);
    r.commitedValue = r.value;
    final income = (parent.value > 0) ? parent : r.target;
    final expense = (parent.value > 0) ? r.target : parent;

    /// Remove value from both transactions' original category
    await updateCategoryHistory(
      account: income.account!.key,
      category: income.category.key,
      date: income.date,
      delta: -r.value,
    );
    await updateCategoryHistory(
      account: expense.account!.key,
      category: expense.category.key,
      date: expense.date,
      delta: r.value,
    );

    /// Add value to "Ignore" category
    await updateCategoryHistory(
      account: income.account!.key,
      category: Category.ignore.key,
      date: income.date,
      delta: r.value,
    );
    await updateCategoryHistory(
      account: expense.account!.key,
      category: Category.ignore.key,
      date: expense.date,
      delta: -r.value,
    );
  }

  Future<void> deleteReimbursement(
    Reimbursement r, {
    required lt.Transaction parent,
  }) async {
    assert(parent.key != 0);
    assert(r.target.key != 0);
    assert(r.value >= 0);
    if (parent.account == null) throw StateError("deleteReimbursement() parent account is null");
    if (r.target.account == null) throw StateError("deleteReimbursement() target account is null");
    if (parent.value * r.target.value > 0) {
      throw StateError("deleteReimbursement() transactions have same sign");
    }

    await _delete(r, parent: parent);
    final income = (parent.value > 0) ? parent : r.target;
    final expense = (parent.value > 0) ? r.target : parent;

    /// Add value back to both transactions' original category
    await updateCategoryHistory(
      account: income.account!.key,
      category: income.category.key,
      date: income.date,
      delta: r.value,
    );
    await updateCategoryHistory(
      account: expense.account!.key,
      category: expense.category.key,
      date: expense.date,
      delta: -r.value,
    );

    /// Remove value from "Ignore" category
    await updateCategoryHistory(
      account: income.account!.key,
      category: Category.ignore.key,
      date: income.date,
      delta: -r.value,
    );
    await updateCategoryHistory(
      account: expense.account!.key,
      category: Category.ignore.key,
      date: expense.date,
      delta: r.value,
    );
  }
}

extension ReimbursementsDatabaseExtension on DatabaseExecutor {
  Future<List<Reimbursement>> loadReimbursements({
    required lt.Transaction parent,
    required Map<int, Account> accounts,
    required Map<int, Category> categories,
    required Map<int, Tag> tags,
  }) async {
    final parentColumn = (parent.value > 0) ? _income : _expense;
    final targetColumn = (parent.value > 0) ? _expense : _income;
    final innerTable = '''
    (
      SELECT
        t.*,
        reimbs.$_value as reimb_value
      FROM 
        $reimbursementsTable reimbs
      JOIN
        $transactionsTable t on t.$transactionKey = reimbs.$targetColumn
      WHERE
        reimbs.$parentColumn = ?
    )
  ''';
    final args = [parent.key];
    final q = createTransactionQuery(innerTable: innerTable);
    final maps = await rawQuery(q, args);
    return [
      for (final map in maps)
        Reimbursement(
          target: transactionFromMap(
            map,
            accounts: accounts,
            categories: categories,
            tags: tags,
          ),
          value: map["reimb_value"] as int,
          commitedValue: map["reimb_value"] as int,
        ),
    ];
  }
}
