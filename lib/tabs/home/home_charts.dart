import 'package:flutter/material.dart';
import 'package:libra_sheet/components/buttons/time_frame_selector.dart';
import 'package:libra_sheet/data/app_state/account_state.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/time_value.dart';
import 'package:libra_sheet/graphing/cartesian/cartesian_axes.dart';
import 'package:libra_sheet/graphing/cartesian/discrete_cartesian_graph.dart';
import 'package:libra_sheet/graphing/cartesian/month_axis.dart';
import 'package:libra_sheet/graphing/pie/pie_chart.dart';
import 'package:libra_sheet/graphing/series/line_series.dart';
import 'package:libra_sheet/graphing/series/series.dart';
import 'package:libra_sheet/graphing/series/stack_line_series.dart';
import 'package:libra_sheet/tabs/home/chart_with_title.dart';
import 'package:libra_sheet/tabs/home/home_tab_state.dart';
import 'package:libra_sheet/tabs/navigation/libra_navigation.dart';
import 'package:provider/provider.dart';

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
            HomeChartMode.stacked => const _StackedChart(),
            HomeChartMode.pies => const _PieCharts(),
          },
        ),
        const SizedBox(height: 10),
        const _HomeChartSelectors(),
        const SizedBox(height: 10),
      ],
    );
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

/// Row containing the segmented buttons below the chart
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

class _PieCharts extends StatelessWidget {
  const _PieCharts({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final needScroll = constraints.maxHeight < 2 * HomeCharts.minPieHeight;
      final pieChartsAligned =
          needScroll && constraints.maxWidth > 2 * HomeCharts.minPieHeight + 16;
      if (pieChartsAligned) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            const Expanded(child: _AssetsPie(null)),
            Container(
              width: 1,
              height: constraints.maxHeight,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(height: 10),
            const Expanded(child: _LiabilitiesPie(null)),
          ],
        );
      } else if (needScroll) {
        return ListView(
          children: [
            const Center(child: _AssetsPie(HomeCharts.minPieHeight)),
            Container(
              height: 1,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const Center(child: _LiabilitiesPie(HomeCharts.minPieHeight)),
          ],
        );
      } else {
        return Column(
          children: [
            const Expanded(child: const _AssetsPie(null)),
            Container(
              height: 1,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const Expanded(child: _LiabilitiesPie(null)),
          ],
        );
      }
    });
  }
}

class _NetWorthGraph extends StatelessWidget {
  const _NetWorthGraph({super.key});

  static final gradientColors = [
    Colors.blue.withAlpha(10),
    Colors.blue.withAlpha(80),
    Colors.blue.withAlpha(170),
  ];
  static const gradientStops = [0.0, 0.6, 1.0];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HomeTabState>();
    return Padding(
      padding: const EdgeInsets.only(left: 6, right: 10),
      child: DiscreteCartesianGraph(
        yAxis: CartesianAxis(
          theme: Theme.of(context),
          axisLoc: null,
          valToString: formatDollar,
          min: 0,
        ),
        xAxis: MonthAxis(
          theme: Theme.of(context),
          axisLoc: 0,
          dates: state.monthList.looseRange(state.timeFrameRange),
          pad: 0,
        ),
        data: SeriesCollection([
          LineSeries<TimeIntValue>(
            name: "Net Worth",
            color: Colors.blue,
            data: state.netWorthData.looseRange(state.timeFrameRange),
            valueMapper: (i, item) => Offset(i.toDouble(), item.value.asDollarDouble()),
            gradient: LinearGradient(
              colors: gradientColors,
              stops: gradientStops,
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ]),
      ),
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
      // textLeft: 'Assets',
      // textRight: total.dollarString(),
      textStyle: Theme.of(context).textTheme.titleLarge,
      padding: const EdgeInsets.only(top: 10),
      child: PieChart<Account>(
        data: accounts,
        valueMapper: (it) => it.balance.asDollarDouble(),
        colorMapper: (it) => it.color,
        labelMapper: (it, frac) => "${it.name}\n${formatPercent(frac)}",
        onTap: (i, it) => toAccountScreen(context, it),
        defaultLabel: "Assets\n${total.dollarString()}",
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
      // textLeft: 'Liabilities',
      // textRight: (-total).dollarString(),
      textStyle: Theme.of(context).textTheme.headlineMedium,
      padding: const EdgeInsets.only(top: 10),
      child: PieChart<Account>(
        data: accounts,
        valueMapper: (it) => it.balance.abs().asDollarDouble(),
        colorMapper: (it) => it.color,
        labelMapper: (it, frac) => "${it.name}\n${formatPercent(frac)}",
        onTap: (i, it) => toAccountScreen(context, it),
        defaultLabel: "Liabilities\n${(-total).dollarString()}",
      ),
    );
  }
}

class _StackedChart extends StatelessWidget {
  const _StackedChart({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HomeTabState>();
    return Padding(
      padding: const EdgeInsets.only(left: 6, right: 10),
      child: DiscreteCartesianGraph(
        yAxis: CartesianAxis(
          theme: Theme.of(context),
          axisLoc: null,
          valToString: formatDollar,
        ),
        xAxis: MonthAxis(
          theme: Theme.of(context),
          axisLoc: 0,
          dates: state.monthList.looseRange(state.timeFrameRange),
          pad: 0,
        ),
        data: SeriesCollection([
          for (final accHistory in state.liabAccounts + state.assetAccounts)
            StackLineSeries<int>(
              name: accHistory.account.name,
              color: accHistory.account.color,
              data: accHistory.values.looseRange(state.timeFrameRange),
              valueMapper: (i, item) => Offset(i.toDouble(), item.asDollarDouble()),
            ),
        ]),
        // onTap: (iSeries, series, iData) {
        //         if (range != null) iData += range!.$1;
        //         // The -1 because of the dashed horizontal line inflates the series index by 1.
        //         if (averageColor != null) iSeries--;
        //         onTap?.call(data.categories[iSeries].category, data.times[iData]);
        //       },
      ),
    );
  }
}
