import 'package:flutter/material.dart';
import 'package:libra_sheet/components/common_back_bar.dart';
import 'package:libra_sheet/components/dialogs/confirmation_dialog.dart';
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
    /// We have to create the [TransactionDetailsState] provider here because
    ///   1. The [LayoutBuilder] in [_Body] would recreate it whenever the screen layout changes.
    ///   2. Can override the back buttons to be more intuitive when navigating into the transaction
    ///      details.
    return ChangeNotifierProvider(
      create: (context) => TransactionDetailsState(
        null,
        appState: context.read<LibraAppState>(),
        onSave: context.read<AddCsvState>().saveTransaction,
        onDelete: (t) => context.read<AddCsvState>().deleteTransaction(),
        onSaveRule: context.read<AddCsvState>().reprocessRule,
      ),
      builder: (context, child) {
        void onBack() async {
          final csvState = context.read<AddCsvState>();
          final detailsState = context.read<TransactionDetailsState>();
          if (csvState.focusedTransIndex == -1) {
            final confirmed = await showConfirmationDialog(
                context: context,
                title: 'Back to CSV Input?',
                msg: "This will delete any changes you've made here.");
            if (confirmed) csvState.cancelPreviewTransactions();
          } else if (detailsState.focus == TransactionDetailActiveFocus.none) {
            csvState.focusTransaction(-1);
          } else {
            detailsState.clearFocus();
          }
        }

        return Column(
          children: [
            CommonBackBar(
              leftText: 'Preview Transactions',
              onBack: onBack,
            ),
            const Expanded(child: _Body()),
            const Divider(height: 1, thickness: 1),
            _BottomBar(onBack: onBack),
          ],
        );
      },
    );
  }
}

/// The main body of the preview screen. It displays a list of the newly created transactions on the
/// left and a transaction editor on the right. If the window is too narrow, the editor overlays
/// the list instead.
class _Body extends StatelessWidget {
  const _Body({super.key});

  @override
  Widget build(BuildContext context) {
    final csvState = context.watch<AddCsvState>();
    final transactions = TransactionGrid(
      csvState.transactions,
      fixedColumns: 1,
      maxRowsForName: 2,
      onTap: (t, i) {
        csvState.focusTransaction(i);
        context.read<TransactionDetailsState>().replaceSeed(t);
      },
    );
    final details = TransactionDetailsEditor(
      onCancel: () => csvState.focusTransaction(-1),
    );
    const reimbursements = ReimbursementEditor(
      subTitle: 'Only saved transactions appear below. If you want to reimburse two of the preview '
          'transactions with each other, please save them first.',
    );

    final focus =
        context.select<TransactionDetailsState, TransactionDetailActiveFocus>((it) => it.focus);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          /// Layout transaction grid and editor as a single stack
          return IndexedStack(
            index: csvState.focusedTransIndex == -1 ? 0 : 1 + focus.index,
            children: [
              transactions,
              details,
              const AllocationEditor(),
              reimbursements,
            ],
          );
        } else {
          /// Layout transaction grid side-by-side with editor
          return Row(
            children: [
              Expanded(child: transactions),
              const VerticalDivider(width: 1, thickness: 1),
              SizedBox(
                width: 475,
                child: IndexedStack(
                  index: csvState.focusedTransIndex == -1 ? 0 : 1 + focus.index,
                  children: [
                    const SizedBox(),
                    details,
                    const AllocationEditor(),
                    reimbursements,
                  ],
                ),
              ),
            ],
          );
        }
      },
    );
  }
}

/// This is the bottom bar on the add csv navigation path. It contains a back button and a save
/// button.
class _BottomBar extends StatelessWidget {
  final Function() onBack;
  const _BottomBar({super.key, required this.onBack});

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
            onPressed: onBack,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.navigate_before,
                  size: 26,
                ),
                SizedBox(width: 5),
                Text('Back'),
                SizedBox(width: 5),
              ],
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: (state.focusedTransIndex == -1) ? () => save(context, state) : null,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 10),
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
