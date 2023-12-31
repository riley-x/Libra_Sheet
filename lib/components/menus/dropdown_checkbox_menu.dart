import 'package:flutter/material.dart';

/// Dropdown menu where each entry has a checkbox that can be selected.
class DropdownCheckboxMenu<T> extends StatelessWidget {
  const DropdownCheckboxMenu({
    super.key,
    required this.items,
    required this.builder,
    this.isChecked,
    this.isTristate,
    this.onChanged,
    this.icon,
  });

  final IconData? icon;
  final List<T> items;
  final Widget Function(BuildContext, T) builder;
  final bool? Function(T)? isChecked;
  final bool Function(T)? isTristate;
  final Function(T item, bool? isChecked)? onChanged;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      builder: (BuildContext context, MenuController controller, Widget? child) {
        return IconButton(
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: Icon(icon ?? Icons.more_vert),
        );
      },
      menuChildren: [
        for (int i = 0; i < items.length; i++)
          SizedBox(
            width: 250,
            child: CheckboxListTile(
              dense: true,
              title: builder(context, items[i]),
              value: isChecked?.call(items[i]),
              onChanged: (bool? value) {
                onChanged?.call(items[i], value);
              },
              tristate: isTristate?.call(items[i]) ?? false,
            ),
          ),
      ],
    );
  }
}
