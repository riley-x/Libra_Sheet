import 'package:flutter/material.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/database/database_setup.dart';
import 'package:libra_sheet/data/database/transactions.dart';
import 'package:libra_sheet/data/objects/transaction.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filter_state.dart';

/// Helper class for managing transactions. Every widget that monitors transactions should probably
/// watch this service, so that they can be notified when transactions are added or edited (which
/// affects all value-based entities and, because of reimbursements, can affect all other
/// transactions).
///
/// This service isn't meant to be used in the widget tree, although it is provided nonetheless to
/// enable easy callbacks, usually via context.read().
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
      accounts: appState.createAccountMap(),
      categories: appState.categories.createKeyMap(),
      tags: appState.tags.createKeyMap(),
    );
    return ts;
  }

  Future<void> save(Transaction? old, Transaction nu) async {
    debugPrint("TransactionService::save() $nu");
    if (old == null) {
      assert(nu.key == 0);
      await insertTransaction(nu);
    } else {
      await updateTransaction(old, nu);
    }
    _onUpdate();
  }

  Future<void> addAll(List<Transaction> transactions) async {
    await libraDatabase?.transaction((txn) async {
      for (final t in transactions) {
        await insertTransaction(t, txn: txn);
      }
    });
    _onUpdate();
  }

  Future<void> delete(Transaction t) async {
    debugPrint("TransactionService::delete() $t");
    await deleteTransaction(t);
    _onUpdate();
  }

  Future<void> loadRelations(Transaction t) {
    return loadTransactionRelations(t, appState.categories.createKeyMap());
  }
}
