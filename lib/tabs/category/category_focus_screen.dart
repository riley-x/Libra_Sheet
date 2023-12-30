import 'package:flutter/material.dart';
import 'package:libra_sheet/components/buttons/time_frame_selector.dart';
import 'package:libra_sheet/components/common_back_bar.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filter_grid.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filters.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/app_state/transaction_service.dart';
import 'package:libra_sheet/data/database/category_history.dart';
import 'package:libra_sheet/data/database/libra_database.dart';
import 'package:libra_sheet/data/date_time_utils.dart';
import 'package:libra_sheet/data/enums.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/time_value.dart';
import 'package:libra_sheet/graphing/wrapper/category_stack_chart.dart';
import 'package:libra_sheet/graphing/wrapper/red_green_bar_chart.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filter_state.dart';
import 'package:libra_sheet/tabs/navigation/libra_navigation.dart';
import 'package:provider/provider.dart';

/// Full-screen Widget that shows the details for a single category. On the left column is a list
/// of transactions, and on the right column is a history bar chart.
///
/// [initialFilters] sets what data is being loaded. If [initialFilters.categories] is null, it will
/// be autofilled with the current category.
///   - For the transaction list, the filters are used directly.
///   - For the bar chart, The accounts are used and other fields are ignored.
class CategoryFocusScreen extends StatefulWidget {
  const CategoryFocusScreen({
    super.key,
    required this.category,
    this.initialFilters,
    this.initialHistoryTimeFrame,
  });

  final Category category;
  final TransactionFilters? initialFilters;
  final TimeFrame? initialHistoryTimeFrame;

  @override
  State<CategoryFocusScreen> createState() => _CategoryFocusScreenState();
}

class _CategoryFocusScreenState extends State<CategoryFocusScreen> {
  CategoryHistory data = CategoryHistory.empty;
  TimeFrame historyTimeFrame = const TimeFrame(TimeFrameEnum.all);
  late TransactionService service;
  late TransactionFilters initialFilters;

  Future<void> loadData() async {
    if (!mounted) return; // this is needed because we add [loadData] as a callback to a Notifier.

    /// Load all category histories
    final appState = context.read<LibraAppState>();
    final rawHistory = await LibraDatabase.db.getCategoryHistory(
      accounts: initialFilters.accounts.map((e) => e.key),
    );
    if (!mounted) return; // across async await

    /// Output list.
    final newData = CategoryHistory(appState.monthList);
    newData.addIndividual(widget.category, rawHistory, recurseSubcats: widget.category.level == 1);
    // Don't add subcats for the super categories with level == 0

    setState(() {
      data = newData;
    });
  }

  void onSetTimeFrame(TimeFrame it) {
    setState(() {
      historyTimeFrame = it;
    });
  }

  @override
  void initState() {
    super.initState();
    service = context.read<TransactionService>();
    service.addListener(loadData);

    initialFilters = widget.initialFilters ?? TransactionFilters();
    if (initialFilters.categories.isEmpty) {
      initialFilters.categories = CategoryTristateMap({widget.category});
    }

    if (widget.initialHistoryTimeFrame != null) {
      historyTimeFrame = widget.initialHistoryTimeFrame!;
    }

    loadData();
  }

  @override
  void dispose() {
    super.dispose();
    service.removeListener(loadData);
  }

  @override
  Widget build(BuildContext context) {
    var title = widget.category.name;
    if (widget.category == Category.income) title += " Income"; // "Uncategorized Income"
    if (widget.category == Category.expense) title += " Expense";

    String? rightText;
    if (initialFilters.accounts.length == 1) {
      rightText = "Account: ${initialFilters.accounts.first.name}";
    } else if (initialFilters.accounts.length > 1) {
      rightText = "Multiple accounts";
    }

    /// Provide the [TransactionFilterState] here so we can callback to it easily.
    return ChangeNotifierProvider(
      create: (context) => TransactionFilterState(service, initialFilters: initialFilters),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 5),
          CommonBackBar(
            leftText: title,
            rightText: rightText,
            rightStyle: Theme.of(context).textTheme.titleMedium,
          ),
          Expanded(
            child: _Body(
              category: widget.category,
              initialFilters: initialFilters,
              data: data,
              historyTimeFrame: historyTimeFrame,
              onSetTimeFrame: onSetTimeFrame,
            ),
          ),
        ],
      ),
    );
  }
}

String? dateRangeFilterDescription(TransactionFilters filters) {
  if (filters.startTime != null && filters.endTime != null) {
    return "${filters.startTime!.MMddyy()}\n- ${filters.endTime!.MMddyy()}";
  } else if (filters.startTime != null) {
    return "From\n${filters.startTime!.MMddyy()}";
  } else if (filters.endTime != null) {
    return "Up to\n${filters.endTime!.MMddyy()}";
  } else {
    return null;
  }
}

class _Body extends StatelessWidget {
  const _Body({
    super.key,
    this.initialFilters,
    required this.category,
    required this.data,
    required this.historyTimeFrame,
    required this.onSetTimeFrame,
  });

