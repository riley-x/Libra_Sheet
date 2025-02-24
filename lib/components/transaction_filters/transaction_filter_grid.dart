import 'package:flutter/material.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filters.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_list.dart';
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
    this.quickFilter = false,
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
  final bool quickFilter;

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
      quickFilter: quickFilter,
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
    this.quickFilter = false,
  });

  final Widget? title;
  final int? maxRowsForName;
  final int? fixedColumns;
  final Function(Transaction)? onSelect;
  final EdgeInsets? padding;
  final Widget? fab;
  final String? Function(TransactionFilters)? filterDescription;
  final bool quickFilter;

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
                      color: Colors.orange,
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
                    ? Colors.orange
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        if (quickFilter)
          Row(
            children: [
              const SizedBox(width: 10),
              const Text("Quick search:"),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: state.nameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    isDense: true,
                  ),
                  onChanged: state.setName,
                  maxLines: 1,
                  // style: widget.style,
                ),
              ),
              const SizedBox(width: 10),
            ],
          ),
        const SizedBox(height: 10),
        Expanded(
          child: Scaffold(
            body: TransactionList(
              transactions: state.transactions,
              padding: padding ??
                  EdgeInsets.only(top: 10, left: 10, bottom: fab != null ? 80 : 10, right: 10),
              maxRowsForName: maxRowsForName,
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
