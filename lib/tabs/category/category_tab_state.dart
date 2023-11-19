import 'package:flutter/material.dart';
import 'package:libra_sheet/data/account.dart';
import 'package:libra_sheet/data/category.dart';

enum ExpenseType { income, expense }

enum CategoryTabTimeFrame { current, oneYear, all }

class CategoryTabState extends ChangeNotifier {
  Category? categoryFocused;
  // List<Transaction>? accountFocusedTransactions = testTransactions;

  CategoryTabTimeFrame timeFrame = CategoryTabTimeFrame.all;
  ExpenseType expenseType = ExpenseType.expense;
  Account? account;
  bool showSubCategories = false;

  void focusCategory(Category? category) {
    categoryFocused = category;
    // TODO load
    notifyListeners();
  }

  void setExpenseType(ExpenseType x) {
    expenseType = x;
    notifyListeners();
  }

  void setTimeFrame(CategoryTabTimeFrame x) {
    timeFrame = x;
    notifyListeners();
  }

  void setAccount(Account? x) {
    account = x;
    notifyListeners();
  }

  void shouldShowSubCategories(bool x) {
    showSubCategories = x;
    notifyListeners();
  }
}
