import 'dart:math';

import 'package:flutter/material.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/database/category_history.dart';
import 'package:libra_sheet/data/database/libra_database.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/enums.dart';

enum CategoryTabTimeFrame { current, oneYear, all }

class CategoryTabState extends ChangeNotifier {
  final LibraAppState appState;
  CategoryTabState(this.appState) {
    appState.transactions.addListener(loadValues);
    loadValues();
  }

  @override
  void dispose() {
    appState.transactions.removeListener(loadValues);
    super.dispose();
  }

  //--------------------------------------------------------------------------
  // Filters / Selections
  //--------------------------------------------------------------------------
  CategoryTabTimeFrame timeFrame = CategoryTabTimeFrame.all;
  ExpenseType expenseType = ExpenseType.expense;
  final Set<Account> accounts = {};
  // final Set<Tag> tags = {}; TODO not trivial
  bool showSubCategories = false;

  void setExpenseType(ExpenseType x) {
    expenseType = x;
    notifyListeners(); // no need to reload values
  }

  void setTimeFrame(CategoryTabTimeFrame x) {
    timeFrame = x;
    loadValues();
  }

  void shouldShowSubCategories(bool x) {
    showSubCategories = x;
    notifyListeners(); // no need to reload values
  }

  //--------------------------------------------------------------------------
  // Values
  //--------------------------------------------------------------------------

  /// A map category.key: int_value for the current options settings. This aggregates subcat totals
  /// into the parent level = 1 categories
  Map<int, int> aggregateValues = {};

  /// A map category.key: int_value for the current options settings. This does not do any
  /// aggregation of subcat values, useful for finding the "unsubcategorized" amount.
  Map<int, int> individualValues = {};

  /// Aggregate subcat values into parent categories. No recurse because max level = 2.
  void _aggregateSubCatVals(Category parent) {
    var val = aggregateValues[parent.key] ?? 0;
    for (final subCat in parent.subCats) {
      val += aggregateValues[subCat.key] ?? 0;
    }
    aggregateValues[parent.key] = val;
  }

  void loadValues() async {
    notifyListeners();
    if (appState.monthList.isEmpty) return;
    final startTime = switch (timeFrame) {
      CategoryTabTimeFrame.all => null,
      CategoryTabTimeFrame.current => appState.monthList.lastOrNull,
      CategoryTabTimeFrame.oneYear => appState.monthList[max(0, appState.monthList.length - 12)]
    };
    individualValues = await LibraDatabase.db.getCategoryTotals(
      start: startTime,
      accounts: accounts.map((e) => e.key),
    );

    /// Aggregate
    aggregateValues = Map.of(individualValues);
    for (final cat in appState.categories.income.subCats) {
      _aggregateSubCatVals(cat);
    }
    for (final cat in appState.categories.expense.subCats) {
      _aggregateSubCatVals(cat);
    }
    notifyListeners();
  }
}
