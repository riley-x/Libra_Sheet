import 'package:flutter/material.dart';
import 'package:libra_sheet/components/common_back_bar.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filter_grid.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
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
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1),
        const _BottomBar(),
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
      /// It's kind of slow on clicking a transaction, probably because we're recreating the
      /// Notifier everytime here? but not the end of the world.
      /// Could elevate to above widget and call TransactionDetailsState.replaceSeed in addition
      /// to state.focusTransaction.
      final trans = state.transactions[state.focusedTransIndex];
      return ChangeNotifierProvider(
        key: ObjectKey(trans),
        create: (context) => TransactionDetailsState(
          trans,
          appState: context.read<LibraAppState>(),
          onSave: state.saveTransaction,
          onDelete: (t) => state.deleteTransaction(),
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

class _BottomBar extends StatelessWidget {
  const _BottomBar({super.key});

  void save(BuildContext context, AddCsvState state) {
    Navigator.of(context).pop();
    state.saveAll();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(child: Text('Saved ${state.transactions.length} transactions.')),
        width: 280.0,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AddCsvState>();
    return Container(
      height: 35,
      color: Theme.of(context).colorScheme.primaryContainer.withAlpha(70),
      child: Row(
        children: [
          const SizedBox(width: 10),
          TextButton(
            onPressed: state.clearTransactions,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 5),
                Icon(
                  Icons.navigate_before,
                  size: 26,
                ),
                SizedBox(width: 5),
                Text('Back'),
              ],
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: (state.focusedTransIndex == -1) ? () => save(context, state) : null,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 5),
                Text('Save'),
                Icon(
                  Icons.navigate_next,
                  size: 26,
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
        ],
      ),
    );
  }
}
