import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:libra_sheet/components/dialogs/confirmation_dialog.dart'
    show showConfirmationDialog;
import 'package:libra_sheet/components/dialogs/loading_scrim.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/database/libra_database.dart';
import 'package:libra_sheet/flutter_utils/html.dart' show triggerFileDownload, pickFile;
import 'package:libra_sheet/tabs/settings/google_drive_card.dart';
import 'package:libra_sheet/tabs/settings/settings_card.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart' show databaseFactoryFfiWeb;

class DatabaseScreen extends StatelessWidget {
  const DatabaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!kIsWeb) ...[
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
              " restore a backup, simply replace the file above.",
            ),
            const SizedBox(height: 40),
          ],

          /// Google drive
          const GoogleDriveSection(),

          /// Web export bytes
          if (kIsWeb) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Backup Data', style: Theme.of(context).textTheme.titleLarge),
            ),
            const SizedBox(height: 10),
            SettingsCard(
              content: Text('Export Backup', style: Theme.of(context).textTheme.titleMedium),
              onTap: () async {
                final bytes = await databaseFactoryFfiWeb.readDatabaseBytes(
                  LibraDatabase.databasePath,
                );
                triggerFileDownload(bytes, "libra_sheet.db");
              },
            ),
            const SizedBox(height: 10),
            SettingsCard(
              content: Text('Restore Backup', style: Theme.of(context).textTheme.titleMedium),
              onTap: () async {
                final state = context.read<LibraAppState>();
                final messenger = ScaffoldMessenger.of(context);

                final ok = await showConfirmationDialog(
                  context: context,
                  title: 'Upload Backup',
                  msg:
                      'Uploading a backup will override everything currently stored.'
                      'Are you sure you wish to continue?',
                );
                if (!ok) return;

                final file = await pickFile();
                if (file == null) return;

                if (!context.mounted) return;
                showLoadingScrim(context: context);

                final bytes = await file.readAsBytes();
                await LibraDatabase.close();
                await databaseFactoryFfiWeb.writeDatabaseBytes(LibraDatabase.databasePath, bytes);
                await LibraDatabase.open();
                await state.onDatabaseReplaced();

                if (!context.mounted) return;
                Navigator.of(context, rootNavigator: true).pop();

                // For some reason this doesn't show. Maybe because of the RestartWidget?
                messenger.showSnackBar(
                  SnackBar(
                    content: const Center(child: Text('Backup uploaded successfully')),
                    width: 500.0,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
          ],

          /// CSV exports
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Export to CSV', style: Theme.of(context).textTheme.titleLarge),
          ),
          const SizedBox(height: 10),
          SettingsCard(
            content: Text('Export Balance History', style: Theme.of(context).textTheme.titleMedium),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              final filepath = await context.read<LibraAppState>().exportBalanceHistoryToCsv();
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
          ),
          const SizedBox(height: 8),
          SettingsCard(
            content: Text('Export Transactions', style: Theme.of(context).textTheme.titleMedium),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              final filepath = await context.read<LibraAppState>().exportTransactionsToCsv();
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
          ),
        ],
      ),
    );
  }
}
