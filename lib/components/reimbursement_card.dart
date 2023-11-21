import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/reimbursement.dart';

class ReimbursementCard extends StatelessWidget {
  final Reimbursement? reimbursement;
  final Function(Reimbursement?)? onTap;

  const ReimbursementCard(
    this.reimbursement, {
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    Widget? content;
    if (reimbursement == null) {
      content = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(width: 5, height: 30),
          Text(
            'Add a reimbursement',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      );
    } else {
      var accCatStr = '';
      final dtFormat = DateFormat("M/d/yy");
      if (reimbursement!.otherTransaction.account != null) {
        accCatStr = reimbursement!.otherTransaction.account!.name;
      }
      if (reimbursement!.otherTransaction.category != null) {
        if (accCatStr.isNotEmpty) {
          accCatStr += ', ';
        }
        accCatStr += reimbursement!.otherTransaction.category!.name;
      }
      content = LimitedBox(
        maxWidth: 300,
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Text(
                    reimbursement!.otherTransaction.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    accCatStr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(reimbursement!.value.dollarString()),
                Text(dtFormat.format(reimbursement!.otherTransaction.date)),
              ],
            ),
          ],
        ),
      );
    }
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: (onTap == null) ? null : () => onTap!.call(reimbursement),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: content,
        ),
      ),
    );
  }
}
