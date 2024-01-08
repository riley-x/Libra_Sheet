import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:libra_sheet/components/cards/transaction_card.dart';
import 'package:libra_sheet/components/TwoElementRow.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/objects/reimbursement.dart';

/// Somewhat similar to [TransactionCard], displays the details of a reimbursement transaction
/// but lists the reimbursement value instead. Also includes a "Add a reimbursement" card when
/// [reimbursement] is null.
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
      if (reimbursement!.target.account != null) {
        accCatStr = reimbursement!.target.account!.name;
      }
      if (accCatStr.isNotEmpty) {
        accCatStr += ', ';
      }
      accCatStr += reimbursement!.target.category.name;

      final dtFormat = DateFormat("M/d/yy");
      content = LimitedBox(
        maxWidth: 500,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reimbursement!.target.name,
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
                Text(
                  reimbursement!.value.dollarString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(dtFormat.format(reimbursement!.target.date)),
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

class ReimbursementCard2 extends StatelessWidget {
  const ReimbursementCard2({super.key, required this.reimbursement, this.onTap});

  final Reimbursement reimbursement;
  final Function(Reimbursement?)? onTap;

  @override
  Widget build(BuildContext context) {
    return TwoElementRow(
      leftWidth: 100,
      rightWidth: 440,
      left: Text(reimbursement.value.dollarString()),
      right: TransactionCard(
        margin: EdgeInsets.zero,
        trans: reimbursement.target,
        onSelect: (onTap == null) ? null : (it) => onTap!.call(reimbursement),
        // rightContent: Padding(
        //   padding: const EdgeInsets.only(left: 20),
        //   child: Column(
        //     crossAxisAlignment: CrossAxisAlignment.end,
        //     children: [
        //       const Text('Reimb:'),
        //       Text(reimbursement.value.dollarString()),
        //     ],
        //   ),
        // ),
      ),
    );
  }
}
