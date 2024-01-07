import 'package:flutter/material.dart';
import 'package:libra_sheet/data/export/google_drive.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class GoogleDriveCard extends StatelessWidget {
  const GoogleDriveCard({super.key});

  @override
  Widget build(BuildContext context) {
    final drive = context.watch<GoogleDrive>();
    final status = drive.status();
    return Card(
      child: Padding(
        padding: const EdgeInsets.only(left: 15, top: 8, bottom: 8, right: 5),
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
                        GoogleDriveSyncStatus.disabled => Text(
                            "disabled",
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                          ),
                      },
                    ],
                  ),
                  if (status != GoogleDriveSyncStatus.disabled) ...[
                    _FieldRow(
                      'Drive ID:',
                      '${GoogleDrive().driveFile?.id}',
                      url: GoogleDrive().driveFile?.webViewLink,
                    ),
                    _FieldRow('Drive Timestamp:', '${GoogleDrive().getDriveTime()?.toLocal()}'),
                    _FieldRow(
                        'Device Timestamp:', '${GoogleDrive().lastLocalUpdateTime.toLocal()}'),
                  ]
                ],
              ),
            ),
            if (drive.active)
              IconButton(
                onPressed: drive.sync,
                icon: const Icon(Icons.refresh),
              ),
          ],
        ),
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow(this.label, this.value, {this.url});

  final String label;
  final String value;
  final String? url;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 20),
        SizedBox(
          width: 150,
          child: Text(label),
        ),
        Expanded(
            child: url == null
                ? Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      onTap: () => launchUrl(Uri.parse(url!)),
                      child: Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ),
                  )),
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
        } else {
          await drive.enable();
        }
      },
    );
  }
}
