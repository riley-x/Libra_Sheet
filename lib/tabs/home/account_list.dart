import 'package:flutter/material.dart';
import 'package:libra_sheet/components/cards/account_card.dart';
import 'package:libra_sheet/data/app_state/account_state.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:provider/provider.dart';

/// The account list view used in the sidebar of the home tab.
class AccountList extends StatelessWidget {
  final EdgeInsets padding;

  const AccountList({
    super.key,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<AccountState>().list;

    return ListView(
      padding: padding,
      children: [
        Text(
          "Cash Accounts",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        for (final account in accounts) ...[
          if (account.type == AccountType.cash) AccountCard(account: account),
        ],
        const SizedBox(height: 20),
        Text(
          "Bank Accounts",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        for (final account in accounts) ...[
          if (account.type == AccountType.bank) AccountCard(account: account),
        ],
        const SizedBox(height: 20),
        Text(
          "Investment Accounts",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        for (final account in accounts) ...[
          if (account.type == AccountType.investment) AccountCard(account: account),
        ],
        const SizedBox(height: 20),
        Text(
          "Liabilities",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        for (final account in accounts) ...[
          if (account.type == AccountType.liability) AccountCard(account: account),
        ],
      ],
    );
  }
}
