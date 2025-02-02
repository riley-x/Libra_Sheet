import 'package:flutter/material.dart';
import 'package:libra_sheet/graphing/cartesian/discrete_cartesian_graph.dart';
import 'package:libra_sheet/graphing/series/series.dart';

/// This is like [PooledTooltip] but with two sections for income and expense and subtotals.
class IncomeExpenseTooltip extends StatelessWidget {
  const IncomeExpenseTooltip({
    super.key,
    required this.mainGraph,
    required this.hoverLoc,
    required this.incomeSeries,
    required this.expenseSeries,
  });
  final DiscreteCartesianGraphPainter mainGraph;
  final int? hoverLoc;
  final List<Series> incomeSeries;
  final List<Series> expenseSeries;

  @override
  Widget build(BuildContext context) {
    if (hoverLoc == null) return const SizedBox();

    int count = 0;
    Widget? _getSeriesLabel(BuildContext context, Series series) {
      if (hoverLoc == null) return null;
      if (hoverLoc! >= series.data.length) return null;

      final widget = series.hoverBuilder(context, hoverLoc!, mainGraph);
      if (widget != null) {
        count++;
        return widget;
      }

      final val = series.hoverValue(hoverLoc!);
      if (val == null || val == 0) return null;

      count++;
      var label = mainGraph.yAxis.valToString(val);
      return Text(
        (series.name.isNotEmpty) ? "${series.name}: $label" : label,
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    double getTotal(bool isIncome) {
      var total = 0.0;
      for (final series in isIncome ? incomeSeries : expenseSeries) {
        total += series.hoverValue(hoverLoc!) ?? 0;
      }
      return total;
    }

    final incomeTotal = getTotal(true);
    final expenseTotal = getTotal(false);

    List<Widget> getEntries() {
      /// Title
      final entries = <Widget>[
        Center(
          child: Text(
            mainGraph.xAxis.valToString(hoverLoc!.toDouble()),
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
      ];

      final incomeLabels = <Widget>[];
      for (final s in incomeSeries) {
        final label = _getSeriesLabel(context, s);
        if (label == null) continue;
        incomeLabels.add(label);
      }

      final expenseLabels = <Widget>[];
      for (final s in expenseSeries) {
        final label = _getSeriesLabel(context, s);
        if (label == null) continue;
        expenseLabels.add(label);
      }

      if (incomeLabels.isEmpty && expenseLabels.isEmpty) return entries;
      final showSubtotals = incomeLabels.length > 1 && expenseLabels.length > 1;

      /// Divider
      entries.addAll([
        const SizedBox(height: 2),
        Divider(height: 1, thickness: 1, color: Theme.of(context).colorScheme.onSurface),
      ]);

      /// Income
      if (incomeLabels.isNotEmpty) {
        entries.addAll(incomeLabels);
        if (showSubtotals) {
          entries.addAll([
            Divider(height: 5, thickness: 0.5, color: Theme.of(context).colorScheme.onSurface),
            Text(
              "Income Total: ${mainGraph.yAxis.valToString(incomeTotal)}",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ]);
        }
      }

      /// Spacing
      if (showSubtotals) {
        entries.add(const SizedBox(height: 12));
      }

      /// Expense
      if (expenseLabels.isNotEmpty) {
        entries.addAll(expenseLabels);
        if (showSubtotals) {
          entries.addAll([
            Divider(height: 5, thickness: 0.5, color: Theme.of(context).colorScheme.onSurface),
            Text(
              "Expense Total: ${mainGraph.yAxis.valToString(expenseTotal)}",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ]);
        }
      }

      /// Net total
      if (incomeLabels.length + expenseLabels.length > 1) {
        entries.addAll([
          Text(
            "Net Total: ${mainGraph.yAxis.valToString(incomeTotal + expenseTotal)}",
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ]);
      }

      return entries;
    }

    return IntrinsicWidth(
      child: Container(
        padding: const EdgeInsets.only(left: 10, right: 10, top: 3, bottom: 4),
        constraints: const BoxConstraints(maxWidth: 400), // Catch to prevent ultra long lines
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onInverseSurface.withAlpha(210),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: getEntries(),
        ),
      ),
    );
  }
}
