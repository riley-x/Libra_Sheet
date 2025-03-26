/// A view mode selectable in the [AnalyzeTabViewSelector]
enum AnalyzeTabView {
  doubleStack,
  netIncome,
  other,
  expenseFlow,
  incomeFlow,
  expenseHeatmap,
  incomeHeatmap
}

/// View-specific state for each [AnalyzeTabView]
abstract class AnalyzeTabViewState {
  AnalyzeTabView get type;

  const AnalyzeTabViewState();

  static AnalyzeTabViewState of(AnalyzeTabView view) {
    switch (view) {
      case AnalyzeTabView.doubleStack:
        return const DoubleStackView(showSubcats: false);
      case AnalyzeTabView.netIncome:
        return const NetIncomeView(includeOther: false);
      case AnalyzeTabView.other:
        return const OtherView();
      case AnalyzeTabView.expenseFlow:
        return const ExpenseFlowsView();
      case AnalyzeTabView.incomeFlow:
        return const IncomeFlowsView();
      case AnalyzeTabView.expenseHeatmap:
        return const ExpenseHeatmapView(showSubcats: false, showPie: false);
      case AnalyzeTabView.incomeHeatmap:
        return const IncomeHeatmapView(showSubcats: false, showPie: false);
    }
  }
}

class DoubleStackView implements AnalyzeTabViewState {
  const DoubleStackView({required this.showSubcats, this.showSeparated = false});

  @override
  AnalyzeTabView get type => AnalyzeTabView.doubleStack;

  final bool showSubcats;
  final bool showSeparated;

  DoubleStackView withSubcats(bool value) {
    return DoubleStackView(showSubcats: value, showSeparated: showSeparated);
  }

  DoubleStackView withSeparated(bool value) {
    return DoubleStackView(showSubcats: showSubcats, showSeparated: value);
  }
}

class NetIncomeView implements AnalyzeTabViewState {
  const NetIncomeView({this.includeOther = false, this.cumulative = false});

  @override
  AnalyzeTabView get type => AnalyzeTabView.netIncome;

  final bool? includeOther;
  final bool cumulative;

  NetIncomeView withOther(bool? value) {
    return NetIncomeView(includeOther: value, cumulative: cumulative);
  }

  NetIncomeView withCumulative(bool value) {
    return NetIncomeView(includeOther: includeOther, cumulative: value);
  }
}

class OtherView implements AnalyzeTabViewState {
  const OtherView({this.cumulative = false});

  @override
  AnalyzeTabView get type => AnalyzeTabView.other;

  final bool cumulative;

  OtherView withCumulative(bool value) {
    return OtherView(cumulative: value);
  }
}

abstract class FlowsView implements AnalyzeTabViewState {
  final bool showSubcats;
  final bool justified;

  const FlowsView({this.showSubcats = false, this.justified = false});

  FlowsView withSubcats(bool value);
  FlowsView withJustified(bool value);
}

class ExpenseFlowsView extends FlowsView {
  @override
  AnalyzeTabView get type => AnalyzeTabView.expenseFlow;

  const ExpenseFlowsView({super.showSubcats, super.justified});

  @override
  FlowsView withJustified(bool value) {
    return ExpenseFlowsView(showSubcats: showSubcats, justified: value);
  }

  @override
  FlowsView withSubcats(bool value) {
    return ExpenseFlowsView(showSubcats: value, justified: justified);
  }
}

class IncomeFlowsView extends FlowsView {
  @override
  AnalyzeTabView get type => AnalyzeTabView.incomeFlow;

  const IncomeFlowsView({super.showSubcats, super.justified});

  @override
  FlowsView withJustified(bool value) {
    return IncomeFlowsView(showSubcats: showSubcats, justified: value);
  }

  @override
  FlowsView withSubcats(bool value) {
    return IncomeFlowsView(showSubcats: value, justified: justified);
  }
}

abstract class HeatmapView extends AnalyzeTabViewState {
  final bool showSubcats;
  final bool showAverages;
  final bool showPie;

  const HeatmapView({required this.showSubcats, this.showAverages = false, required this.showPie});

  HeatmapView withSubcats(bool value);
  HeatmapView withAverages(bool value);
  HeatmapView withPie(bool value);
}

class ExpenseHeatmapView extends HeatmapView {
  const ExpenseHeatmapView(
      {required super.showSubcats, super.showAverages, required super.showPie});

  @override
  AnalyzeTabView get type => AnalyzeTabView.expenseHeatmap;

  @override
  ExpenseHeatmapView withSubcats(bool value) {
    return ExpenseHeatmapView(showSubcats: value, showAverages: showAverages, showPie: showPie);
  }

  @override
  ExpenseHeatmapView withPie(bool value) {
    return ExpenseHeatmapView(showSubcats: showSubcats, showAverages: showAverages, showPie: value);
  }

  @override
  ExpenseHeatmapView withAverages(bool value) {
    return ExpenseHeatmapView(showSubcats: showSubcats, showAverages: value, showPie: showPie);
  }
}

class IncomeHeatmapView extends HeatmapView {
  const IncomeHeatmapView({required super.showSubcats, super.showAverages, required super.showPie});

  @override
  AnalyzeTabView get type => AnalyzeTabView.incomeHeatmap;

  @override
  IncomeHeatmapView withSubcats(bool value) {
    return IncomeHeatmapView(showSubcats: value, showAverages: showAverages, showPie: showPie);
  }

  @override
  IncomeHeatmapView withPie(bool value) {
    return IncomeHeatmapView(showSubcats: showSubcats, showAverages: showAverages, showPie: value);
  }

  @override
  HeatmapView withAverages(bool value) {
    return IncomeHeatmapView(showSubcats: showSubcats, showAverages: value, showPie: showPie);
  }
}
