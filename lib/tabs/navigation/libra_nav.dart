import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/export/google_drive.dart';
import 'package:provider/provider.dart';

enum LibraNavDestination {
  home(icon: Icons.home, label: 'Home'),
  analyze(icon: Icons.insights, label: 'Analyze'),
  // cashFlows(icon: Icons.swap_horiz, label: 'Cash Flows'),
  // categories(icon: Icons.category, label: 'Categories'),
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

class LibraNav extends StatefulWidget {
  const LibraNav({
    super.key,
    this.onDestinationSelected,
  });

  final Function(int)? onDestinationSelected;

  // these were empirically determined from testing
  static const minWidth = 80.0;
  static const iconWidth = 24.0;
  static const iconPadding = (minWidth - iconWidth) / 2;
  static const iconButtonPadding = 8.0;
  static const iconManualPadding = iconPadding - iconButtonPadding;
  // this is our choice
  static const expandedWidth = 220.0;

  @override
  State<LibraNav> createState() => _LibraNavState();
}

class _LibraNavState extends State<LibraNav> {
  bool extended = true;

  void toggleExtended() {
    setState(() {
      extended = !extended;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.select<LibraAppState, bool>((it) => it.isDarkMode);
    final selectedIndex = context.select<LibraAppState, int>((it) => it.currentTab);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final bkgColor = (isDarkMode) ? colorScheme.surface : colorScheme.secondary;
    final textColor = (isDarkMode) ? colorScheme.onSurface : colorScheme.onSecondary;

    return ExcludeFocus(
      child: NavigationRail(
        backgroundColor: bkgColor,
        indicatorColor: colorScheme.surfaceContainerHighest,
        unselectedLabelTextStyle: textTheme.labelLarge?.copyWith(color: textColor),
        selectedLabelTextStyle: textTheme.labelLarge?.copyWith(color: textColor),
        unselectedIconTheme: Theme.of(context).iconTheme.copyWith(color: textColor),
        extended: extended,
        minExtendedWidth: LibraNav.expandedWidth,
        destinations: libraNavDestinations,
        selectedIndex: selectedIndex,
        onDestinationSelected: widget.onDestinationSelected,
        leading: _LeadingContent(textColor: textColor, toggleExtended: toggleExtended),
        trailing: _FooterContent(textColor: textColor),
      ),
    );
  }
}

class _LeadingContent extends StatelessWidget {
  const _LeadingContent({required this.textColor, required this.toggleExtended});

  final Color textColor;
  final Function() toggleExtended;

  @override
  Widget build(BuildContext context) {
    final animation = NavigationRail.extendedAnimation(context);
    final textStyle = Theme.of(context).textTheme.headlineMedium;
    return AnimatedBuilder(
        animation: animation,
        builder: (BuildContext context, Widget? child) {
          return SizedBox(
            width: lerpDouble(LibraNav.minWidth, LibraNav.expandedWidth, animation.value),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRect(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(width: LibraNav.iconManualPadding),
                      Align(
                        heightFactor: 1.0,
                        widthFactor: animation.value,
                        alignment: AlignmentDirectional.centerStart,
                        child: FadeTransition(
                          opacity: animation.drive(CurveTween(curve: const Interval(0.0, 0.25))),
                          child: Text("Libra Sheet", style: textStyle?.copyWith(color: textColor)),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: toggleExtended,
                        icon: Icon(
                          animation.value == 1 ? Icons.first_page : Icons.last_page,
                          color: textColor,
                        ),
                      ),
                      SizedBox(width: lerpDouble(LibraNav.iconManualPadding, 0, animation.value)),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
  }
}

class _FooterContent extends StatelessWidget {
  const _FooterContent({required this.textColor});

  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).colorScheme.brightness == Brightness.dark;
    final animation = NavigationRail.extendedAnimation(context);

    final errorColor =
        (isDark) ? Theme.of(context).colorScheme.error : const Color.fromARGB(255, 255, 200, 200);

    final cloudStatus = context.watch<GoogleDrive>().status();
    final cloudIcon = switch (cloudStatus) {
      GoogleDriveSyncStatus.upToDate => Icons.cloud_done,
      GoogleDriveSyncStatus.driveAhead => Icons.cloud_download,
      GoogleDriveSyncStatus.localAhead => Icons.cloud_upload,
      GoogleDriveSyncStatus.noConnection => Icons.cloud_off,
      GoogleDriveSyncStatus.disabled => Icons.cloud_off,
    };
    final cloudText = switch (cloudStatus) {
      GoogleDriveSyncStatus.upToDate => "Up to date",
      GoogleDriveSyncStatus.driveAhead => "Download pending",
      GoogleDriveSyncStatus.localAhead => "Upload pending",
      GoogleDriveSyncStatus.noConnection => "No connection",
      GoogleDriveSyncStatus.disabled => "",
    };
    final cloudColor = switch (cloudStatus) {
      GoogleDriveSyncStatus.upToDate => Colors.green,
      GoogleDriveSyncStatus.driveAhead => Colors.amber,
      GoogleDriveSyncStatus.localAhead => Colors.amber,
      GoogleDriveSyncStatus.noConnection => errorColor,
      GoogleDriveSyncStatus.disabled => null,
    };

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: AnimatedBuilder(
            animation: animation,
            builder: (BuildContext context, Widget? child) {
              return SizedBox(
                width: lerpDouble(LibraNav.minWidth, LibraNav.expandedWidth, animation.value),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (kDebugMode) ...[
                      const _IconFooter(
                        icon: Icons.bug_report,
                        label: "Debug mode",
                        color: Colors.yellow,
                      ),
                    ],
                    _IconFooter(
                      icon: cloudIcon,
                      label: cloudText,
                      color: cloudColor,
                    ),
                    _DarkModeSwitch(textColor: textColor),
                  ],
                ),
              );
            }),
      ),
    );
  }
}

class _IconFooter extends StatelessWidget {
  const _IconFooter({
    super.key,
    required this.icon,
    required this.label,
    this.color,
    this.onPressed,
  });

