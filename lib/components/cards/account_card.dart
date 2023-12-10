import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/tabs/navigation/libra_navigation.dart';

class AccountCard extends StatelessWidget {
  const AccountCard({
    super.key,
    required this.account,
    this.onTap,
  });

  final Account account;
  final Function(Account)? onTap;

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
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
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
