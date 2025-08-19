import 'package:flutter/material.dart';
import 'package:libra_sheet/components/menus/custom_submenu_button.dart';

/// Dropdown button for selecting an object of class [T].
class DropdownSelector<T> extends StatefulWidget {
  final T selected;
  final Iterable<T> items;
  final Function(T)? onSelected;
  final Widget Function(BuildContext context, T item) builder;
  final Widget Function(BuildContext context, T item)? selectedBuilder;
  final Iterable<T>? Function(T item)? subItems;

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
    this.subItems,
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
    final selectedWidget = (widget.selectedBuilder ?? widget.builder).call(
      context,
      widget.selected,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        Widget build(T item, {double rightMargin = 0}) {
          /// For some reason, the child of the [MenuItemButton] receives an unconstrained width. So
          /// we pass another constrained box. But this needs to be deflated by the width used for
          /// the scroll bar, 16 pixels.
          return ConstrainedBox(
            constraints: constraints
                .deflate(EdgeInsets.only(right: 16 + rightMargin))
                .tighten(width: double.infinity)
                .widthConstraints(),
            child: widget.builder(context, item),
          );
        }

        final menuChildren = <Widget>[];
        for (final (i, x) in widget.items.indexed) {
          final subItems = widget.subItems?.call(x);
          Widget button;
          if (subItems != null && subItems.isNotEmpty) {
            button = CustomSubmenuButton(
              onSelect: () => widget.onSelected?.call(x),
              menuChildren: [
                for (final child in subItems)
                  CustomMenuItemButton(
                    onPressed: () => widget.onSelected?.call(child),
                    child: build(child),
                  ),
              ],
              child: build(x, rightMargin: 32), // for right arrow icon
            );
          } else {
            button = CustomMenuItemButton(
              focusNode: (i == 0) ? _firstFocus : null,
              onPressed: () => widget.onSelected?.call(x),
              child: build(x),
            );
          }

          menuChildren.add(
            ConstrainedBox(
              /// This expands the constraints to the maximum width, aka the assumed width of the
              /// Anchor child, since otherwise the menu will size to intrinsic width of the
              /// MenuItemButtons.
              constraints: constraints.tighten(width: double.infinity).widthConstraints(),
              child: button,
            ),
          );
        }

        return CustomMenuAnchor(
          controller: _menuController,
          crossAxisUnconstrained: false,
          menuChildren: menuChildren,
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
    this.subItems,
    this.selectedBuilder,
    this.borderRadius,
    this.onSave,
    this.validator,
  });

  final T? initial;
  final List<T?> items; // this should be nullable because FormField uses T? too
  final Iterable<T?>? Function(T? item)? subItems;
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
                  : Theme.of(context).colorScheme.outline,
            ),
          ),
          child: DropdownSelector<T?>(
            selected: state.value,
            items: items,
            subItems: subItems,
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
