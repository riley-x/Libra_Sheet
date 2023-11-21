import 'package:flutter/material.dart';
import 'package:libra_sheet/components/form_buttons.dart';
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
              rowSpacing,
              labelRow(
                context,
                'Value',
                ValueField(
                  initial: state.focusedReimbursement?.value,
                  onSave: (it) => state.updatedReimbursement.value = it,
                  positiveOnly: true,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FormButtons(
          allowDelete: state.focusedReimbursement != null,
          // showCancel: state.focusedReimbursement == null,
          onDelete: state.deleteReimbursement,
          onReset: state.resetReimbursement,
          onSave: state.saveReimbursement,
          onCancel: state.clearFocus,
        )
      ],
    );
  }
}
