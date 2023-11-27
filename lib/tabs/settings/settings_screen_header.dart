import 'package:flutter/material.dart';
import 'package:libra_sheet/components/common_back_bar.dart';
import 'package:libra_sheet/tabs/settings/settings_tab.dart';

/// Common header for settings sub screens
class SettingsScreenHeader extends StatelessWidget {
  const SettingsScreenHeader({
    super.key,
    required this.screen,
    required this.isFullScreen,
    this.onBack,
    required this.child,
  });

  final SettingsScreen screen;
  final bool isFullScreen;
  final Function()? onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isFullScreen)
          CommonBackBar(
            leftText: "Settings  |  ${screen.title}",
            onBack: onBack,
          ),
        if (!isFullScreen) ...[
          const SizedBox(height: 10),
          Text(
            screen.title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 10),
        ],
        Expanded(
          child: child,
        ),
      ],
    );
  }
}
