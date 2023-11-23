import 'package:flutter/material.dart';
import 'package:libra_sheet/components/common_back_bar.dart';

/// Common header for settings sub screens
class SettingsScreenHeader extends StatelessWidget {
  const SettingsScreenHeader({
    super.key,
    required this.title,
    required this.isFullScreen,
    this.onBack,
    required this.child,
  });

  final String title;
  final bool isFullScreen;
  final Function()? onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isFullScreen)
          CommonBackBar(
            leftText: "Settings  |  $title",
            onBack: onBack,
          ),
        if (!isFullScreen) ...[
          const SizedBox(height: 10),
          Text(
            title,
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
