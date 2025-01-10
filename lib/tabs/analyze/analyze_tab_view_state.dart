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

  const AnalyzeTabViewState();

  static AnalyzeTabViewState of(AnalyzeTabView view) {
    switch (view) {
      case AnalyzeTabView.doubleStack:
        return const DoubleStackView(showSubcats: false);
      case AnalyzeTabView.netIncome:
        return const NetIncomeView(includeOther: false);
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

class DoubleStackView extends AnalyzeTabViewState {
  const DoubleStackView({required this.showSubcats});

  @override
  AnalyzeTabView get type => AnalyzeTabView.doubleStack;

  final bool showSubcats;

  DoubleStackView withSubcats(bool value) {
    return DoubleStackView(showSubcats: value);
  }
}

class NetIncomeView extends AnalyzeTabViewState {
  const NetIncomeView({required this.includeOther});

  @override
  AnalyzeTabView get type => AnalyzeTabView.netIncome;

  final bool? includeOther;

  NetIncomeView withOther(bool? value) {
    return NetIncomeView(includeOther: value);
  }
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
