import 'package:flutter/material.dart';

enum LibraNavDestination {
  home(icon: Icons.home, label: 'Home'),
  cashFlows(icon: Icons.swap_horiz, label: 'Cash Flows'),
  categories(icon: Icons.category, label: 'Categories'),
  transactions(icon: Icons.request_quote, label: 'Transactions');

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
    required this.selectedIndex,
    required this.extended,
    this.onDestinationSelected,
  });

  final int selectedIndex;
  final bool extended;
  final Function(int)? onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return NavigationRail(
      backgroundColor: colorScheme.secondary,
      indicatorColor: colorScheme.surfaceVariant,
      unselectedLabelTextStyle:
          textTheme.labelLarge?.copyWith(color: colorScheme.onSecondary),
      selectedLabelTextStyle:
          textTheme.labelLarge?.copyWith(color: colorScheme.onSecondary),
      unselectedIconTheme:
          Theme.of(context).iconTheme.copyWith(color: colorScheme.onSecondary),
      extended: extended,
      minExtendedWidth: 180,
      destinations: libraNavDestinations,
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
    );
  }
}
