import 'package:flutter/material.dart';
import 'package:libra_sheet/data/account.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class LibraPieChart extends StatelessWidget {
  const LibraPieChart(this.data, {super.key});

  final CircularSeries data;

  @override
  Widget build(BuildContext context) {
    return SfCircularChart(
      margin: const EdgeInsets.only(top: 5),
      tooltipBehavior: TooltipBehavior(
        enable: true,
        activationMode: ActivationMode.singleTap,
        format: 'point.x: \$point.y',
      ),
      series: <CircularSeries>[data],
    );
  }
}

class AccountPieChart extends StatelessWidget {
  const AccountPieChart(this.accounts, {super.key});

  final List<Account> accounts;

  @override
  Widget build(BuildContext context) {
    return LibraPieChart(
      DoughnutSeries<Account, String>(
        animationDuration: 300,
        dataSource: accounts,
        xValueMapper: (Account data, _) => data.name,
        yValueMapper: (Account data, _) => data.balance / 10000,
        pointColorMapper: (Account account, _) => account.color,
        dataLabelMapper: (Account account, _) => account.name,
        // account.balance.dollarString(),
        radius: '80%',
        innerRadius: '60%',
        enableTooltip: true,
        // explode: true,
        // explodeGesture: ActivationMode.singleTap,
        dataLabelSettings: DataLabelSettings(
          isVisible: true,
          textStyle: Theme.of(context).textTheme.labelLarge,
          labelIntersectAction: LabelIntersectAction.shift, // Avoid labels intersection
          labelPosition: ChartDataLabelPosition.outside,
          // connectorLineSettings:
          // ConnectorLineSettings(type: ConnectorType.curve, length: '25%'),
        ),
      ),
    );
  }
}
