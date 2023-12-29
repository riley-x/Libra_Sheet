import 'package:flutter/material.dart';
import 'package:libra_sheet/components/cards/transaction_card.dart';
import 'package:libra_sheet/data/objects/transaction.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filter_state.dart';
import 'package:provider/provider.dart';

import 'transaction_filter_dialog.dart';

/// [initialFilters] is used as an object key, so make sure you keep a persistent object instead
/// of recreating it in a build function. Otherwise random rebuilds will constantly reload the
/// transactions and reset the filter.
class TransactionFilterGrid extends StatelessWidget {
  const TransactionFilterGrid({
    super.key,
    this.initialFilters,
    this.title,
    this.maxRowsForName = 1,
    this.fixedColumns = 1,
    this.onSelect,
    this.padding,
    this.fab,
    this.createProvider = true,
    this.highlightIcon,
  });

  final Widget? title;
  final TransactionFilters? initialFilters;
  final int? maxRowsForName;
  final int? fixedColumns;
  final Function(Transaction)? onSelect;
  final EdgeInsets? padding;
  final Widget? fab;
  final bool createProvider;
  final bool Function(TransactionFilters)? highlightIcon;

  @override
  Widget build(BuildContext context) {
    assert(createProvider || initialFilters == null);
    // initialFilters is only used for initializing the provider state
    final grid = _TransactionFilterGrid(
      padding: padding,
      title: title,
      maxRowsForName: maxRowsForName,
      fixedColumns: fixedColumns,
      onSelect: onSelect,
      fab: fab,
      highlightIcon: highlightIcon,
    );
    if (!createProvider) return grid;
    return ChangeNotifierProvider(
      key: ObjectKey(initialFilters),
      create: (context) => TransactionFilterState(
        context.read(),
        initialFilters: initialFilters,
      ),
      child: grid,
    );
  }
}

class _TransactionFilterGrid extends StatelessWidget {
  const _TransactionFilterGrid({
    super.key,
    this.title,
    this.maxRowsForName = 1,
    this.fixedColumns,
    this.onSelect,
    this.padding,
    this.fab,
    this.highlightIcon,
  });

  final Widget? title;
  final int? maxRowsForName;
  final int? fixedColumns;
  final Function(Transaction)? onSelect;
  final EdgeInsets? padding;
  final Widget? fab;
  final bool Function(TransactionFilters)? highlightIcon;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransactionFilterState>();
    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 10),
            (title != null)
                ? title!
                : Text(
                    "Transactions",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
            const Spacer(),
            IconButton(
              onPressed: () => showDialog(
                  context: context,
                  builder: (context) => TransactionFilterDialog(
                        initialFilters: state.filters,
                        onSave: state.setFilters,
                      )),
              icon: Icon(
                Icons.filter_list,
                color: (highlightIcon?.call(state.filters) == true)
                    ? Colors.lightBlue
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        Expanded(
          child: Scaffold(
            body: TransactionGrid(
              state.transactions,
              padding: padding ??
                  EdgeInsets.only(top: 10, left: 10, bottom: fab != null ? 80 : 10, right: 10),
              maxRowsForName: maxRowsForName,
              fixedColumns: fixedColumns,
              onSelect: (onSelect != null) ? (t, i) => onSelect!.call(t) : null,
            ),
            floatingActionButton: fab,
          ),
        ),
      ],
    );
  }
}

class TransactionGrid extends StatelessWidget {
  const TransactionGrid(
    this.transactions, {
    this.maxRowsForName = 1,
    this.fixedColumns,
    this.onSelect,
    this.padding,
    super.key,
  });

  final List<Transaction> transactions;
  final int? maxRowsForName;
  final int? fixedColumns;
  final Function(Transaction t, int index)? onSelect;

  /// Padding needs to be added inside the ListView so that the scrollbar isn't weirdly offset.
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    // Don't use GridLayout here because it has to fix the aspect ratio on the items instead
    // of using the instrinsic height.
    return LayoutBuilder(
      builder: (context, constraints) {
        const minWidth = 300;
        final numCols = fixedColumns ?? (constraints.maxWidth / minWidth).floor();
        final numRows = (transactions.length + numCols - 1) ~/ numCols;
        final includeLimitText = transactions.length == 300;
        return ListView.builder(
          itemCount: numRows + (includeLimitText ? 1 : 0),
          padding: includeLimitText ? padding?.copyWith(bottom: 0) : padding,
          itemBuilder: (context, index) {
            if (index == numRows) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 4, top: (padding?.bottom ?? 28) - 20),
                  child: Text(
                    "Results are limited to the first 300 transactions",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              );
            }
            final startIndex = index * numCols;
            if (startIndex >= transactions.length) return null;
            return Row(
              children: [
                for (int i = startIndex; i < startIndex + numCols; i++)
                  (i >= transactions.length)
                      ? const Spacer()
                      : Expanded(
                          child: TransactionCard(
                            trans: transactions[i],
                            maxRowsForName: maxRowsForName,
                            onSelect: (onSelect != null) ? (it) => onSelect!(it, i) : null,
                          ),
                        ),
              ],
            );
          },
        );
      },
    );
  }
}
