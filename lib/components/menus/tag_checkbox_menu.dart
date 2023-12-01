import 'package:flutter/material.dart';
import 'package:libra_sheet/components/cards/libra_chip.dart';
import 'package:libra_sheet/components/menus/dropdown_checkbox_menu.dart';
import 'package:libra_sheet/components/title_row.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/objects/tag.dart';
import 'package:provider/provider.dart';

/// Displays a header with a dropdown checkbox menu to select tags. Selected tags will appear beneath
/// the header as chips.
class TagFilterSection extends StatelessWidget {
  const TagFilterSection({
    super.key,
    required this.selected,
    this.onChanged,
    this.whenChanged,
    this.headerStyle,
  });

  final TextStyle? headerStyle;
  final Set<Tag> selected;
  final Function(Tag, bool?)? onChanged;

  /// Can update [selected] in-place using default behavior. This callback must be set to be
  /// notified of the change, and [onChaged] must be null.
  final Function(Tag, bool?)? whenChanged;

  void defaultOnChanged(Tag tag, bool? val) {
    if (onChanged != null) {
      onChanged!(tag, val);
      return;
    }
    if (whenChanged == null) return;
    if (val == true) {
      selected.add(tag);
    } else {
      selected.remove(tag);
    }
    whenChanged!.call(tag, val);
  }

  @override
  Widget build(BuildContext context) {
    assert(onChanged == null || whenChanged == null);
    final tags = context.watch<LibraAppState>().tags.list;
    return Column(
      children: [
        TitleRow(
          title: Text("Tags", style: headerStyle ?? Theme.of(context).textTheme.titleMedium),
          right: TagCheckboxMenu(
            tags: tags,
            isChecked: selected.contains,
            onChanged: defaultOnChanged,
          ),
        ),
        if (selected.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 0),
            child: Text(
              'None',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                    fontStyle: FontStyle.italic,
                  ),
              // color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        if (selected.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final tag in selected)
                LibraChip(
                  tag.name,
                  color: tag.color,
                  onTap: () => defaultOnChanged(tag, false),
                ),
            ],
          ),
      ],
    );
  }
}

class TagCheckboxMenu extends StatelessWidget {
  const TagCheckboxMenu({
    super.key,
    required this.tags,
    required this.isChecked,
    required this.onChanged,
  });

  final List<Tag> tags;
  final bool? Function(Tag)? isChecked;
  final Function(Tag, bool?)? onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownCheckboxMenu<Tag>(
      icon: Icons.add,
      items: tags,
      builder: (context, tag) => Text(
        tag.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelLarge,
      ),
      isChecked: isChecked,
      onChanged: onChanged,
    );
  }
}
