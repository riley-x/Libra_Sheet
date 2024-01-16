import 'package:flutter/material.dart';
import 'package:libra_sheet/components/common_back_bar.dart';
import 'package:libra_sheet/components/dialogs/confirmation_dialog.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/app_state/transaction_service.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/data/objects/transaction.dart';
import 'package:libra_sheet/tabs/transactionDetails/allocation_editor.dart';
import 'package:libra_sheet/tabs/transactionDetails/reimbursement_editor.dart';
import 'package:libra_sheet/tabs/transactionDetails/transaction_details_editor.dart';
import 'package:libra_sheet/tabs/transactionDetails/transaction_details_state.dart';
import 'package:provider/provider.dart';

/// This is a top-level screen that is added to LibraAppState's backstack. It shows two columns.
/// On the left are FormFields for editing the current transaction's fields. On the right is a
/// space to edit allocations and reimbursements. When the screen is not wide enough, the latter
/// is converted to a second screen with a back button (but this is not added to the LibraAppState
/// backstack).
class TransactionDetailsScreen extends StatelessWidget {
  const TransactionDetailsScreen(
    this.original, {
    super.key,
    this.initialAccount,
  });

  /// Transaction being edited, or null if a new transaction.
  final Transaction? original;

  /// Optional initial values to set the form fields with.
  final Account? initialAccount;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TransactionDetailsState(
        original,
        appState: context.read<LibraAppState>(),
        initialAccount: initialAccount,
        onSave: (old, nu) {
          context.read<TransactionService>().save(old, nu);
          Navigator.of(context).pop();
        },
        onDelete: (t) {
          showConfirmationDialog(
            context: context,
            title: "Delete Transaction?",
            msg: "Are you sure you want to delete this transaction? This cannot be undone!",
            onConfirmed: () {
              context.read<TransactionService>().delete(t);
              Navigator.of(context).pop();
            },
          );
        },
      ),
      builder: (context, child) {
        final seed = context.select<TransactionDetailsState, Transaction?>((it) => it.seed);
        return Column(
          children: [
            CommonBackBar(
              leftText: "Transaction Editor",
              rightText: (seed == null || seed.key == 0)
                  ? "New transaction"
                  : "Database key: ${original?.key}",
              rightStyle: Theme.of(context).textTheme.labelMedium,
              onBack: () {
                final state = context.read<TransactionDetailsState>();
                if (state.focus != TransactionDetailActiveFocus.none) {
                  state.clearFocus();
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
            const Expanded(child: _TransactionDetailsScreen()),
          ],
        );
      },
    );
  }
}

class _TransactionDetailsScreen extends StatelessWidget {
  const _TransactionDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const mainEditor = TransactionDetailsEditor();

    final focus =
        context.select<TransactionDetailsState, TransactionDetailActiveFocus>((it) => it.focus);
    final auxEditor = switch (focus) {
      TransactionDetailActiveFocus.none => const SizedBox(),
      TransactionDetailActiveFocus.allocation => const AllocationEditor(),
      TransactionDetailActiveFocus.reimbursement => const ReimbursementEditor(),
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 1000) {
          /// The IndexedStack keeps the FormField states alive when transitioning to the
          /// auxEditor and back.
          return IndexedStack(
            index: focus == TransactionDetailActiveFocus.none ? 0 : 1,
            children: [
              mainEditor,
              auxEditor,
            ],
          );
        } else {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              mainEditor,
              Container(
                width: 1,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              Expanded(child: auxEditor),
            ],
          );
        }
      },
    );
  }
}
