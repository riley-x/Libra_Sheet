import 'package:flutter/material.dart';

/// Dropdown button for selecting an object of class [T].
/// P.S. Don't try switching to a DropdownButtonFormField -- a lot of trouble getting the underline
/// hidden.
class LibraDropdownMenu<T> extends StatelessWidget {
  final T? selected;
  final List<T> items;
  final Function(T?)? onChanged;
  final BorderRadius? borderRadius;
  final double height;
  final Widget Function(T?) builder;

  const LibraDropdownMenu({
    super.key,
    required this.items,
    required this.builder,
    this.selected,
    this.onChanged,
    this.borderRadius,
    this.height = 30,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: height),
      child: Theme(
        data: Theme.of(context).copyWith(
          /// this is the color used for the currently selected item in the menu itself
          focusColor: Theme.of(context).colorScheme.secondaryContainer,
          // hoverColor: Theme.of(context).colorScheme.secondaryContainer.withAlpha(128),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            borderRadius: borderRadius ?? BorderRadius.circular(10),

            /// this is the color of the button when it has keyboard focus
            focusColor: Theme.of(context).colorScheme.background,
            value: selected,
            items: [
              for (final item in items)
                DropdownMenuItem(
                  value: item,
                  child: builder(item),
                ),
            ],
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

class LibraDropdownFormField<T> extends StatelessWidget {
  const LibraDropdownFormField({
    super.key,
    this.initial,
    required this.items,
    required this.builder,
    this.borderRadius,
    this.height = 30,
    this.onSave,
  });

  final T? initial;
  final List<T> items;
  final Function(T?)? onSave;
  final BorderRadius? borderRadius;
  final double height;
  final Widget Function(T?) builder;

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      initialValue: initial,
      builder: (state) {
        final widget = LibraDropdownMenu<T>(
          selected: state.value,
          items: items,
          builder: builder,
          height: height,
          borderRadius: borderRadius,
          onChanged: state.didChange,
        );
        if (state.hasError) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: borderRadius ?? BorderRadius.circular(10),
              border: Border.all(color: Theme.of(context).colorScheme.error),
            ),
            child: widget,
          );
        } else {
          return widget;
        }
      },
      validator: (value) => (value == null) ? '' : null,
      onSaved: onSave,
    );
  }
}
