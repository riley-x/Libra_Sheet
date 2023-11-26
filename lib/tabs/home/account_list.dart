import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:provider/provider.dart';

class AccountRow extends StatelessWidget {
  const AccountRow({
    super.key,
    required this.account,
    this.onTap,
  });

  final Account account;
  final Function(Account)? onTap;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var lastUpdatedColor = theme.colorScheme.outline;
    if (account.lastUpdated != null &&
        account.lastUpdated!.difference(DateTime.now()).inDays < -30) {
      lastUpdatedColor = theme.colorScheme.error;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          if (onTap != null) {
            onTap?.call(account);
          } else {
            context.read<LibraAppState>().focusAccount(account);
          }
        },
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
                    account.description,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
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
  final EdgeInsets padding;

  const AccountList({
    super.key,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<LibraAppState>();

    return ListView(
      padding: padding,
      children: [
        Text(
          "Cash Accounts",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        for (final account in appState.accounts) ...[
          if (account.type == AccountType.cash) AccountRow(account: account),
        ],
        const SizedBox(height: 20),
        Text(
          "Bank Accounts",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        for (final account in appState.accounts) ...[
          if (account.type == AccountType.bank) AccountRow(account: account),
        ],
        const SizedBox(height: 20),
        Text(
          "Investment Accounts",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        for (final account in appState.accounts) ...[
          if (account.type == AccountType.investment) AccountRow(account: account),
        ],
        const SizedBox(height: 20),
        Text(
          "Liabilities",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        for (final account in appState.accounts) ...[
          if (account.type == AccountType.liability) AccountRow(account: account),
        ],
      ],
    );
  }
}
