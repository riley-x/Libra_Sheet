import 'package:flutter/material.dart';
import 'package:libra_sheet/components/expense_type_selector.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filters.dart';
import 'package:libra_sheet/data/date_time_utils.dart';
import 'package:libra_sheet/data/enums.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/time_value.dart';
import 'package:libra_sheet/graphing/cartesian/month_axis.dart';
import 'package:libra_sheet/graphing/series/dashed_horiztonal_line.dart';
import 'package:libra_sheet/graphing/wrapper/category_stack_chart.dart';
import 'package:libra_sheet/tabs/analyze/analyze_tab_state.dart';
import 'package:libra_sheet/tabs/analyze/analyze_tab_view_state.dart';
import 'package:libra_sheet/tabs/navigation/libra_navigation.dart';

(Widget, List<Widget>) doubleSidedGraph(
  BuildContext context,
  AnalyzeTabState state,
  ThemeData theme,
) {
  final range = state.timeFrame.getRange(state.incomeData.times);
  final viewState = state.currentViewState as DoubleStackView;
  final total = state.netIncome.looseRange(range).sum();

  void onTap(Category category, DateTime month) {
    toCategoryScreen(
      context,
      category,
      initialHistoryTimeFrame: state.timeFrame,
      initialFilters: TransactionFilters(
        startTime: month,
        endTime: month.monthEnd(),
        categories: CategoryTristateMap({category}),
        accounts: Set.from(state.accounts),
      ),
    );
  }

  final headerElements = [
    /// Show separated
    // const VerticalDivider(width: 30, thickness: 3, indent: 4, endIndent: 4),
    // Text('Show Separated', style: theme.textTheme.bodyMedium),
    // const SizedBox(width: 10),
    // Checkbox(
    //   value: viewState.showSeparated,
    //   onChanged: (bool? value) => state.setViewState(viewState.withSeparated(value == true)),
    // ),

    /// Expense/income
    Text('Show', style: theme.textTheme.bodyMedium),
    const SizedBox(width: 10),
    ExpenseFilterTypeSelector(
      viewState.filterType,
      onSelect: (type) => state.setViewState(viewState.withType(type)),
    ),

    /// Subcats
    const VerticalDivider(width: 30, thickness: 3, indent: 4, endIndent: 4),
    Text('Show Subcats', style: theme.textTheme.bodyMedium),
    const SizedBox(width: 10),
    Checkbox(
      value: viewState.showSubcats,
      onChanged: (bool? value) => state.setViewState(viewState.withSubcats(value == true)),
    ),

    /// Total
    const Spacer(),
    Text('Total: ${total.dollarString()}'),
    const SizedBox(width: 10),
  ];

  final Widget graph;
  if (viewState.showSeparated) {
    final textStyle = theme.textTheme.displaySmall;
    graph = Column(
      children: [
        const SizedBox(height: 4),
        Text("Income", style: textStyle),
        Expanded(
          child: CategoryStackChart(
            data: viewState.showSubcats ? state.incomeDataSubCats : state.incomeData,
            range: range,
            averageColor: Colors.green,
            onTap: (category, month) => onTap(category, month),
            onRange: state.setTimeFrame,
          ),
        ),
        const SizedBox(height: 16),
        Text("Expenses", style: textStyle),
        Expanded(
          child: CategoryStackChart(
            data: viewState.showSubcats ? state.expenseDataSubCats : state.expenseData,
            range: range,
            averageColor: Colors.red.shade700,
            onTap: (category, month) => onTap(category, month),
            onRange: state.setTimeFrame,
            invertValues: true,
          ),
        ),
      ],
    );
  } else {
    final data = switch (viewState.filterType) {
      ExpenseFilterType.all =>
        viewState.showSubcats ? state.combinedHistorySubCats : state.combinedHistory,
      ExpenseFilterType.income =>
        viewState.showSubcats ? state.incomeDataSubCats : state.incomeData,
      ExpenseFilterType.expense =>
        viewState.showSubcats ? state.expenseDataSubCats : state.expenseData,
    };
    graph = CategoryStackChart(
      width: 0.7,
      data: data,
      range: range,
      onTap: (category, month) => onTap(category, month),
      onRange: state.setTimeFrame,
      invertValues: viewState.filterType == ExpenseFilterType.expense,
      xAxis: MonthAxis(
        theme: Theme.of(context),
        axisLoc: 0,
        dates: state.combinedHistory.times.looseRange(range),
        axisPainter: Paint()
          ..color = Theme.of(context).colorScheme.onSurface
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..isAntiAlias = false,
      ),
      extraSeriesBefore: [
        if (viewState.filterType != ExpenseFilterType.expense)
          DashedHorizontalLine(
            y: state.incomeData.getDollarAverageMonthlyTotal(range),
            color: Colors.green,
            lineWidth: 1.5,
          ),
        if (viewState.filterType != ExpenseFilterType.income)
          DashedHorizontalLine(
            y: viewState.filterType == ExpenseFilterType.expense
                ? -state.expenseData.getDollarAverageMonthlyTotal(range)
                : state.expenseData.getDollarAverageMonthlyTotal(range),
            color: Colors.red.shade700,
            lineWidth: 1.5,
          ),
      ],
    );
  }

  return (graph, headerElements);
}
