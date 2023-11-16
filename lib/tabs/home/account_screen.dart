import 'package:flutter/material.dart';
import 'package:libra_sheet/components/transaction_card.dart';
import 'package:libra_sheet/data/account.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/transaction.dart';
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
            const SizedBox(width: 5),
          ],
        ),
        const TestGraph(),
        const SizedBox(height: 20),
        Row(
          children: [
            Text(
              "Recent Transactions",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Spacer(),
            IconButton(
              onPressed: null,
              icon: Icon(
                Icons.filter_alt,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 10),
          ],
        ),
        TransactionCard(
            trans: Transaction(
                name: "test test",
                date: DateTime(2023, 11, 12),
                value: 12322300)),
        Expanded(
          child: ListView(
            children: ((transactions != null)
                ? [
                    for (final t in transactions) TransactionCard(trans: t),
                  ]
                : []),
          ),
        ),
      ],
    );
  }
}
