import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:libra_sheet/components/selectors/account_selection_menu.dart';
import 'package:libra_sheet/components/selectors/category_selection_menu.dart';
import 'package:libra_sheet/components/common_back_bar.dart';
import 'package:libra_sheet/components/libra_text_field.dart';
import 'package:libra_sheet/data/enums.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/transaction.dart';

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
  final _valueFieldKey = GlobalKey<FormFieldState<String>>();

  @override
  Widget build(BuildContext context) {
    var type = ExpenseFilterType.all;

    return Form(
      key: _formKey,
      // onChanged: () {
      //   if (_valueFieldKey.currentState?.isValid == true) {
      //     final val = _valueFieldKey.currentState?.value?.toIntDollar();
      //     if (val != null && val != 0) {
      //       type = (val > 0) ? ExpenseFilterType.income : ExpenseFilterType.expense;
      //     }
      //     print(type);
      //   }
      // },
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
                  formFieldKey: _valueFieldKey,
                  initial: widget.seed?.value,
                  onSave: (newValue) => print(newValue),
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
                  type: type,
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
  });

  final int? initial;
  final Function(int)? onSave;
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
      // validator should ensure not null already
      onSave: (it) => onSave?.call(it?.toIntDollar() ?? 0),
    );
  }
}
