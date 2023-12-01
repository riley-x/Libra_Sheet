import 'package:flutter/material.dart';

/// Dropdown button for selecting an object of class [T].
/// P.S. Don't try switching to a DropdownButtonFormField -- a lot of trouble getting the underline
/// hidden. Also not worth undoing the nullable T?'s because both the DropdownMenu and FormField
/// makes callbacks/inputs nullable
class LibraDropdownMenu<T> extends StatelessWidget {
  final T? selected;
  final List<T?> items;
  final Function(T?)? onChanged;
  final BorderRadius? borderRadius;
  final double height;
  final Widget Function(T?) builder;

  final bool isDense;

  const LibraDropdownMenu({
    super.key,
    required this.items,
    required this.builder,
    this.selected,
    this.onChanged,
    this.borderRadius,
    this.height = 30,
    this.isDense = false,
  });

  @override
  Widget build(BuildContext context) {
    /// We have to add selected into the list if it's not already, otherwise the DropdownButton complains.
    /// This happens if i.e. an income category is selected but the list is changed to expenses.
    var menuItems = <DropdownMenuItem<T?>>[];
    bool seenSelected = selected == null; // i.e. false by default
    for (final item in items) {
      menuItems.add(DropdownMenuItem(
        value: item,
        child: builder(item),
      ));
      if (item == selected) {
        seenSelected = true;
      }
    }
    if (!seenSelected) {
      menuItems.add(DropdownMenuItem(
        value: selected,
        child: builder(selected),
      ));
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: height),
      child: Theme(
        data: Theme.of(context).copyWith(
          /// this is the color used for the currently selected item in the menu itself
          focusColor: Theme.of(context).colorScheme.secondaryContainer,
          // hoverColor: Theme.of(context).colorScheme.secondaryContainer.withAlpha(128),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T?>(
            padding: const EdgeInsets.symmetric(horizontal: 9),
            borderRadius: borderRadius ?? BorderRadius.circular(4),

            /// this is the color of the button when it has keyboard focus
            focusColor: Theme.of(context).colorScheme.background,
            value: selected,
            items: menuItems,
            onChanged: onChanged,
            isDense: isDense,
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
    this.validator,
  });

  final T? initial;
  final List<T?> items;
  final Function(T?)? onSave;
  final String? Function(T?)? validator;
  final BorderRadius? borderRadius;
  final double height;
  final Widget Function(T?) builder;

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      key: ObjectKey(initial), // This forces the form field to rebuild if the initial value changes
      initialValue: initial,
      builder: (state) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: borderRadius ?? BorderRadius.circular(4),
            border: Border.all(
                color: (state.hasError)
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.surface),
          ),
          child: LibraDropdownMenu<T>(
            selected: state.value,
            items: items,
            builder: builder,
            height: height,
            borderRadius: borderRadius,
            onChanged: state.didChange,
          ),
        );
      },
      validator: validator ?? ((value) => (value == null) ? '' : null),
      onSaved: onSave,
    );
  }
}
