import 'package:flutter/foundation.dart' as fnd;
import 'package:libra_sheet/components/buttons/time_frame_selector.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/database/category_history.dart';
import 'package:libra_sheet/data/database/libra_database.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/time_value.dart';

enum CashFlowType { categories, net }

class CashFlowState extends fnd.ChangeNotifier {
  final LibraAppState appState;

  CashFlowState(this.appState) {
    appState.transactions.addListener(load);
    load();
  }

  @override
  void dispose() {
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

  Future<void> load() async {
    final rawHistory = await LibraDatabase.db.getCategoryHistory(
      accounts: accounts.map((e) => e.key),
    );
    final rawIncome = await LibraDatabase.db.getMonthlyNetIncome(
      accounts: accounts.map((e) => e.key),
    );

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

    netIncome = rawIncome.withAlignedTimes(appState.monthList).fixedForCharts();

    netReturns = rawHistory[Category.investment.key]?.withAlignedTimes(appState.monthList) ??
        appState.monthList.map((e) => TimeIntValue(time: e, value: 0)).toList().fixedForCharts();

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
  }

  void shouldShowSubCategories(bool x) {
    showSubCategories = x;
    notifyListeners();
  }
}
