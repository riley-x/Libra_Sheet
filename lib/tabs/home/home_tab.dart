import 'package:flutter/material.dart';
import 'package:libra_sheet/data/account.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/test_state.dart';
import 'package:libra_sheet/tabs/home/account_row.dart';
import 'package:provider/provider.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<LibraAppState>();
    final account =
        Account(name: 'Robinhood', number: 'xxx-1234', balance: 13451200);

    return Row(
      children: [
        Expanded(
          child: ListView(
            children: [
              for (final account in appState.accounts)
                AccountRow(account: account),
              Text("Next to hell"),
            ],
          ),
        ),
        Placeholder(),
      ],
    );
    // return Row(
    //   children: [
    //     ListView(
    //       children: const [
    //         Text('Test1'),
    //         Text('Test2'),
    //       ],
    //     )
    //   ],
    // );
  }
}
