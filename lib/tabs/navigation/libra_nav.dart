import 'dart:ui';

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

  // these were empirically determined from testing
  static const minWidth = 80.0;
  static const iconWidth = 24.0;
  static const iconPadding = (minWidth - iconWidth) / 2;
  // this is our choice
  static const minExtendedWidth = 220.0;

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
        minExtendedWidth: minExtendedWidth,
        destinations: libraNavDestinations,
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        trailing: _FooterContent(textColor: textColor),
      ),
    );
  }
}

class _FooterContent extends StatelessWidget {
  const _FooterContent({required this.textColor});

  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium;
    final Animation<double> animation = NavigationRail.extendedAnimation(context);

    final cloudStatus = context.watch<GoogleDrive>().status();
    final cloudIcon = switch (cloudStatus) {
      GoogleDriveSyncStatus.upToDate => const Icon(Icons.cloud_done, color: Colors.green),
      GoogleDriveSyncStatus.driveAhead => const Icon(Icons.cloud_download, color: Colors.amber),
      GoogleDriveSyncStatus.localAhead => const Icon(Icons.cloud_upload, color: Colors.amber),
      GoogleDriveSyncStatus.noConnection =>
        Icon(Icons.cloud_off, color: Theme.of(context).colorScheme.error),
      GoogleDriveSyncStatus.disabled => const SizedBox(),
    };
    final cloudText = switch (cloudStatus) {
      GoogleDriveSyncStatus.upToDate =>
        Text("Up to date", style: textStyle?.copyWith(color: Colors.green)),
      GoogleDriveSyncStatus.driveAhead =>
        Text("Download pending", style: textStyle?.copyWith(color: Colors.amber)),
      GoogleDriveSyncStatus.localAhead =>
        Text("Upload pending", style: textStyle?.copyWith(color: Colors.amber)),
      GoogleDriveSyncStatus.noConnection => Text("No connection",
          style: textStyle?.copyWith(color: Theme.of(context).colorScheme.error)),
      GoogleDriveSyncStatus.disabled => const SizedBox(),
    };

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: AnimatedBuilder(
            animation: animation,
            builder: (BuildContext context, Widget? child) {
              return SizedBox(
                width: lerpDouble(LibraNav.minWidth, LibraNav.minExtendedWidth, animation.value),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRect(
                      child: Row(
                        children: [
                          const SizedBox(width: LibraNav.iconPadding),
                          cloudIcon,
                          const SizedBox(width: LibraNav.iconPadding),
                          Align(
                            heightFactor: 1.0,
                            widthFactor: animation.value,
                            alignment: AlignmentDirectional.centerStart,
                            child: cloudText,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: lerpDouble(0, 30, animation.value)),
                    if (animation.value == 1) _DarkModeSwitch(textColor: textColor),
                  ],
                ),
              );
            }),
      ),
    );
  }
}

class _DarkModeSwitch extends StatelessWidget {
  const _DarkModeSwitch({required this.textColor});

  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.select<LibraAppState, bool>((it) => it.isDarkMode);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.dark_mode_outlined, color: textColor),
        const SizedBox(width: 5),
        Switch(
          value: !isDarkMode,
          onChanged: (value) => context.read<LibraAppState>().toggleDarkMode(),
          activeColor: Theme.of(context).colorScheme.surfaceVariant,
        ),
        const SizedBox(width: 5),
        Icon(Icons.light_mode, color: textColor),
      ],
    );
  }
}
