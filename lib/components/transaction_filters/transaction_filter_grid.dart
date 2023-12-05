import 'package:flutter/material.dart';
import 'package:libra_sheet/components/cards/transaction_card.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_speed_dial.dart';
import 'package:libra_sheet/data/objects/transaction.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filter_state.dart';
import 'package:provider/provider.dart';

import 'transaction_filter_dialog.dart';

class TransactionFilterGrid extends StatelessWidget {
  const TransactionFilterGrid({
    super.key,
    this.initialFilters,
    this.title,
    this.maxRowsForName = 1,
    this.fixedColumns = 1,
    this.onSelect,
    this.padding,
    this.showSpeedDial = false,
  });

  final Widget? title;
  final TransactionFilters? initialFilters;
  final int? maxRowsForName;
  final int? fixedColumns;
  final Function(Transaction)? onSelect;
  final EdgeInsets? padding;
  final bool showSpeedDial;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      key: ObjectKey(initialFilters),
      create: (context) => TransactionFilterState(context.read(), initialFilters: initialFilters),
      child: _TransactionFilterGrid(
        padding: padding,
        title: title,
        maxRowsForName: maxRowsForName,
        fixedColumns: fixedColumns,
        onSelect: onSelect,
        showSpeedDial: showSpeedDial,
      ),
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
    this.showSpeedDial = false,
  });

  final Widget? title;
  final int? maxRowsForName;
  final int? fixedColumns;
  final Function(Transaction)? onSelect;
  final EdgeInsets? padding;
  final bool showSpeedDial;

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
                    "Recent Transactions",
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
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        Expanded(
          child: Scaffold(
            body: TransactionGrid(
              state.transactions,
              padding: padding ??
                  EdgeInsets.only(top: 10, left: 10, bottom: showSpeedDial ? 80 : 10, right: 10),
              maxRowsForName: maxRowsForName,
              fixedColumns: fixedColumns,
              onSelect: (onSelect != null) ? (t, i) => onSelect!.call(t) : null,
            ),
            floatingActionButton: showSpeedDial ? const TransactionSpeedDial() : null,
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
        return ListView.builder(
          itemCount: numRows,
          padding: padding,
          itemBuilder: (context, index) {
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
