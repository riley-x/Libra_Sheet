import 'package:flutter/material.dart';
import 'package:libra_sheet/theme/colorscheme.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart' show DateFormat;

void main() {
  runApp(const LibraApp());
}

class LibraApp extends StatelessWidget {
  const LibraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => LibraAppState(),
      child: MaterialApp(
        title: 'Libra Sheet',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: libraDarkColorScheme,
        ),
        home: const MyHomePage(title: 'Flutter Demo Home Page'),
      ),
    );
  }
}

class SalesData {
  late DateTime year;
  final double sales;

  SalesData(int year, this.sales) {
    this.year = DateTime(year);
  }
}

class LibraAppState extends ChangeNotifier {
  final List<SalesData> chartData = [
    SalesData(2010, 35),
    SalesData(2011, 28),
    SalesData(2012, 34),
    SalesData(2013, 32),
    SalesData(2014, 40)
  ];

  void increment() {
    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<LibraAppState>();
    return Scaffold(
      body: Center(
        child: SfCartesianChart(
          primaryXAxis: DateTimeCategoryAxis(
            dateFormat: DateFormat.y(),
          ),
          series: <ChartSeries>[
            LineSeries<SalesData, DateTime>(
              dataSource: appState.chartData,
              xValueMapper: (SalesData sales, _) => sales.year,
              yValueMapper: (SalesData sales, _) => sales.sales,
            ),
          ],
        ),
      ),
    );
  }
}
