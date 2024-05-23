import 'package:flutter/material.dart';
import 'package:libra_sheet/data/objects/transaction.dart';

/// This is the form that appears when multi-selecting transactions.
class TransactionBulkEditor extends StatelessWidget {
  const TransactionBulkEditor(this.transactions, {super.key});

  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
