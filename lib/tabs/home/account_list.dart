import 'package:flutter/material.dart';
import 'package:libra_sheet/components/cards/account_card.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:provider/provider.dart';

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
          if (account.type == AccountType.cash) AccountCard(account: account),
        ],
        const SizedBox(height: 20),
        Text(
          "Bank Accounts",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        for (final account in appState.accounts) ...[
          if (account.type == AccountType.bank) AccountCard(account: account),
        ],
        const SizedBox(height: 20),
        Text(
          "Investment Accounts",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        for (final account in appState.accounts) ...[
          if (account.type == AccountType.investment) AccountCard(account: account),
        ],
        const SizedBox(height: 20),
        Text(
          "Liabilities",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        for (final account in appState.accounts) ...[
          if (account.type == AccountType.liability) AccountCard(account: account),
        ],
      ],
    );
  }
}
