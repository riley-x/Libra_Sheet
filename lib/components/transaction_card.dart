import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/transaction.dart';

class TransactionCard extends StatelessWidget {
  const TransactionCard({super.key, required this.trans});

  final Transaction trans;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    final dtFormat = DateFormat.yMMMd();

    return GestureDetector(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trans.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      // style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      trans.account?.name ?? "",
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.outline),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    trans.value.dollarString(),
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(
                    dtFormat.format(trans.date),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
