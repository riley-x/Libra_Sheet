import 'package:flutter/material.dart';
import 'package:libra_sheet/data/test_state.dart';
import 'package:libra_sheet/tabs/home/account_row.dart';
import 'package:provider/provider.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<LibraAppState>();

    return Row(
      children: [
        SizedBox(
          width: 250,
          child: ListView(
            children: [
              for (final account in appState.accounts)
                AccountRow(account: account),
              Text("Next to hell"),
            ],
          ),
        ),
        Expanded(
          child: Placeholder(),
          flex: 1,
        ),
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