  final IconData icon;
  final Color? color;
  final String label;
  final Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium;
    final Animation<double> animation = NavigationRail.extendedAnimation(context);
    return ClipRect(
      child: Row(
        children: [
          const SizedBox(width: LibraNav.iconManualPadding),
          IconButton(
            onPressed: onPressed,
            icon: Icon(icon, color: color),
          ),
          const SizedBox(width: LibraNav.iconManualPadding),
          Align(
            heightFactor: 1.0,
            widthFactor: animation.value,
            alignment: AlignmentDirectional.centerStart,
            child: FadeTransition(
              opacity: animation.drive(CurveTween(curve: const Interval(0.0, 0.25))),
              child: Text(label, style: textStyle?.copyWith(color: color)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkModeSwitch extends StatelessWidget {
  const _DarkModeSwitch({required this.textColor});

  final Color textColor;

  /// From testing
  // static const height = 40.0;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.select<LibraAppState, bool>((it) => it.isDarkMode);
    final animation = NavigationRail.extendedAnimation(context);
    return ClipRect(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(width: LibraNav.iconManualPadding),
          IconButton(
            onPressed: animation.value == 0 ? context.read<LibraAppState>().toggleDarkMode : null,
            icon: Icon(
              (isDarkMode || animation.value > 0.1) ? Icons.dark_mode_outlined : Icons.light_mode,
              color: textColor,
            ),
          ),
          Align(
            heightFactor: 1.0,
            widthFactor: animation.value,
            alignment: AlignmentDirectional.centerStart,
            child: FadeTransition(
              opacity: animation.drive(CurveTween(curve: const Interval(0.0, 1.0))),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: !isDarkMode,
                      onChanged: (value) => context.read<LibraAppState>().toggleDarkMode(),
                      activeColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: LibraNav.iconButtonPadding),
                  Icon(Icons.light_mode, color: textColor),
                ],
              ),
            ),
          ),
          const SizedBox(width: LibraNav.iconManualPadding),
        ],
      ),
    );
  }
}
