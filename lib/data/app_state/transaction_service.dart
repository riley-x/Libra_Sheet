import 'package:flutter/material.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/database/database_setup.dart';
import 'package:libra_sheet/data/database/transactions.dart';
import 'package:libra_sheet/data/objects/transaction.dart';

// TODO is this class even necessary

/// Helper class for managing transactions. Every widget that monitors transactions should probably
/// watch this service, so that they can be notified when transactions are added or edited (which,
/// because of reimbursements, can affect all other transactions).
class TransactionService extends ChangeNotifier {
  //----------------------------------------------------------------------------
  // Fields
  //----------------------------------------------------------------------------
  final LibraAppState appState;
  TransactionService(this.appState);

  // final Map<Object, List<Transaction>> lists = {};

  //----------------------------------------------------------------------------
  // Database Interface
  //----------------------------------------------------------------------------
  Future<List<Transaction>> load(TransactionFilters filters) async {
    final ts = await loadTransactions(
      filters,
      accounts: appState.createAccountMap(),
      categories: appState.categories.createKeyMap(),
    );
    return ts;
  }

  Future<void> saveAll(List<Transaction> transactions) async {
    await libraDatabase?.transaction((txn) async {
      for (final t in transactions) {
        await insertTransaction(t, txn: txn);
      }
    });
    notifyListeners();
  }
}
