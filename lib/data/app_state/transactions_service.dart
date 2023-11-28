import 'package:flutter/material.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/database/database_setup.dart';
import 'package:libra_sheet/data/database/transactions.dart';
import 'package:libra_sheet/data/objects/transaction.dart';

/// Helper class for managing transactions
class TransactionService extends ChangeNotifier {
  //----------------------------------------------------------------------------
  // Fields
  //----------------------------------------------------------------------------
  final LibraAppState appState;
  TransactionService(this.appState);

  //----------------------------------------------------------------------------
  // Database Interface
  //----------------------------------------------------------------------------
  Future<void> saveAll(List<Transaction> transactions) async {
    libraDatabase?.transaction((txn) async {
      for (final t in transactions) {
        await insertTransaction(t, txn: txn);
      }
    });
  }
}
