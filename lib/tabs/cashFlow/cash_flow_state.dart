import 'package:flutter/foundation.dart' as fnd;
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/database/category_history.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/time_value.dart';

enum CashFlowType { categories, net }

enum CashFlowTimeFrame { oneYear, lastYear, all }

class CashFlowState extends fnd.ChangeNotifier {
  CashFlowState(this.appState) {
    load();
  }

  final LibraAppState appState;

  CashFlowType type = CashFlowType.categories;
  CashFlowTimeFrame timeFrame = CashFlowTimeFrame.all;
  final Set<Account> accounts = {};

  List<CategoryHistory> incomeData = [];
  List<CategoryHistory> expenseData = [];

  void _loadList(
    List<CategoryHistory> list,
    Map<int, List<TimeIntValue>> categoryHistory,
    Category parent,
  ) {
    final parentVals = categoryHistory[parent.key];
    if (parentVals != null) {
      list.add(CategoryHistory(parent, parentVals));
    }

    for (final cat in parent.subCats) {
      var vals = categoryHistory[cat.key];

      /// Add values from subcategories too. Only need to recurse once since max level = 2.
      for (final subCat in cat.subCats) {
        var subVals = categoryHistory[subCat.key];
        if (subVals == null) continue;
        vals = (vals == null) ? subVals : addParallel(vals, subVals);
      }
      if (vals != null) {
        list.add(CategoryHistory(cat, vals));
      }
    }
  }

  Future<void> load() async {
    final categoryHistory = await getCategoryHistory(
      callback: (_, vals) =>
          vals.withAlignedTimes(appState.monthList).fixedForCharts(absValues: true),
    );

    incomeData.clear();
    _loadList(incomeData, categoryHistory, appState.categories.income);

    expenseData.clear();
    _loadList(expenseData, categoryHistory, appState.categories.expense);

    notifyListeners();
  }

  //------------------------------------------------------------------------------
  // Field callbacks
  //------------------------------------------------------------------------------
  void setType(CashFlowType t) {
    type = t;
    notifyListeners();
  }

  void setTimeFrame(CashFlowTimeFrame t) {
    timeFrame = t;
    notifyListeners();
  }
}
