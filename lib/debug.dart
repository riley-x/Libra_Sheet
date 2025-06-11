import 'package:flutter/material.dart';
import 'package:libra_sheet/components/dialogs/confirmation_dialog.dart';
import 'package:libra_sheet/data/export/google_drive.dart';

Future<void> debugManualMethod(BuildContext context) async {
  final val = GoogleDrive().status();
  showConfirmationDialog(context: context, msg: "$val");
}
