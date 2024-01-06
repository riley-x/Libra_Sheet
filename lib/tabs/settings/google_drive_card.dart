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
        onTap: drive.active ? drive.sync : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          child: Row(
            children: [
              Expanded(
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
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(color: Colors.green),
                            ),
                          GoogleDriveSyncStatus.driveAhead => Text(
                              "active (waiting for download)",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(color: Colors.amber),
                            ),
                          GoogleDriveSyncStatus.localAhead => Text(
                              "active (waiting for upload)",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(color: Colors.amber),
                            ),
                          GoogleDriveSyncStatus.noAuthentication => Text(
                              "disabled",
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                            ),
                        },
                      ],
                    ),
                    if (status != GoogleDriveSyncStatus.noAuthentication) ...[
                      _FieldRow('Drive ID:', '${GoogleDrive.driveFile?.id}'),
                      _FieldRow(
                          'Drive Timestamp:', '${GoogleDrive.driveFile?.modifiedTime?.toLocal()}'),
                      _FieldRow(
                          'Device Timestamp:', '${GoogleDrive.lastLocalUpdateTime.toLocal()}'),
                    ]
                  ],
                ),
              ),
              if (drive.active) const Icon(Icons.refresh),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow(this.label, this.value, {super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final drive = context.watch<GoogleDrive>();
    return Row(
      children: [
        const SizedBox(width: 20),
        SizedBox(
          width: 150,
          child: Text(label),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class GoogleDriveSwitch extends StatelessWidget {
  const GoogleDriveSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final drive = context.watch<GoogleDrive>();
    return Switch(
      value: drive.active,
      activeColor: Theme.of(context).colorScheme.surfaceTint,
      activeTrackColor: Theme.of(context).colorScheme.primaryContainer,
      onChanged: (it) async {
        if (drive.active) {
          drive.disable();
        } else if (drive.isAuthorized) {
          drive.enable();
        } else {
          await drive.promptUserConsent();
        }
      },
    );
  }
}
