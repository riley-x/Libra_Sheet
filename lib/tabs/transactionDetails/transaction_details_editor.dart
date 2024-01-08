import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:libra_sheet/components/cards/allocation_card.dart';
import 'package:libra_sheet/components/cards/libra_chip.dart';
import 'package:libra_sheet/components/cards/transaction_card.dart';
import 'package:libra_sheet/components/dialogs/confirmation_dialog.dart';
import 'package:libra_sheet/components/libra_text_field.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/objects/reimbursement.dart';
import 'package:libra_sheet/components/menus/account_selection_menu.dart';
import 'package:libra_sheet/components/menus/category_selection_menu.dart';
import 'package:libra_sheet/components/menus/dropdown_checkbox_menu.dart';
import 'package:libra_sheet/components/form_buttons.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/objects/tag.dart';
import 'package:libra_sheet/components/table_form_utils.dart';
import 'package:libra_sheet/tabs/transactionDetails/transaction_details_state.dart';
import 'package:libra_sheet/tabs/transactionDetails/value_field.dart';
import 'package:provider/provider.dart';

/// This lays out a single-column form for the fields of one transaction. This is used both in the
/// full-screen [TransactionDetailsScreen], and in the half-column of [PreviewTransactionsScreen]
/// when adding CSVs.
class TransactionDetailsEditor extends StatelessWidget {
  const TransactionDetailsEditor({super.key, this.onCancel});

  final Function()? onCancel;

  static const maxWidth = 600.0;
  static const horizontalPadding = 20.0;

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
      child: SizedBox(
        width: maxWidth,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: horizontalPadding),
          child: FocusScope(
            child: Form(
              key: state.formKey,
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Details',
                      style: Theme.of(context).textTheme.headlineSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Table(
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    columnWidths: const {
                      0: IntrinsicColumnWidth(),
                      1: FixedColumnWidth(275),
                    },
                    children: [
                      labelRow(
                        context,
                        'Account',
                        AccountSelectionFormField(
                          height: 35,
                          initial: state.seed?.account ?? state.initialAccount,
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
                          minLines: 2,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),

                  /// --------------------------------------------------
                  /// Allocations
                  /// --------------------------------------------------
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Allocations',
                          style: Theme.of(context).textTheme.headlineSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.info_outline),
                        onPressed: () => showConfirmationDialog(
                          context: context,
                          title: 'Allocations',
                          msg:
                              "An allocation lets you split a transaction into multiple categories.",
                          showCancel: false,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => state.focusAllocation(null),
                      ),
                    ],
                  ),
                  for (final alloc in state.allocations) ...[
                    const SizedBox(height: 6),
                    AllocationCard(
                      alloc,
                      onTap: (it) => state.focusAllocation(it),
                    ),
                  ],

                  /// --------------------------------------------------
                  /// Reimbursements
                  /// --------------------------------------------------
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Reimbursements',
                          style: Theme.of(context).textTheme.headlineSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.info_outline),
                        onPressed: () => showConfirmationDialog(
                          context: context,
                          title: 'Reimbursements',
                          msg:
                              "A reimbursement cancels a specified amount from two opposite transactions.\n\n"
                              "For example, you pay for dinner with a friend and log a \$60 dining transaction, "
                              "and then your friend Venmo's you back \$30. "
                              "But your real expense was only \$30, and the Venmo transaction shouldn't count as income. "
                              "By reimbursing the two transactions with each other, you get the desired result.",
                          showCancel: false,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => state.focusReimbursement(null),
                      ),
                    ],
                  ),
                  for (final r in state.reimbursements) ...[
                    const SizedBox(height: 6),
                    _ReimbursementRow(r, onTap: (it) => state.focusReimbursement(it)),
                  ],

                  /// --------------------------------------------------
                  /// Form Buttons
                  /// --------------------------------------------------
                  const SizedBox(height: 20),
                  FormButtons(
                    showDelete: (state.seed != null && !state.seedStale),
                    onCancel: (onCancel != null) ? onCancel : Navigator.of(context).pop,
                    onDelete: state.delete,
                    // onReset: state.reset,
                    // disable save when the allocation/reimb editor is open
                    onSave: (state.focus == TransactionDetailActiveFocus.none && !state.seedStale)
                        ? state.save
                        : null,
                  ),
                  const SizedBox(height: 10),
                  if (state.errorMessage != null)
                    SizedBox(
                      width: maxWidth - 100,
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
      ),
    );
  }
}

class _CategoryLabel extends StatelessWidget {
  const _CategoryLabel();

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
  const _DateField({this.initial, this.onSave});

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
  const _TagSelector({required this.tags, this.onChanged});

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
      ],
    );
  }
}

class _ReimbursementRow extends StatelessWidget {
  const _ReimbursementRow(this.reimbursement, {this.onTap});

  final Reimbursement reimbursement;
  final Function(Reimbursement?)? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(reimbursement.value.dollarString()),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: TransactionCard(
            margin: EdgeInsets.zero,
            trans: reimbursement.target,
            onSelect: (onTap == null) ? null : (it) => onTap!.call(reimbursement),
          ),
        ),
      ],
    );
  }
}
