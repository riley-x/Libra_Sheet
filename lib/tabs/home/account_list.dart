import 'package:flutter/material.dart';
import 'package:libra_sheet/components/cards/account_card.dart';
import 'package:libra_sheet/data/app_state/account_state.dart';
import 'package:libra_sheet/data/int_dollar.dart';
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

    // TODO maybe a splash screen and auto redirect
    if (accounts.isEmpty) {
      return const Center(
        child: Text(
          'Welcome to Libra Sheet!\nPlease add an account in the Settings tab to get started.',
          textAlign: TextAlign.center,
        ),
      );
    }

    List<Widget> accountSection(AccountType type) {
      final accs = [];
      var sum = 0;
      for (final account in accounts) {
        if (account.type == type) {
          sum += account.balance;
          accs.add(AccountCard(account: account));
        }
      }
      if (accs.isEmpty) return const [];
      return [
        Row(
          children: [
            Text(
              "${type.label} Accounts",
              style: Theme.of(context).textTheme.displaySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  sum.dollarString(),
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
        ...accs,
        const SizedBox(height: 20),
      ];
    }

    return ListView(
      padding: padding,
      children: [
        ...accountSection(AccountType.cash),
        ...accountSection(AccountType.bank),
        ...accountSection(AccountType.investment),
        ...accountSection(AccountType.liability),
      ],
    );
  }
}