  final Category category;
  final TransactionFilters? initialFilters;
  final CategoryHistory data;
  final TimeFrame historyTimeFrame;
  final Function(TimeFrame) onSetTimeFrame;

  @override
  Widget build(BuildContext context) {
    final range = historyTimeFrame.getRange(data.times);
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 0), // this offsets the title
            child: TransactionFilterGrid(
              padding: const EdgeInsets.only(right: 10, left: 10),
              createProvider: false,
              fixedColumns: 1,
              maxRowsForName: 3,
              onSelect: (t) => toTransactionDetails(context, t),
              filterDescription: dateRangeFilterDescription,
            ),
          ),
        ),
        Container(
          width: 1,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        const SizedBox(width: 2),
        Expanded(
          child: _HistoryChart(
            category: category,
            data: data,
            range: range,
            initialFilters: initialFilters,
            historyTimeFrame: historyTimeFrame,
            onSetTimeFrame: onSetTimeFrame,
          ),
        ),
        const SizedBox(width: 2),
      ],
    );
  }
}

class _HistoryChart extends StatelessWidget {
  const _HistoryChart({
    super.key,
    required this.data,
    required this.historyTimeFrame,
    required this.onSetTimeFrame,
    required this.category,
    required this.range,
    required this.initialFilters,
  });

  final CategoryHistory data;
  final TimeFrame historyTimeFrame;
  final Function(TimeFrame p1) onSetTimeFrame;
  final Category category;
  final (int, int) range;
  final TransactionFilters? initialFilters;

  @override
  Widget build(BuildContext context) {
    /// When clicking on the bar chart, if the same category, just update the transaction list to
    /// the selected month.
    void setFilterMonth(DateTime month) {
      final filterState = context.read<TransactionFilterState>();
      filterState.setFilters(TransactionFilters(
        accounts: Set.from(initialFilters?.accounts ?? {}),
        categories: CategoryTristateMap({category}, false),
        startTime: month,
        endTime: month.monthEnd(),
      ));
    }

    return Column(
      children: [
        // This empircally matches the extra height caused by the icon button in the transaction
        // filter grid
        SizedBox(
          height: 40,
          child: Row(
            children: [
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Category History',
                  style: Theme.of(context).textTheme.headlineSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TimeFrameSelector(
                style: const ButtonStyle(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                ),
                months: data.times,
                selected: historyTimeFrame,
                onSelect: onSetTimeFrame,
              ),
              const SizedBox(width: 10),
            ],
          ),
        ),
        Expanded(
          child: (data.categories.isEmpty)
              ? const SizedBox() // this prevents a flicker from the default [0, 100] empty chart
              : (category.type == ExpenseFilterType.all)
                  // This screen is also used for Investment Returns and possibly Ignore
                  // which both use type [all]. In these cases there's gauranteed only one
                  // category but we have both positive and negative values. So show RedGreen
                  // instead.
                  ? RedGreenBarChart(
                      [
                        for (int i = range.$1; i < range.$2; i++)
                          TimeIntValue(
                            time: data.times[i],
                            value: data.categories.first.values[i],
                          ),
                      ],
                      onSelect: (_, point) => setFilterMonth(point.time),
                    )
                  // Otherwise, just a normal category, and show the stack chart.
                  : CategoryStackChart(
                      data: data,
                      range: range,
                      onTap: (category, month) {
                        if (category == this.category) {
                          setFilterMonth(month);
                        } else {
                          toCategoryScreen(
                            context,
                            category,
                            initialHistoryTimeFrame: historyTimeFrame,
                            initialFilters: TransactionFilters(
                              startTime: month,
                              endTime: month.monthEnd(),
                              categories: CategoryTristateMap({category}),
                              accounts: initialFilters?.accounts,
                            ),
                          );
                        }
                      },
                    ),
        ),
        // Which values to show? Should match transaction filters? But the category history
        // is all...and it's unintuitive what is being displayed. For example, if focusing on
        // one month, don't want to display just one month history but do want to in heatmap.
        // Also, it's more consistent without this because subcats, supercats, and cats without
        // children don't have the heatmap anyways.

        // if (state.aggregateValues[category.key] != state.individualValues[category.key]) ...[
        //   const SizedBox(height: 5),
        //   Container(
        //     height: 1,
        //     color: Theme.of(context).colorScheme.outlineVariant,
        //   ),
        //   Expanded(
        //     child: Padding(
        //       padding: const EdgeInsets.all(8.0),
        //       child: CategoryHeatMap(
        //         categories: category.subCats + [category],
        //         individualValues: state.individualValues,
        //         aggregateValues: state.individualValues,
        //         // individual here because the focus screen is always nested categories
        //         onSelect: (it) {
        //           if (it != category) context.read<CategoryTabState>().focusCategory(it);
        //         },
        //       ),
        //     ),
        //   ),
        // ],
      ],
    );
  }
}
