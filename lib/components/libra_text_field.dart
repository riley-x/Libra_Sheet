import 'package:flutter/material.dart';

/// Common simplified text field that calls [onChanged] whenever it looses focus.
class FocusTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? intial;
  final bool error;
  final bool active;
  final int? minLines;
  final int? maxLines;
  final TextStyle? style;
  final Function(String?)? onChanged;

  const FocusTextField({
    super.key,
    this.label,
    this.hint,
    this.intial,
    this.error = false,
    this.active = false,
    this.minLines,
    this.maxLines = 1,
    this.style,
    this.onChanged,
  });

  @override
  State<FocusTextField> createState() => _FocusTextFieldState();
}

class _FocusTextFieldState extends State<FocusTextField> {
  final FocusNode _focus = FocusNode();
  String? text;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    super.dispose();
    _focus.removeListener(_onFocusChange);
    _focus.dispose();
  }

  void _onFocusChange() {
    if (!_focus.hasFocus) {
      widget.onChanged?.call(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LimitedBox(
      maxWidth: 100,
      child: TextFormField(
        initialValue: widget.intial,
        decoration: InputDecoration(
          filled: widget.active && !widget.error,
          fillColor: Theme.of(context).colorScheme.secondaryContainer,
          errorText: (widget.error) ? '' : null, // setting this to not null shows the error border
          errorStyle: const TextStyle(height: 0),
          border: const OutlineInputBorder(), // this sets the shape, but the color is not used
          hintText: widget.hint,
          hintStyle: Theme.of(context).textTheme.bodySmall,
          labelText: widget.label,
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          isDense: true,
        ),
        onChanged: (it) => text = it,
        focusNode: _focus,
        maxLines: widget.maxLines,
        minLines: widget.minLines,
        style: widget.style,
      ),
    );
  }
}

class LibraTextFormField extends StatelessWidget {
  const LibraTextFormField({
    super.key,
    this.initial,
    this.hint,
    this.validator,
    this.onSave,
    this.onChanged,
    this.minLines,
    this.maxLines = 1,
    this.formFieldKey,
    this.controller,
  });

  final int? minLines;
  final int? maxLines;
  final String? initial;
  final String? hint;
  final String? Function(String? text)? validator;
  final Function(String? text)? onSave;
  final Function(String? text)? onChanged;
  final Key? formFieldKey;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      /// This forces the form field to rebuild if the initial value changes
      key: formFieldKey ?? Key(initial ?? '__^^^__null'),
      controller: controller,
      autovalidateMode: AutovalidateMode.disabled,
      initialValue: initial,
      style: Theme.of(context).textTheme.bodyMedium,
      minLines: minLines,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        // hintStyle: Theme.of(context).textTheme.bodySmall,
        errorStyle: const TextStyle(height: 0), // remove space used by error message
        border: const OutlineInputBorder(), // this sets the shape, but the color is not used
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        isDense: true,
      ),
      validator: validator,
      onSaved: onSave,
      onChanged: onChanged,
    );
  }
}
