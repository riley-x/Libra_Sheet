import 'package:flutter/material.dart';

class ConfirmationDialog extends StatelessWidget {
  const ConfirmationDialog({
    super.key,
    this.title,
    this.msg,
    this.showCancel = true,
    this.maxWidth = 500,
  });

  final String? title;
  final String? msg;
  final bool showCancel;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: (title == null) ? null : Text(title!),
      content: (msg == null)
          ? null
          : ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Text(msg!),
            ),
      actions: <Widget>[
        if (showCancel)
          TextButton(
            onPressed: () => Navigator.pop(context, 'Cancel'),
            child: const Text('Cancel'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context, 'Ok'),
          child: const Text('Ok'),
        ),
      ],
    );
  }
}

Future<bool> showConfirmationDialog({
  required BuildContext context,
  String? title,
  String? msg,
  @Deprecated('Use await') Function(bool confirmed)? onClose,
  @Deprecated('Use await') Function()? onConfirmed,
  bool showCancel = true,
  double maxWidth = 500,
}) async {
  final result = await showDialog(
    context: context,
    builder: (BuildContext context) {
      return ConfirmationDialog(
        title: title,
        msg: msg,
        showCancel: showCancel,
        maxWidth: maxWidth,
      );
    },
  );
  final confirmed = result == 'Ok';
  if (onClose != null) onClose(confirmed);
  if (confirmed && onConfirmed != null) onConfirmed();
  return confirmed;
}
