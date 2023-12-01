import 'package:flutter/material.dart';
import 'package:libra_sheet/components/form_buttons.dart';
import 'package:libra_sheet/components/cards/transaction_card.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filter_grid.dart';
import 'package:libra_sheet/data/enums.dart';
import 'package:libra_sheet/data/objects/transaction.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filter_state.dart';
import 'package:libra_sheet/tabs/transactionDetails/table_form_utils.dart';
import 'package:libra_sheet/tabs/transactionDetails/transaction_details_state.dart';
import 'package:libra_sheet/tabs/transactionDetails/value_field.dart';
import 'package:provider/provider.dart';

/// Simple form for adding a reimbursement, used in the second panel of the transaction detail screen.
class ReimbursementEditor extends StatelessWidget {
  const ReimbursementEditor({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransactionDetailsState>();
    return Column(
      children: [
        const SizedBox(height: 10),
        Text(
          (state.focusedReimbursement == null) ? 'Add Reimbursement' : 'Edit Reimbursement',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 10),
        Form(
          key: state.reimbursementFormKey,
          child: Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: const {
              0: IntrinsicColumnWidth(),
              1: FixedColumnWidth(250),
            },
            children: [
              labelRow(
                context,
                'Value',
                ValueField(
                  initial: state.focusedReimbursement?.value,
                  onSave: (it) => state.reimbursementValue = it,
                  positiveOnly: true,
                ),
                tooltip: "Value should always be positive.",
              ),
              rowSpacing,
              labelRow(
                context,
                'Transaction',
                Visibility(
                  visible: state.reimburseTarget != null,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: TransactionCard(
                    trans: state.reimburseTarget ?? dummyTransaction,
                    margin: const EdgeInsets.all(0),
                    showTags: false,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FormButtons(
          showDelete: state.focusedReimbursement != null,
          onDelete: state.deleteReimbursement,
          onReset: state.resetReimbursement,
          onSave: state.saveReimbursement,
          onCancel: state.clearFocus,
        ),
        const SizedBox(height: 10),
        Container(
          height: 1,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        // const SizedBox(height: 5),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: TransactionFilterGrid(
              initialFilters: switch (state.expenseType) {
                ExpenseFilterType.expense => TransactionFilters(minValue: 0),
                ExpenseFilterType.income => TransactionFilters(maxValue: 0),
                ExpenseFilterType.all => null
              },
              title: Text(
                'Select target transaction',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              onSelect: state.setReimbursementTarget,
            ),
          ),
        )
      ],
    );
  }
}
