import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:libra_sheet/data/test_data.dart';
import 'package:libra_sheet/tabs/transaction_details_screen.dart';
import 'package:libra_sheet/data/account.dart';
import 'package:libra_sheet/data/libra_app_state.dart';
import 'package:libra_sheet/data/transaction.dart';
import 'package:libra_sheet/tabs/cashFlow/cash_flow_tab.dart';
import 'package:libra_sheet/tabs/category/category_tab.dart';
import 'package:libra_sheet/tabs/home/account_screen.dart';
import 'package:libra_sheet/tabs/home/home_tab.dart';
import 'package:libra_sheet/tabs/libra_nav.dart';
import 'package:libra_sheet/tabs/transaction/transaction_tab.dart';
import 'package:libra_sheet/theme/colorscheme.dart';
import 'package:libra_sheet/theme/text_theme.dart';
import 'package:provider/provider.dart';

void main() {
  /// Disable debugPrint() in release mode
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  } else {
    initializeTestData();
  }
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

class LibraHomePage extends StatelessWidget {
  const LibraHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentTab = context.select<LibraAppState, int>((it) => it.currentTab);

    /// DO NOT select the List itself, as that is a pointer only and updates won't be registered.
    final focusPage =
        context.select<LibraAppState, (DetailScreen, Object?)?>((it) => it.backStack.lastOrNull);

    Widget page;
    if (focusPage != null) {
      switch (focusPage.$1) {
        case DetailScreen.account:
          page = AccountScreen(account: focusPage.$2 as Account);
        case DetailScreen.transaction:
          page = TransactionDetailsScreen(focusPage.$2 as Transaction?);
      }
    } else {
      switch (LibraNavDestination.values[currentTab]) {
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
    }

    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: LibraNav(
                selectedIndex: currentTab,
                extended: constraints.maxWidth >= 900,
                onDestinationSelected: context.read<LibraAppState>().setTab,
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
