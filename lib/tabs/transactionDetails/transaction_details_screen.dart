import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:libra_sheet/components/libra_chip.dart';
import 'package:libra_sheet/components/reimbursement_card.dart';
import 'package:libra_sheet/components/selectors/account_selection_menu.dart';
import 'package:libra_sheet/components/selectors/category_selection_menu.dart';
import 'package:libra_sheet/components/common_back_bar.dart';
import 'package:libra_sheet/components/libra_text_field.dart';
import 'package:libra_sheet/components/selectors/dropdown_checkbox_menu.dart';
import 'package:libra_sheet/data/account.dart';
import 'package:libra_sheet/data/allocation.dart';
import 'package:libra_sheet/data/category.dart';
import 'package:libra_sheet/data/enums.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/libra_app_state.dart';
import 'package:libra_sheet/data/reimbursement.dart';
import 'package:libra_sheet/data/tag.dart';
import 'package:libra_sheet/data/transaction.dart';
import 'package:provider/provider.dart';

import '../../components/allocation_card.dart';

class TransactionDetailsScreen extends StatelessWidget {
  const TransactionDetailsScreen(this.transaction, {super.key});

  /// Transaction used to initialize the fields. Also, the key is used in case of "Update".
  final Transaction? transaction;

  @override
  Widget build(BuildContext context) {
    return Column(
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
              SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: _TransactionDetails(transaction),
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
    );
  }
}

class _TransactionDetails extends StatefulWidget {
  const _TransactionDetails(this.seed, {super.key});

  /// Transaction used to initialize the fields.
  final Transaction? seed;

  @override
  State<_TransactionDetails> createState() => _TransactionDetailsState();
}

