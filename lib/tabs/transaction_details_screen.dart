import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:libra_sheet/components/libra_chip.dart';
import 'package:libra_sheet/components/printer.dart';
import 'package:libra_sheet/components/selectors/account_selection_menu.dart';
import 'package:libra_sheet/components/selectors/dropdown_category_menu.dart';
import 'package:libra_sheet/components/selectors/category_selection_menu.dart';
import 'package:libra_sheet/components/common_back_bar.dart';
import 'package:libra_sheet/components/libra_text_field.dart';
import 'package:libra_sheet/components/selectors/dropdown_checkbox_menu.dart';
import 'package:libra_sheet/data/category.dart';
import 'package:libra_sheet/data/enums.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/libra_app_state.dart';
import 'package:libra_sheet/data/tag.dart';
import 'package:libra_sheet/data/transaction.dart';
import 'package:provider/provider.dart';

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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: _TransactionDetails(transaction),
                ),
              ),
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
  final Set<Tag> tags = {};

  @override
  void initState() {
    super.initState();
    if (widget.seed != null) {
      expenseType = _valToFilterType(widget.seed?.value);
      for (final tag in widget.seed?.tags ?? []) {
        tags.add(tag);
      }
    }
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

  @override
  Widget build(BuildContext context) {
    /// WARNING!
    /// Form rebuilds every FormField descendant on every change of one of the fields (i.e. it calls
    /// their respective builder functions). (Tested and noted in the onChange() callback).
    /// This may not be ideal...
    return Form(
      key: _formKey,
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
                  height: 40,
                  initial: widget.seed?.account,
                  onSave: (it) => print(it?.name),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              _rowSpacing,
              _labelRow(
                context,
                'Name',
                _NameField(
                  initialName: widget.seed?.name,
                  onSave: (newValue) => print(newValue),
                ),
              ),
              _rowSpacing,
              _labelRow(
                context,
                'Date',
                _DateField(
                  initial: widget.seed?.date,
                  onSave: (newValue) => print(newValue),
                ),
              ),
              _rowSpacing,
              _labelRow(
                context,
                'Value',
                _ValueField(
                  initial: widget.seed?.value,
                  onSave: (newValue) => print(newValue),
                  onChanged: _onValueChanged,
                ),
              ),
              _rowSpacing,
              _labelRow(
                context,
                'Category',
                CategorySelectionFormField(
                  height: 40,
                  initial: widget.seed?.category,
                  onSave: (it) => print(it?.name),
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
            ],
          ),
          ElevatedButton(
            onPressed: () {
              // Validate will return true if the form is valid, or false if
              // the form is invalid.
              if (_formKey.currentState?.validate() ?? false) {
                _formKey.currentState?.save();
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

TableRow _labelRow(BuildContext context, String label, Widget? right,
    {Alignment labelAlign = Alignment.topRight}) {
  return TableRow(
    children: [
      Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleMedium,
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

class _NameField extends StatelessWidget {
  const _NameField({
    super.key,
    this.initialName,
    this.onSave,
  });

  final String? initialName;
  final Function(String?)? onSave;

  @override
  Widget build(BuildContext context) {
    return LibraTextFormField(
      initial: initialName,
      minLines: 3,
      maxLines: 3,
      validator: (it) => null,
      onSave: onSave,
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

  final Set<Tag> tags;
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
        const SizedBox(width: 7),
      ],
    );
  }
}
