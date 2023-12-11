import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:libra_sheet/components/cards/allocation_card.dart';
import 'package:libra_sheet/components/cards/libra_chip.dart';
import 'package:libra_sheet/components/libra_text_field.dart';
import 'package:libra_sheet/components/cards/reimbursement_card.dart';
import 'package:libra_sheet/components/menus/account_selection_menu.dart';
import 'package:libra_sheet/components/menus/category_selection_menu.dart';
import 'package:libra_sheet/components/menus/dropdown_checkbox_menu.dart';
import 'package:libra_sheet/components/form_buttons.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/objects/tag.dart';
import 'package:libra_sheet/tabs/transactionDetails/table_form_utils.dart';
import 'package:libra_sheet/tabs/transactionDetails/transaction_details_state.dart';
import 'package:libra_sheet/tabs/transactionDetails/value_field.dart';
import 'package:provider/provider.dart';

/// This lays out a single-column form for the fields of one transaction. This is used both in the
/// full-screen [TransactionDetailsScreen], and in the half-column of [PreviewTransactionsScreen]
/// when adding CSVs.
class TransactionDetailsEditor extends StatelessWidget {
  const TransactionDetailsEditor({super.key, this.onCancel});

  final Function()? onCancel;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransactionDetailsState>();
    var categories =
        context.watch<LibraAppState>().categories.flattenedCategories(state.expenseType);
    categories = [Category.empty, Category.ignore, Category.investment] + categories + [];
    // the transaction constructor will convert Category.empty into the correct super category
    // however we must manually convert the initial category to [Category.empty] so that there isn't
    // a duplicate.
    Category? initialCategory() {
      if (state.seed == null) return null;
      if (state.seed!.category == Category.income || state.seed!.category == Category.expense) {
        return Category.empty;
      }
      return state.seed!.category;
    }

    /// WARNING!
    /// Form rebuilds every FormField descendant on every change of one of the fields (i.e. it calls
    /// their respective builder functions). (Tested and noted in the onChange() callback).
    /// This may not be ideal...
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child: FocusScope(
          child: Form(
            key: state.formKey,
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
                      '', // not used
                      CategorySelectionFormField(
                        height: 35,
                        initial: initialCategory(),
                        categories: categories,
                        onSave: (it) => state.category = it,
                      ),
                      labelCustom: const _CategoryLabel(),
                    ),
                    rowSpacing,
                    labelRow(
                      context,
                      'Tags',
                      ExcludeFocus(
                        child: _TagSelector(
                          tags: state.tags,
                          onChanged: state.onTagChanged,
                        ),
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
                            AllocationCard(
                              alloc,
                              onTap: (it) => state.focusAllocation(it),
                            ),
                            const SizedBox(height: 6)
                          ],
                          AllocationCard(
                            null,
                            onTap: (it) => state.focusAllocation(it),
                          ),
                        ],
                      ),
                      labelAlign: TableCellVerticalAlignment.top,
                      tooltip: "An allocation assigns a portion of the\n"
                          "transaction's value to a separate category.",
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
                              onTap: (it) => state.focusReimbursement(it),
                            ),
                            const SizedBox(height: 6)
                          ],
                          ReimbursementCard(
                            null,
                            onTap: (it) => state.focusReimbursement(it),
                          ),
                        ],
                      ),
                      labelAlign: TableCellVerticalAlignment.top,
                      tooltip: "A reimbursement cancels a specified amount\n"
                          "from two opposite transactions. For example,\n"
                          "a \$100 dining transaction can be reimbursed\n"
                          "by four \$20 Venmo payments. The net effect \n"
                          "is a \$20 addition to the dining category.",
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                FormButtons(
                  showDelete: (state.seed != null),
                  onCancel: (onCancel != null) ? onCancel : Navigator.of(context).pop,
                  onDelete: state.delete,
                  // onReset: state.reset,
                  // disable save when the allocation/reimb editor is open
                  onSave: (state.focus == TransactionDetailActiveFocus.none) ? state.save : null,
                ),
                const SizedBox(height: 10),
                if (state.errorMessage != null)
                  SizedBox(
                    width: 300,
                    child: Text(
                      state.errorMessage!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryLabel extends StatelessWidget {
  const _CategoryLabel({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransactionDetailsState>();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: "Create a rule matching this transaction.",
          textStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onInverseSurface,
                fontSize: 14,
              ),
          child: ExcludeFocus(
            child: IconButton(
              onPressed: state.toggleSaveRule,
              icon: (state.saveAsRule)
                  ? const Icon(Icons.bookmark_add, color: Colors.green)
                  : const Icon(Icons.bookmark_outline),
            ),
          ),
        ),
        Tooltip(
          message: "Choose the 'Ignore' category to not count this\n"
              "transaction in your income or expenses. The\n"
              "'Investment Returns' category is similar, but\n"
              "has its own dedicated cash flow graph.",
          textStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onInverseSurface,
                fontSize: 14,
              ),
          child: Text(
            'Category',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ],
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
          _dateFormat.parse(value, true);
          return null;
        } on FormatException {
          return '';
        }
      },
      onSave: (it) => onSave?.call(_dateFormat.parse(it!, true)),
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
                  color: tag.color,
                  onTap: () => onChanged?.call(tag, false),
                ),
            ],
          ),
        ),
        DropdownCheckboxMenu<Tag>(
          icon: Icons.add,
          items: context.watch<LibraAppState>().tags.list,
          builder: (context, tag) => Text(
            tag.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          isChecked: (it) => tags.contains(it),
          onChanged: onChanged,
        ),
        const SizedBox(width: 2),
      ],
    );
  }
}
