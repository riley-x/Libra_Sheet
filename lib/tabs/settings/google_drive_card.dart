import 'package:flutter/material.dart';
import 'package:libra_sheet/components/dialogs/confirmation_dialog.dart';
import 'package:libra_sheet/data/export/google_drive.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class GoogleDriveSection extends StatelessWidget {
  const GoogleDriveSection({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GoogleDrive>();
    return Column(
      children: [
        const GoogleDriveTitle(),
        const SizedBox(height: 5),
        const GoogleDriveCard(),
        if (state.active) ...[
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                onTap: GoogleDrive().promptUserConsent,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, right: 8, top: 4, bottom: 4),
                  child: Text(
                    'Change account',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
          const SizedBox(height: 25),
        ],
        if (!state.active) const SizedBox(height: 40),
      ],
    );
  }
}

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
                        GoogleDriveSyncStatus.noConnection => Text(
                            "no connection",
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                          ),
                        GoogleDriveSyncStatus.disabled => const Text("off"),
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

class GoogleDriveTitle extends StatelessWidget {
  const GoogleDriveTitle({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Google Drive Sync',
            style: Theme.of(context).textTheme.titleLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () {
            showConfirmationDialog(
              context: context,
              title: 'Google Drive Sync',
              msg: 'Automatically backup your data onto Google Drive!\n\n'
                  'On the first sync, a file "libra_sheet.db" will be created in your "My Drive" folder. '
                  'You can rename and move the file somewhere else though. '
                  'Libra Sheet will automatically update that file anytime you make a change. '
                  '\n\nLibra Sheet can not sync with any file that you manually upload to Google Drive.'
                  '\n\nWarning: If you use Libra Sheet on multiple computers, make sure to not touch the database file until the sync is complete. '
                  'The app uses the last modified time of the file to check the sync status, '
                  'so you may accidentally overwrite the cloud file with a stale local file.',
              showCancel: false,
            );
          },
        ),
        const SizedBox(width: 5),
        const GoogleDriveSwitch(),
      ],
    );
  }
}
