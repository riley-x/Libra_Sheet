import 'package:flutter/material.dart';
import 'package:libra_sheet/data/transaction.dart';

class TransactionDetails extends StatelessWidget {
  const TransactionDetails(this.transaction, {super.key, this.onBack});

  /// Transaction used to initialize the fields. Also, the key is used in case of "Update".
  final Transaction? transaction;
  final Function()? onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              "Transaction Editor",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const Spacer(),
            Text(
              "Database key: ${transaction?.key}",
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(width: 15),
          ],
        ),
      ],
    );
  }
}
