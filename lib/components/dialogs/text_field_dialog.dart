import 'package:flutter/material.dart';

class TextFieldDialog extends StatefulWidget {
  const TextFieldDialog({
    super.key,
    this.title,
    this.initial,
    this.width,
    this.validator,
  });

  final String? title;
  final String? initial;
  final double? width;
  final bool Function(String?)? validator;

  @override
  State<TextFieldDialog> createState() => _TextFieldDialogState();
}

class _TextFieldDialogState extends State<TextFieldDialog> {
  String result = "";
  bool error = false;

  @override
  void initState() {
    super.initState();
    result = widget.initial ?? "";
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: (widget.title == null) ? null : Text(widget.title!),
      content: SizedBox(
        width: widget.width,
        child: TextFormField(
          onChanged: (it) => result = it,
          initialValue: widget.initial,
          decoration: InputDecoration(
            error: error ? const SizedBox() : null,
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (widget.validator?.call(result) == false) {
              setState(() {
                error = true;
              });
            } else {
              Navigator.pop(context, result);
            }
          },
          child: const Text('Ok'),
        ),
      ],
    );
  }
}

Future<String?> showTextFieldDialog({
  required BuildContext context,
  String? title,
  String? initial,
  double? width,
  bool Function(String?)? validator,
}) async {
  return await showDialog(
    context: context,
    builder: (BuildContext context) {
      return TextFieldDialog(
        title: title,
        initial: initial,
        width: width,
        validator: validator,
      );
    },
  );
}
