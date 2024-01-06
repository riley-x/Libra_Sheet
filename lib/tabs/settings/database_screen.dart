import 'package:flutter/material.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/database/libra_database.dart';
import 'package:libra_sheet/tabs/settings/google_drive_card.dart';
import 'package:libra_sheet/tabs/settings/settings_card.dart';
import 'package:provider/provider.dart';

class DatabaseScreen extends StatelessWidget {
  const DatabaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("All the data in the app is saved to the following file:"),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: SelectableText(
                LibraDatabase.databasePath,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const Text(
              "The app will also periodically make backups in the same folder. If you ever need to"
              " restore a backup, simply replace the file above."),
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Google Drive Sync',
                  style: Theme.of(context).textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const GoogleDriveSwitch(),
            ],
          ),
          const SizedBox(height: 5),
          // TODO add way to change account
          const GoogleDriveCard(),
          const SizedBox(height: 10),
          const Text(
              'On the first sync, a file "libra_sheet.db" will be created in your "My Drive" folder. '
              'Feel free to move it afterwards though. Warning: if you upload a database file manually, '
              'the app will not have permissions to sync with it.'),
          const SizedBox(height: 40),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Export to CSV',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 10),
          SettingsCard(
            content: Text(
              'Export Balance History',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            onTap: () {
              final messenger = ScaffoldMessenger.of(context);
              context.read<LibraAppState>().exportBalanceHistoryToCsv().then(
                (filepath) {
                  if (filepath == null || !messenger.mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Center(child: Text('Saved balance history to $filepath.')),
                      width: 500.0,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 8),
          SettingsCard(
            content: Text(
              'Export Transactions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            onTap: () {
              final messenger = ScaffoldMessenger.of(context);
              context.read<LibraAppState>().exportTransactionsToCsv().then(
                (filepath) {
                  if (filepath == null || !messenger.mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Center(child: Text('Saved transaction history to $filepath.')),
                      width: 500.0,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
