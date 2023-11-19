import 'package:flutter/material.dart';
import 'package:libra_sheet/data/account.dart';
import 'package:libra_sheet/data/category.dart';
import 'package:libra_sheet/data/test_data.dart';
import 'package:libra_sheet/data/transaction.dart';

enum ExpenseType { income, expense }

enum CategoryTabTimeFrame { current, oneYear, all }

class CategoryTabState extends ChangeNotifier {
  /// The list contains the nesting of category focuses, since you can focus a subcategory from a parent.
  List<CategoryValue> categoriesFocused = [];
  List<Transaction> categoryFocusedTransactions = [];

  CategoryTabTimeFrame timeFrame = CategoryTabTimeFrame.all;
  ExpenseType expenseType = ExpenseType.expense;
  Account? account;
  bool showSubCategories = false;

  void clearFocus() {
    if (categoriesFocused.isEmpty) return;
    categoriesFocused.removeLast();
    if (categoriesFocused.isEmpty) {
      categoryFocusedTransactions.clear();
    } else {
// TODO load transactions
    }

    notifyListeners();
  }

  void focusCategory(CategoryValue category) {
    categoriesFocused.add(category);
    // TODO load transactions
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
