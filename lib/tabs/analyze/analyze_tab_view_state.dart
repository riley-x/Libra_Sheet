enum AnalyzeTabView {
  doubleStack,
  netIncome,
  expenseFlow,
  incomeFlow,
  expenseHeatmap,
  incomeHeatmap
}

abstract class AnalyzeTabViewState {
  AnalyzeTabView get type;

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
        return const ExpenseHeatmapView(showSubcats: false, showPie: false);
      case AnalyzeTabView.incomeHeatmap:
        return const IncomeHeatmapView(showSubcats: false, showPie: false);
    }
  }
}

class DoubleStackView implements AnalyzeTabViewState {
  const DoubleStackView({required this.showSubcats});

  @override
  AnalyzeTabView get type => AnalyzeTabView.doubleStack;

  final bool showSubcats;

  DoubleStackView withSubcats(bool value) {
    return DoubleStackView(showSubcats: value);
  }
}

class NetIncomeView implements AnalyzeTabViewState {
  const NetIncomeView({required this.includeOther});

  @override
  AnalyzeTabView get type => AnalyzeTabView.netIncome;

  final bool? includeOther;

  NetIncomeView withOther(bool? value) {
    return NetIncomeView(includeOther: value);
  }
}

class ExpenseFlowsView implements AnalyzeTabViewState {
  @override
  AnalyzeTabView get type => AnalyzeTabView.expenseFlow;
}

class IncomeFlowsView implements AnalyzeTabViewState {
  @override
  AnalyzeTabView get type => AnalyzeTabView.incomeFlow;
}

abstract class HeatmapView implements AnalyzeTabViewState {
  final bool showSubcats;
  final bool showPie;

  const HeatmapView({required this.showSubcats, required this.showPie});

  HeatmapView withSubcats(bool value);
  HeatmapView withPie(bool value);
}

class ExpenseHeatmapView extends HeatmapView {
  const ExpenseHeatmapView({required super.showSubcats, required super.showPie});

  @override
  AnalyzeTabView get type => AnalyzeTabView.expenseHeatmap;

  @override
  ExpenseHeatmapView withSubcats(bool value) {
    return ExpenseHeatmapView(showSubcats: value, showPie: showPie);
  }

  @override
  ExpenseHeatmapView withPie(bool value) {
    return ExpenseHeatmapView(showSubcats: showSubcats, showPie: value);
  }
}

class IncomeHeatmapView extends HeatmapView {
  const IncomeHeatmapView({required super.showSubcats, required super.showPie});

  @override
  AnalyzeTabView get type => AnalyzeTabView.incomeHeatmap;

  @override
  IncomeHeatmapView withSubcats(bool value) {
    return IncomeHeatmapView(showSubcats: value, showPie: showPie);
  }

  @override
  IncomeHeatmapView withPie(bool value) {
    return IncomeHeatmapView(showSubcats: showSubcats, showPie: value);
  }
}
