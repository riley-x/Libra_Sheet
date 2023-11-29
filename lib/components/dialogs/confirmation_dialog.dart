import 'package:flutter/material.dart';

class ConfirmationDialog extends StatelessWidget {
  const ConfirmationDialog({super.key, this.title, this.msg});

  final String? title;
  final String? msg;

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

void showConfirmationDialog({
  required BuildContext context,
  String? title,
  String? msg,
  Function(bool confirmed)? onClose,
  Function()? onConfirmed,
}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return ConfirmationDialog(title: title, msg: msg);
    },
  ).then((msg) {
    final confirmed = msg == 'Ok';
    if (onClose != null) onClose(confirmed);
    if (confirmed && onConfirmed != null) onConfirmed();
  });
}
