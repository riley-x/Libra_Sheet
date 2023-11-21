import 'package:flutter/material.dart';
import 'package:libra_sheet/data/allocation.dart';
import 'package:libra_sheet/tabs/transactionDetails/transaction_details_state.dart';
import 'package:provider/provider.dart';

/// Simple form for adding an allocation, used in the second panel of the transaction detail screen.
class AllocationEditor extends StatelessWidget {
  const AllocationEditor({
    super.key,
    this.initial,
  });

  final Allocation? initial;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransactionDetailsState>();
    return Column(
      children: [
        Text((initial == null) ? 'Add Allocation' : 'Edit Allocation'),
      ],
    );
  }
}
