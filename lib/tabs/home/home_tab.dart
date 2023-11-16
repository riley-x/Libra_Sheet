import 'package:flutter/material.dart';
import 'package:libra_sheet/data/account.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/graphing/line.dart';
import 'package:libra_sheet/tabs/home/account_list.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
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
              const TestGraph(),
              Center(
                child: Container(
                  // width: 500,
                  // height: 500,
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
