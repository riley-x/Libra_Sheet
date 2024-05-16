import 'package:flutter/material.dart';
import 'package:libra_sheet/tabs/home/account_list.dart';
import 'package:libra_sheet/tabs/home/home_charts.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 400,
          child: AccountList(
            padding: EdgeInsets.only(top: 10, left: 10, right: 12, bottom: 10),
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
