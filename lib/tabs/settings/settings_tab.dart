import 'package:flutter/material.dart';
import 'package:libra_sheet/data/libra_app_state.dart';
import 'package:libra_sheet/tabs/settings/edit_accounts_screen.dart';
import 'package:libra_sheet/tabs/settings/edit_categories_screen.dart';
import 'package:libra_sheet/tabs/settings/settings_screen_header.dart';
import 'package:libra_sheet/tabs/settings/settings_tab_state.dart';
import 'package:provider/provider.dart';

import 'settings_card.dart';

enum _CurrentTab {
  none(''),
  accounts('Accounts'),
  categories('Categories'),
  tags('Tags'),
  rules('Rules'),
  transactions('Transactions'),
  database('Database');

  const _CurrentTab(this.title);

  final String title;
}

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  _CurrentTab tab = _CurrentTab.none;

  void onBack() {
    setState(() {
      tab = _CurrentTab.none;
    });
  }

  void onSelect(_CurrentTab it) {
    setState(() {
      tab = it;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget mainScreen = _SettingsTab(onSelect: onSelect);
    Widget auxContent = switch (tab) {
      _CurrentTab.accounts => const EditAccountsScreen(),
      _CurrentTab.categories => const EditCategoriesScreen(),
      _ => const Placeholder(),
    };

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<EditAccountState>(
            create: (context) => EditAccountState(context.read<LibraAppState>())),
        ChangeNotifierProvider<EditCategoriesState>(create: (context) => EditCategoriesState()),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isFullScreen = constraints.maxWidth < 850;
          Widget auxScreen = SettingsScreenHeader(
            title: tab.title,
            isFullScreen: isFullScreen,
            onBack: onBack,
            child: auxContent,
          );

          if (isFullScreen) {
            if (tab == _CurrentTab.none) {
              return mainScreen;
            } else {
              return auxScreen;
            }
          } else {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
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

  final Function(_CurrentTab tab)? onSelect;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
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
                  onTap: () => onSelect?.call(_CurrentTab.accounts),
                ),
                const SizedBox(height: 8),
                SettingsCard(
                  text: 'Categories',
                  subText:
                      "Customize your categories. Each transaction is classified into a single category.",
                  onTap: () => onSelect?.call(_CurrentTab.categories),
                ),
                const SizedBox(height: 8),
                SettingsCard(
                  text: 'Tags',
                  subText: "Customize your tags. Transactions can have multiple tags.",
                  onTap: () => onSelect?.call(_CurrentTab.tags),
                ),
                const SizedBox(height: 8),
                SettingsCard(
                  text: 'Rules',
                  subText: "Create automatic categorization rules when inputting CSV files.",
                  onTap: () => onSelect?.call(_CurrentTab.rules),
                ),
                const SizedBox(height: 8),
                SettingsCard(
                  text: 'Transactions',
                  subText: "Add new transactions.",
                  onTap: () => onSelect?.call(_CurrentTab.transactions),
                ),
                const SizedBox(height: 8),
                SettingsCard(
                  text: 'Database',
                  subText: "Backup or restore the app database.",
                  onTap: () => onSelect?.call(_CurrentTab.database),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
