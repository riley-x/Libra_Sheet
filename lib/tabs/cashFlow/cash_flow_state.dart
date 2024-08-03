import 'package:flutter/foundation.dart' as fnd;
import 'package:libra_sheet/components/buttons/time_frame_selector.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/database/category_history.dart';
import 'package:libra_sheet/data/database/libra_database.dart';
import 'package:libra_sheet/data/date_time_utils.dart';
import 'package:libra_sheet/data/enums.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/time_value.dart';

enum CashFlowType { categories, net }

class CashFlowState extends fnd.ChangeNotifier {
  final LibraAppState appState;
  bool _disposed = false;

  CashFlowState(this.appState) {
    appState.transactions.addListener(load);
    load();
  }

  @override
  void dispose() {
    _disposed = true;
    appState.transactions.removeListener(load);
    super.dispose();
  }

  /// Filters
  CashFlowType type = CashFlowType.categories;
  TimeFrame timeFrame = const TimeFrame(TimeFrameEnum.all);
  final Set<Account> accounts = {};
  bool showSubCategories = false;

  /// These aggregate subcategory data into parent categories
  CategoryHistory incomeData = CategoryHistory.empty;
  CategoryHistory expenseData = CategoryHistory.empty;

  /// These separate subcategory data
  CategoryHistory incomeDataSubCats = CategoryHistory.empty;
  CategoryHistory expenseDataSubCats = CategoryHistory.empty;

  List<TimeIntValue> netIncome = [];
  List<TimeIntValue> netReturns = [];

  /// Totals
  int incomeTotal = 0;
  int expenseTotal = 0;
  int otherTotal = 0;

  Future<void> load() async {
    _loadTotals();

    final rawHistory = await LibraDatabase.read((db) => db.getCategoryHistory(
          accounts: accounts.map((e) => e.key),
        ));
    final rawIncome = await LibraDatabase.read((db) => db.getMonthlyNetIncome(
          accounts: accounts.map((e) => e.key),
        ));
    if (_disposed) return; // can happen due to async gap
    if (rawHistory == null || rawIncome == null) return;

    /// Accumulate to level = 1 categories
    incomeData = CategoryHistory(appState.monthList);
    incomeData.addIndividual(appState.categories.income, rawHistory, recurseSubcats: false);
    for (final cat in appState.categories.income.subCats) {
      incomeData.addCumulative(cat, rawHistory);
    }

    expenseData = CategoryHistory(appState.monthList);
    expenseData.addIndividual(appState.categories.expense, rawHistory, recurseSubcats: false);
    for (final cat in appState.categories.expense.subCats) {
      expenseData.addCumulative(cat, rawHistory);
    }

    /// Separated subcat data
    incomeDataSubCats = CategoryHistory(appState.monthList);
    expenseDataSubCats = CategoryHistory(appState.monthList);
    incomeDataSubCats.addIndividual(appState.categories.income, rawHistory);
    expenseDataSubCats.addIndividual(appState.categories.expense, rawHistory);

    netIncome = rawIncome.withAlignedTimes(appState.monthList);

    netReturns = rawHistory[Category.other.key]?.withAlignedTimes(appState.monthList) ??
        appState.monthList.map((e) => TimeIntValue(time: e, value: 0)).toList();

    notifyListeners();
  }

  Future<void> _loadTotals() async {
    /// Get months
    final range = timeFrame.getDateRange(appState.monthList);
    final startMonth = range.$1 ?? appState.monthList.first;
    final endMonth = range.$2 ?? appState.monthList.last;

    /// Load
    final vals = await LibraDatabase.read((db) => db.getCategoryTotals(
          start: startMonth,
          end: endMonth.monthEnd(),
          accounts: accounts.map((e) => e.key),
        ));
    if (_disposed) return; // can happen due to async gap
    if (vals == null) return;

    /// Sum
    incomeTotal = 0;
    expenseTotal = 0;
    otherTotal = 0;
    final categories = appState.categories.createKeyMap();
    for (final x in vals.entries) {
      final cat = categories[x.key];
      if (cat?.type == ExpenseFilterType.income) {
        incomeTotal += x.value;
      } else if (cat?.type == ExpenseFilterType.expense) {
        expenseTotal += x.value;
      } else if (cat?.isOther == true) {
        otherTotal += x.value;
      }
    }
    notifyListeners();
  }

  //------------------------------------------------------------------------------
  // Filter field callbacks
  //------------------------------------------------------------------------------
  void setType(CashFlowType t) {
    type = t;
    notifyListeners();
  }

  void setTimeFrame(TimeFrame t) {
    timeFrame = t;
    notifyListeners();
    _loadTotals();
  }

  void shouldShowSubCategories(bool x) {
    showSubCategories = x;
    notifyListeners();
  }
}
