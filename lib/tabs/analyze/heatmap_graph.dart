import 'package:flutter/material.dart';
import 'package:libra_sheet/components/buttons/time_frame_selector.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filters.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/graphing/pie/pie_chart.dart';
import 'package:libra_sheet/graphing/wrapper/category_heat_map.dart';
import 'package:libra_sheet/tabs/analyze/analyze_tab_state.dart';
import 'package:libra_sheet/tabs/analyze/analyze_tab_view_state.dart';
import 'package:libra_sheet/tabs/navigation/libra_navigation.dart';
import 'package:libra_sheet/data/date_time_utils.dart';

(Widget, List<Widget>) heatmapGraph(
    BuildContext context, AnalyzeTabState state, ThemeData theme, List<Category> categories) {
  final viewState = state.currentViewState as HeatmapView;
  final range = state.timeFrame.getRange(state.incomeData.times);
  final individualValues = state.combinedHistorySubCats.getCategoryTotals(range, true);
  final aggregateValues = state.combinedHistory.getCategoryTotals(range, true);

  void onTap(Category category) {
    final dateRange = state.timeFrame.getDateRange(state.combinedHistory.times);
    toCategoryScreen(
      context,
      category,
      initialFilters: TransactionFilters(
        categories: CategoryTristateMap([category]),
        startTime: state.timeFrame.selection == TimeFrameEnum.all ? null : dateRange.$1,
        endTime:
            state.timeFrame.selection != TimeFrameEnum.custom ? null : dateRange.$2?.monthEnd(),
        accounts: state.accounts,
      ),
      initialHistoryTimeFrame: state.timeFrame,
    );
  }

  final headerElements = [
    Text('Show Subcats', style: theme.textTheme.bodyMedium),
    const SizedBox(width: 10),
    Checkbox(
      value: viewState.showSubcats,
      onChanged: (bool? value) => state.setViewState(viewState.withSubcats(value == true)),
    ),
    const VerticalDivider(width: 30, thickness: 3, indent: 4, endIndent: 4),
    Text('View', style: theme.textTheme.bodyMedium),
    const SizedBox(width: 10),
    IconButton(
      color: viewState.showPie ? null : theme.colorScheme.primary,
      onPressed: () => state.setViewState(viewState.withPie(false)),
      icon: const Icon(Icons.view_comfortable),
    ),
    IconButton(
      color: viewState.showPie ? theme.colorScheme.primary : null,
      onPressed: () => state.setViewState(viewState.withPie(true)),
      icon: const Icon(Icons.pie_chart),
    ),
    const Spacer(),
    // Text('Total: ${total.dollarString()}'),
    // const SizedBox(width: 10),
  ];

  final graph = Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: viewState.showPie
        ? PieChart(
            data: viewState.showSubcats
                ? ([categories[0], ...categories.sublist(1).flattened()]) // 0 is super category
                : categories,
            valueMapper: (category) => viewState.showSubcats
                ? individualValues[category.key]?.asDollarDouble() ?? 0
                : aggregateValues[category.key]?.asDollarDouble() ?? 0,
            colorMapper: (category) => category.color,
            labelMapper: (category, value) => "${category.name}\n${formatPercent(value)}",
            onTap: (i, cat) => onTap(cat),
          )
        : CategoryHeatMap(
            categories: categories,
            individualValues: individualValues,
            aggregateValues: aggregateValues,
            onSelect: onTap,
            showSubCategories: viewState.showSubcats,
            // averageDenominator: 1,
          ),
  );

  return (graph, headerElements);
}
