import 'package:flutter/material.dart';
import 'package:libra_sheet/data/account.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/test_data.dart';
import 'package:libra_sheet/data/transaction.dart';
import 'package:libra_sheet/graphing/line.dart';
import 'package:libra_sheet/tabs/home/account_list.dart';
import 'package:libra_sheet/tabs/home/account_screen.dart';
import 'package:provider/provider.dart';

class HomeTabState extends ChangeNotifier {
  Account? accountFocused;
  List<Transaction>? accountFocusedTransactions = testTransactions;

  void focusAccount(Account? account) {
    accountFocused = account;
    // load accountFocusedTransactions
    notifyListeners();
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => HomeTabState(),
      child: Consumer<HomeTabState>(
        builder: (context, state, child) {
          if (state.accountFocused != null) {
            return AccountScreen(account: state.accountFocused!);
          } else {
            return const _HomeTab();
          }
        },
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HomeTabState>();
    if (state.accountFocused != null) {
      return const Placeholder();
    } else {
      return Row(
        children: [
          const SizedBox(
            width: 300,
            child: Padding(
              padding: EdgeInsets.only(top: 10),
              child: AccountList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Container(
              width: 1,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                Row(
                  children: [
                    Text(
                      "Net Worth",
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const Spacer(),
                    Text(
                      13413418374.dollarString(),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(width: 5)
                  ],
                ),
                const SizedBox(
                  height: 300,
                  child: TestGraph(),
                ),
                const SizedBox(height: 25),
                const Center(
                  child: SizedBox(
                    height: 300,
                    child: TestPie(),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }
}
