import 'package:flutter/material.dart';
import 'package:libra_sheet/components/common_back_bar.dart';
import 'package:libra_sheet/components/transaction_filter_grid.dart';
import 'package:libra_sheet/tabs/csv/add_csv_state.dart';
import 'package:provider/provider.dart';

class PreviewTransactionsScreen extends StatelessWidget {
  const PreviewTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AddCsvState>();
    return Column(
      children: [
        CommonBackBar(
          leftText: 'Preview Transactions',
          onBack: () => state.clearTransactions(),
        ),
        Expanded(
          child: TransactionGrid(
            state.transactions,
            fixedColumns: 1,
            maxRowsForName: 2,
          ),
        ),
      ],
    );
  }
}
