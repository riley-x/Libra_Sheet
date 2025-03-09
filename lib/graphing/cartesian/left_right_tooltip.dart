import 'package:flutter/material.dart';
import 'package:libra_sheet/graphing/cartesian/discrete_cartesian_graph.dart';
import 'package:libra_sheet/graphing/series/series.dart';

/// This is a hover tooltip that pools together all the data at a single point in a discrete x-value
/// graph. It displays a title followed by entries from each series in a column. Entry labels are
/// left-aligned while the values are right-aligned.
class LeftRightTooltip extends StatelessWidget {
  const LeftRightTooltip(
    this.mainGraph,
    this.hoverLoc, {
    super.key,
    this.series,
    this.reverse = false,
    this.includeTotal = true,
  });
  final DiscreteCartesianGraphPainter mainGraph;
  final int? hoverLoc;
  final bool reverse;
  final bool includeTotal;

  /// A list of entries to show in the tooltip, from top to bottom (unless [reverse]). If null, will
  /// use the series items from [mainGraph] by default.
  final List<Series>? series;

  @override
  Widget build(BuildContext context) {
    if (hoverLoc == null) return const SizedBox();

    (Widget, Widget)? getSeriesLabel(BuildContext context, Series series) {
      if (hoverLoc == null) return null;
      if (hoverLoc! >= series.data.length) return null;

      final val = series.hoverValue(hoverLoc!);
      if (val == null || val == 0) return null;

      final label = series.hoverBuilder(context, hoverLoc!, mainGraph, labelOnly: true) ??
          Text(
            series.name,
            style: Theme.of(context).textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
          );

      return (
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 100, maxWidth: 200),
          child: Padding(padding: const EdgeInsets.only(right: 14), child: label),
        ),
        Text(mainGraph.yAxis.valToString(val), style: Theme.of(context).textTheme.bodyMedium),
      );
    }

    var seriesList = series ?? mainGraph.data.data;
    if (reverse) seriesList = seriesList.reversed.toList();

    double total = 0.0;
    final List<Widget> labelEntries = <Widget>[];
    final List<Widget> valueEntries = <Widget>[];

    /// Series entries
    int count = 0;
    for (final s in seriesList) {
      final label = getSeriesLabel(context, s);
      if (label == null) continue;
      count++;
      total += s.hoverValue(hoverLoc!) ?? 0;
      labelEntries.add(label.$1);
      valueEntries.add(label.$2);
    }

    /// Total
    /// Values and therefore the divider need to be included in the same column as the values.
    if (includeTotal && count > 1) {
      labelEntries.addAll([
        Divider(height: 5, thickness: 0.5, color: Theme.of(context).colorScheme.onSurface),
        Text("Total ", style: Theme.of(context).textTheme.labelLarge)
      ]);
      valueEntries.addAll([
        Divider(height: 5, thickness: 0.5, color: Theme.of(context).colorScheme.onSurface),
        Text(
          mainGraph.yAxis.valToString(total),
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
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              mainGraph.xAxis.valToString(hoverLoc!.toDouble()),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            if (count > 0) ...[
              const SizedBox(height: 2),
              Divider(height: 1, thickness: 1, color: Theme.of(context).colorScheme.onSurface),
            ],
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
      ),
    );
  }
}
