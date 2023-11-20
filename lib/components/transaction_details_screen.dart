import 'package:flutter/material.dart';
import 'package:libra_sheet/components/common_back_bar.dart';
import 'package:libra_sheet/data/transaction.dart';

class TransactionDetailsScreen extends StatelessWidget {
  const TransactionDetailsScreen(this.transaction, {super.key});

  /// Transaction used to initialize the fields. Also, the key is used in case of "Update".
  final Transaction? transaction;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CommonBackBar(
          leftText: "Transaction Editor",
          rightText: "Database key: ${transaction?.key}",
          rightStyle: Theme.of(context).textTheme.labelMedium,
        ),
      ],
    );
  }
}
