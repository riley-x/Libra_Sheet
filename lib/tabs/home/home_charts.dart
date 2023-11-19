import 'package:flutter/material.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/graphing/line.dart';
import 'package:libra_sheet/tabs/home/chart_with_title.dart';
import 'package:libra_sheet/tabs/home/home_tab.dart';

class HomeCharts extends StatelessWidget {
  const HomeCharts({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      const minChartHeight = 400.0;
      final pieChartsAligned = constraints.maxWidth > 2 * minChartHeight + 50;
      if (pieChartsAligned && constraints.maxHeight > 2 * minChartHeight + 50) {
        return Placeholder();
      } else {
        return _ListCharts(
          chartHeight: minChartHeight,
          pieChartsAligned: pieChartsAligned,
        );
      }
    });
  }
}

/// Expands the line chart to maximum height
class _ExpandedCharts extends StatelessWidget {
  const _ExpandedCharts({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ChartWithTitle(
            height: 300,
            textLeft: 'Net Worth',
            textRight: 13413418374.dollarString(),
            textStyle: Theme.of(context).textTheme.headlineMedium,
            padding: const EdgeInsets.only(top: 10),
            child: TestGraph(),
          ),
        ),
      ],
    );
  }
}

/// Gives each chart a fixed height inside a list view. Used when the height of the window is not
/// sufficient to display all of the adequately.
class _ListCharts extends StatelessWidget {
  final double chartHeight;
  final bool pieChartsAligned;

  const _ListCharts({
    super.key,
    required this.chartHeight,
    required this.pieChartsAligned,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> pieChildren = (pieChartsAligned)
        ? [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: ChartWithTitle(
                    height: chartHeight,
                    textLeft: 'Assets',
                    textRight: '\$123.00',
                    textStyle: Theme.of(context).textTheme.headlineMedium,
                    padding: const EdgeInsets.only(top: 10),
                    child: TestPie(),
                  ),
                ),
                Container(
                  width: 1,
                  height: chartHeight,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ChartWithTitle(
                    height: chartHeight,
                    textLeft: 'Assets',
                    textRight: '\$123.00',
                    textStyle: Theme.of(context).textTheme.headlineMedium,
                    padding: const EdgeInsets.only(top: 10),
                    child: TestPie(),
                  ),
                ),
              ],
            ),
          ]
        : [
            Center(
              child: ChartWithTitle(
                height: chartHeight,
                textLeft: 'Assets',
                textRight: '\$123.00',
                textStyle: Theme.of(context).textTheme.headlineMedium,
                padding: const EdgeInsets.only(top: 10),
                child: TestPie(),
              ),
            ),
            Container(
              height: 1,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            Center(
              child: ChartWithTitle(
                height: chartHeight,
                textLeft: 'Assets',
                textRight: '\$123.00',
                textStyle: Theme.of(context).textTheme.headlineMedium,
                padding: const EdgeInsets.only(top: 10),
                child: TestPie(),
              ),
            ),
          ];

    return ListView(
      children: [
        ChartWithTitle(
          height: chartHeight,
          textLeft: 'Net Worth',
          textRight: 13413418374.dollarString(),
          textStyle: Theme.of(context).textTheme.headlineMedium,
          padding: const EdgeInsets.only(top: 10),
          child: TestGraph(),
        ),
        const SizedBox(height: 5),
        Container(
          height: 1,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),

        /// Don't add padding here or else the vertical grid lines won't be tight
        ...pieChildren,
      ],
    );
  }
}
