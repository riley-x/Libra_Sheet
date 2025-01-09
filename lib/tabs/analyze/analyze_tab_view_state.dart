enum AnalyzeTabView {
  doubleStack,
  netIncome,
  expenseFlow,
  incomeFlow,
  expenseHeatmap,
  incomeHeatmap
}

sealed class AnalyzeTabViewState {
  AnalyzeTabView get type;

  static AnalyzeTabViewState of(AnalyzeTabView view) {
    switch (view) {
      case AnalyzeTabView.doubleStack:
        return DoubleStackView();
      case AnalyzeTabView.netIncome:
        return NetIncomeView();
      case AnalyzeTabView.expenseFlow:
        return ExpenseFlowsView();
      case AnalyzeTabView.incomeFlow:
        return IncomeFlowsView();
      case AnalyzeTabView.expenseHeatmap:
        return ExpenseHeatmapView();
      case AnalyzeTabView.incomeHeatmap:
        return IncomeHeatmapView();
    }
  }
}

class DoubleStackView extends AnalyzeTabViewState with SubcatToggle {
  @override
  AnalyzeTabView get type => AnalyzeTabView.doubleStack;
}

class NetIncomeView extends AnalyzeTabViewState {
  @override
  AnalyzeTabView get type => AnalyzeTabView.netIncome;
}

class ExpenseFlowsView extends AnalyzeTabViewState {
  @override
  AnalyzeTabView get type => AnalyzeTabView.expenseFlow;
}

class IncomeFlowsView extends AnalyzeTabViewState {
  @override
  AnalyzeTabView get type => AnalyzeTabView.incomeFlow;
}

class ExpenseHeatmapView extends AnalyzeTabViewState {
  @override
  AnalyzeTabView get type => AnalyzeTabView.expenseHeatmap;
}

class IncomeHeatmapView extends AnalyzeTabViewState {
  @override
  AnalyzeTabView get type => AnalyzeTabView.incomeHeatmap;
}

mixin SubcatToggle {
  bool showSubcats = false;

  bool toggle() {
    showSubcats = !showSubcats;
    return showSubcats;
  }
}
