import 'package:flutter/material.dart';
import 'package:libra_sheet/components/form_buttons.dart';
import 'package:libra_sheet/components/libra_text_field.dart';
import 'package:libra_sheet/components/show_color_picker.dart';
import 'package:libra_sheet/data/category.dart';
import 'package:libra_sheet/data/libra_app_state.dart';
import 'package:libra_sheet/tabs/settings/category_card.dart';
import 'package:libra_sheet/tabs/settings/settings_tab_state.dart';
import 'package:libra_sheet/tabs/transactionDetails/table_form_utils.dart';
import 'package:provider/provider.dart';

/// Settings screen for editing categories
class EditCategoriesScreen extends StatelessWidget {
  const EditCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<EditCategoriesState>();
    return IndexedStack(
      index: (state.isFocused) ? 0 : 1,
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

class _CategorySection extends StatelessWidget {
  const _CategorySection(this.isExpense, {super.key});

  final bool isExpense;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<LibraAppState>();
    final categories = (isExpense) ? appState.expenseCategories : appState.incomeCategories;

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
            IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
          ],
        ),
        if (categories.isNotEmpty)
          SizedBox(
            height: BaseCategoryCard.height * categories.countFlattened(),
            child: ReorderableListView(
              buildDefaultDragHandles: false,
              physics: const NeverScrollableScrollPhysics(),
              onReorder: (o, n) => appState.reorderCategories(isExpense, o, n),
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

class _EditCategory extends StatelessWidget {
  const _EditCategory({super.key});

  @override
  Widget build(BuildContext context) {
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
                  initial: state.focused?.name,
                  validator: (it) => null,
                  onSave: (it) => state.saveName = it ?? '',
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
          allowDelete: state.focused != null,
          onCancel: state.clearFocus,
          onReset: state.reset,
          onSave: state.save,
        ),
      ],
    );
  }
}
