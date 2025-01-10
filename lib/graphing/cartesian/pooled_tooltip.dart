import 'package:flutter/material.dart';
import 'package:libra_sheet/graphing/cartesian/discrete_cartesian_graph.dart';
import 'package:libra_sheet/graphing/series/series.dart';

/// This is a hover tooltip that pools together all the data at a single point in a discrete x-value
/// graph. It displays a title followed by entries from each series in a column.
class PooledTooltip extends StatelessWidget {
  const PooledTooltip(
    this.mainGraph,
    this.hoverLoc, {
    super.key,
    this.series,
    this.reverse = false,
    this.includeTotal = true,
    this.labelAlignment = Alignment.centerLeft,
  });
  final DiscreteCartesianGraphPainter mainGraph;
  final int? hoverLoc;
  final bool reverse;
  final bool includeTotal;
  final Alignment labelAlignment;

  /// A list of entries to show in the tooltip, from top to bottom (unless [reverse]). If null, will
  /// use the series items from [mainGraph] by default.
  final List<Series>? series;

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

    String getTotal() {
      var total = 0.0;
      for (final series in mainGraph.data.data) {
        total += series.hoverValue(hoverLoc!) ?? 0;
      }
      return mainGraph.yAxis.valToString(total);
    }

    var seriesList = series ?? mainGraph.data.data;
    if (reverse) seriesList = seriesList.reversed.toList();

    return IntrinsicWidth(
      child: Container(
        padding: const EdgeInsets.only(left: 10, right: 10, top: 3, bottom: 4),
        constraints: const BoxConstraints(maxWidth: 400), // Catch to prevent ultra long lines
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onInverseSurface.withAlpha(210),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// Title
            Text(
              mainGraph.xAxis.valToString(hoverLoc!.toDouble()),
              style: Theme.of(context).textTheme.labelLarge,
            ),

            /// Divider
            if (seriesList.isNotEmpty) ...[
              const SizedBox(height: 2),
              Divider(height: 1, thickness: 1, color: Theme.of(context).colorScheme.onSurface),
            ],

            /// Series items
            for (final s in seriesList)
              Align(
                alignment: labelAlignment,
                child: _getSeriesLabel(context, s),
              ),

            /// Total
            if (count > 1 && includeTotal) ...[
              Divider(height: 5, thickness: 0.5, color: Theme.of(context).colorScheme.onSurface),
              Align(
                alignment: labelAlignment,
                child: Text(
                  "Total: ${getTotal()}",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
