import 'package:flutter/material.dart';
import 'package:libra_sheet/components/transaction_filter_grid.dart';
import 'package:libra_sheet/data/account.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/graphing/line.dart';
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
        Row(
          children: [
            IconButton(
              onPressed: () {
                context.read<HomeTabState>().focusAccount(null);
              },
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              account.name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const Spacer(),
            Text(
              account.balance.dollarString(),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(width: 15),
          ],
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
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Container(
                width: 1,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              const SizedBox(width: 5),
              const Expanded(child: TestGraph()),
              const SizedBox(width: 10),
            ],
          ),
        ),
      ],
    );
  }
}
