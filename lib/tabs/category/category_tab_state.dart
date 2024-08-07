import 'dart:math';

import 'package:flutter/material.dart';
import 'package:libra_sheet/components/buttons/time_frame_selector.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/database/category_history.dart';
import 'package:libra_sheet/data/database/libra_database.dart';
import 'package:libra_sheet/data/date_time_utils.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/enums.dart';

class CategoryTabState extends ChangeNotifier {
  final LibraAppState appState;
  bool _disposed = false;
  CategoryTabState(this.appState) {
    appState.transactions.addListener(loadValues);
    loadValues();
  }

  @override
  void dispose() {
    _disposed = true;
    appState.transactions.removeListener(loadValues);
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      // can happen due to async gaps
      super.notifyListeners();
    }
  }

  //--------------------------------------------------------------------------
  // Filters / Selections
  //--------------------------------------------------------------------------
  ExpenseType expenseType = ExpenseType.expense;
  TimeFrame timeFrame = const TimeFrame(TimeFrameEnum.all);

  /// This is the month range as specified by [timeFrame]; it is set on [loadValues] (which is
  /// triggered by [setTimeFrame]), so it should be in sync with [timeFrame].
  (DateTime, DateTime)? timeFrameMonths;

  final Set<Account> accounts = {};
  // final Set<Tag> tags = {}; TODO not trivial
  bool showSubCategories = false;
  bool showAverages = false;

  //--------------------------------------------------------------------------
  // Callbacks
  //--------------------------------------------------------------------------

  void setExpenseType(ExpenseType x) {
    expenseType = x;
    notifyListeners(); // no need to reload values
  }

  void setTimeFrame(TimeFrame x) {
    timeFrame = x;
    notifyListeners();
    loadValues();
  }

  void shouldShowSubCategories(bool x) {
    showSubCategories = x;
    notifyListeners(); // no need to reload values
  }

  void shouldShowAverages(bool x) {
    showAverages = x;
    notifyListeners(); // no need to reload values
  }

  int months() {
    return 1 + timeFrameMonths!.$2.monthDiff(timeFrameMonths!.$1);
  }

  int averageDenominator() {
    if (!showAverages || timeFrameMonths == null) return 1;
    return 1 + timeFrameMonths!.$2.monthDiff(timeFrameMonths!.$1);
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

  /// We also get the full month-by-month history for the mini barchart. Only need aggregated here.
  CategoryHistory categoryHistory = CategoryHistory.empty;

  /// Totals
  int incomeTotal = 0;
  int expenseTotal = 0;

  /// Aggregate subcat values into parent categories. No recurse because max level = 2.
  void _aggregateSubCatVals(Category parent) {
    var val = aggregateValues[parent.key] ?? 0;
    for (final subCat in parent.subCats) {
      val += aggregateValues[subCat.key] ?? 0;
    }
    aggregateValues[parent.key] = val;
  }

  void loadValues() async {
    timeFrameMonths = null;
    if (appState.monthList.isEmpty) return;
    _loadHistory();

    /// Get months
    final range = timeFrame.getDateRange(appState.monthList);
    final startMonth = range.$1 ?? appState.monthList.first;
    final endMonth = range.$2 ?? appState.monthList.last;
    timeFrameMonths = (startMonth, endMonth);

    /// Load
    final vals = await LibraDatabase.read((db) => db.getCategoryTotals(
          start: startMonth,
          end: endMonth.monthEnd(),
          accounts: accounts.map((e) => e.key),
        ));
    if (_disposed || vals == null) return;
    individualValues = vals;

    /// Aggregate
    aggregateValues = Map.of(individualValues);
    for (final cat in appState.categories.income.subCats) {
      _aggregateSubCatVals(cat);
    }
    for (final cat in appState.categories.expense.subCats) {
      _aggregateSubCatVals(cat);
    }

    /// Totals
    incomeTotal = 0;
    expenseTotal = 0;
    final categories = appState.categories.createKeyMap();
    for (final x in vals.entries) {
      final type = categories[x.key]?.type;
      if (type == ExpenseFilterType.income) {
        incomeTotal += x.value;
      } else if (type == ExpenseFilterType.expense) {
        expenseTotal += x.value;
      }
    }

    notifyListeners();
  }

  Future<void> _loadHistory() async {
    final rawHistory = await LibraDatabase.read((db) => db.getCategoryHistory(
          accounts: accounts.map((e) => e.key),
        ));
    if (_disposed || rawHistory == null) return;

    /// Accumulate to level = 1 categories
    categoryHistory = CategoryHistory(appState.monthList, invertExpenses: false);
    categoryHistory.addIndividual(appState.categories.income, rawHistory, recurseSubcats: false);
    categoryHistory.addIndividual(appState.categories.expense, rawHistory, recurseSubcats: false);
    for (final cat in appState.categories.income.subCats) {
      categoryHistory.addCumulative(cat, rawHistory);
    }
    for (final cat in appState.categories.expense.subCats) {
      categoryHistory.addCumulative(cat, rawHistory);
    }
    notifyListeners();
  }
}
