import 'package:flutter/material.dart';
import 'package:libra_sheet/data/libra_app_state.dart';
import 'package:provider/provider.dart';

/// Simple top app bar with a back button and two texts.
class CommonBackBar extends StatelessWidget {
  final String? leftText;
  final String? rightText;
  final TextStyle? rightStyle;
  final Function()? onBack;
  const CommonBackBar({
    super.key,
    this.leftText,
    this.rightText,
    this.onBack,
    this.rightStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack ?? context.read<LibraAppState>().popBackStack,
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          leftText ?? '',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const Spacer(),
        Text(
          rightText ?? '',
          style: rightStyle ?? Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(width: 15),
      ],
    );
  }
}
