sealed class AnalyzeTabViewState {}

class DoubleStackView extends AnalyzeTabViewState with SubcatToggle {}

class NetIncomeView extends AnalyzeTabViewState {}

class ExpenseFlowsView extends AnalyzeTabViewState {}

class IncomeFlowsView extends AnalyzeTabViewState {}

class ExpenseHeatmapView extends AnalyzeTabViewState {}

class IncomeHeatmapView extends AnalyzeTabViewState {}

mixin SubcatToggle {
  bool showSubcats = false;

  bool toggle() {
    showSubcats = !showSubcats;
    return showSubcats;
  }
}
