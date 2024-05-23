import 'package:flutter/material.dart';
import 'package:libra_sheet/data/objects/account.dart';

/// This callback is used to draw a single account row in dropdown menus.
Widget accountMenuBuilder(
  BuildContext context,
  Account? account, {
  String? nullText,
}) {
  final text = Text(
    account?.name ?? nullText ?? '',
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: (account != null)
        ? Theme.of(context).textTheme.labelLarge
        : Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).hintColor),
  );
  return LimitedBox(
    maxWidth: 400, // prevent errors from [Flexible] below
    child: Row(
      children: [
        Container(
          width: 4,
          height: 30,
          color: account?.color,
        ),
        SizedBox(width: (account == null) ? 0 : 7),
        Flexible(child: text), // Necessary to make sure the text clips properly
      ],
    ),
  );
}
