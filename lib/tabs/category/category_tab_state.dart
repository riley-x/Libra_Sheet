import 'package:flutter/material.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/enums.dart';
import 'package:libra_sheet/data/test_data.dart';
import 'package:libra_sheet/data/objects/transaction.dart';

enum CategoryTabTimeFrame { current, oneYear, all }

class CategoryTabState extends ChangeNotifier {
  /// The list contains the nesting of category focuses, since you can focus a subcategory from a parent.
  List<Category> categoriesFocused = [];
  List<Transaction> categoryFocusedTransactions = [];

  /// A map category.key: int_value for the currently displayed values
  Map<int, int> values = testCategoryValues;

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
      // TODO load transactions and history
    }

    notifyListeners();
  }

  void focusCategory(Category category) {
    categoriesFocused.add(category);
    // TODO load transactions and history
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
