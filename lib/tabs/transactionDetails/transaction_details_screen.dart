import 'package:flutter/material.dart';
import 'package:libra_sheet/components/common_back_bar.dart';
import 'package:libra_sheet/data/transaction.dart';
import 'package:libra_sheet/tabs/transactionDetails/allocation_editor.dart';
import 'package:libra_sheet/tabs/transactionDetails/transaction_details_editor.dart';
import 'package:libra_sheet/tabs/transactionDetails/transaction_details_state.dart';
import 'package:provider/provider.dart';

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
          const Expanded(child: _TransactionDetailsScreen()),
        ],
      ),
    );
  }
}

class _TransactionDetailsScreen extends StatelessWidget {
  const _TransactionDetailsScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const mainEditor = SingleChildScrollView(
      physics: ClampingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child: TransactionDetailsEditor(),
      ),
    );

    final focus =
        context.select<TransactionDetailsState, TransactionDetailActiveFocus>((it) => it.focus);
    final auxEditor = switch (focus) {
      TransactionDetailActiveFocus.none => const SizedBox(),
      TransactionDetailActiveFocus.allocation => const AllocationEditor(),
      TransactionDetailActiveFocus.reimbursement => const SizedBox(),
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 850) {
          if (focus == TransactionDetailActiveFocus.none) {
            return mainEditor;
          } else {
            return auxEditor;
          }
        } else {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              mainEditor,
              Container(
                width: 1,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              Expanded(child: auxEditor),
            ],
          );
        }
      },
    );
  }
}
