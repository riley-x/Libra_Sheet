import 'package:flutter/material.dart';
import 'package:libra_sheet/data/account.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/tabs/home/home_tab.dart';
import 'package:provider/provider.dart';

/// Main widget for displaying the details of a single account. Navigated to by clicking on an
/// account in the HomeTab.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key, required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    return Column(
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
        )
      ],
    );
  }
}
