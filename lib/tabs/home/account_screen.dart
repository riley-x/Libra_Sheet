import 'package:flutter/material.dart';
import 'package:libra_sheet/components/common_back_bar.dart';
import 'package:libra_sheet/components/transaction_filter_grid.dart';
import 'package:libra_sheet/data/account.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/graphing/line.dart';
import 'package:libra_sheet/tabs/home/chart_with_title.dart';
import 'package:libra_sheet/tabs/home/home_tab.dart';
import 'package:provider/provider.dart';

/// Main widget for displaying the details of a single account. Navigated to by clicking on an
/// account in the HomeTab.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key, required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    var transactions = context.watch<HomeTabState>().accountFocusedTransactions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 5),
        CommonBackBar(
          leftText: account.name,
          rightText: account.balance.dollarString(),
          onBack: () {
            context.read<HomeTabState>().focusAccount(null);
          },
        ),
        const SizedBox(height: 5),
        Container(
          height: 2,
          color: Theme.of(context).colorScheme.outline,
        ),
        Expanded(
          child: Row(
            children: [
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(),
                  child: TransactionFilterGrid(
                    transactions ?? [],
                    fixedColumns: 1,
                    maxRowsForName: 3,
                    onSelect: (it) => print(it.name), // TODO
                  ),
                ),
              ),
              const SizedBox(width: 5),
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
                  child: TestGraph(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
