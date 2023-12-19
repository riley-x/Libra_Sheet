import 'package:flutter/foundation.dart' as fnd;
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/database/category_history.dart';
import 'package:libra_sheet/data/database/libra_database.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/time_value.dart';

enum CashFlowType { categories, net }

enum CashFlowTimeFrame { oneYear, lastYear, all }

class CashFlowState extends fnd.ChangeNotifier {
  final LibraAppState appState;

  CashFlowState(this.appState) {
    appState.transactions.addListener(load);
    load();
  }

  /// Filters
  CashFlowType type = CashFlowType.categories;
  CashFlowTimeFrame timeFrame = CashFlowTimeFrame.all;
  final Set<Account> accounts = {};
  bool showSubCategories = false;

  /// These aggregate subcategory data into parent categories
  List<CategoryHistory> incomeData = [];
  List<CategoryHistory> expenseData = [];

  /// These separate subcategory data
  List<CategoryHistory> incomeDataSubCats = [];
  List<CategoryHistory> expenseDataSubCats = [];

  List<TimeIntValue> netIncome = [];
  List<TimeIntValue> netReturns = [];

  void _loadList(
    List<CategoryHistory> aggregateList,
    List<CategoryHistory> subcatList,
    Map<int, List<TimeIntValue>> categoryHistory,
    Category parent,
  ) {
    final parentVals = categoryHistory[parent.key];
    if (parentVals != null) {
      final vals = parentVals.fixedForCharts(absValues: true);
      aggregateList.add(CategoryHistory(parent, vals));
      subcatList.add(CategoryHistory(parent, vals));
    }

    for (final cat in parent.subCats) {
      var vals = categoryHistory[cat.key];
      if (vals != null) {
        subcatList.add(CategoryHistory(cat, vals.fixedForCharts(absValues: true)));
      }

      /// Accumulate values from subcategories too. Only need to recurse once since max level = 2.
      for (final subCat in cat.subCats) {
        var subVals = categoryHistory[subCat.key];
        if (subVals == null) continue;
        subcatList.add(CategoryHistory(subCat, subVals.fixedForCharts(absValues: true)));
        vals = (vals == null) ? subVals : addParallel(vals, subVals);
      }

      if (vals != null) {
        aggregateList.add(CategoryHistory(cat, vals.fixedForCharts(absValues: true)));
      }
    }
  }

  Future<void> load() async {
    final categoryHistory = await LibraDatabase.db.getCategoryHistory(
      accounts: accounts.map((e) => e.key),
      callback: (_, vals) => vals.withAlignedTimes(appState.monthList),
    );
    final _netIncome = await LibraDatabase.db.getMonthlyNetIncome(
      accounts: accounts.map((e) => e.key),
    );

    incomeData.clear();
    incomeDataSubCats.clear();
    _loadList(incomeData, incomeDataSubCats, categoryHistory, appState.categories.income);

    expenseData.clear();
    expenseDataSubCats.clear();
    _loadList(expenseData, expenseDataSubCats, categoryHistory, appState.categories.expense);

    netIncome = _netIncome.withAlignedTimes(appState.monthList).fixedForCharts();

    netReturns = categoryHistory[Category.investment.key]?.fixedForCharts() ??
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

  void setTimeFrame(CashFlowTimeFrame t) {
    timeFrame = t;
    notifyListeners();
  }

  void shouldShowSubCategories(bool x) {
    showSubCategories = x;
    notifyListeners();
  }
}
