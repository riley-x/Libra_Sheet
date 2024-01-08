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
    timeFrameMonths = null;
    if (appState.monthList.isEmpty) return;

    /// Get months
    final startMonth = switch (timeFrame.selection) {
      TimeFrameEnum.all => appState.monthList.first,
      TimeFrameEnum.oneYear => appState.monthList[max(0, appState.monthList.length - 12)],
      TimeFrameEnum.twoYear => appState.monthList[max(0, appState.monthList.length - 24)],
      TimeFrameEnum.custom => timeFrame.customStart!,
    };
    final endMonth = switch (timeFrame.selection) {
      TimeFrameEnum.custom => timeFrame.customEndInclusive!,
      _ => appState.monthList.last,
    };
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
    notifyListeners();
  }
}
