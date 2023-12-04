import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:libra_sheet/tabs/navigation/libra_navigation.dart';

class TransactionSpeedDial extends StatelessWidget {
  const TransactionSpeedDial({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      useRotationAnimation: true,
      spacing: 3,
      // Can't use overlay because of this bug:
      // https://github.com/darioielardi/flutter_speed_dial/issues/290
      renderOverlay: false,
      overlayOpacity: 0.4,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.upload_file),
          backgroundColor: Colors.green.shade600,
          foregroundColor: Colors.white,
          label: 'Add CSV',
          onTap: () => toCsvScreen(context),
        ),
        SpeedDialChild(
          child: const Icon(Icons.edit_note),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          label: 'Add manual',
          onTap: () => toTransactionDetails(context, null),
        ),
      ],
    );
  }
}
