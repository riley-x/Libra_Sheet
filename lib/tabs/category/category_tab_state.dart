import 'dart:math';

import 'package:flutter/material.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/database/category_history.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/enums.dart';
import 'package:libra_sheet/data/test_data.dart';
import 'package:libra_sheet/data/objects/transaction.dart';

enum CategoryTabTimeFrame { current, oneYear, all }

class CategoryTabState extends ChangeNotifier {
  final LibraAppState appState;
  CategoryTabState(this.appState) {
    _loadValues();
  }

  //--------------------------------------------------------------------------
  // Filters / Selections
  //--------------------------------------------------------------------------
  CategoryTabTimeFrame timeFrame = CategoryTabTimeFrame.all;
  ExpenseType expenseType = ExpenseType.expense;
  Account? account;
  bool showSubCategories = false;

  //--------------------------------------------------------------------------
  // Values
  //--------------------------------------------------------------------------

  /// A map category.key: int_value for the current options settings
  Map<int, int> values = {};

  /// Aggregate subcat values into parent categories. No recurse because max level = 2.
  void _aggregateSubCatVals(Category parent) {
    var val = values[parent.key] ?? 0;
    for (final subCat in parent.subCats) {
      val += values[subCat.key] ?? 0;
    }
    values[parent.key] = val;
  }

  void _loadValues() async {
    if (appState.monthList.isEmpty) return;
    final startTime = switch (timeFrame) {
      CategoryTabTimeFrame.all => null,
      CategoryTabTimeFrame.current => appState.monthList.lastOrNull,
      CategoryTabTimeFrame.oneYear => appState.monthList[max(0, appState.monthList.length - 12)]
    };
    values = await getCategoryTotals(startTime, const []); // TODO accounts

    /// Aggregate
    for (final cat in appState.categories.income.subCats) {
      _aggregateSubCatVals(cat);
    }
    for (final cat in appState.categories.expense.subCats) {
      _aggregateSubCatVals(cat);
    }
    notifyListeners();
  }

  //--------------------------------------------------------------------------

  /// The list contains the nesting of category focuses, since you can focus a subcategory from a parent.
  List<Category> categoriesFocused = [];
  List<Transaction> categoryFocusedTransactions = [];

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
    notifyListeners(); // no need to reload values
  }

  void setTimeFrame(CategoryTabTimeFrame x) {
    timeFrame = x;
    _loadValues();
  }

  void setAccount(Account? x) {
    account = x;
    _loadValues();
  }

  void shouldShowSubCategories(bool x) {
    showSubCategories = x;
    notifyListeners(); // no need to reload values
  }
}
