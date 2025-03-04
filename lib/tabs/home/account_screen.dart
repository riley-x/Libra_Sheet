import 'package:flutter/material.dart';
import 'package:libra_sheet/components/buttons/time_frame_selector.dart';
import 'package:libra_sheet/components/common_back_bar.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filter_grid.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filter_state.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filters.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_speed_dial.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/app_state/transaction_service.dart';
import 'package:libra_sheet/data/database/category_history.dart';
import 'package:libra_sheet/data/database/libra_database.dart';
import 'package:libra_sheet/data/date_time_utils.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/time_value.dart';
import 'package:libra_sheet/graphing/cartesian/cartesian_axes.dart';
import 'package:libra_sheet/graphing/cartesian/discrete_cartesian_graph.dart';
import 'package:libra_sheet/graphing/cartesian/month_axis.dart';
import 'package:libra_sheet/graphing/cartesian/pooled_tooltip.dart';
import 'package:libra_sheet/graphing/series/line_series.dart';
import 'package:libra_sheet/graphing/series/series.dart';
import 'package:libra_sheet/graphing/wrapper/category_stack_chart.dart';
import 'package:libra_sheet/tabs/home/home_tab_state.dart';
import 'package:libra_sheet/tabs/navigation/libra_navigation.dart';
import 'package:libra_sheet/tabs/transactionDetails/transaction_bulk_editor.dart';
import 'package:provider/provider.dart';

/// Main widget for displaying the details of a single account. Navigated to by clicking on an
/// account in the HomeTab.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key, required this.account});

  final Account account;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  CategoryHistory categoryHistory = CategoryHistory.empty;
  TransactionFilters? initialFilters;
  late TransactionService service;
  bool showIgnored = false;

  Future<void> loadData() async {
    if (!mounted) return; // this is needed because we add [loadData] as a callback to a Notifier.

    /// Load all category histories
    final appState = context.read<LibraAppState>();
    final rawHistory = await LibraDatabase.read((db) => db.getCategoryHistory(
          accounts: [widget.account.key],
        ));
    if (!mounted || rawHistory == null) return; // across async await

    /// Output list
    final newData = CategoryHistory(appState.monthList, invertExpenses: false);
    newData.addIndividual(appState.categories.income, rawHistory, recurseSubcats: false);
    newData.addIndividual(appState.categories.expense, rawHistory, recurseSubcats: false);
    for (final cat in appState.categories.income.subCats + appState.categories.expense.subCats) {
      newData.addCumulative(cat, rawHistory);
    }
    if (showIgnored) {
      newData.addIndividual(appState.categories.other, rawHistory, recurseSubcats: false);
      newData.addIndividual(appState.categories.ignore, rawHistory, recurseSubcats: false);
    }

    setState(() {
      categoryHistory = newData;
    });
  }

  @override
  void initState() {
    super.initState();
    initialFilters = TransactionFilters(accounts: {widget.account});
    service = context.read<TransactionService>();
    service.addListener(loadData);
    loadData();
  }

  @override
  void dispose() {
    super.dispose();
    service.removeListener(loadData);
  }

  void toggleShowIgnored(bool newValue) {
    setState(() {
      showIgnored = newValue;
    });
    loadData();
  }

  String? _filterDescription(TransactionFilters filters) {
    if (filters.hasBasicFilters() ||
        !filters.categories.isEmpty ||
        filters.tags.isNotEmpty ||
        filters.accounts.length != 1 ||
        filters.accounts.first != widget.account) return "Modified";
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HomeTabState>();
    final accountHistory = state.historyMap[widget.account.key];

    return ChangeNotifierProvider(
      create: (context) => TransactionFilterState(
        context.read(),
        initialFilters: initialFilters,
      ),
      builder: (context, child) {
        final transactionState = context.watch<TransactionFilterState>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CommonBackBar(
              leftText: widget.account.name,
              rightText: accountHistory?.values.lastOrNull?.dollarString() ?? '',
              // Don't use account.balance because that can be stale after adding a transaction (still true?)
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: TransactionFilterGrid(
                        createProvider: false,
                        fab: TransactionSpeedDial(initialAccount: widget.account),
                        onSelect: (t) => toTransactionDetails(context, t),
                        filterDescription: _filterDescription,
                        monthEndBalances: accountHistory?.monthEndValues,
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  Expanded(
                    child: (transactionState.selected.isEmpty)
                        ? _Graphs(widget.account, categoryHistory, this)
                        : const TransactionBulkEditor(),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Graphs extends StatelessWidget {
  const _Graphs(this.account, this.categoryHistory, this.state, {super.key});

  final Account account;
  final CategoryHistory categoryHistory;
  final _AccountScreenState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 10, left: 6, top: 6, bottom: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Balance History',
                  style: Theme.of(context).textTheme.headlineSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const _TimeFrameSelector(),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 4, right: 8, bottom: 4),
            child: _Graph(account),
          ),
        ),
        const Divider(height: 1, thickness: 1),
        Padding(
          padding: const EdgeInsets.only(right: 10, left: 6, top: 6, bottom: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Category History',
                  style: Theme.of(context).textTheme.headlineSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'Show\nIgnored',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: state.showIgnored,
                  onChanged: state.toggleShowIgnored,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 4, right: 8, bottom: 4),
            child: _CategoryChart(account, categoryHistory),
          ),
        )
      ],
    );
  }
}

