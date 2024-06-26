import 'package:flutter/material.dart';
import 'package:libra_sheet/components/dialogs/confirmation_dialog.dart';
import 'package:libra_sheet/components/form_buttons.dart';
import 'package:libra_sheet/components/libra_text_field.dart';
import 'package:libra_sheet/components/menus/category_selection_menu.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/enums.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/objects/category_rule.dart';
import 'package:libra_sheet/tabs/settings/settings_card.dart';
import 'package:libra_sheet/tabs/settings/settings_tab.dart';
import 'package:libra_sheet/components/table_form_utils.dart';
import 'package:provider/provider.dart';

/// State for the tag submenu in the settings tab
class EditRulesState extends ChangeNotifier {
  final LibraAppState appState;

  EditRulesState(this.appState);

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool isFocused = false;

  /// Rule being edited. All fields are saved to [focused], on form.save(), which edits it in place!
  CategoryRule focused = CategoryRule.empty;

  /// The original category of the rule, used to update properly. This is lost when form.save()
  /// happens otherwise.
  Category? originalCategory;

  void _init() {}

  void reset() {
    formKey.currentState?.reset();
    _init();
    notifyListeners();
  }

  void setFocus(CategoryRule? it, ExpenseType type) {
    if (it == null) {
      focused = CategoryRule(pattern: "", category: null, type: type);
    } else {
      focused = it;
    }
    originalCategory = focused.category;
    isFocused = true;
    reset();
    // it's important to call reset() here so the forms don't keep stale data from previous focuses.
    // this is orthogonal to the Key(initial) used by the forms; if the initial state didn't change
    // (i.e. both null when adding accounts back to back), only the reset above will clear the form.
  }

  void clearFocus() {
    focused = CategoryRule.empty;
    isFocused = false;
    notifyListeners();
  }

  void delete(bool confirmed) {
    if (confirmed) {
      appState.rules.delete(focused);
      clearFocus();
    }
  }

  void save() async {
    if (formKey.currentState?.validate() ?? false) {
      formKey.currentState?.save(); // this saves all fields to [focused]
      if (focused.key == 0) {
        appState.rules.add(focused);
      } else {
        appState.rules.update(focused, originalCategory);
      }
      clearFocus();
    }
  }
}

/// This parent screen shows the cards to show either the income or expense rules.
class RulesSettingsScreen extends StatelessWidget {
  const RulesSettingsScreen(this.screenCallback, {super.key});

  final Function(SettingsScreen screen) screenCallback;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text("Each rule matches a pattern to a cateogry."
                ' For example, you can set all transactions with "TST*" in their name to category "Food."'
                ' Rules are case sensitive!'
                // '\n\nIf multiple rules match a transaction, the rule with the longest pattern wins.'
                // ' For example, if you have two rules:\n'
                // '         - Uber => Taxis\n'
                // '         - Uber eats => Takeout\n'
                // ' the latter is longer and will take priority.',
                ),
          ),
          const SizedBox(height: 8),
          SettingsCard(
            text: 'Income Rules',
            onTap: () {
              context.read<EditRulesState>().clearFocus();
              screenCallback.call(SettingsScreen.incomeRules);
            },
          ),
          const SizedBox(height: 8),
          SettingsCard(
            text: 'Expense Rules',
            onTap: () {
              context.read<EditRulesState>().clearFocus();
              screenCallback.call(SettingsScreen.expenseRules);
            },
          ),
        ],
      ),
    );
  }
}

/// Settings screen for editing rules. This lists the rules for one of the expense types, allowing
/// to reorder them, and clicking on a rule opens the editor screen.
class EditRulesScreen extends StatelessWidget {
  const EditRulesScreen(this.type, {super.key});

  final ExpenseType type;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<LibraAppState>();
    final state = context.watch<EditRulesState>();
    final rules = (type == ExpenseType.income) ? appState.rules.income : appState.rules.expense;

    List<Widget> getRuleList() {
      final out = <Widget>[];
      int i = 0;
      for (final entry in rules.entries) {
        for (final rule in entry.value) {
          out.add(_RuleRow(
            rule: rule,
            key: ObjectKey(rule),
            isLast: i == rules.length - 1,
          ));
          i++;
        }
      }
      return out;
    }

    /// The IndexedStack preserves the scroll state of the scroll I think...
    return IndexedStack(
      index: (state.isFocused) ? 0 : 1,
      children: [
        _EditRule(
          /// this prevents the IndexedStack from reusing the form editor, which causes a flicker
          key: ObjectKey(state.focused),
          type: type,
        ),
        Scaffold(
          body: ListView(
            padding: const EdgeInsets.only(top: 15, bottom: 80), // to account for FAB
            children: getRuleList(),
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            onPressed: () => state.setFocus(null, type),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({
    super.key,
    required this.rule,
    required this.isLast,
  });

  final CategoryRule rule;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.read<EditRulesState>().setFocus(rule, rule.type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 10,
              child: Text(
                rule.pattern,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 4,
              height: 20,
              color: rule.category?.color ?? Colors.transparent,
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 5,
              child: Text(
                rule.category?.name ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Single rule details editing form
class _EditRule extends StatelessWidget {
  const _EditRule({super.key, required this.type});

  final ExpenseType type;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<EditRulesState>();
    var categories =
        context.watch<LibraAppState>().categories.flattenedCategories(type.toFilterType());
    categories = [Category.ignore, Category.other] + categories;
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
                'Pattern',
                LibraTextFormField(
                  initial: state.focused.pattern,
                  validator: (it) => (it?.isEmpty == true) ? '' : null,
                  onSave: (it) => state.focused.pattern = it ?? '',
                ),
                tooltip: "Patterns are case sensitive!",
              ),
              rowSpacing,
              labelRow(
                context,
                'Category',
                CategorySelectionFormField(
                  initial: state.focused.category,
                  categories: categories,
                  onSave: (it) => state.focused.category = it,
                  validator: (it) {
                    if (it == null) {
                      return ''; // empty string produces error with no size box change
                    } else {
                      return null;
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        FormButtons(
          showDelete: state.focused.key != 0,
          onCancel: state.clearFocus,
          // onReset: state.reset,
          onSave: state.save,
          onDelete: () => showConfirmationDialog(
            context: context,
            title: "Delete Rule?",
            msg: 'Are you sure you want to delete rule "${state.focused.pattern}"?'
                ' This cannot be undone!',
            onClose: state.delete,
          ),
        ),
      ],
    );
  }
}
