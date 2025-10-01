import 'package:flutter/material.dart';
import 'package:libra_sheet/components/libra_text_field.dart';
import 'package:libra_sheet/data/int_dollar.dart';

/// Text field for
class ValueField extends StatelessWidget {
  const ValueField({
    super.key,
    this.formFieldKey,
    this.initial,
    this.onSave,
    this.onChanged,
    this.positiveOnly = false,
    this.allowNull = false,
    this.controller,
    this.hint,
    this.validator,
  });

  final int? initial;
  final Function(int)? onSave;
  final Function(int?)? onChanged;
  final Key? formFieldKey;
  final bool positiveOnly;
  final bool allowNull;
  final TextEditingController? controller;
  final String? hint;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return LibraTextFormField(
      formFieldKey: formFieldKey,
      controller: controller,
      hint: hint,
      initial: initial?.dollarString(dollarSign: false),
      validator:
          validator ??
          (String? text) {
            if (text == null || text.isEmpty) return allowNull ? null : 'Please enter a value';
            final val = text.toIntDollar();
            if (val == null) return 'Not a valid value';
            if (positiveOnly && val < 0) return 'Must be positive';
            return null;
          },
      onChanged: (onChanged == null) ? null : (it) => onChanged!.call(it?.toIntDollar()),
      onSave: (it) => onSave?.call(it?.toIntDollar() ?? 0),
    );
  }
}
