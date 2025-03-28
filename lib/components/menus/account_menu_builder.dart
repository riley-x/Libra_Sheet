import 'package:flutter/material.dart';
import 'package:libra_sheet/components/menus/account_checkbox_menu.dart';
import 'package:libra_sheet/data/objects/account.dart';

Widget accountOrHeaderMenuBuilder(
  BuildContext context,
  AccountOrHeader? account, {
  bool containsHeaders = false,
  String? nullText,
}) {
  if (account?.header != null) {
    return LimitedBox(
      maxWidth: 400,
      child: Text(
        "${account!.header!.label} Accounts",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelLarge,
      ),
    );
  } else {
    return accountMenuBuilder(
      context,
      account?.account,
      indent: containsHeaders,
      nullText: nullText,
    );
  }
}

/// This callback is used to draw a single account row in dropdown menus.
Widget accountMenuBuilder(
  BuildContext context,
  Account? account, {
  bool indent = false,
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
        if (indent) const SizedBox(width: 8),
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
