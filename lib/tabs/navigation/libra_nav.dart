import 'package:flutter/material.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:provider/provider.dart';

enum LibraNavDestination {
  home(icon: Icons.home, label: 'Home'),
  cashFlows(icon: Icons.swap_horiz, label: 'Cash Flows'),
  categories(icon: Icons.category, label: 'Categories'),
  transactions(icon: Icons.request_quote, label: 'Transactions'),
  settings(icon: Icons.settings, label: 'Settings');

  const LibraNavDestination({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}

final libraNavDestinations = [
  for (var dest in LibraNavDestination.values)
    NavigationRailDestination(
      icon: Icon(dest.icon),
      label: Text(dest.label),
    )
];

class LibraNav extends StatelessWidget {
  const LibraNav({
    super.key,
    required this.extended,
    this.onDestinationSelected,
  });

  final bool extended;
  final Function(int)? onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.select<LibraAppState, bool>((it) => it.isDarkMode);
    final selectedIndex = context.select<LibraAppState, int>((it) => it.currentTab);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final bkgColor = (isDarkMode) ? colorScheme.background : colorScheme.secondary;
    final textColor = (isDarkMode) ? colorScheme.onBackground : colorScheme.onSecondary;

    return ExcludeFocus(
      child: NavigationRail(
        backgroundColor: bkgColor,
        indicatorColor: colorScheme.surfaceVariant,
        unselectedLabelTextStyle: textTheme.labelLarge?.copyWith(color: textColor),
        selectedLabelTextStyle: textTheme.labelLarge?.copyWith(color: textColor),
        unselectedIconTheme: Theme.of(context).iconTheme.copyWith(color: textColor),
        extended: extended,
        minExtendedWidth: 220,
        destinations: libraNavDestinations,
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        trailing: (!extended)
            ? null
            : Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Icon(Icons.dark_mode_outlined, color: textColor),
                        const SizedBox(width: 5),
                        Switch(
                          value: !isDarkMode,
                          onChanged: (value) => context.read<LibraAppState>().toggleDarkMode(),
                          activeColor: colorScheme.surfaceVariant,
                        ),
                        const SizedBox(width: 5),
                        Icon(Icons.light_mode, color: textColor),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
