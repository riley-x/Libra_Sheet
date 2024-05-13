import 'package:flutter/material.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/enums.dart';
import 'package:libra_sheet/tabs/settings/database_screen.dart';
import 'package:libra_sheet/tabs/settings/edit_accounts_screen.dart';
import 'package:libra_sheet/tabs/settings/edit_categories_screen.dart';
import 'package:libra_sheet/tabs/settings/edit_rules_screen.dart';
import 'package:libra_sheet/tabs/settings/edit_tags_screen.dart';
import 'package:libra_sheet/tabs/settings/settings_screen_header.dart';
import 'package:provider/provider.dart';

import 'settings_card.dart';

enum SettingsScreen {
  none(''),
  accounts('Accounts'),
  categories('Categories'),
  tags('Tags'),
  rules('Rules'),
  incomeRules('Rules  |  Income', SettingsScreen.rules),
  expenseRules('Rules  |  Expense', SettingsScreen.rules),
  transactions('Transactions'),
  database('Database');

  const SettingsScreen(this.title, [this.parent]);

  final String title;
  final SettingsScreen? parent;
}

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  SettingsScreen tab = SettingsScreen.none;

  bool clearFocus(BuildContext context) {
    switch (tab) {
      case SettingsScreen.accounts:
        final state = context.read<EditAccountState>();
        if (state.isFocused) {
          state.clearFocus();
          return true;
        }
      case SettingsScreen.categories:
        final state = context.read<EditCategoriesState>();
        if (state.isFocused) {
          state.clearFocus();
          return true;
        }
      case SettingsScreen.tags:
        final state = context.read<EditTagsState>();
        if (state.isFocused) {
          state.clearFocus();
          return true;
        }
      case SettingsScreen.incomeRules:
      case SettingsScreen.expenseRules:
        final state = context.read<EditRulesState>();
        if (state.isFocused) {
          state.clearFocus();
          return true;
        }
      default:
    }
    return false;
  }

  void onBack(BuildContext context) {
    if (clearFocus(context)) return;
    setState(() {
      if (tab.parent != null) {
        tab = tab.parent!;
      } else {
        tab = SettingsScreen.none;
      }
    });
  }

  void onSelect(BuildContext context, SettingsScreen it) {
    clearFocus(context);
    setState(() {
      tab = it;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      /// The providers need to be above the LayoutBuilder to survive a screen switch
      providers: [
        ChangeNotifierProvider<EditAccountState>(
            create: (context) => EditAccountState(context.read<LibraAppState>())),
        ChangeNotifierProvider<EditCategoriesState>(
            create: (context) => EditCategoriesState(context.read<LibraAppState>())),
        ChangeNotifierProvider<EditTagsState>(
            create: (context) => EditTagsState(context.read<LibraAppState>())),
        ChangeNotifierProvider<EditRulesState>(
            create: (context) => EditRulesState(context.read<LibraAppState>())),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          Widget mainScreen = _SettingsTab(onSelect: (it) => onSelect(context, it));
          Widget auxContent = switch (tab) {
            SettingsScreen.accounts => const EditAccountsScreen(),
            SettingsScreen.categories => const EditCategoriesScreen(),
            SettingsScreen.tags => const EditTagsScreen(),
            SettingsScreen.rules => RulesSettingsScreen((it) => onSelect(context, it)),
            SettingsScreen.incomeRules => const EditRulesScreen(ExpenseType.income),
            SettingsScreen.expenseRules => const EditRulesScreen(ExpenseType.expense),
            SettingsScreen.database => const DatabaseScreen(),
            _ => const SizedBox(),
          };

          bool isFullScreen = constraints.maxWidth < 950;
          Widget auxScreen = SettingsScreenHeader(
            screen: tab,
            isFullScreen: isFullScreen,
            onBack: () => onBack(context),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: auxContent,
            ),
          );

          if (isFullScreen) {
            if (tab == SettingsScreen.none) {
              return mainScreen;
            } else {
              return auxScreen;
            }
          } else {
            return Row(
              children: [
                mainScreen,
                Container(
                  width: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                Expanded(child: auxScreen),
              ],
            );
          }
        },
      ),
    );
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab({super.key, this.onSelect});

  final Function(SettingsScreen tab)? onSelect;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Text(
                  'Settings',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 10),
                SettingsCard(
                  text: 'Accounts',
                  subText: "Add and edit accounts.",
                  onTap: () => onSelect?.call(SettingsScreen.accounts),
                ),
                const SizedBox(height: 8),
                SettingsCard(
                  text: 'Categories',
                  subText: "Customize your income and expense categories.",
                  onTap: () => onSelect?.call(SettingsScreen.categories),
                ),
                const SizedBox(height: 8),
                SettingsCard(
                  text: 'Tags',
                  subText: "Customize your tags. "
                      // "Tags are lightweight labels to help organize similar transactions from different categories and accounts. "
                      "Tags help you easily track specific transactions.",
                  onTap: () => onSelect?.call(SettingsScreen.tags),
                ),
                const SizedBox(height: 8),
                SettingsCard(
                  text: 'Rules',
                  subText: "Create automatic categorization rules when inputting CSV files.",
                  onTap: () => onSelect?.call(SettingsScreen.rules),
                ),
                const SizedBox(height: 8),
                // SettingsCard(
                //   text: 'Transactions',
                //   subText: "Add new transactions.",
                //   onTap: () => onSelect?.call(SettingsScreen.transactions),
                // ),
                // const SizedBox(height: 8),
                SettingsCard(
                  text: 'Database',
                  subText: "Backup and export the app database.",
                  onTap: () => onSelect?.call(SettingsScreen.database),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
