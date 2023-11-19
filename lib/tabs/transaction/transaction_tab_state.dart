import 'package:flutter/material.dart';
import 'package:libra_sheet/data/account.dart';
import 'package:libra_sheet/data/enums.dart';
import 'package:libra_sheet/data/test_data.dart';
import 'package:libra_sheet/data/transaction.dart';

class TransactionTabState extends ChangeNotifier {
  TransactionTabState(this.accounts) : accountFilterSelected = List.filled(accounts.length, false);

  final List<Account> accounts;
  final List<bool> accountFilterSelected;

  Set<ExpenseType> expenseFilterSelected = {};

  List<Transaction> transactions = testTransactions;
  Transaction? focusedTransaction;

  bool showSubCategories = false;

  void focus(Transaction? trans) {
    focusedTransaction = trans;
    notifyListeners();
  }

  void setAccountFilter(int i, bool selected) {
    accountFilterSelected[i] = selected;
    notifyListeners();
  }

  void setExpenseFilter(Set<ExpenseType> newSelection) {
    expenseFilterSelected = newSelection;
    notifyListeners();
  }
}
