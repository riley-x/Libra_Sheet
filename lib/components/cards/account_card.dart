import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:libra_sheet/components/dialogs/text_field_dialog.dart';
import 'package:libra_sheet/components/menus/context_menu.dart';
import 'package:libra_sheet/data/app_state/account_state.dart';
import 'package:libra_sheet/data/date_time_utils.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/tabs/navigation/libra_navigation.dart';
import 'package:provider/provider.dart';

class AccountCard extends StatelessWidget {
  const AccountCard({
    super.key,
    required this.account,
    this.onTap,
    this.padding,
  });

  final Account account;
  final Function(Account)? onTap;
  final EdgeInsets? padding;

  /// Context menu
  Future<void> _onSecondaryTapUp(BuildContext context, TapUpDetails details) async {
    final accountState = context.read<AccountState>();
    await showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => CustomSingleChildLayout(
        delegate: ContextMenuPositionDelegate(target: details.globalPosition),
        child: Material(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ContextMenuItem(
                  text: 'Mark Up-to-date',
                  isFirst: true,
                  onTap: () async {
                    final res = await showTextFieldDialog(
                      context: context,
                      title: "Last Updated:",
                      initial: DateFormat('M/d/yy').format(DateTime.now()),
                      validator: (text) {
                        if (text?.isEmpty == true) return true;
                        final date = text?.parseDate();
                        return date != null;
                      },
                    );
                    if (res != null) {
                      if (res.isEmpty) {
                        account.lastUserUpdate = null;
                      } else {
                        account.lastUserUpdate = res.parseDate();
                      }
                      await accountState.notifyUpdate(account);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var lastUpdatedColor = theme.colorScheme.outline;
    if (account.lastUpdated != null &&
        account.lastUpdated!.difference(DateTime.now()).inDays < -30) {
      lastUpdatedColor = theme.colorScheme.error;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      // surfaceTintColor: // the alpha blend is necessary since the shadow behind is blackish
      //     Color.alphaBlend(account.color.withAlpha(128), Theme.of(context).colorScheme.surface),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          if (onTap != null) {
            onTap?.call(account);
          } else {
            toAccountScreen(context, account);
          }
        },
        onSecondaryTapUp: (it) => _onSecondaryTapUp(context, it),
        child: Padding(
          padding: padding ?? const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 40,
                color: account.color,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      account.description,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    account.balance.dollarString(),
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(
                    account.lastUpdated != null
                        ? "Updated: ${DateFormat.MMMd().format(account.lastUpdated!)}"
                        : "",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: lastUpdatedColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
