import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:libra_sheet/data/account.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/test_state.dart';
import 'package:libra_sheet/tabs/home/home_tab.dart';
import 'package:provider/provider.dart';

class AccountRow extends StatelessWidget {
  const AccountRow({
    super.key,
    required this.account,
  });

  final Account account;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var lastUpdatedColor = theme.colorScheme.outline;
    if (account.lastUpdated != null &&
        account.lastUpdated!.difference(DateTime.now()).inDays < -30) {
      lastUpdatedColor = theme.colorScheme.error;
    }

    return GestureDetector(
      onTap: () {
        context.read<HomeTabState>().focusAccount(account);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(
                    account.number,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.outline),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    account.balance.dollarString(),
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(
                    account.lastUpdated != null
                        ? "Updated: ${DateFormat.MMMd().format(account.lastUpdated!)}"
                        : "",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: lastUpdatedColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AccountList extends StatelessWidget {
  const AccountList({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<LibraAppState>();

    return ListView(
      children: [
        Text(
          "Bank Accounts",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        for (final account in appState.accounts) AccountRow(account: account),
        const SizedBox(height: 20),
        Text(
          "Investment Accounts",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        for (final account in appState.accounts) AccountRow(account: account),
        const SizedBox(height: 20),
        Text(
          "Liabilities",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        for (final account in appState.accounts) AccountRow(account: account),
      ],
    );
  }
}