import 'package:flutter/material.dart';
import 'package:libra_sheet/components/transaction_card.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/database/transactions.dart';
import 'package:libra_sheet/data/objects/transaction.dart';
import 'package:provider/provider.dart';

class TransactionFilterGrid extends StatefulWidget {
  const TransactionFilterGrid(
    this.transactions, {
    super.key,
    this.title,
    this.maxRowsForName = 1,
    this.fixedColumns,
    this.onSelect,
  });

  final Widget? title;
  final List<Transaction> transactions;
  final int? maxRowsForName;
  final int? fixedColumns;
  final Function(Transaction)? onSelect;

  @override
  State<TransactionFilterGrid> createState() => _TransactionFilterGridState();
}

class _TransactionFilterGridState extends State<TransactionFilterGrid> {
  // TODO put current filter state here, do the actual filtering
  late final LibraAppState appState;
  TransactionFilters filters = TransactionFilters();

  @override
  void initState() {
    super.initState();
    appState = context.read();

    // WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
    //   appState = context.read();
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            (widget.title != null)
                ? widget.title!
                : Text(
                    "Recent Transactions",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
            const Spacer(),
            IconButton(
              onPressed: () => showDialog(
                  context: context,
                  builder: (context) {
                    return _FitlerDialog();
                  }),
              icon: Icon(
                Icons.filter_list,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        Expanded(
          child: TransactionGrid(
            widget.transactions,
            maxRowsForName: widget.maxRowsForName,
            fixedColumns: widget.fixedColumns,
            onSelect: (t, i) => widget.onSelect?.call(t),
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

class _FitlerDialog extends StatelessWidget {
  const _FitlerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('This is a typical dialog.'),
            const SizedBox(height: 15),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
