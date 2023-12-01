import 'package:flutter/material.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filter_state.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filters_column.dart';
import 'package:provider/provider.dart';

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
    return ChangeNotifierProvider(
      create: (context) => TransactionFilterState(context.read(), initialFilters),
      builder: (context, child) => Dialog(
        child: SizedBox(
          width: 300,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TransactionFiltersColumn(
              showConfirmationButtons: true,
              onCancel: () => Navigator.pop(context),
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
