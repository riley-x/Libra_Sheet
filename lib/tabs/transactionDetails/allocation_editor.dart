import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:libra_sheet/components/libra_text_field.dart';
import 'package:libra_sheet/components/menus/category_selection_menu.dart';
import 'package:libra_sheet/components/form_buttons.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/components/table_form_utils.dart';
import 'package:libra_sheet/tabs/transactionDetails/transaction_details_state.dart';
import 'package:libra_sheet/tabs/transactionDetails/value_field.dart';
import 'package:provider/provider.dart';

/// Simple form for adding an allocation, used in the second panel of the transaction detail screen.
class AllocationEditor extends StatelessWidget {
  const AllocationEditor({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransactionDetailsState>();
    var categories = context.watch<LibraAppState>().categories.parentCategories(state.expenseType);
    categories += [Category.ignore, Category.other];
    return Column(
      children: [
        const SizedBox(height: 10),
        Text(
          (state.focusedAllocation == null) ? 'Add Allocation' : 'Edit Allocation',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 10),
        Form(
          key: state.allocationFormKey,
          child: Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: const {0: IntrinsicColumnWidth(), 1: FixedColumnWidth(250)},
            children: [
              labelRow(
                context,
                'Name',
                LibraTextFormField(
                  initial: state.focusedAllocation?.name,
                  validator: (it) => null,
                  onSave: (it) => state.updatedAllocation.name = it ?? '',
                ),
              ),
              rowSpacing,
              labelRow(
                context,
                'Date',
                _DateField(
                  initial: state.focusedAllocation?.timestamp,
                  onSave: (it) => state.updatedAllocation.timestamp = it,
                ),
                tooltip:
                    "Optional. If set, allocates this amount to a different date than the parent transaction's.",
              ),
              rowSpacing,
              labelRow(
                context,
                'Value',
                ValueField(
                  initial: state.focusedAllocation?.value,
                  onSave: (it) => state.updatedAllocation.value = it.abs(),
                  // positiveOnly: true,
                ),
                // tooltip: "Value should always be positive.",
              ),
              rowSpacing,
              labelRow(
                context,
                'Category',
                CategorySelectionFormFieldV2(
                  height: 35,
                  initial: state.focusedAllocation?.category,
                  categories: categories,
                  onSave: (it) => state.updatedAllocation.category = it,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FormButtons(
          showDelete: state.focusedAllocation != null,
          // showCancel: state.focusedAllocation == null,
          onDelete: state.deleteAllocation,
          // onReset: state.resetAllocation,
          onSave: state.saveAllocation,
          onCancel: state.clearFocus,
        ),
      ],
    );
  }
}

final _dateFormat = DateFormat('MM/dd/yy');

class _DateField extends StatelessWidget {
  const _DateField({this.initial, this.onSave});

  final DateTime? initial;
  final Function(DateTime)? onSave;

  @override
  Widget build(BuildContext context) {
    return LibraTextFormField(
      initial: (initial == null) ? '' : _dateFormat.format(initial!),
      hint: 'MM/DD/YY',
      validator: (String? value) {
        if (value == null || value.isEmpty) return null;
        try {
          _dateFormat.parse(value, true);
          return null;
        } on FormatException {
          return ''; // No message to not take up sapce
        }
      },
      onSave: (it) {
        if (it != null && it.isNotEmpty) onSave?.call(_dateFormat.parse(it, true));
      },
    );
  }
}
