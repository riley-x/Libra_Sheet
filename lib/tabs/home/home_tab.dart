import 'package:flutter/material.dart';
import 'package:libra_sheet/tabs/home/account_list.dart';
import 'package:libra_sheet/tabs/home/home_charts.dart';
import 'package:provider/provider.dart';

class HomeTabState extends ChangeNotifier {}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => HomeTabState(),
      child: const _HomeTab(),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
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
