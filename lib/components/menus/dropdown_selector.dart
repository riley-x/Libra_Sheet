import 'package:flutter/material.dart';

class DropdownMenu<T> extends StatelessWidget {
  final T? selected;
  final List<T?> items;
  final Function(T?)? onChanged;
  final BorderRadius? borderRadius;
  final double height;
  final Widget Function(T?) builder;
  final Widget Function(BuildContext, T? item)? selectedBuilder;

  final bool isDense;

  const DropdownMenu({
    super.key,
    required this.items,
    required this.builder,
    required this.selected,
    this.selectedBuilder,
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

    List<Widget> selectedItemBuilder(BuildContext context) {
      if (selectedBuilder == null) return [];
      return [for (final item in menuItems) selectedBuilder!(context, item.value)];
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
            selectedItemBuilder: (selectedBuilder == null) ? null : selectedItemBuilder,

            /// this is the color of the button when it has keyboard focus
            // focusColor: Theme.of(context).colorScheme.primaryContainer,
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

/// Dropdown button for selecting an object of class [T].
class DropdownSelector<T> extends StatefulWidget {
  final T selected;
  final Iterable<T> items;
  final Function(T)? onSelected;
  final Widget Function(BuildContext context, T item) builder;
  final Widget Function(BuildContext context, T item)? selectedBuilder;

  final BorderRadius? borderRadius;
  final EdgeInsets padding;

  const DropdownSelector({
    super.key,
    required this.items,
    required this.builder,
    required this.selected,
    required this.onSelected,
    this.selectedBuilder,
    this.borderRadius,
    this.padding = const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
  });

  @override
  State<DropdownSelector<T>> createState() => _DropdownSelectorState<T>();
}

class _DropdownSelectorState<T> extends State<DropdownSelector<T>> {
  final MenuController _menuController = MenuController();
  final FocusNode _firstFocus = FocusNode();

  @override
  void dispose() {
    _firstFocus.dispose();
    super.dispose();
  }

  void _open() {
    _menuController.open();
    _firstFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final selectedWidget =
        (widget.selectedBuilder ?? widget.builder).call(context, widget.selected);
    return LayoutBuilder(
      builder: (context, constraints) {
        return LimitedBox(
          maxWidth: 400,
          child: MenuAnchor(
            controller: _menuController,
            menuChildren: [
              for (final (i, x) in widget.items.indexed)
                ConstrainedBox(
                  constraints: constraints.widthConstraints(),
                  child: MenuItemButton(
                    focusNode: (i == 0) ? _firstFocus : null,
                    onPressed: () => widget.onSelected?.call(x),
                    child: widget.builder(context, x),
                  ),
                ),
            ],
            // crossAxisUnconstrained: false, // this doesn't seem to do anything?
            child: ClipRRect(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
              child: InkWell(
                borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
                onTap: () => _menuController.isOpen ? _menuController.close() : _open(),
                child: Padding(
                  padding: widget.padding,
                  child: Row(
                    children: [
                      Expanded(child: selectedWidget),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class LibraDropdownFormField<T> extends StatelessWidget {
  const LibraDropdownFormField({
    super.key,
    this.initial,
    required this.items,
    required this.builder,
    this.selectedBuilder,
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
  final Widget Function(BuildContext, T?)? selectedBuilder;

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
          child: DropdownMenu<T>(
            selected: state.value,
            items: items,
            builder: builder,
            selectedBuilder: selectedBuilder,
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
