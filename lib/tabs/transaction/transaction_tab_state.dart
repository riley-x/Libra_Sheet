import 'package:flutter/material.dart';
import 'package:libra_sheet/data/account.dart';
import 'package:libra_sheet/data/category.dart';
import 'package:libra_sheet/data/enums.dart';
import 'package:libra_sheet/data/test_data.dart';
import 'package:libra_sheet/data/transaction.dart';

class TransactionTabState extends ChangeNotifier {
  Set<ExpenseType> expenseFilterSelected = {};
  Set<int> accountFilterSelected = {};
  Set<int> categoryFilterSelected = {};

  List<Transaction> transactions = testTransactions;
  Transaction? focusedTransaction;

  void focus(Transaction? trans) {
    focusedTransaction = trans;
    notifyListeners();
  }

  void setExpenseFilter(Set<ExpenseType> newSelection) {
    expenseFilterSelected = newSelection;
    notifyListeners();
  }

  void setAccountFilter(Account account, bool selected) {
    if (selected) {
      accountFilterSelected.add(account.key);
    } else {
      accountFilterSelected.remove(account.key);
    }
    notifyListeners();
  }

  void setCategoryFilter(Category cat, bool selected) {
    if (selected) {
      categoryFilterSelected.add(cat.key);
    } else {
      categoryFilterSelected.remove(cat.key);
    }
    notifyListeners();
  }
}
