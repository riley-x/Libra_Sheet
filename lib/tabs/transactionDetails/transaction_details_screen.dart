import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:libra_sheet/components/libra_chip.dart';
import 'package:libra_sheet/components/reimbursement_card.dart';
import 'package:libra_sheet/components/selectors/account_selection_menu.dart';
import 'package:libra_sheet/components/selectors/category_selection_menu.dart';
import 'package:libra_sheet/components/common_back_bar.dart';
import 'package:libra_sheet/components/libra_text_field.dart';
import 'package:libra_sheet/components/selectors/dropdown_checkbox_menu.dart';
import 'package:libra_sheet/data/libra_app_state.dart';
import 'package:libra_sheet/data/tag.dart';
import 'package:libra_sheet/data/transaction.dart';
import 'package:libra_sheet/tabs/transactionDetails/table_form_utils.dart';
import 'package:libra_sheet/tabs/transactionDetails/transaction_details_state.dart';
import 'package:provider/provider.dart';

import '../../components/allocation_card.dart';
import '../../components/tri_buttons.dart';
import 'value_field.dart';

class TransactionDetailsScreen extends StatelessWidget {
  const TransactionDetailsScreen(this.transaction, {super.key});

  /// Transaction used to initialize the fields. Also, the key is used in case of "Update".
  final Transaction? transaction;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TransactionDetailsState(transaction),
      child: Column(
        children: [
          CommonBackBar(
            leftText: "Transaction Editor",
            rightText: "Database key: ${transaction?.key}",
            rightStyle: Theme.of(context).textTheme.labelMedium,
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SingleChildScrollView(
                  physics: ClampingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: _TransactionDetails(),
                  ),
                ),
                Container(
                  width: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionDetails extends StatelessWidget {
  const _TransactionDetails({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransactionDetailsState>();

    /// WARNING!
    /// Form rebuilds every FormField descendant on every change of one of the fields (i.e. it calls
    /// their respective builder functions). (Tested and noted in the onChange() callback).
    /// This may not be ideal...
    return Form(
      key: state.formKey,
      child: SizedBox(
        width: 450,
        child: Column(
          children: [
            Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: const {
                0: IntrinsicColumnWidth(),
                1: FixedColumnWidth(250),
              },
              children: [
                labelRow(
                  context,
                  'Account',
                  AccountSelectionFormField(
                    height: 35,
                    initial: state.seed?.account,
                    onSave: (it) => state.account = it,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                rowSpacing,
                labelRow(
                  context,
                  'Name',
                  LibraTextFormField(
                    initial: state.seed?.name,
                    minLines: 3,
                    maxLines: 3,
                    validator: (it) => null,
                    onSave: (it) => state.name = it,
                  ),
                ),
                rowSpacing,
                labelRow(
                  context,
                  'Date',
                  _DateField(
                    initial: state.seed?.date,
                    onSave: (it) => state.date = it,
                  ),
                ),
                rowSpacing,
                labelRow(
                  context,
                  'Value',
                  ValueField(
                    initial: state.seed?.value,
                    onSave: (it) => state.value = it,
                    onChanged: state.onValueChanged,
                  ),
                ),
                rowSpacing,
                labelRow(
                  context,
                  'Category',
                  CategorySelectionFormField(
                    height: 35,
                    initial: state.seed?.category,
                    onSave: (it) => state.category = it,
                    borderRadius: BorderRadius.circular(4),
                    type: state.expenseType,
                  ),
                ),
                rowSpacing,
                labelRow(
                  context,
                  'Tags',
                  _TagSelector(
                    tags: state.tags,
                    onChanged: state.onTagChanged,
                  ),
                ),
                rowSpacing,
                labelRow(
                  context,
                  'Note',
                  LibraTextFormField(
                    initial: state.seed?.note,
                    validator: (it) => null,
                    onSave: (it) => state.note = it,
                  ),
                ),
                rowSpacing,
                labelRow(
                  context,
                  'Allocations',
                  Column(
                    children: [
                      for (final alloc in state.allocations) ...[
                        AllocationCard(alloc),
                        const SizedBox(height: 4)
                      ],
                      const AllocationCard(null),
                    ],
                  ),
                  labelAlign: TableCellVerticalAlignment.top,
                ),
                rowSpacing,
                rowSpacing,
                labelRow(
                  context,
                  'Reimbursements',
                  Column(
                    children: [
                      for (final r in state.reimbursements) ...[
                        ReimbursementCard(
                          r,
                          onTap: (it) {},
                        ),
                        const SizedBox(height: 6)
                      ],
                      ReimbursementCard(
                        null,
                        onTap: (it) {},
                      ),
                    ],
                  ),
                  labelAlign: TableCellVerticalAlignment.top,
                ),
              ],
            ),
            const SizedBox(height: 20),
            TriButtons(
              allowDelete: (state.seed?.key ?? 0) > 0,
              onDelete: state.delete,
              onReset: state.reset,
              onSave: state.save,
            ),
          ],
        ),
      ),
    );
  }
}

final _dateFormat = DateFormat('MM/dd/yy');

class _DateField extends StatelessWidget {
  const _DateField({
    super.key,
    this.initial,
    this.onSave,
  });

  final DateTime? initial;
  final Function(DateTime)? onSave;

  @override
  Widget build(BuildContext context) {
    return LibraTextFormField(
      initial: (initial == null) ? '' : _dateFormat.format(initial!),
      hint: 'MM/DD/YY',
      validator: (String? value) {
        if (value == null || value.isEmpty) return ''; // No message to not take up sapce
        try {
          _dateFormat.parse(value);
          return null;
        } on FormatException {
          return '';
        }
      },
      onSave: (it) => onSave?.call(_dateFormat.parse(it!)),
    );
  }
}

class _TagSelector extends StatelessWidget {
  const _TagSelector({super.key, required this.tags, this.onChanged});

  final List<Tag> tags;
  final Function(Tag, bool?)? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final tag in tags)
                LibraChip(
                  tag.name,
                  onTap: () => onChanged?.call(tag, false),
                ),
            ],
          ),
        ),
        DropdownCheckboxMenu<Tag>(
          icon: Icons.add,
          items: context.watch<LibraAppState>().tags,
          builder: (context, tag) => Text(
            tag.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          isChecked: (it) => tags.contains(it),
          onChanged: onChanged,
        ),
        const SizedBox(width: 7.5),
      ],
    );
  }
}
