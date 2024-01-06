import 'package:flutter/material.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/export/google_drive.dart';
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

    final cloudStatus = context.watch<GoogleDrive>().status();

    final cloudIcon = switch (cloudStatus) {
      GoogleDriveSyncStatus.upToDate => const Icon(Icons.cloud_done, color: Colors.green),
      GoogleDriveSyncStatus.driveAhead => const Icon(Icons.cloud_download, color: Colors.amber),
      GoogleDriveSyncStatus.localAhead => const Icon(Icons.cloud_upload, color: Colors.amber),
      GoogleDriveSyncStatus.disabled => const SizedBox(),
    };

    final cloudText = switch (cloudStatus) {
      GoogleDriveSyncStatus.upToDate =>
        Text("Up to date", style: textTheme.bodyMedium?.copyWith(color: Colors.green)),
      GoogleDriveSyncStatus.driveAhead =>
        Text("Download pending", style: textTheme.bodyMedium?.copyWith(color: Colors.amber)),
      GoogleDriveSyncStatus.localAhead =>
        Text("Upload pending", style: textTheme.bodyMedium?.copyWith(color: Colors.amber)),
      GoogleDriveSyncStatus.disabled => const SizedBox(),
    };

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
        // TODO this is janky when expanding because the animation starts off narrow but the column
        // expands to the width of the wider content already
        trailing: Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: extended
                  ? [
                      SizedBox(
                        width: 220,
                        child: Row(
                          children: [
                            const SizedBox(width: 30),
                            cloudIcon,
                            const SizedBox(width: 20),
                            cloudText,
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
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
                    ]
                  : [
                      cloudIcon,
                    ],
            ),
          ),
        ),
      ),
    );
  }
}
