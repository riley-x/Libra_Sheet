import 'package:flutter/material.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filters.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/database/libra_database.dart';
import 'package:libra_sheet/data/database/reimbursements.dart';
import 'package:libra_sheet/data/database/transactions.dart';
import 'package:libra_sheet/data/objects/transaction.dart';

/// Helper class for managing transactions. Every widget that monitors transactions should probably
/// watch this service, so that they can be notified when transactions are added or edited (which
/// affects all value-based entities and, because of reimbursements, can affect all other
/// transactions).
class TransactionService extends ChangeNotifier {
  final LibraAppState appState;
  TransactionService(this.appState);

  void _onUpdate() async {
    // This updates the monthsList, which is used downstream
    await appState.reloadAfterTransactions();
    notifyListeners();
  }

  Future<List<Transaction>> load(TransactionFilters filters) async {
    final ts = await loadTransactions(
      filters,
      accounts: appState.accounts.createAccountMap(),
      categories: appState.categories.createKeyMap(),
      tags: appState.tags.createKeyMap(),
    );
    return ts;
  }

  Future<void> save(Transaction? old, Transaction nu) async {
    debugPrint("TransactionService::save() \nold=$old\nnew=$nu");
    if (old == null) {
      assert(nu.key == 0);
      await LibraDatabase.updateTransaction((txn) async => await txn.insertTransaction(nu));
    } else {
      await LibraDatabase.updateTransaction((txn) async => await txn.updateTransaction(old, nu));
    }
    _onUpdate();
  }

  Future<void> addAll(List<Transaction> transactions) async {
    await LibraDatabase.updateTransaction((txn) async {
      for (final t in transactions) {
        await txn.insertTransaction(t);
      }
    });
    _onUpdate();
    LibraDatabase.backup();
  }

  Future<void> delete(Transaction t) async {
    debugPrint("TransactionService::delete() $t");
    await LibraDatabase.updateTransaction((txn) async => await txn.deleteTransaction(t));
    _onUpdate();
  }

  Future<void> loadRelations(Transaction t) {
    return loadTransactionRelations(
      t,
      accounts: appState.accounts.createAccountMap(),
      categories: appState.categories.createKeyMap(),
      tags: appState.tags.createKeyMap(),
    );
  }

  Future<void> reloadReimbursements(Transaction t) async {
    await LibraDatabase.read((db) async {
      t.reimbursements = await db.loadReimbursements(
        parent: t,
        accounts: appState.accounts.createAccountMap(),
        categories: appState.categories.createKeyMap(),
        tags: appState.tags.createKeyMap(),
      );
    });
  }

  Future<Map<int, Transaction>> loadByKey(Iterable<int> keys) {
    return LibraDatabase.db.loadTransactionsByKey(
      keys,
      accounts: appState.accounts.createAccountMap(),
      categories: appState.categories.createKeyMap(),
      tags: appState.tags.createKeyMap(),
    );
  }

  Future<Transaction?> loadSingle(int key) async {
    final map = await loadByKey({key});
    final t = map[key];
    if (t == null) return null;
    await loadRelations(t);
    return t;
  }
}
