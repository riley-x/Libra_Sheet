import 'package:flutter/material.dart';
import 'package:libra_sheet/data/app_state/account_state.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/time_value.dart';
import 'package:libra_sheet/graphing/date_time_graph.dart';
import 'package:libra_sheet/graphing/pie/pie_chart.dart';
import 'package:libra_sheet/tabs/home/chart_with_title.dart';
import 'package:libra_sheet/tabs/navigation/libra_navigation.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class HomeCharts extends StatelessWidget {
  const HomeCharts({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      const minChartHeight = 400.0;
      final pieChartsAligned = constraints.maxWidth > 2 * minChartHeight + 16;
      if (pieChartsAligned && constraints.maxHeight > 2 * minChartHeight + 1) {
        return const _ExpandedCharts();
      } else {
        return _ListCharts(
          chartHeight: minChartHeight,
          pieChartsAligned: pieChartsAligned,
        );
      }
    });
  }
}

/// Expands the line chart and pie charts to equal heights
class _ExpandedCharts extends StatelessWidget {
  const _ExpandedCharts({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Expanded(child: _NetWorthGraph(null)),
        Container(
          height: 1,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        Expanded(child: _alignedPies(null, context)),
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
    return ListView(
      children: [
        _NetWorthGraph(chartHeight),
        Container(
          height: 1,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),

        /// Don't add padding here or else the vertical grid lines won't be tight
        if (pieChartsAligned) _alignedPies(chartHeight, context),
        if (!pieChartsAligned) ..._verticalPies(chartHeight, context),
      ],
    );
  }
}

Widget _alignedPies(double? height, BuildContext context) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: [
      Expanded(child: _AssetsPie(height)),
      Container(
        width: 1,
        height: height,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
      const SizedBox(height: 10),
      Expanded(child: _LiabilitiesPie(height)),
    ],
  );
}

List<Widget> _verticalPies(double height, BuildContext context) {
  return [
    Center(child: _AssetsPie(height)),
    Container(
      height: 1,
      color: Theme.of(context).colorScheme.outlineVariant,
    ),
    Center(child: _LiabilitiesPie(height)),
  ];
}

class _NetWorthGraph extends StatelessWidget {
  const _NetWorthGraph(this.height, {super.key});

  final double? height;

  @override
  Widget build(BuildContext context) {
    final gradientColors = LinearGradient(
      colors: [
        Colors.blue.withAlpha(10),
        Colors.blue.withAlpha(80),
        Colors.blue.withAlpha(170),
      ],
      stops: const [0.0, 0.6, 1],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    );

    List<TimeIntValue> data = context.watch<LibraAppState>().netWorthData;
    return ChartWithTitle(
      height: height,
      textLeft: 'Net Worth',
      textRight: (data.lastOrNull?.value ?? 0).dollarString(),
      textStyle: Theme.of(context).textTheme.headlineMedium,
      padding: const EdgeInsets.only(top: 10),
      child: DateTimeGraph([
        AreaSeries<TimeIntValue, DateTime>(
          animationDuration: 0,
          dataSource: data,
          xValueMapper: (TimeIntValue sales, _) => sales.time,
          yValueMapper: (TimeIntValue sales, _) => sales.value.asDollarDouble(),
          gradient: gradientColors,
          borderColor: Colors.blue,
          borderWidth: 3,
          borderDrawMode: BorderDrawMode.top,
        ),
      ]),
    );
  }
}

class _AssetsPie extends StatelessWidget {
  final double? height;
  const _AssetsPie(this.height, {super.key});

  @override
  Widget build(BuildContext context) {
    final accounts =
        context.watch<AccountState>().list.where((it) => it.type != AccountType.liability).toList();
    final total = accounts.fold(0, (cum, acc) => cum + acc.balance);
    return ChartWithTitle(
      height: height,
      textLeft: 'Assets',
      textRight: total.dollarString(),
      textStyle: Theme.of(context).textTheme.headlineMedium,
      padding: const EdgeInsets.only(top: 10),
      child: PieChart<Account>(
        data: accounts,
        valueMapper: (it) => it.balance.asDollarDouble(),
        colorMapper: (it) => it.color,
        labelMapper: (it, frac) => "${it.name}\n${formatPercent(frac)}",
        onTap: (i, it) => toAccountScreen(context, it),
      ),
    );
  }
}

class _LiabilitiesPie extends StatelessWidget {
  final double? height;
  const _LiabilitiesPie(this.height, {super.key});

  @override
  Widget build(BuildContext context) {
    final accounts =
        context.watch<AccountState>().list.where((it) => it.type == AccountType.liability).toList();
    final total = accounts.fold(0, (cum, acc) => cum + acc.balance);
    return ChartWithTitle(
      height: height,
      textLeft: 'Liabilities',
      textRight: (-total).dollarString(),
      textStyle: Theme.of(context).textTheme.headlineMedium,
      padding: const EdgeInsets.only(top: 10),
      child: PieChart<Account>(
        data: accounts,
        valueMapper: (it) => it.balance.abs().asDollarDouble(),
        colorMapper: (it) => it.color,
        labelMapper: (it, frac) => "${it.name}\n${formatPercent(frac)}",
        onTap: (i, it) => toAccountScreen(context, it),
      ),
    );
  }
}
