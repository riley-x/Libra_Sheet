import 'package:flutter/material.dart';
import 'package:libra_sheet/data/test_state.dart';
import 'package:libra_sheet/tabs/cashFlow/cash_flow_tab.dart';
import 'package:libra_sheet/tabs/category/category_tab.dart';
import 'package:libra_sheet/tabs/home/home_tab.dart';
import 'package:libra_sheet/tabs/libra_nav.dart';
import 'package:libra_sheet/tabs/transaction/transaction_tab.dart';
import 'package:libra_sheet/theme/colorscheme.dart';
import 'package:libra_sheet/theme/text_theme.dart';
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
          textTheme: libraTextTheme,
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
    Widget page;
    switch (LibraNavDestination.values[selectedIndex]) {
      case LibraNavDestination.home:
        page = const HomeTab();
      case LibraNavDestination.cashFlows:
        page = const CashFlowTab();
      case LibraNavDestination.categories:
        page = const CategoryTab();
      case LibraNavDestination.transactions:
        page = const TransactionTab();
      default:
        page = const Placeholder();
    }

    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: LibraNav(
                selectedIndex: selectedIndex,
                extended: constraints.maxWidth >= 900,
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
