import 'package:flutter/material.dart';

/// Common simplified text field for forms
class LibraTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final bool error;
  final bool active;
  final Function(String?)? onChanged;

  const LibraTextField({
    super.key,
    this.label,
    this.hint,
    this.error = false,
    this.active = false,
    this.onChanged,
  });

  @override
  State<LibraTextField> createState() => _LibraTextFieldState();
}

class _LibraTextFieldState extends State<LibraTextField> {
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
    return SizedBox(
      width: 100,
      child: TextField(
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
      ),
    );
  }
}
