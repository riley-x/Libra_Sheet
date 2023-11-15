import 'package:flutter/material.dart';

enum LibraNavDestination {
  home(icon: Icons.home, label: 'Home'),
  balances(icon: Icons.account_balance, label: 'Balances');

  const LibraNavDestination({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}

var libraNavDestinations = [
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
    return NavigationRail(
      extended: extended,
      minExtendedWidth: 150,
      destinations: libraNavDestinations,
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
    );
  }
}
