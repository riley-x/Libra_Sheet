import 'package:libra_sheet/data/account.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/test_state.dart';
import 'package:libra_sheet/data/time_value.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

class TestGraph extends StatelessWidget {
  const TestGraph({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<LibraAppState>();

    return SfCartesianChart(
      primaryXAxis: DateTimeAxis(
        // dateFormat: DateFormat.y(),
        dateFormat: DateFormat.yMMM(),
        // interactiveTooltip: InteractiveTooltip(
        //   enable: true,
        //   borderColor: Colors.red,
        //   borderWidth: 2,
        // ),
        // majorGridLines: const MajorGridLines(width: 0),
      ),
      trackballBehavior: TrackballBehavior(
        enable: true,
        activationMode: ActivationMode.singleTap,
        tooltipSettings: const InteractiveTooltip(
          format: 'point.x: \$point.y',
        ),
      ),
      // zoomPanBehavior: ZoomPanBehavior( // this needs to elevate to a StatefulWidget I think
      //   enableSelectionZooming: true,
      //   selectionRectBorderColor: Colors.red,
      //   selectionRectBorderWidth: 1,
      //   selectionRectColor: Colors.grey,
      // ),
      series: <ChartSeries>[
        LineSeries<TimeValue, DateTime>(
          animationDuration: 300,
          dataSource: appState.chartData,
          xValueMapper: (TimeValue sales, _) => sales.time,
          yValueMapper: (TimeValue sales, _) => sales.value,
        ),
      ],
    );
  }
}

class TestPie extends StatelessWidget {
  const TestPie({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<LibraAppState>();

    return SfCircularChart(
      margin: const EdgeInsets.only(top: 5),
      tooltipBehavior: TooltipBehavior(
        enable: true,
        activationMode: ActivationMode.singleTap,
        format: 'point.x: \$point.y',
      ),
      series: <CircularSeries>[
        DoughnutSeries<Account, String>(
          animationDuration: 300,
          dataSource: appState.accounts,
          xValueMapper: (Account data, _) => data.name,
          yValueMapper: (Account data, _) => data.balance / 10000,
          pointColorMapper: (Account account, _) => account.color,
          dataLabelMapper: (Account account, _) => account.name,
          // account.balance.dollarString(),
          radius: '100%',
          innerRadius: '60%',
          enableTooltip: true,
          // explode: true,
          // explodeGesture: ActivationMode.singleTap,
          dataLabelSettings: DataLabelSettings(
            isVisible: true,
            textStyle: Theme.of(context).textTheme.labelLarge,
            labelIntersectAction:
                LabelIntersectAction.shift, // Avoid labels intersection
            labelPosition: ChartDataLabelPosition.outside,
            // connectorLineSettings:
            // ConnectorLineSettings(type: ConnectorType.curve, length: '25%'),
          ),
        ),
      ],
    );
  }
}
