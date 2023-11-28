import 'package:flutter/material.dart';
import 'package:libra_sheet/components/common_back_bar.dart';
import 'package:libra_sheet/components/transaction_filter_grid.dart';
import 'package:libra_sheet/tabs/csv/add_csv_state.dart';
import 'package:libra_sheet/tabs/transactionDetails/allocation_editor.dart';
import 'package:libra_sheet/tabs/transactionDetails/reimbursement_editor.dart';
import 'package:libra_sheet/tabs/transactionDetails/transaction_details_editor.dart';
import 'package:libra_sheet/tabs/transactionDetails/transaction_details_state.dart';
import 'package:provider/provider.dart';

class PreviewTransactionsScreen extends StatelessWidget {
  const PreviewTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AddCsvState>();
    return Column(
      children: [
        CommonBackBar(
          leftText: 'Preview Transactions',
          onBack: () => state.clearTransactions(),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: TransactionGrid(
                  state.transactions,
                  fixedColumns: 1,
                  maxRowsForName: 2,
                  onSelect: (t, i) => state.focusTransaction(i),
                ),
              ),
              const VerticalDivider(width: 1, thickness: 1),
              const SizedBox(
                width: 450,
                child: _TransactionDetails(),
              )
            ],
          ),
        ),
      ],
    );
  }
}

class _TransactionDetails extends StatelessWidget {
  const _TransactionDetails({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AddCsvState>();
    if (state.focusedTransIndex == -1) {
      return const SizedBox();
    } else {
      /// It's kind of slow to recreate the Notifier everytime here, but not the end of the world.
      /// Not sure where one could call TransactionDetailsState.replaceSeed.
      final trans = state.transactions[state.focusedTransIndex];
      return ChangeNotifierProvider(
        key: ObjectKey(trans),
        create: (context) => TransactionDetailsState(
          trans,
          onSave: (t) => print(t),
          onDelete: (t) => print(t),
        ),
        builder: (context, child) {
          final focus = context
              .select<TransactionDetailsState, TransactionDetailActiveFocus>((it) => it.focus);
          return IndexedStack(
            index: focus.index,
            children: [
              child!,
              const AllocationEditor(),
              const ReimbursementEditor(),
            ],
          );
        },
        child: TransactionDetailsEditor(
          onCancel: () => state.focusTransaction(-1),
        ),
      );
    }
  }
}
