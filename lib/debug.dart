import 'package:flutter/material.dart';

Future<void> debugManualMethod(BuildContext context) async {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('Backup uploaded successfully')));
}