class _TimeFrameSelector extends StatelessWidget {
  const _TimeFrameSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HomeTabState>();
    return TimeFrameSelector(
      months: state.monthList,
      selected: state.timeFrame,
      onSelect: state.setTimeFrame,
      style: const ButtonStyle(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity(horizontal: -4, vertical: -4),
      ),
    );
  }
}

class _Graph extends StatelessWidget {
  const _Graph(this.account, {super.key});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HomeTabState>();
    final months = state.monthList.looseRange(state.timeFrameRange);
    final data = state.historyMap[account.key]?.values.looseRange(state.timeFrameRange) ?? [];

    return DiscreteCartesianGraph(
      yAxis: CartesianAxis(
        theme: Theme.of(context),
        axisLoc: null,
        valToString: (val, [order]) => formatDollar(val, dollarSign: order == null, order: order),
        min: (account.type != AccountType.liability && !data.hasNegative()) ? 0 : null,
        max: (account.type == AccountType.liability && !data.hasPositive()) ? 0 : null,
      ),
      xAxis: MonthAxis(
        theme: Theme.of(context),
        axisLoc: 0,
        dates: months,
        // keep pad=0.5 to align with the category history chart (modulo shifting from the yaxis labels)
      ),
      data: SeriesCollection([
        LineSeries<int>(
          name: "",
          color: account.color,
          data: data,
          valueMapper: (i, item) => Offset(i.toDouble(), item.asDollarDouble()),
          gradient: LinearGradient(
            colors: [
              account.color.withAlpha(10),
              account.color.withAlpha(80),
              account.color.withAlpha(170),
            ],
            stops: const [0.0, 0.6, 1],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            tileMode: TileMode.mirror,
          ),
        ),
      ]),
      hoverTooltip: (painter, loc) => PooledTooltip(
        painter,
        loc,
        labelAlignment: Alignment.center,
      ),
      onRange: (xStart, xEnd) => state.setTimeFrame(TimeFrame(
        TimeFrameEnum.custom,
        customStart: months[xStart],
        customEndInclusive: months[xEnd],
      )),
    );
  }
}

class _CategoryChart extends StatelessWidget {
  const _CategoryChart(this.account, this.categoryHistory, {super.key});

  final Account account;
  final CategoryHistory categoryHistory;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HomeTabState>();
    return CategoryStackChart(
      data: categoryHistory,
      range: state.timeFrameRange,
      onTap: (category, month) {
        toCategoryScreen(
          context,
          category,
          initialHistoryTimeFrame: state.timeFrame,
          initialFilters: TransactionFilters(
            startTime: month,
            endTime: month.monthEnd(),
            categories: CategoryTristateMap({category}),
            accounts: {account},
          ),
        );
      },
      onRange: state.setTimeFrame,
    );
  }
}
