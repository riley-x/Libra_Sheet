import 'package:flutter/material.dart';
import 'package:libra_sheet/components/common_back_bar.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filter_grid.dart';
import 'package:libra_sheet/data/database/category_history.dart';
import 'package:libra_sheet/data/database/libra_database.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/time_value.dart';
import 'package:libra_sheet/graphing/date_time_graph.dart';
import 'package:libra_sheet/tabs/home/chart_with_title.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filter_state.dart';
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

  Future<void> loadData() async {
    final appState = context.read<LibraAppState>();
    var newData = await LibraDatabase.db.getMonthlyNet(accountId: widget.account.key);
    newData = newData.withAlignedTimes(appState.monthList, cumulate: true).fixedForCharts();
    setState(() {
      data = newData;
    });
  }

  @override
  void initState() {
    super.initState();
    loadData();
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
                  initialFilters: TransactionFilters(accounts: {widget.account}),
                  showSpeedDial: true,
                  // onSelect: context.read<LibraAppState>().focusTransaction,
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
                      xValueMapper: (TimeIntValue sales, _) => sales.time,
                      yValueMapper: (TimeIntValue sales, _) => sales.value.abs().asDollarDouble(),
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
