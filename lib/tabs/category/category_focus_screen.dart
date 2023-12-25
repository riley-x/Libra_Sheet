import 'package:flutter/material.dart';
import 'package:libra_sheet/components/common_back_bar.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filter_grid.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/app_state/transaction_service.dart';
import 'package:libra_sheet/data/database/category_history.dart';
import 'package:libra_sheet/data/database/libra_database.dart';
import 'package:libra_sheet/data/date_time_utils.dart';
import 'package:libra_sheet/data/enums.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/time_value.dart';
import 'package:libra_sheet/graphing/category_stack_chart.dart';
import 'package:libra_sheet/graphing/red_green_bar_chart.dart';
import 'package:libra_sheet/tabs/home/chart_with_title.dart';
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
  });

  final Category category;
  final TransactionFilters? initialFilters;

  @override
  State<CategoryFocusScreen> createState() => _CategoryFocusScreenState();
}

class _CategoryFocusScreenState extends State<CategoryFocusScreen> {
  CategoryHistory data = CategoryHistory.empty;
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

    /// Output list
    final newData = CategoryHistory(appState.monthList);
    newData.addIndividual(widget.category, rawHistory, recurseSubcats: widget.category.level == 1);

    setState(() {
      data = newData;
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
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    super.key,
    required this.category,
    this.initialFilters,
    required this.data,
  });

  final Category category;
  final TransactionFilters? initialFilters;
  final CategoryHistory data;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 10), // this offsets the title
            child: TransactionFilterGrid(
              padding: const EdgeInsets.only(right: 10),
              createProvider: false,
              initialFilters: initialFilters,
              fixedColumns: 1,
              maxRowsForName: 3,
              onSelect: (t) => toTransactionDetails(context, t),
            ),
          ),
        ),
        Container(
          width: 1,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        Expanded(
          child: Column(
            children: [
              /// this empircally matches the extra height caused by the icon button in the transaction filter grid
              const SizedBox(height: 7),
              Expanded(
                child: ChartWithTitle(
                  textLeft: 'Category History',
                  textStyle: Theme.of(context).textTheme.headlineSmall,
                  child: (category.type == ExpenseFilterType.all)
                      // This screen is also used for Investment Returns and Net income/expense
                      // which both use type [all]. In these cases there's gauranteed only one
                      // category but we have both positive and negative values. So show RedGreen
                      // instead.
                      ? RedGreenBarChart(
                          [
                            for (int i = 0; i < data.times.length; i++)
                              TimeIntValue(
                                time: data.times[i],
                                value: data.categories.firstOrNull?.values[i] ?? 0,
                              ),
                          ],
                          onSelect: (_, point) {
                            final filterState = context.read<TransactionFilterState>();
                            filterState.filters.categories = CategoryTristateMap({category}, false);
                            filterState.setStartTime(point.time, false);
                            filterState.setEndTime(point.time.monthEnd());
                          },
                        )
                      // Otherwise, just a normal category, and show the stack chart.
                      : CategoryStackChart(
                          data: data,
                          onTap: (category, month) {
                            if (category == this.category) {
                              final filterState = context.read<TransactionFilterState>();
                              filterState.filters.categories =
                                  CategoryTristateMap({category}, false);
                              filterState.setStartTime(month, false);
                              filterState.setEndTime(month.monthEnd());
                            } else {
                              toCategoryScreen(
                                context,
                                category,
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
              ),
              // TODO which values to show? Should match transaction filters? But the category history
              // is all...and it's unintuitive what is being displayed. For example, if focusing on
              // one month, don't want to display just one month history but do want to in heatmap.

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
          ),
        ),
      ],
    );
  }
}
