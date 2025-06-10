import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:libra_sheet/components/cards/transaction_card.dart';
import 'package:libra_sheet/components/keyboard_utils.dart' show isMultiselect;
import 'package:libra_sheet/components/menus/transaction_context_menu.dart';
import 'package:libra_sheet/data/app_state/transaction_service.dart';
import 'package:libra_sheet/data/objects/transaction.dart';
import 'package:provider/provider.dart';

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
    } else if (onlyMulti || isMultiselect()) {
      onMultiselect?.call(t, index, false);
    } else {
      onTap?.call(t, index);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Center(
        child: Text(
          "No transactions",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
        ),
      );
    }

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
                              onDuplicate: () => context.read<TransactionService>().createDuplicate(
                                transactions[i],
                              ),
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
