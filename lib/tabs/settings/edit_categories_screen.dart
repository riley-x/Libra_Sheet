// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

import 'package:flutter/material.dart';
import 'package:libra_sheet/components/dialogs/confirmation_dialog.dart';
import 'package:libra_sheet/components/form_buttons.dart';
import 'package:libra_sheet/components/libra_text_field.dart';
import 'package:libra_sheet/components/menus/category_selection_menu.dart';
import 'package:libra_sheet/components/show_color_picker.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/tabs/settings/category_card.dart';
import 'package:libra_sheet/tabs/transactionDetails/table_form_utils.dart';
import 'package:provider/provider.dart';

/// State for the EditCategoriesScreen in the settings tab
class EditCategoriesState extends ChangeNotifier {
  final LibraAppState appState;
  EditCategoriesState(this.appState);

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool isFocused = false;

  /// This state is also used for determining the height of the ReorderableListViews at the top level.
  final Set<int> categoryIsExpanded = {};

  /// Currently edited category. This also serves as the initial state for the FormFields.
  Category focused = Category.empty;

  /// Save sink for the FormFields
  String saveName = '';
  Category? parent;

  /// Active UI state for the displayed box, and the saved value
  Color color = Colors.deepPurple;

  void _init() {
    color = focused.color;
  }

  void reset() {
    formKey.currentState?.reset();
    _init();
    notifyListeners();
  }

  void setFocus(Category it) {
    focused = it;
    isFocused = true;
    reset();
    // it's important to call reset() here so the forms don't keep stale data from previous focuses.
    // this is orthogonal to the Key(initial) used by the forms; if the initial state didn't change
    // (i.e. both null when adding accounts back to back), only the reset above will clear the form.
  }

  void clearFocus() {
    isFocused = false;
    notifyListeners();
  }

  void delete(bool confirmed) {
    if (confirmed) {
      clearFocus();
      appState.categories.delete(focused);
      notifyListeners();
    }
  }

  void onExpandedChanged(Category cat, bool isExpanded) {
    if (isExpanded) {
      categoryIsExpanded.add(cat.key);
    } else {
      categoryIsExpanded.remove(cat.key);
    }
    notifyListeners();
  }

  void save() async {
    if (formKey.currentState?.validate() ?? false) {
      formKey.currentState?.save();
      final cat = focused.copyWith(
        name: saveName,
        color: color,
        level: parent!.level + 1,
        parent: parent,
      );
      if (focused.key == 0) {
        appState.categories.add(cat);
      } else {
        appState.categories.update(focused, cat);
      }
      clearFocus();
    }
  }

  double calculateHeight(List<Category> categories) {
    double height = categories.length * BaseCategoryCard.height;
    for (final cat in categories) {
      if (categoryIsExpanded.contains(cat.key)) {
        height += cat.subCats.length * BaseCategoryCard.height;
      }
    }
    return height;
  }
}

/// Settings screen for editing categories
class EditCategoriesScreen extends StatelessWidget {
  const EditCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<EditCategoriesState>();
    return IndexedStack(
      index: (state.isFocused) ? 0 : 1,
      sizing: StackFit.expand,
      children: [
        _EditCategory(
          /// this prevents the IndexedStack from reusing the form editor, which causes a flicker
          key: ObjectKey(state.focused),
        ),
        const SingleChildScrollView(
          child: Column(
            children: [
              _CategorySection(false),
              SizedBox(height: 30),
              _CategorySection(true),
            ],
          ),
        ),
      ],
    );
  }
}

/// Displays one of the two "Income" or "Expense" category lists
class _CategorySection extends StatelessWidget {
  const _CategorySection(this.isExpense, {super.key});

  final bool isExpense;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<LibraAppState>();
    final state = context.watch<EditCategoriesState>();
    final superCat = (isExpense) ? appState.categories.expense : appState.categories.income;
    final categories = superCat.subCats;

    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 15),
            Text(
              (isExpense) ? 'Expense' : 'Income',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Spacer(),
            IconButton(
              onPressed: () => state.setFocus(
                Category(
                  name: '',
                  color: Colors.lightBlue,
                  parent: (isExpense) ? Category.expense : Category.income,
                ),
              ),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        if (categories.isNotEmpty)
          SizedBox(
            height: state.calculateHeight(categories),
            child: ReorderableListView(
              buildDefaultDragHandles: false,
              physics: const NeverScrollableScrollPhysics(),
              onReorder: (o, n) => appState.categories.reorder(superCat, o, n),
              children: <Widget>[
                for (int i = 0; i < categories.length; i++)
                  CategoryCard(
                    cat: categories[i],
                    index: i,
                    key: ObjectKey(categories[i]),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Form for the category fields
class _EditCategory extends StatelessWidget {
  const _EditCategory({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<LibraAppState>();
    final state = context.watch<EditCategoriesState>();
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
                  validator: (it) => null,
                  onSave: (it) => state.saveName = it ?? '',
                ),
              ),
              rowSpacing,
              labelRow(
                  context,
                  'Parent',
                  CategorySelectionFormField(
                    initial: state.focused.parent,
                    categories: appState.categories.getPotentialParents(state.focused),
                    superAsNone: true,
                    onSave: (it) => state.parent = it,
                    validator: (it) {
                      if (it == null) {
                        return ''; // empty string produces error with no size box change
                      } else if (it.level == 1 && state.focused.subCats.isNotEmpty) {
                        // TODO this error message doesn't show
                        return 'A category with sub-categories must have its parent be "None"';
                      } else {
                        return null;
                      }
                    },
                  ),
                  tooltip: "Set the parent to create a nested category. Note that\n"
                      "a category with sub-categories cannot be nested again;\n"
                      "its parent must be 'None'"),
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
                      initialColor: state.color,
                      onColorChanged: (it) => state.color = it,
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
          showDelete: state.focused.key > 0,
          onCancel: state.clearFocus,
          onReset: state.reset,
          onSave: state.save,
          onDelete: () => showConfirmationDialog(
            context: context,
            title: "Delete Category?",
            msg: 'Are you sure you want to delete category "${state.focused.name}"? '
                "This cannot be undone! Any sub-categories and linked transactions and "
                "rules will be broken.",
            onClose: state.delete,
          ),
        ),
      ],
    );
  }
}
