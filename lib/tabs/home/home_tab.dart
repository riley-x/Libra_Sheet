import 'package:flutter/material.dart';
import 'package:libra_sheet/data/account.dart';
import 'package:libra_sheet/data/test_data.dart';
import 'package:libra_sheet/data/transaction.dart';
import 'package:libra_sheet/tabs/home/account_list.dart';
import 'package:libra_sheet/tabs/home/account_screen.dart';
import 'package:libra_sheet/tabs/home/home_charts.dart';
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
            width: 370,
            child: AccountList(
              padding: EdgeInsets.only(top: 10, left: 10, right: 10),
            ),
          ),
          Container(
            width: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const Expanded(child: HomeCharts()),
        ],
      );
    }
  }
}
