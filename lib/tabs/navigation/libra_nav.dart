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
    final selectedIndex = context.select<LibraAppState, int>((it) => it.currentTab);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return NavigationRail(
      backgroundColor: colorScheme.secondary,
      indicatorColor: colorScheme.surfaceVariant,
      unselectedLabelTextStyle: textTheme.labelLarge?.copyWith(color: colorScheme.onSecondary),
      selectedLabelTextStyle: textTheme.labelLarge?.copyWith(color: colorScheme.onSecondary),
      unselectedIconTheme: Theme.of(context).iconTheme.copyWith(color: colorScheme.onSecondary),
      extended: extended,
      minExtendedWidth: 220,
      destinations: libraNavDestinations,
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                const Icon(Icons.dark_mode),
                Switch(
                  value: context.select<LibraAppState, bool>((it) => !it.isDarkMode),
                  onChanged: (value) => context.read<LibraAppState>().toggleDarkMode(),
                ),
                const Icon(Icons.light_mode),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
