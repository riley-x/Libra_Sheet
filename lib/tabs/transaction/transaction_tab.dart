import 'package:flutter/material.dart';
import 'package:libra_sheet/components/transaction_filter_grid.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/tabs/transaction/transaction_tab_filters.dart';
import 'package:libra_sheet/tabs/transaction/transaction_tab_state.dart';
import 'package:provider/provider.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class TransactionTab extends StatelessWidget {
  const TransactionTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TransactionTabState(),
      child: const _TransactionTab(),
    );
  }
}

class _TransactionTab extends StatelessWidget {
  const _TransactionTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransactionTabState>();
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10, left: 10),
                  child: Scaffold(
                    body: TransactionGrid(
                      state.transactions,
                      maxRowsForName: 3,
                      fixedColumns: 1,
                      onSelect: context.read<LibraAppState>().focusTransaction,
                    ),
                    floatingActionButton: SpeedDial(
                      icon: Icons.add,
                      activeIcon: Icons.close,
                      useRotationAnimation: true,
                      spacing: 3,
                      // renderOverlay: false,
                      overlayOpacity: 0.4,
                      children: [
                        SpeedDialChild(
                          child: const Icon(Icons.upload_file),
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                          label: 'Add CSV',
                          onTap: () => context.read<LibraAppState>().navigateToAddCsvScreen(),
                        ),
                        SpeedDialChild(
                          child: const Icon(Icons.edit_note),
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          label: 'Add manual',
                          onTap: () => context.read<LibraAppState>().focusTransaction(null),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Text(
                "Results are limited to the first 300 transactions",
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),

        /// Separator
        const SizedBox(width: 10),
        Container(
          width: 1,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),

        /// Filters
        const SizedBox(
          width: 300,
          child: Center(
            child: TransactionTabFilters(
              interiorPadding: EdgeInsets.symmetric(horizontal: 10),
            ),
          ),
        ),
      ],
    );
  }
}
