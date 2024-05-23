import 'package:flutter/material.dart';
import 'package:libra_sheet/components/buttons/time_frame_selector.dart';
import 'package:libra_sheet/components/common_back_bar.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filter_grid.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filters.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_speed_dial.dart';
import 'package:libra_sheet/data/database/category_history.dart';
import 'package:libra_sheet/data/database/libra_database.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/time_value.dart';
import 'package:libra_sheet/graphing/cartesian/cartesian_axes.dart';
import 'package:libra_sheet/graphing/cartesian/discrete_cartesian_graph.dart';
import 'package:libra_sheet/graphing/cartesian/month_axis.dart';
import 'package:libra_sheet/graphing/cartesian/snap_line_hover.dart';
import 'package:libra_sheet/graphing/series/line_series.dart';
import 'package:libra_sheet/graphing/series/series.dart';
import 'package:libra_sheet/tabs/home/home_tab_state.dart';
import 'package:libra_sheet/tabs/navigation/libra_navigation.dart';
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
  // List<TimeIntValue> data = [];
  TransactionFilters? initialFilters;
  // TransactionService? service;

  // Future<void> loadData() async {
  //   if (!mounted) return;
  //   final appState = context.read<LibraAppState>();
  //   var newData = await LibraDatabase.read((db) => db.getMonthlyNet(accountId: widget.account.key));
  //   if (!mounted || newData == null) return;

  //   newData = newData.withAlignedTimes(appState.monthList, cumulate: true, trimStart: true);
  //   if (newData.length == 1) {
  //     // Duplicate the data point so the plot isn't empty
  //     newData.add(newData[0].withTime((it) => it.add(const Duration(seconds: 1))));
  //   }
  //   setState(() {
  //     data = newData!;
  //   });
  // }

  @override
  void initState() {
    super.initState();
    initialFilters = TransactionFilters(accounts: {widget.account});
    // service = context.read<TransactionService>();
    // service!.addListener(loadData);
    // loadData();
  }

  @override
  void dispose() {
    super.dispose();
    // service?.removeListener(loadData);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HomeTabState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommonBackBar(
          leftText: widget.account.name,
          rightText: state.historyMap[widget.account.key]?.values.lastOrNull?.dollarString() ?? '',
          // Don't use account.balance because that can be stale after adding a transaction
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: TransactionFilterGrid(
                  initialFilters: initialFilters,
                  fab: TransactionSpeedDial(initialAccount: widget.account),
                  onSelect: (t) => toTransactionDetails(context, t),
                  filterDescription: (filters) {
                    if (filters.hasBasicFilters() ||
                        !filters.categories.isEmpty ||
                        filters.tags.isNotEmpty ||
                        filters.accounts.length != 1 ||
                        filters.accounts.first != widget.account) return "Modified";
                    return null;
                  },
                ),
              ),
              Container(
                width: 1,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              Expanded(
                child: _GraphWithTitle(widget.account),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GraphWithTitle extends StatelessWidget {
  const _GraphWithTitle(this.account, {super.key});

  final Account account;

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
    return DiscreteCartesianGraph(
      yAxis: CartesianAxis(
        theme: Theme.of(context),
        axisLoc: null,
        valToString: formatDollar,
        min: 0,
      ),
      xAxis: MonthAxis(
        theme: Theme.of(context),
        axisLoc: 0,
        dates: state.monthList.looseRange(state.timeFrameRange),
        pad: 0,
      ),
      data: SeriesCollection([
        LineSeries<int>(
          name: "",
          color: account.color,
          data: state.historyMap[account.key]?.values.looseRange(state.timeFrameRange) ?? [],
          valueMapper: (i, item) => Offset(i.toDouble(),
              (account.type == AccountType.liability ? -item : item).asDollarDouble()),
          gradient: LinearGradient(
            colors: [
              account.color.withAlpha(10),
              account.color.withAlpha(80),
              account.color.withAlpha(170),
            ],
            stops: const [0.0, 0.6, 1],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
      ]),
      hoverTooltip: (painter, loc) => PooledTooltip(
        painter,
        loc,
        labelAlignment: Alignment.center,
      ),
    );
  }
}
