import 'package:flutter/material.dart';
import 'package:libra_sheet/data/export/google_drive.dart';
import 'package:provider/provider.dart';

class GoogleDriveCard extends StatelessWidget {
  const GoogleDriveCard({super.key});

  @override
  Widget build(BuildContext context) {
    final drive = context.watch<GoogleDrive>();
    final status = drive.status();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          if (drive.active) {
            drive.disable();
          } else if (drive.isAuthorized) {
            drive.enable();
          } else {
            await drive.promptUserConsent();
          }
          print(GoogleDrive.driveFile?.modifiedTime);
          print(GoogleDrive.lastLocalUpdateTime);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    'Sync status: ',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  switch (status) {
                    GoogleDriveSyncStatus.upToDate => Text(
                        "active (up to date)",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.green),
                      ),
                    GoogleDriveSyncStatus.driveAhead => Text(
                        "active (waiting for download)",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.amber),
                      ),
                    GoogleDriveSyncStatus.localAhead => Text(
                        "active (waiting for upload)",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.amber),
                      ),
                    GoogleDriveSyncStatus.noAuthentication => Text(
                        "disabled (click to enable)",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                      ),
                  },
                ],
              ),
              if (status != GoogleDriveSyncStatus.noAuthentication) ...[
                Row(
                  children: [
                    const SizedBox(width: 20),
                    const SizedBox(
                      width: 100,
                      child: Text('Drive ID:'),
                    ),
                    Text('${GoogleDrive.driveFile?.id}'),
                  ],
                ),
                Row(
                  children: [
                    const SizedBox(width: 20),
                    const SizedBox(
                      width: 100,
                      child: Text('Timestamp:'),
                    ),
                    Text('${GoogleDrive.driveFile?.modifiedTime?.toLocal()}'),
                  ],
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
