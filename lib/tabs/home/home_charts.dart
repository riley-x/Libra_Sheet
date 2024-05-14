import 'package:flutter/material.dart';
import 'package:libra_sheet/components/buttons/time_frame_selector.dart';
import 'package:libra_sheet/data/app_state/account_state.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/time_value.dart';
import 'package:libra_sheet/graphing/date_time_graph.dart';
import 'package:libra_sheet/graphing/pie/pie_chart.dart';
import 'package:libra_sheet/tabs/home/chart_with_title.dart';
import 'package:libra_sheet/tabs/home/home_tab_state.dart';
import 'package:libra_sheet/tabs/navigation/libra_navigation.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class HomeCharts extends StatelessWidget {
  const HomeCharts({
    super.key,
  });

  static const minNetWorthHeight = 500.0;
  static const minPieHeight = 400.0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HomeTabState>();
    return Column(
      children: [
        const _NetWorthTitle(),
        Expanded(
          child: switch (state.mode) {
            HomeChartMode.netWorth => const _NetWorthGraph(),
            HomeChartMode.stacked => const Placeholder(),
            HomeChartMode.pies => const Placeholder(),
          },
        ),
        const SizedBox(height: 10),
        const _HomeChartSelectors(),
        const SizedBox(height: 10),
      ],
    );

    // return LayoutBuilder(builder: (context, constraints) {
    //   final expandedCharts = constraints.maxHeight > minNetWorthHeight + minPieHeight + 1;
    //   final pieChartsAligned = constraints.maxWidth > 2 * minPieHeight + 16;
    //   if (pieChartsAligned && expandedCharts) {
    //     return const _ExpandedCharts();
    //   } else {
    //     return _ListCharts(pieChartsAligned: pieChartsAligned);
    //   }
    // });
  }
}

class _NetWorthTitle extends StatelessWidget {
  const _NetWorthTitle({super.key});

  @override
  Widget build(BuildContext context) {
    List<TimeIntValue> data = context.watch<HomeTabState>().netWorthData;
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10, top: 8, bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Net Worth',
              style: Theme.of(context).textTheme.headlineMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            (data.lastOrNull?.value ?? 0).dollarString(),
            style: Theme.of(context).textTheme.headlineMedium,
            maxLines: 1,
          )
        ],
      ),
    );
  }
}

class _HomeChartSelectors extends StatelessWidget {
  const _HomeChartSelectors({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(
          children: [
            // Text("Display"),
            // SizedBox(height: 5),
            _ModeSelector(),
          ],
        ),
        Column(
          children: [
            // Text("Time Frame"),
            // SizedBox(height: 5),
            _TimeFrameSelector(),
          ],
        )
      ],
    );
  }
}

/// Segmented button for the chart mode
class _ModeSelector extends StatelessWidget {
  const _ModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HomeTabState>();
    return SegmentedButton<HomeChartMode>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(
          value: HomeChartMode.stacked,
          icon: Icon(Icons.area_chart),
        ),
        ButtonSegment(
          value: HomeChartMode.netWorth,
          icon: Icon(Icons.show_chart),
        ),
        ButtonSegment(
          value: HomeChartMode.pies,
          icon: Icon(Icons.pie_chart),
        ),
      ],
      selected: {state.mode},
      onSelectionChanged: (newSelection) => state.setMode(newSelection.first),
    );
  }
}

/// Segmented button for the time frame
class _TimeFrameSelector extends StatelessWidget {
  const _TimeFrameSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final monthList = context.watch<LibraAppState>().monthList;
    final state = context.watch<HomeTabState>();
    return TimeFrameSelector(
      months: monthList,
      selected: state.timeFrame,
      onSelect: state.setTimeFrame,
      enabled: state.mode != HomeChartMode.pies,
    );
  }
}

/// Expands the line chart to fill the total height of the screen. The pie chart is left fixed.
class _ExpandedCharts extends StatelessWidget {
  const _ExpandedCharts({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // const Expanded(child: _NetWorthGraph(null)),
        Container(
          height: 1,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        _alignedPies(HomeCharts.minPieHeight, context),
      ],
    );
  }
}

/// Gives each chart a fixed height inside a list view. Used when the height of the window is not
/// sufficient to display all of the adequately.
class _ListCharts extends StatelessWidget {
  final bool pieChartsAligned;

  const _ListCharts({
    super.key,
    required this.pieChartsAligned,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        // const _NetWorthGraph(HomeCharts.minNetWorthHeight),
        Container(
          height: 1,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),

        /// Don't add padding here or else the vertical grid lines won't be tight
        if (pieChartsAligned) _alignedPies(HomeCharts.minPieHeight, context),
        if (!pieChartsAligned) ..._verticalPies(HomeCharts.minPieHeight, context),
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
  const _NetWorthGraph({super.key});

  static final gradientColors = LinearGradient(
    colors: [
      Colors.blue.withAlpha(10),
      Colors.blue.withAlpha(80),
      Colors.blue.withAlpha(170),
    ],
    stops: const [0.0, 0.6, 1],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HomeTabState>();
    return DateTimeGraph([
      AreaSeries<TimeIntValue, DateTime>(
        animationDuration: 0,
        dataSource: state.netWorthData.sublist(state.timeFrameRange.$1, state.timeFrameRange.$2),
        xValueMapper: (TimeIntValue sales, _) => sales.time,
        yValueMapper: (TimeIntValue sales, _) => sales.value.asDollarDouble(),
        gradient: gradientColors,
        borderColor: Colors.blue,
        borderWidth: 3,
        borderDrawMode: BorderDrawMode.top,
      ),
    ]);
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
