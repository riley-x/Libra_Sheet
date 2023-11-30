import 'package:flutter/material.dart';
import 'package:libra_sheet/data/database/transactions.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/objects/tag.dart';
import 'package:libra_sheet/tabs/transaction/transaction_filter_state.dart';
import 'package:libra_sheet/tabs/transaction/transaction_filters_column.dart';
import 'package:provider/provider.dart';

class TransactionFilterDialog extends StatelessWidget {
  const TransactionFilterDialog({
    super.key,
    required this.initialFilters,
    this.onSave,
  });

  final TransactionFilters initialFilters;
  final Function({
    required TransactionFilters filters,
    required Set<Account> accounts,
    required Set<Tag> tags,
    required CategoryTristateMap categories,
  })? onSave;

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
                      onSave!.call(
                        filters: state.filters,
                        accounts: state.accountFilterSelected,
                        categories: state.categoryFilterSelected,
                        tags: state.tags,
                      );
                      Navigator.pop(context);
                    },
            ),
          ),
        ),
      ),
    );
  }
}