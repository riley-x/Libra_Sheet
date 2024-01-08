import 'package:flutter/material.dart';
import 'package:libra_sheet/components/two_element_row.dart';
import 'package:libra_sheet/data/date_time_utils.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/objects/transaction.dart';

class TransactionTooltip extends StatelessWidget {
  const TransactionTooltip(this.t, {super.key});

  final Transaction t;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 10, top: 3, bottom: 4),
      constraints: const BoxConstraints(maxWidth: 500),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onInverseSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TwoElementRow(
              left: const Text('Account'),
              right: Row(
                children: [
                  Container(color: t.account?.color, width: 4, height: 24),
                  const SizedBox(width: 6),
                  Text(t.account?.name ?? ''),
                ],
              ),
            ),
            TwoElementRow(left: const Text('Date'), right: Text(t.date.MMddyy())),
            TwoElementRow(left: const Text('Value'), right: Text(t.value.dollarString())),
            TwoElementRow(
              left: const Text('Name'),
              right: Text(t.name),
              verticalAlignment: CrossAxisAlignment.start,
            ),
            TwoElementRow(
              left: const Text('Category'),
              right: Row(
                children: [
                  if (t.category.level > 0) ...[
                    Container(color: t.category.color, width: 4, height: 24),
                    const SizedBox(width: 6),
                  ],
                  Text(t.category.name),
                ],
              ),
            ),
            if (t.note.isNotEmpty)
              TwoElementRow(
                left: const Text('Note'),
                right: Text(t.note),
                verticalAlignment: CrossAxisAlignment.start,
              ),
          ],
        ),
      ),
    );
  }
}
