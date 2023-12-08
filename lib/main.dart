import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:libra_sheet/data/database/libra_database.dart';
import 'package:libra_sheet/data/test_data.dart';
import 'package:libra_sheet/tabs/cashFlow/cash_flow_state.dart';
import 'package:libra_sheet/tabs/category/category_tab_state.dart';
import 'package:libra_sheet/tabs/settings/settings_tab.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filter_state.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/tabs/cashFlow/cash_flow_tab.dart';
import 'package:libra_sheet/tabs/category/category_tab.dart';
import 'package:libra_sheet/tabs/home/home_tab.dart';
import 'package:libra_sheet/tabs/navigation/libra_nav.dart';
import 'package:libra_sheet/tabs/transaction/transaction_tab.dart';
import 'package:libra_sheet/theme/text_theme.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  /// Disable debugPrint() in release mode
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }
  initializeTestData();

  /// Top level state
  final state = LibraAppState();
  await state.init();
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
        ChangeNotifierProvider(create: (_) => CashFlowState(state)),
        // used by the transaction tab
        ChangeNotifierProvider(create: (_) => TransactionFilterState(state.transactions)),
      ],
      builder: (context, child) {
        final isDarkMode = context.select<LibraAppState, bool>((it) => it.isDarkMode);
        return MaterialApp(
          title: 'Libra Sheet',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: context.select<LibraAppState, ColorScheme>((it) => it.colorScheme),
            textTheme: (isDarkMode) ? libraDarkTextTheme : libraTextTheme,
          ),
          themeAnimationDuration: Duration.zero,
          // the animation gets really janky when you have case statements on [isDarkMode] because
          // those don't animate with the rest of the theme.
          home: child,
        );
      },
      child: const LibraHomePage(),
    );
  }
}

class LibraHomePage extends StatelessWidget {
  const LibraHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: LibraNav(
                extended: constraints.maxWidth >= 900,
                onDestinationSelected: context.read<LibraAppState>().setTab,
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Navigator(
                    key: context.read<LibraAppState>().navigatorKey,
                    onGenerateRoute: (settings) {
                      // This just generates a single default route, since we have no named routes
                      return MaterialPageRoute(builder: (context) => const _Home());
                    },
                  ),
                  Positioned(
                    bottom: 10,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        color: Theme.of(context).colorScheme.surface.withAlpha(128),
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        child: Text(
                          'This is a sample only. Expect some things to not work!',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _Home extends StatelessWidget {
  const _Home({super.key});

  @override
  Widget build(BuildContext context) {
    final currentTab = context.select<LibraAppState, int>((it) => it.currentTab);

    var widgets = [
      const HomeTab(),
      const CashFlowTab(),
      const CategoryTab(),
      const TransactionTab(),
      const SettingsTab(),
    ];

    return IndexedStack(
      index: currentTab,
      // sizing: StackFit.expand,
      children: [
        for (final w in widgets)
          Material(
            child: w,
          )
      ],
    );
  }
}
