import 'package:flutter/material.dart';
import 'package:libra_sheet/components/common_back_bar.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filter_grid.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filters.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_speed_dial.dart';
import 'package:libra_sheet/data/app_state/transaction_service.dart';
import 'package:libra_sheet/data/database/category_history.dart';
import 'package:libra_sheet/data/database/libra_database.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/time_value.dart';
import 'package:libra_sheet/graphing/date_time_graph.dart';
import 'package:libra_sheet/tabs/home/chart_with_title.dart';
import 'package:libra_sheet/tabs/navigation/libra_navigation.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// Main widget for displaying the details of a single account. Navigated to by clicking on an
/// account in the HomeTab.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key, required this.account});

  final Account account;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  List<TimeIntValue> data = [];
  TransactionFilters? initialFilters;
  TransactionService? service;

  Future<void> loadData() async {
    if (!mounted) return;
    final appState = context.read<LibraAppState>();
    var newData = await LibraDatabase.read((db) => db.getMonthlyNet(accountId: widget.account.key));
    if (!mounted || newData == null) return;

    newData = newData
        .withAlignedTimes(appState.monthList, cumulate: true, trimStart: true)
        .fixedForCharts();
    if (newData.length == 1) {
      // Duplicate the data point so the plot isn't empty
      newData.add(newData[0].withTime((it) => it.add(const Duration(seconds: 1))));
    }
    setState(() {
      data = newData!;
    });
  }

  @override
  void initState() {
    super.initState();
    initialFilters = TransactionFilters(accounts: {widget.account});
    service = context.read<TransactionService>();
    service!.addListener(loadData);
    loadData();
  }

  @override
  void dispose() {
    super.dispose();
    service?.removeListener(loadData);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommonBackBar(
          leftText: widget.account.name,
          rightText: data.lastOrNull?.value.dollarString() ?? '',
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
                ),
              ),
              Container(
                width: 1,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              Expanded(
                child: ChartWithTitle(
                  /// this empircally matches the extra height caused by the icon button in the transaction filter grid
                  padding: const EdgeInsets.only(top: 7),
                  textLeft: 'Balance History',
                  textStyle: Theme.of(context).textTheme.headlineSmall,
                  child: DateTimeGraph([
                    AreaSeries<TimeIntValue, DateTime>(
                      animationDuration: 300,
                      dataSource: data,
                      xValueMapper: (TimeIntValue it, _) => it.time,
                      yValueMapper: (TimeIntValue it, _) =>
                          (widget.account.type == AccountType.liability)
                              ? -it.value.asDollarDouble()
                              : it.value.asDollarDouble(),
                      borderColor: widget.account.color,
                      borderWidth: 3,
                      borderDrawMode: BorderDrawMode.top,
                      gradient: LinearGradient(
                        colors: [
                          widget.account.color.withAlpha(10),
                          widget.account.color.withAlpha(80),
                          widget.account.color.withAlpha(170),
                        ],
                        stops: const [0.0, 0.6, 1],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
