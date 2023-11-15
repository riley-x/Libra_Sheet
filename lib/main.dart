import 'package:flutter/material.dart';
import 'package:libra_sheet/data/time_value.dart';
import 'package:libra_sheet/graphing/line.dart';
import 'package:libra_sheet/theme/colorscheme.dart';
import 'package:provider/provider.dart';

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
        home: const MyHomePage(),
      ),
    );
  }
}

class LibraAppState extends ChangeNotifier {
  final List<TimeValue> chartData = [
    TimeValue.monthEnd(2010, 1, 35),
    TimeValue.monthEnd(2011, 2, 28),
    TimeValue.monthEnd(2012, 3, 34),
    TimeValue.monthEnd(2013, 4, 32),
    TimeValue.monthEnd(2014, 5, 40)
  ];

  void increment() {
    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<LibraAppState>();
    var chartData = appState.chartData;

    Widget page;
    switch (selectedIndex) {
      case 0:
        page = TestGraph(
          chartData: chartData,
        );
        break;
      case 1:
        page = const Placeholder();
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                extended: constraints.maxWidth >= 600,
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.home),
                    label: Text('Home'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.favorite),
                    label: Text('Favorites'),
                  ),
                ],
                selectedIndex: selectedIndex,
                onDestinationSelected: (value) {
                  setState(() {
                    selectedIndex = value;
                  });
                },
              ),
            ),
            Expanded(
              child: Container(
                // color: Theme.of(context).colorScheme.primaryContainer,
                child: page,
              ),
            ),
          ],
        ),
      );
    });
  }
}
