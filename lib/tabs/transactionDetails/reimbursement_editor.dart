import 'package:flutter/material.dart';
import 'package:libra_sheet/components/form_buttons.dart';
import 'package:libra_sheet/components/cards/transaction_card.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filter_grid.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filters.dart';
import 'package:libra_sheet/data/enums.dart';
import 'package:libra_sheet/components/table_form_utils.dart';
import 'package:libra_sheet/tabs/navigation/libra_navigation.dart';
import 'package:libra_sheet/tabs/transactionDetails/transaction_details_state.dart';
import 'package:libra_sheet/tabs/transactionDetails/value_field.dart';
import 'package:provider/provider.dart';

/// Simple form for adding a reimbursement, used in the second panel of the transaction detail screen.
/// It shows a two-column form at the top and a list of target transactions on bottom.
class ReimbursementEditor extends StatelessWidget {
  final String? subTitle;
  const ReimbursementEditor({super.key, this.subTitle});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransactionDetailsState>();
    return Column(
      children: [
        const SizedBox(height: 10),
        Text(
          (state.focusedReimbursement == null) ? 'Add Reimbursement' : 'Edit Reimbursement',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 10),
        if (subTitle != null)
          Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
            child: Text(subTitle!),
          ),
        const _Form(),
        const SizedBox(height: 20),
        FormButtons(
          showDelete: state.focusedReimbursement != null,
          onDelete: state.deleteReimbursement,
          // onReset: state.resetReimbursement,
          onSave: state.saveReimbursement,
          onCancel: state.clearFocus,
        ),
        if (state.reimbursementError != null)
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 5),
            child: Text(
              state.reimbursementError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const SizedBox(height: 10),
        const Divider(height: 1, thickness: 1),
        // const SizedBox(height: 5),
        const Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: _TransactionsList(),
          ),
        )
      ],
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransactionDetailsState>();
    return Form(
      key: state.reimbursementFormKey,
      child: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: const {
          0: IntrinsicColumnWidth(),
          1: FixedColumnWidth(300),
        },
        children: [
          labelRow(
            context,
            'Value',
            ValueField(
              controller: state.reimbursementValueController,
              onSave: (it) => state.reimbursementValue = it.abs(),
              // positiveOnly: true,
            ),
            // tooltip: "Value should always be positive, even for expenses.",
          ),
          rowSpacing,
          labelRow(
            context,
            'Transaction',
            (state.reimburseTarget == null)
                ? const SizedBox(height: TransactionCard.normalHeight)
                : TransactionCard(
                    trans: state.reimburseTarget!,
                    margin: const EdgeInsets.all(0),
                    showTags: false,
                    onTap: (t) => toTransactionDetails(context, t),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TransactionsList extends StatelessWidget {
  const _TransactionsList({super.key});

  @override
  Widget build(BuildContext context) {
    final expenseType =
        context.select<TransactionDetailsState, ExpenseFilterType>((value) => value.expenseType);
    return TransactionFilterGrid(
      initialFilters: switch (expenseType) {
        ExpenseFilterType.expense => TransactionFilters(minValue: 0),
        ExpenseFilterType.income => TransactionFilters(maxValue: 0),
        ExpenseFilterType.all => null
      },
      quickFilter: true,
      title: Text(
        'Select target transaction',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      onSelect: context.read<TransactionDetailsState>().setReimbursementTarget,
    );
  }
}
