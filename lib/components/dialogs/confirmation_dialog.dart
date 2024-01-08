import 'package:flutter/material.dart';

class ConfirmationDialog extends StatelessWidget {
  const ConfirmationDialog({
    super.key,
    this.title,
    this.msg,
    this.showCancel = true,
  });

  final String? title;
  final String? msg;
  final bool showCancel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: (title == null) ? null : Text(title!),
      content: (msg == null)
          ? null
          : ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
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
}) async {
  final result = await showDialog(
    context: context,
    builder: (BuildContext context) {
      return ConfirmationDialog(title: title, msg: msg, showCancel: showCancel);
    },
  );
  final confirmed = result == 'Ok';
  if (onClose != null) onClose(confirmed);
  if (confirmed && onConfirmed != null) onConfirmed();
  return confirmed;
}
