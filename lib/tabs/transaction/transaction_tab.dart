import 'package:flutter/material.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filter_grid.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filters_column.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filter_state.dart';
import 'package:libra_sheet/tabs/navigation/libra_navigation.dart';
import 'package:provider/provider.dart';

import '../../components/transaction_filters/transaction_speed_dial.dart';

class TransactionTab extends StatelessWidget {
  const TransactionTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: _TransactionList()),
        const VerticalDivider(width: 1, thickness: 1),
        SizedBox(
          width: 300,
          child: Column(
            children: [
              const Expanded(
                child: TransactionFiltersColumn(
                  interiorPadding: EdgeInsets.symmetric(horizontal: 10),
                ),
              ),
              Text(
                "Results are limited to the first 300 transactions",
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TransactionList extends StatelessWidget {
  const _TransactionList({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransactionFilterState>();
    return Scaffold(
      body: TransactionGrid(
        state.transactions,
        padding: const EdgeInsets.only(top: 10, left: 10, bottom: 80, right: 10),
        // extra padding on bottom to not overlap the floating action button
        maxRowsForName: 1,
        fixedColumns: 1,
        onSelect: (t, i) => toTransactionDetails(context, t),
      ),
      floatingActionButton: const TransactionSpeedDial(),
    );
  }
}
