import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

void showColorPicker({
  required BuildContext context,
  Color? initialColor,
  required Function(Color) onColorChanged,
  Function()? onClose,
}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Pick a color"),
        content: SingleChildScrollView(
          child: HueRingPicker(
            pickerColor: initialColor ?? Theme.of(context).colorScheme.primary,
            onColorChanged: onColorChanged,
          ),
        ),
      );
    },
  ).then((value) => onClose?.call());
}
