import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:libra_sheet/data/test_data.dart';
import 'package:libra_sheet/tabs/category/category_tab_state.dart';
import 'package:libra_sheet/tabs/csv/add_csv_screen.dart';
import 'package:libra_sheet/tabs/settings/settings_tab.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filter_state.dart';
import 'package:libra_sheet/tabs/transactionDetails/transaction_details_screen.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/objects/transaction.dart' as transaction;
import 'package:libra_sheet/tabs/cashFlow/cash_flow_tab.dart';
import 'package:libra_sheet/tabs/category/category_tab.dart';
import 'package:libra_sheet/tabs/home/account_screen.dart';
import 'package:libra_sheet/tabs/home/home_tab.dart';
import 'package:libra_sheet/tabs/libra_nav.dart';
import 'package:libra_sheet/tabs/transaction/transaction_tab.dart';
import 'package:libra_sheet/theme/colorscheme.dart';
import 'package:libra_sheet/theme/text_theme.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  /// Disable debugPrint() in release mode
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  } else {
    initializeTestData();
  }

  /// Top level state
  final state = LibraAppState();
  runApp(LibraApp(state));
}

class LibraApp extends StatelessWidget {
  final LibraAppState state;

  const LibraApp(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: state),
        ChangeNotifierProvider.value(value: state.transactions),
        ChangeNotifierProvider(create: (_) => CategoryTabState(state)),
        // used by the transaction tab
        ChangeNotifierProvider(create: (_) => TransactionFilterState(state.transactions)),
      ],
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

    Widget focusPageWidget = switch (focusPage?.$1) {
      null => const Placeholder(),
      DetailScreen.account => AccountScreen(account: focusPage!.$2 as Account),
      DetailScreen.transaction =>
        TransactionDetailsScreen(focusPage!.$2 as transaction.Transaction?),
      DetailScreen.addCsv => const AddCsvScreen()
    };

    Widget mainTab = switch (LibraNavDestination.values[currentTab]) {
      LibraNavDestination.home => const HomeTab(),
      LibraNavDestination.cashFlows => const CashFlowTab(),
      LibraNavDestination.categories => const CategoryTab(),
      LibraNavDestination.transactions => const TransactionTab(),
      LibraNavDestination.settings => const SettingsTab(),
    };

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
              child: IndexedStack(
                index: (focusPage == null) ? 0 : 1,
                sizing: StackFit.expand,
                children: [
                  mainTab,
                  focusPageWidget,
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