class _TransactionDetailsState extends State<_TransactionDetails> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  ExpenseFilterType expenseType = ExpenseFilterType.all;

  /// These variables are saved to by the relevant FormFields. Don't need to manage via SetState.
  Account? account;
  String? name;
  DateTime? date;
  int? value;
  Category? category;
  String? note;

  /// These variables are the state for the relevant fields
  final List<Tag> tags = [];
  final List<Allocation> allocations = [];
  final List<Reimbursement> reimbursements = [];

  void _init() {
    if (widget.seed != null) {
      expenseType = _valToFilterType(widget.seed?.value);
      tags.insertAll(0, widget.seed?.tags ?? const []);
      allocations.insertAll(0, widget.seed?.allocations ?? const []);
      reimbursements.insertAll(0, widget.seed?.reimbursements ?? const []);
    }
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  ExpenseFilterType _valToFilterType(int? val) {
    if (val == null || val == 0) {
      return ExpenseFilterType.all;
    } else if (val > 0) {
      return ExpenseFilterType.income;
    } else {
      return ExpenseFilterType.expense;
    }
  }

  void _onValueChanged(int? val) {
    var newType = _valToFilterType(val);
    if (newType != expenseType) {
      setState(() {
        expenseType = newType;
      });
    }
  }

  void _reset() {
    _formKey.currentState?.reset();
    setState(() {
      tags.clear();
      allocations.clear();
      reimbursements.clear();
      _init();
    });
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      if (name == null || date == null || value == null || note == null) {
        debugPrint("_TransactionDetailsState:_save() ERROR found null values!");
        return;
      }
      var t = Transaction(
        key: widget.seed?.key ?? 0,
        name: name!,
        date: date!,
        value: value!,
        category: category,
        account: account,
        note: note!,
        allocations: allocations,
        reimbursements: reimbursements,
        tags: tags,
      );
      print(t); // TODO save transaction
    }
  }

  @override
  Widget build(BuildContext context) {
    /// WARNING!
    /// Form rebuilds every FormField descendant on every change of one of the fields (i.e. it calls
    /// their respective builder functions). (Tested and noted in the onChange() callback).
    /// This may not be ideal...
    return Form(
      key: _formKey,
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
                _labelRow(
                  context,
                  'Account',
                  AccountSelectionFormField(
                    height: 35,
                    initial: widget.seed?.account,
                    onSave: (it) => account = it,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                _rowSpacing,
                _labelRow(
                  context,
                  'Name',
                  LibraTextFormField(
                    initial: widget.seed?.name,
                    minLines: 3,
                    maxLines: 3,
                    validator: (it) => null,
                    onSave: (it) => name = it,
                  ),
                ),
                _rowSpacing,
                _labelRow(
                  context,
                  'Date',
                  _DateField(
                    initial: widget.seed?.date,
                    onSave: (it) => date = it,
                  ),
                ),
                _rowSpacing,
                _labelRow(
                  context,
                  'Value',
                  _ValueField(
                    initial: widget.seed?.value,
                    onSave: (it) => value = it,
                    onChanged: _onValueChanged,
                  ),
                ),
                _rowSpacing,
                _labelRow(
                  context,
                  'Category',
                  CategorySelectionFormField(
                    height: 35,
                    initial: widget.seed?.category,
                    onSave: (it) => category = it,
                    borderRadius: BorderRadius.circular(4),
                    type: expenseType,
                  ),
                ),
                _rowSpacing,
                _labelRow(
                  context,
                  'Tags',
                  _TagSelector(
                    tags: tags,
                    onChanged: (tag, selected) {
                      setState(() {
                        if (selected == true) {
                          tags.add(tag);
                        } else {
                          tags.remove(tag);
                        }
                      });
                    },
                  ),
                ),
                _rowSpacing,
                _labelRow(
                  context,
                  'Note',
                  LibraTextFormField(
                    initial: widget.seed?.note,
                    validator: (it) => null,
                    onSave: (it) => note = it,
                  ),
                ),
                _rowSpacing,
                _labelRow(
                  context,
                  'Allocations',
                  Column(
                    children: [
                      for (final alloc in allocations) ...[
                        AllocationCard(alloc),
                        const SizedBox(height: 4)
                      ],
                      const AllocationCard(null),
                    ],
                  ),
                  labelAlign: TableCellVerticalAlignment.top,
                ),
                _rowSpacing,
                _rowSpacing,
                _labelRow(
                  context,
                  'Reimbursements',
                  Column(
                    children: [
                      for (final r in reimbursements) ...[
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
            _Buttons(
              allowDelete: (widget.seed?.key ?? 0) > 0,
              delete: () {}, // TODO
              reset: _reset,
              save: _save,
            ),
          ],
        ),
      ),
    );
  }
}

TableRow _labelRow(BuildContext context, String label, Widget? right,
    {TableCellVerticalAlignment? labelAlign}) {
  return TableRow(
    children: [
      TableCell(
        verticalAlignment: labelAlign,
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      ),
      if (right != null) right,
    ],
  );
}

const _rowSpacing = TableRow(children: [
  SizedBox(
    height: 8,
  ),
  SizedBox(
    height: 8,
  )
]);

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

class _ValueField extends StatelessWidget {
  const _ValueField({
    super.key,
    this.formFieldKey,
    this.initial,
    this.onSave,
    this.onChanged,
  });

  final int? initial;
  final Function(int)? onSave;
  final Function(int?)? onChanged;
  final Key? formFieldKey;

  @override
  Widget build(BuildContext context) {
    return LibraTextFormField(
      formFieldKey: formFieldKey,
      initial: initial?.dollarString(dollarSign: false),
      validator: (String? text) {
        if (text == null || text.isEmpty) return ''; // No message to not take up space
        final val = text.toIntDollar();
        if (val == null) return ''; // No message to not take up space
        return null;
      },
      onChanged: (it) => onChanged?.call(it?.toIntDollar()),
      onSave: (it) => onSave?.call(it?.toIntDollar() ?? 0),
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

class _Buttons extends StatelessWidget {
  const _Buttons({
    super.key,
    required this.allowDelete,
    this.delete,
    this.reset,
    this.save,
  });

  final bool allowDelete;
  final Function()? delete;
  final Function()? reset;
  final Function()? save;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (allowDelete) ...[
          ElevatedButton(
            onPressed: delete,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
          const SizedBox(width: 20),
        ],
        ElevatedButton(
          onPressed: reset,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
          ),
          child: const Text('Reset'),
        ),
        const SizedBox(width: 20),
        ElevatedButton(
          onPressed: save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
