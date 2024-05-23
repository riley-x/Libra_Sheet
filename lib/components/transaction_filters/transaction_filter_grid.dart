import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:libra_sheet/components/cards/transaction_card.dart';
import 'package:libra_sheet/components/menus/transaction_context_menu.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filters.dart';
import 'package:libra_sheet/data/app_state/transaction_service.dart';
import 'package:libra_sheet/data/objects/transaction.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filter_state.dart';
import 'package:provider/provider.dart';

import 'transaction_filter_dialog.dart';

/// Shows a grid of transactions with a title row that exposes an icon button for adding filters.
///
/// This widget will create its own [TransactionFilterState] to manage the list of transactions.
/// [initialFilters] can be passed to set the initial list. Note [initialFilters] is used as an
/// object key for the [ChangeNotifierProvider], so make sure you keep a persistent object instead
/// of recreating it in a build function. Otherwise random rebuilds will constantly reload the
/// transactions and reset the filter.
///
/// Alternatively, if you want to manage the state directly, provide one above this widget and set
/// [createProvider] to false. In this case [initialFilters] is unused.
///
/// [filterDescription] will display a tiny message beside the filter icon is not null, and highlight
/// the icon [Colors.blue].
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
    this.filterDescription,
  });

  final Widget? title;
  final TransactionFilters? initialFilters;
  final int? maxRowsForName;
  final int? fixedColumns;
  final Function(Transaction)? onSelect;
  final EdgeInsets? padding;
  final Widget? fab;
  final bool createProvider;
  final String? Function(TransactionFilters)? filterDescription;

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
      filterDescription: filterDescription,
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
    this.filterDescription,
  });

  final Widget? title;
  final int? maxRowsForName;
  final int? fixedColumns;
  final Function(Transaction)? onSelect;
  final EdgeInsets? padding;
  final Widget? fab;
  final String? Function(TransactionFilters)? filterDescription;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TransactionFilterState>();
    final filterMessage = filterDescription?.call(state.filters);
    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 10),
            Expanded(
              child: (title != null)
                  ? title!
                  : Text(
                      "Transactions",
                      style: Theme.of(context).textTheme.headlineSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
            if (filterMessage != null)
              Text(
                filterMessage,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.blue,
                      // fontStyle: FontStyle.italic,
                    ),
                textAlign: TextAlign.right,
              ),
            IconButton(
              onPressed: () => showDialog(
                  context: context,
                  builder: (context) => TransactionFilterDialog(
                        initialFilters: state.filters,
                        onSave: state.setFilters,
                      )),
              icon: Icon(
                Icons.filter_list,
                color: (filterMessage != null)
                    ? Colors.blue
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
              onTap: (onSelect != null) ? (t, i) => onSelect!.call(t) : null,
              onMultiselect: state.multiSelect,
              selected: state.selected,
            ),
            floatingActionButton: fab,
          ),
        ),
      ],
    );
  }
}

/// Shows a grid of transactions.
///
/// [fixedColumns] is the number of columns in the grid. If null, will create as many columns such
/// that each is at least 300 pixels wide.
///
/// [maxRowsForName] the number of rows allowed for the transaction name; see [TransactionCard].
class TransactionGrid extends StatelessWidget {
  const TransactionGrid(
    this.transactions, {
    this.maxRowsForName = 1,
    this.fixedColumns,
    this.selected,
    this.onTap,
    this.onMultiselect,
    this.padding,
    super.key,
  });

  final List<Transaction> transactions;
  final int? maxRowsForName;
  final int? fixedColumns;
  final Map<int, Transaction>? selected;
  final Function(Transaction t, int index)? onTap;
  final Function(Transaction t, int index, bool shift)? onMultiselect;

  /// Padding needs to be added inside the ListView so that the scrollbar isn't weirdly offset.
  final EdgeInsets? padding;

  void _onSelect(Transaction t, int index, bool onlyMulti) {
    if (HardwareKeyboard.instance.isShiftPressed) {
      onMultiselect?.call(t, index, true);
    } else if (onlyMulti ||
        (Platform.isMacOS && HardwareKeyboard.instance.isMetaPressed) ||
        (Platform.isWindows && HardwareKeyboard.instance.isControlPressed)) {
      onMultiselect?.call(t, index, false);
    } else {
      onTap?.call(t, index);
    }
  }

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
                            selected: selected?.containsKey(i) ?? false,
                            maxRowsForName: maxRowsForName,
                            onTap: (onTap == null && onMultiselect == null)
                                ? null
                                : (it) => _onSelect(it, i, false),
                            contextMenu: TransactionContextMenu(
                              onDuplicate: () => context
                                  .read<TransactionService>()
                                  .createDuplicate(transactions[i]),
                              onSelect: () => _onSelect(transactions[i], i, true),
                            ),
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
