import 'package:flutter/material.dart';
import 'package:libra_sheet/data/test_data.dart';
import 'package:libra_sheet/data/transaction.dart';

class TransactionTabState extends ChangeNotifier {
  List<Transaction> transactions = testTransactions;
  Transaction? focusedTransaction;

  bool showSubCategories = false;

  void focus(Transaction? trans) {
    focusedTransaction = trans;
    notifyListeners();
  }
}
