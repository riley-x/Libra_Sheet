import 'package:flutter/material.dart';
import 'package:libra_sheet/components/form_buttons.dart';
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
      builder: (context, child) => AlertDialog(
        contentPadding: const EdgeInsets.only(top: 20, bottom: 15, left: 4, right: 4),
        content: const SizedBox(
          width: 300,
          child: TransactionFiltersColumn(
            interiorPadding: EdgeInsets.symmetric(horizontal: 5), // for the scrollbar
          ),
        ),
        actions: <Widget>[
          FormButtons(
            showDelete: false,
            onCancel: () => Navigator.pop(context),
            // onReset: context.read<TransactionFilterState>().resetFilters,
            onSave: (onSave == null)
                ? null
                : () {
                    final state = context.read<TransactionFilterState>();
                    onSave!.call(state.filters);
                    Navigator.pop(context);
                  },
          )
        ],
      ),
    );
  }
}
