import 'package:flutter/material.dart';

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
        return MenuAnchor(
          controller: _menuController,
          crossAxisUnconstrained: false,
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
    this.onSave,
    this.validator,
  });

  final T? initial;
  final List<T?> items; // this should be nullable because FormField uses T? too
  final Function(T?)? onSave;
  final String? Function(T?)? validator;
  final BorderRadius? borderRadius;
  final Widget Function(BuildContext, T?) builder;
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
                    : Theme.of(context).colorScheme.outline),
          ),
          child: DropdownSelector<T?>(
            selected: state.value,
            items: items,
            builder: builder,
            selectedBuilder: selectedBuilder,
            borderRadius: borderRadius ?? BorderRadius.circular(4),
            onSelected: state.didChange,
          ),
        );
      },
      validator: validator ?? ((value) => (value == null) ? '' : null),
      onSaved: onSave,
    );
  }
}
