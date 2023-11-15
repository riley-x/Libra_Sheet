import 'package:flutter/material.dart';
import 'package:libra_sheet/data/test_state.dart';
import 'package:libra_sheet/graphing/line.dart';
import 'package:libra_sheet/libra_nav.dart';
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
        home: const LibraHomePage(),
      ),
    );
  }
}

class LibraHomePage extends StatefulWidget {
  const LibraHomePage({super.key});

  @override
  State<LibraHomePage> createState() => _LibraHomePageState();
}

class _LibraHomePageState extends State<LibraHomePage> {
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
        page = const Placeholder();
        break;
      // throw UnimplementedError('no widget for $selectedIndex');
    }

    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: LibraNav(
                selectedIndex: selectedIndex,
                extended: constraints.maxWidth >= 600,
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
