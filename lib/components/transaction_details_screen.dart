import 'package:flutter/material.dart';
import 'package:libra_sheet/components/common_back_bar.dart';
import 'package:libra_sheet/components/libra_text_field.dart';
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

class _TransactionDetails extends StatelessWidget {
  const _TransactionDetails(this.t, {super.key});

  /// Transaction used to initialize the fields.
  final Transaction? t;

  @override
  Widget build(BuildContext context) {
    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.top,
      columnWidths: const {
        0: IntrinsicColumnWidth(),
        1: FixedColumnWidth(250),
      },
      children: [
        _nameRow(context, t?.name),
      ],
    );
  }
}

TableRow _nameRow(BuildContext context, String? initialName) {
  return _labelRow(
    context,
    'Account',
    LibraTextField(
      onChanged: (it) => print(it),
    ),
  );
}

TableRow _labelRow(BuildContext context, String label, Widget? right) {
  return TableRow(
    children: [
      Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Text(
            'Account',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
      if (right != null) right,
    ],
  );
}
