import 'package:libra_sheet/data/enums.dart';

/// A view mode selectable in the [AnalyzeTabViewSelector]
enum AnalyzeTabView {
  doubleStack,
  sankey,
  netIncome,
  other,
  expenseFlow,
  incomeFlow,
  expenseHeatmap,
  incomeHeatmap,
}

/// View-specific state for each [AnalyzeTabView]
abstract class AnalyzeTabViewState {
  AnalyzeTabView get type;

  const AnalyzeTabViewState();

  static AnalyzeTabViewState of(AnalyzeTabView view) {
    switch (view) {
      case AnalyzeTabView.doubleStack:
        return const DoubleStackView(showSubcats: false);
      case AnalyzeTabView.sankey:
        return const SankeyView(showAverages: false);
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
  const DoubleStackView({
    required this.showSubcats,
    this.showSeparated = false,
    this.filterType = ExpenseFilterType.all,
  });

  @override
  AnalyzeTabView get type => AnalyzeTabView.doubleStack;

  final bool showSubcats;
  final bool showSeparated;
  final ExpenseFilterType filterType;

  DoubleStackView withSubcats(bool value) {
    return DoubleStackView(
      showSubcats: value,
      showSeparated: showSeparated,
      filterType: filterType,
    );
  }

  DoubleStackView withSeparated(bool value) {
    return DoubleStackView(showSubcats: showSubcats, showSeparated: value, filterType: filterType);
  }

  DoubleStackView withType(ExpenseFilterType filterType) => DoubleStackView(
    showSubcats: showSubcats,
    showSeparated: showSeparated,
    filterType: filterType,
  );
}

class SankeyView implements AnalyzeTabViewState {
  const SankeyView({this.showAverages = false, this.layoutTree = true});

  @override
  AnalyzeTabView get type => AnalyzeTabView.sankey;

  final bool showAverages;
  final bool layoutTree;

  SankeyView withAverages(bool value) {
    return SankeyView(showAverages: value, layoutTree: layoutTree);
  }

  SankeyView withLayoutTree(bool value) {
    return SankeyView(showAverages: showAverages, layoutTree: value);
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
  final bool proportional;

  const FlowsView({this.showSubcats = false, this.proportional = false});

  FlowsView withSubcats(bool value);
  FlowsView withProportional(bool value);
}

class ExpenseFlowsView extends FlowsView {
  @override
  AnalyzeTabView get type => AnalyzeTabView.expenseFlow;

  const ExpenseFlowsView({super.showSubcats, super.proportional});

  @override
  FlowsView withProportional(bool value) {
    return ExpenseFlowsView(showSubcats: showSubcats, proportional: value);
  }

  @override
  FlowsView withSubcats(bool value) {
    return ExpenseFlowsView(showSubcats: value, proportional: proportional);
  }
}

class IncomeFlowsView extends FlowsView {
  @override
  AnalyzeTabView get type => AnalyzeTabView.incomeFlow;

  const IncomeFlowsView({super.showSubcats, super.proportional});

  @override
  FlowsView withProportional(bool value) {
    return IncomeFlowsView(showSubcats: showSubcats, proportional: value);
  }

  @override
  FlowsView withSubcats(bool value) {
    return IncomeFlowsView(showSubcats: value, proportional: proportional);
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
  const ExpenseHeatmapView({
    required super.showSubcats,
    super.showAverages,
    required super.showPie,
  });

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
