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
                child: _TransactionDetails(transaction),
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
        1: FixedColumnWidth(300),
      },
      children: [
        _nameRow(t?.name),
      ],
    );
  }
}

TableRow _nameRow(String? initialName) {
  return TableRow(
    children: [
      Text('Account'),
      LibraTextField(
        onChanged: (it) => print(it),
      )
    ],
  );
}

// class _NameRow extends StatelessWidget {
//   const _NameRow(this.name, {super.key});

//   /// Name used as the initial value.
//   final String? name;

//   @override
//   Widget build(BuildContext context) {
//     return TableRow(
//       children: [
//         Text("Account"),
//       ],
//     );
//   }
// }
