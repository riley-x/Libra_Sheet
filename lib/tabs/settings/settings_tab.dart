import 'package:flutter/material.dart';

import 'settings_card.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    Widget mainScreen = const _SettingsTab();
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 850) {
          if (true) {
            return mainScreen;
          } else {
            return Placeholder();
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
              Expanded(child: Placeholder()),
            ],
          );
        }
      },
    );
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab({super.key});

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
                  onTap: () {}, // TODO
                ),
                const SizedBox(height: 8),
                SettingsCard(
                  text: 'Categories',
                  subText:
                      "Customize your categories. Each transaction is classified into a single category.",
                  onTap: () {}, // TODO
                ),
                const SizedBox(height: 8),
                SettingsCard(
                  text: 'Tags',
                  subText: "Customize your tags. Transactions can have multiple tags.",
                  onTap: () {}, // TODO
                ),
                const SizedBox(height: 8),
                SettingsCard(
                  text: 'Rules',
                  subText: "Create automatic categorization rules when inputting CSV files.",
                  onTap: () {}, // TODO
                ),
                const SizedBox(height: 8),
                SettingsCard(
                  text: 'Transactions',
                  subText: "Add new transactions.",
                  onTap: () {}, // TODO
                ),
                const SizedBox(height: 8),
                SettingsCard(
                  text: 'Database',
                  subText: "Backup or restore the app database.",
                  onTap: () {}, // TODO
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
