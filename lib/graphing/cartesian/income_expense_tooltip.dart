import 'package:flutter/material.dart';
import 'package:libra_sheet/graphing/cartesian/discrete_cartesian_graph.dart';
import 'package:libra_sheet/graphing/series/series.dart';

/// This is like [PooledTooltip] but with two sections for income and expense and subtotals. Values
/// are right aligned.
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

    (Widget, Widget)? _getSeriesLabel(BuildContext context, Series series) {
      if (hoverLoc == null) return null;
      if (hoverLoc! >= series.data.length) return null;

      final val = series.hoverValue(hoverLoc!);
      if (val == null || val == 0) return null;

      var label = series.hoverBuilder(context, hoverLoc!, mainGraph, labelOnly: true) ??
          Text(series.name, style: Theme.of(context).textTheme.bodyMedium);

      return (
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 100, maxWidth: 200),
          child: Padding(padding: const EdgeInsets.only(right: 14), child: label),
        ),
        Text(mainGraph.yAxis.valToString(val), style: Theme.of(context).textTheme.bodyMedium),
      );
    }

    double incomeTotal = 0.0;
    double expenseTotal = 0.0;

    final incomeLabels = <(Widget, Widget)>[];
    for (final s in incomeSeries) {
      final labels = _getSeriesLabel(context, s);
      if (labels == null) continue;
      incomeTotal += s.hoverValue(hoverLoc!) ?? 0;
      incomeLabels.add(labels);
    }

    final expenseLabels = <(Widget, Widget)>[];
    for (final s in expenseSeries) {
      final labels = _getSeriesLabel(context, s);
      if (labels == null) continue;
      expenseTotal += s.hoverValue(hoverLoc!) ?? 0;
      expenseLabels.add(labels);
    }

    final List<Widget> labelEntries = <Widget>[];
    final List<Widget> valueEntries = <Widget>[];

    /// Title divider.
    /// Make sure all dividers are in the nested columns which are wrapped with IntrinsicWidth,
    /// otherwise they expand to like 400 pixels.
    if (incomeLabels.isNotEmpty || expenseLabels.isNotEmpty) {
      labelEntries.addAll([
        const SizedBox(height: 2),
        Divider(height: 1, thickness: 1, color: Theme.of(context).colorScheme.onSurface),
      ]);
      valueEntries.addAll([
        const SizedBox(height: 2),
        Divider(height: 1, thickness: 1, color: Theme.of(context).colorScheme.onSurface),
      ]);
    }

    final showSubtotals = incomeLabels.length > 1 && expenseLabels.length > 1;

    void collectEntries(List<(Widget, Widget)> labels, String title, double total) {
      for (final (label, value) in labels) {
        labelEntries.add(label);
        valueEntries.add(value);
      }
      if (showSubtotals) {
        labelEntries.addAll([
          Divider(height: 5, thickness: 1, color: Theme.of(context).colorScheme.outline),
          Text(title, style: Theme.of(context).textTheme.bodyMedium),
        ]);
        valueEntries.addAll([
          Divider(height: 5, thickness: 1, color: Theme.of(context).colorScheme.outline),
          Text(mainGraph.yAxis.valToString(total), style: Theme.of(context).textTheme.bodyMedium),
        ]);
      }
    }

    collectEntries(incomeLabels, "Income ", incomeTotal);
    if (showSubtotals) {
      labelEntries.add(const SizedBox(height: 12));
      valueEntries.add(const SizedBox(height: 12));
    }
    collectEntries(expenseLabels, "Expenses ", expenseTotal);

    /// Net total
    if (incomeLabels.length + expenseLabels.length > 1) {
      labelEntries.addAll([
        if (!showSubtotals)
          Divider(height: 5, thickness: 0.5, color: Theme.of(context).colorScheme.onSurface),
        Text("Total ", style: Theme.of(context).textTheme.labelLarge)
      ]);
      valueEntries.addAll([
        if (!showSubtotals)
          Divider(height: 5, thickness: 0.5, color: Theme.of(context).colorScheme.onSurface),
        Text(
          mainGraph.yAxis.valToString(incomeTotal + expenseTotal),
          style: Theme.of(context).textTheme.labelLarge,
        )
      ]);
    }

    return Container(
      padding: const EdgeInsets.only(left: 10, right: 10, top: 3, bottom: 4),
      constraints: const BoxConstraints(maxWidth: 400), // Catch to prevent ultra long lines
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onInverseSurface.withAlpha(210),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            mainGraph.xAxis.valToString(hoverLoc!.toDouble()),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IntrinsicWidth(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: labelEntries,
                ),
              ),
              IntrinsicWidth(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: valueEntries,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
