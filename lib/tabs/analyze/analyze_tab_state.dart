import 'package:flutter/foundation.dart' as fnd;
import 'package:libra_sheet/components/buttons/time_frame_selector.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/database/category_history.dart';
import 'package:libra_sheet/data/database/libra_database.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/time_value.dart';
import 'package:libra_sheet/tabs/analyze/analyze_tab_view_state.dart';

class AnalyzeTabState extends fnd.ChangeNotifier {
  final LibraAppState appState;
  bool _disposed = false;

  AnalyzeTabState(this.appState) {
    appState.transactions.addListener(load);
    load();
  }

  @override
  void dispose() {
    _disposed = true;
    appState.transactions.removeListener(load);
    super.dispose();
  }

  /// These aggregate subcategory data into parent categories
  CategoryHistory incomeData = CategoryHistory.empty;
  CategoryHistory expenseData = CategoryHistory.empty;
  CategoryHistory combinedHistory = CategoryHistory.empty;

  /// These separate subcategory data
  CategoryHistory incomeDataSubCats = CategoryHistory.empty;
  CategoryHistory expenseDataSubCats = CategoryHistory.empty;
  CategoryHistory combinedHistorySubCats = CategoryHistory.empty;

  List<TimeIntValue> netIncome = [];
  List<TimeIntValue> netOther = [];

  Future<void> load() async {
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

    expenseData = CategoryHistory(appState.monthList, invertExpenses: false);
    expenseData.addIndividual(appState.categories.expense, rawHistory, recurseSubcats: false);
    for (final cat in appState.categories.expense.subCats) {
      expenseData.addCumulative(cat, rawHistory);
    }

    combinedHistory = CategoryHistory.fromList(
        appState.monthList, incomeData.categories + expenseData.categories);

    /// Separated subcat data
    incomeDataSubCats = CategoryHistory(appState.monthList);
    expenseDataSubCats = CategoryHistory(appState.monthList, invertExpenses: false);
    incomeDataSubCats.addIndividual(appState.categories.income, rawHistory);
    expenseDataSubCats.addIndividual(appState.categories.expense, rawHistory);
    combinedHistorySubCats = CategoryHistory.fromList(
        appState.monthList, incomeDataSubCats.categories + expenseDataSubCats.categories);

    /// Net
    netIncome = rawIncome.withAlignedTimes(appState.monthList);
    netOther = rawHistory[Category.other.key]?.withAlignedTimes(appState.monthList) ??
        appState.monthList.map((e) => TimeIntValue(time: e, value: 0)).toList();

    notifyListeners();
  }

  /// Main view state defines which graph we're looking at as well as per-graph
  /// viewing options.
  AnalyzeTabView currentView = AnalyzeTabView.doubleStack;
  Map<AnalyzeTabView, AnalyzeTabViewState> viewStates = {
    AnalyzeTabView.doubleStack: const DoubleStackView(showSubcats: false)
  };
  AnalyzeTabViewState get currentViewState => viewStates[currentView]!;

  /// Load filters
  final Set<Account> accounts = {};
  TimeFrame timeFrame = const TimeFrame(TimeFrameEnum.all);

  //------------------------------------------------------------------------------
  // Filter field callbacks
  //------------------------------------------------------------------------------
  void setView(AnalyzeTabView view) {
    if (currentView != view) {
      currentView = view;
      if (!viewStates.containsKey(view)) {
        viewStates[view] = AnalyzeTabViewState.of(view);
      }
      notifyListeners();
    }
  }

  void setViewState(AnalyzeTabViewState state) {
    assert(currentView == state.type);
    viewStates[state.type] = state;
    notifyListeners();
  }

  void setTimeFrame(TimeFrame t) {
    timeFrame = t;
    notifyListeners();
    // _loadTotals();
  }
}
