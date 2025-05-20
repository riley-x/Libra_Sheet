import 'package:flutter/foundation.dart' as fnd;
import 'package:flutter/material.dart';
import 'package:libra_sheet/components/buttons/time_frame_selector.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/database/category_history.dart';
import 'package:libra_sheet/data/database/libra_database.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/time_value.dart';
import 'package:libra_sheet/graphing/sankey/sankey_node.dart';
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

  /// Monthly net totals
  List<TimeIntValue> netIncome = [];
  List<TimeIntValue> netOther = [];

  /// Timeframe totals
  (int, int) monthIndexRange = (0, 1);
  int numMonths = 0;
  Map<int, int> aggregatedCatTotals = {};
  Map<int, int> individualCatTotals = {};
  int expenseTotal = 0;
  int incomeTotal = 0;

  /// Sankey
  List<List<SankeyNode>> sankeyNodes = [];

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

    _recalculateTimeFrameData();

    notifyListeners();
  }

  void _recalculateTimeFrameData() {
    /// Totals
    monthIndexRange = timeFrame.getRange(incomeData.times);
    numMonths = combinedHistory.times.looseRange(monthIndexRange).length;
    individualCatTotals = combinedHistorySubCats.getCategoryTotals(monthIndexRange, true);
    aggregatedCatTotals = combinedHistory.getCategoryTotals(monthIndexRange, true);
    expenseTotal = expenseData.getTotal(monthIndexRange);
    incomeTotal = incomeData.getTotal(monthIndexRange);

    _calculateSankey();
  }

  void _calculateSankey() {
    sankeyNodes = [];
    if (expenseTotal == 0 && incomeTotal == 0) return;

    final incomeNode = SankeyNode(
      label: "Total Income",
      color: const Color.fromARGB(255, 17, 85, 37),
      value: incomeTotal.asDollarDouble(),
    );
    final expenseNode = SankeyNode(
      label: "Total Expense",
      color: const Color.fromARGB(255, 132, 38, 26),
      value: expenseTotal.abs().asDollarDouble(),
      labelAlignment: Alignment.centerLeft,
    );
    if (incomeTotal > 0 && expenseTotal.abs() > 0) incomeNode.addDestination(expenseNode);

    final incomeSubcats = <SankeyNode>[];
    final incomeCats = <SankeyNode>[];
    final incomePane = <SankeyNode>[if (incomeTotal > 0) incomeNode];
    final expensePane = <SankeyNode>[if (expenseTotal.abs() > 0) expenseNode];
    final expenseCats = <SankeyNode>[];
    final expenseSubcats = <SankeyNode>[];

    if (incomeNode.value > expenseNode.value) {
      final savingsNode = SankeyNode(
        label: "Savings",
        color: const Color.fromARGB(255, 72, 230, 146),
        value: incomeNode.value - expenseNode.value,
        labelAlignment: Alignment.centerLeft,
      );
      savingsNode.addSource(incomeNode, focus: SankeyPriority.destination);
      expensePane.add(savingsNode);
    } else if (expenseNode.value > incomeNode.value) {
      final deficitsNode = SankeyNode(
        label: "Deficit",
        color: Colors.red,
        value: expenseNode.value - incomeNode.value,
      );
      deficitsNode.addDestination(expenseNode, focus: SankeyPriority.source);
      incomePane.add(deficitsNode);
    }

    /// Income
    for (final cat in appState.categories.income.subCats) {
      final catVal = aggregatedCatTotals[cat.key] ?? 0;
      if (catVal == 0) continue;
      final catNode = SankeyNode(
        label: cat.name,
        color: cat.color,
        value: catVal.asDollarDouble(),
        data: cat,
      );
      catNode.addDestination(incomeNode, focus: SankeyPriority.source);
      incomeCats.add(catNode);

      for (final subcat in cat.subCats) {
        final subcatVal = individualCatTotals[subcat.key] ?? 0;
        if (subcatVal == 0) continue;
        final subcatNode = SankeyNode(
          label: subcat.name,
          color: subcat.color,
          value: subcatVal.asDollarDouble(),
          data: subcat,
        );
        catNode.addSource(subcatNode, focus: SankeyPriority.source);
        incomeSubcats.add(subcatNode);
      }

      final leftoverVal = individualCatTotals[cat.key] ?? 0;
      if (leftoverVal > 0 && leftoverVal != catVal) {
        final subcatNode = SankeyNode(
          label: "Other ${cat.name}",
          color: cat.color,
          value: leftoverVal.asDollarDouble(),
          data: cat,
        );
        catNode.addSource(subcatNode, focus: SankeyPriority.source);
        incomeSubcats.add(subcatNode);
      }
    }

    var leftoverVal = individualCatTotals[appState.categories.income.key] ?? 0;
    if (leftoverVal > 0 && leftoverVal != incomeTotal) {
      final subcatNode = SankeyNode(
        label: "Uncategorized Income",
        color: appState.categories.income.color,
        value: leftoverVal.asDollarDouble(),
        data: appState.categories.income,
      );
      incomeNode.addSource(subcatNode, focus: SankeyPriority.source);
      incomeCats.add(subcatNode);
    }

    /// Expense
    for (final cat in appState.categories.expense.subCats) {
      final catVal = aggregatedCatTotals[cat.key] ?? 0;
      if (catVal == 0) continue;
      final catNode = SankeyNode(
        label: cat.name,
        color: cat.color,
        value: catVal.asDollarDouble(),
        labelAlignment: Alignment.centerLeft,
        data: cat,
      );
      catNode.addSource(expenseNode, focus: SankeyPriority.destination);
      expenseCats.add(catNode);

      for (final subcat in cat.subCats) {
        final subcatVal = individualCatTotals[subcat.key] ?? 0;
        if (subcatVal == 0) continue;
        final subcatNode = SankeyNode(
          label: subcat.name,
          color: subcat.color,
          value: subcatVal.asDollarDouble(),
          labelAlignment: Alignment.centerLeft,
          data: subcat,
        );
        catNode.addDestination(subcatNode, focus: SankeyPriority.destination);
        expenseSubcats.add(subcatNode);
      }

      final leftoverVal = individualCatTotals[cat.key] ?? 0;
      if (leftoverVal > 0 && leftoverVal != catVal) {
        final subcatNode = SankeyNode(
          label: "Other ${cat.name}",
          color: cat.color,
          value: leftoverVal.asDollarDouble(),
          labelAlignment: Alignment.centerLeft,
          data: cat,
        );
        catNode.addDestination(subcatNode, focus: SankeyPriority.destination);
        expenseSubcats.add(subcatNode);
      }
    }

    leftoverVal = individualCatTotals[appState.categories.expense.key] ?? 0;
    if (leftoverVal > 0 && leftoverVal != expenseTotal) {
      final uncatNode = SankeyNode(
        label: "Uncategorized Expenses",
        color: appState.categories.expense.color,
        value: leftoverVal.asDollarDouble(),
        labelAlignment: Alignment.centerLeft,
        data: appState.categories.expense,
      );
      expenseNode.addDestination(uncatNode, focus: SankeyPriority.destination);
      expenseCats.add(uncatNode);
    }

    sankeyNodes = [
      if (incomeSubcats.isNotEmpty) incomeSubcats,
      if (incomeCats.isNotEmpty) incomeCats,
      incomePane,
      expensePane,
      if (expenseCats.isNotEmpty) expenseCats,
      if (expenseSubcats.isNotEmpty) expenseSubcats
    ];

    // for (final list in sankeyNodes) {
    //   debugPrint("$list");
    // }
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
    _recalculateTimeFrameData();
    notifyListeners();
  }
}
