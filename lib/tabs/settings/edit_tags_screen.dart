import 'package:flutter/material.dart';
import 'package:libra_sheet/components/dialogs/confirmation_dialog.dart';
import 'package:libra_sheet/components/form_buttons.dart';
import 'package:libra_sheet/components/libra_chip.dart';
import 'package:libra_sheet/components/libra_text_field.dart';
import 'package:libra_sheet/components/show_color_picker.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/tag.dart';
import 'package:libra_sheet/tabs/transactionDetails/table_form_utils.dart';
import 'package:provider/provider.dart';

/// State for the tag submenu in the settings tab
class EditTagsState extends ChangeNotifier {
  final LibraAppState appState;

  EditTagsState(this.appState);

  /// Accounts Screen
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool isFocused = false;
  Tag focused = Tag.empty;

  /// UI State of non FormField elements
  Color color = Colors.transparent;

  void _init() {
    color = focused.color;
  }

  void reset() {
    formKey.currentState?.reset();
    _init();
    notifyListeners();
  }

  void setFocus(Tag? it) {
    if (it == null) {
      focused = Tag(name: '', color: Colors.blue);
    } else {
      focused = it;
    }
    isFocused = true;
    reset();
    // it's important to call reset() here so the forms don't keep stale data from previous focuses.
    // this is orthogonal to the Key(initial) used by the forms; if the initial state didn't change
    // (i.e. both null when adding accounts back to back), only the reset above will clear the form.
  }

  void clearFocus() {
    focused = Tag.empty;
    isFocused = false;
    notifyListeners();
  }

  void delete(bool confirmed) {
    if (confirmed) {
      appState.tags.delete(focused);
      clearFocus();
    }
  }

  void save() async {
    if (formKey.currentState?.validate() ?? false) {
      formKey.currentState?.save();
      focused.color = color;
      if (focused.key == 0) {
        appState.tags.add(focused);
      } else {
        appState.tags.notifyUpdate(focused);
      }
      clearFocus();
    }
  }
}

/// Settings screen for editing tags. This lists the tags, and clicking them switches to an
/// editor form.
class EditTagsScreen extends StatelessWidget {
  const EditTagsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<LibraAppState>();
    final state = context.watch<EditTagsState>();

    /// The IndexedStack preserves the scroll state of the scroll I think...
    return IndexedStack(
      index: (state.isFocused) ? 0 : 1,
      children: [
        _EditTag(
          /// this prevents the IndexedStack from reusing the form editor, which causes a flicker
          key: ObjectKey(state.focused),
        ),
        Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final tag in appState.tags.list)
                    LibraChip(
                      tag.name,
                      color: tag.color,
                      onTap: () => state.setFocus(tag),
                    ),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            onPressed: () => state.setFocus(null),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

/// Account details form
class _EditTag extends StatelessWidget {
  const _EditTag({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<EditTagsState>();
    return Column(
      children: [
        const SizedBox(height: 10),
        Form(
          key: state.formKey,
          child: Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: const {
              0: IntrinsicColumnWidth(),
              1: FixedColumnWidth(250),
            },
            children: [
              labelRow(
                context,
                'Name',
                LibraTextFormField(
                  initial: state.focused.name,
                  validator: (it) => (it?.isEmpty == false) ? null : '',
                  onSave: (it) => state.focused.name = it ?? '',
                ),
              ),
              rowSpacing,
              labelRow(
                context,
                'Color',
                Container(
                  height: 30,
                  color: state.color,
                  child: InkWell(
                    onTap: () => showColorPicker(
                      context: context,
                      initialColor: state.focused.color,
                      onColorChanged: (it) => state.color = it,
                      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                      onClose: state.notifyListeners,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        FormButtons(
          allowDelete: state.focused.key != 0,
          onCancel: state.clearFocus,
          onReset: state.reset,
          onSave: state.save,
          onDelete: () => showConfirmationDialog(
            context: context,
            title: "Delete Tag?",
            msg: 'Are you sure you want to delete tag "${state.focused.name}"?'
                ' This cannot be undone!',
            onClose: state.delete,
          ),
        ),
      ],
    );
  }
}
