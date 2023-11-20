import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/transaction.dart';

class TransactionCard extends StatelessWidget {
  const TransactionCard({super.key, required this.trans, this.maxRowsForName = 1});

  final Transaction trans;
  final int? maxRowsForName;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    final dtFormat = DateFormat("M/d/yy");

    var subText = '';
    if (trans.account != null) {
      subText += trans.account!.name;
    }
    if (trans.category != null) {
      if (subText.isNotEmpty) {
        subText += ', ';
      }
      subText += trans.category!.name;
    }

    return GestureDetector(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trans.name,
                      maxLines: maxRowsForName,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
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
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: (trans.value < 0) ? theme.colorScheme.error : Colors.green),
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
