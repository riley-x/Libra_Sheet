import 'package:flutter/material.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filter_state.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filters.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filters_column.dart';
import 'package:provider/provider.dart';

/// This dialog shows a [TransactionFiltersColumn] to set new transaction filters. It creates a
/// temporary [TransactionFilterState] to manage the UI fields and returns the filters in [onSave].
class TransactionFilterDialog extends StatelessWidget {
  const TransactionFilterDialog({
    super.key,
    required this.initialFilters,
    this.onSave,
  });

  final TransactionFilters initialFilters;
  final Function(TransactionFilters filters)? onSave;

  @override
  Widget build(BuildContext context) {
    // Here we create a temporary TransactionFilterState to store the in-progress edits, but it
    // doesn't read any transactions
    return ChangeNotifierProvider(
      create: (context) => TransactionFilterState(
        context.read(),
        initialFilters: initialFilters,
        doLoads: false,
      ),
      builder: (context, child) => Dialog(
        child: SizedBox(
          width: 300,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TransactionFiltersColumn(
              interiorPadding: const EdgeInsets.symmetric(horizontal: 4),
              showConfirmationButtons: true,
              onCancel: () => Navigator.pop(context),
              // onReset: context.read<TransactionFilterState>().resetFilters,
              onSave: (onSave == null)
                  ? null
                  : () {
                      final state = context.read<TransactionFilterState>();
                      onSave!.call(state.filters);
                      Navigator.pop(context);
                    },
            ),
          ),
        ),
      ),
    );
  }
}
