import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:libra_sheet/components/form_buttons.dart';
import 'package:libra_sheet/components/libra_text_field.dart';
import 'package:libra_sheet/components/menus/account_selection_menu.dart';
import 'package:libra_sheet/components/menus/category_selection_menu.dart';
import 'package:libra_sheet/components/transaction_filters/transaction_filter_state.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/date_time_utils.dart';
import 'package:libra_sheet/data/enums.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/objects/tag.dart';
import 'package:libra_sheet/data/objects/transaction.dart';
import 'package:libra_sheet/tabs/transactionDetails/value_field.dart';
import 'package:provider/provider.dart';

/// This state handles the form fields of the bulk editor. It assumes that a parent
/// [TransactionFilterState] exists which handles the list of selected transactions.
class BulkEditorState extends ChangeNotifier {
  BulkEditorState(this.parentState) {
    parentState.addListener(update);
    update();
  }

  @override
  void dispose() {
    parentState.removeListener(update);
    nameController.dispose();
    dateController.dispose();
    valueController.dispose();
    noteController.dispose();
    super.dispose();
  }

  void update() {
    if (parentState.selected.isEmpty) return;

    /// Find common fields
    final first = parentState.selected.values.first;
    Account? account = first.account;
    String? name = first.name;
    DateTime? date = first.date;
    int? value = first.value;
    Category? category = first.category;
    String? note = first.note;
    List<Tag> tags = first.tags.toList();
    expenseType = ExpenseFilterType.from(value);

    for (final t in parentState.selected.values.toList().sublist(1)) {
      if (t.account != account) account = null;
      if (t.name != name) name = null;
      if (t.date != date) date = null;
      if (t.value != value) value = null;
      if (t.category != category) category = null;
      if (t.note != note) note = null;
      tags.removeWhere((tag) => !t.tags.contains(tag));
      if (ExpenseFilterType.from(t.value) != expenseType) expenseType = ExpenseFilterType.all;
    }

    /// Update if changed and no user inputs yet
    if (initialAccount != account && initialAccount == this.account) {
      initialAccount = account;
      this.account = account;
    }
    if (initialName != name && (initialName ?? "") == nameController.text) {
      initialName = name;
      if (name == null) {
        nameController.clear();
      } else {
        nameController.text = name;
      }
    }
    if (initialDate != date && (initialDate?.MMddyy() ?? "") == dateController.text) {
      initialDate = date;
      dateController.text = date?.MMddyy() ?? "";
    }
    if (initialValue != value &&
        (initialValue?.dollarString(dollarSign: false) ?? "") == valueController.text) {
      initialValue = value;
      valueController.text = initialValue?.dollarString(dollarSign: false) ?? "";
    }
    if (initialCategory != category && initialCategory == this.category) {
      initialCategory = category;
      this.category = category;
    }
    if (initialNote != note && (initialNote ?? "") == noteController.text) {
      initialNote = note;
      noteController.text = note ?? "";
    }
    notifyListeners();
  }

  /// Reference to a list of selected transactions. Owner should call [update] whenever this map
  /// is updated.
  final TransactionFilterState parentState;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  String? errorMessage;

  Account? initialAccount;
  String? initialName;
  DateTime? initialDate;
  int? initialValue;
  Category? initialCategory;
  String? initialNote;
  List<Tag> initialTags = [];
  ExpenseFilterType expenseType = ExpenseFilterType.all;

  //----------------------------------------------------------------------
  // Form values
  //----------------------------------------------------------------------
  Account? account;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController valueController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  Category? category;
  // List<Tag> tags = [];

  (String?, List<(Transaction, Transaction)>) _validate() {
    if (formKey.currentState?.validate() != true) return ("", []);
    // Need to save the form first to get the values. This doesn't do anything other than set the
    // save sink members above.
    formKey.currentState?.save();
    final date = DateFormat('MM/dd/yy').tryParse(dateController.text, true);
    final value = valueController.text.toIntDollar();

    /// Error check each individual transaction while being created, easier.
    // if (value != null) {
    //   if (category == null && ExpenseFilterType.from(value) != expenseType) {
    //     return "Can't set common value to transactions with different category types";
    //   }
    //   if (category != null &&
    //       category!.type != ExpenseFilterType.all &&
    //       ExpenseFilterType.from(value) != category!.type) {
    //     return "Sign of value does not agree with category";
    //   }
    // }
    // if (category != null &&
    //     category!.type != ExpenseFilterType.all &&
    //     expenseType != category!.type) {
    //   return "Category type does not agree with original categories";
    // }

    final out = <(Transaction, Transaction)>[];
    for (final old in parentState.selected.values) {
      final nu = Transaction(
        key: old.key,
        name: (nameController.text.isNotEmpty) ? nameController.text : old.name,
        date: date ?? old.date,
        value: value ?? old.value,
        category: category ?? old.category,
        account: account ?? old.account,
        note: (noteController.text.isNotEmpty) ? noteController.text : old.note,
        // Don't copy reimbursements/allocations
      );
      if (nu.category.type != ExpenseFilterType.all &&
          nu.category.type != ExpenseFilterType.from(nu.value) &&
          nu.value != 0) {
        return ("Edits would create a transaction with the wrong category type", []);
      }
      out.add((old, nu));
    }
    return (null, out);
  }

  void save() {
    final (msg, out) = _validate();
    errorMessage = msg;
    if (errorMessage == null) {
      parentState.service.updateAll(out);
    }
    notifyListeners();

    /// Note this clears the selections anyways since the TransactionService updates.
    // parentState.clearSelections();
  }
}

/// This is the form that appears when multi-selecting transactions.
class TransactionBulkEditor extends StatelessWidget {
  const TransactionBulkEditor({super.key, this.interiorPadding});

  /// Padding to be applied to the central column. Don't use padding outside the Scroll class, or
  /// else the scroll bar is oddly offset.
  final EdgeInsetsGeometry? interiorPadding;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => BulkEditorState(context.read()),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Padding(
          padding: interiorPadding ?? EdgeInsets.zero,
          child: FocusScope(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: const _Form(),
            ),
          ),
        ),
      ),
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({super.key});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleMedium;
    final state = context.watch<BulkEditorState>();
    return Form(
      key: state.formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// Title
          const SizedBox(height: 10),
          Text(
            "Bulk Edit",
            style: Theme.of(context).textTheme.headlineMedium,
          ),

          /// Account
          const SizedBox(height: 15),
          Text("Account", style: textStyle),
          const SizedBox(height: 5),
          const _AccountField(),

          /// Name
          const SizedBox(height: 15),
          Text("Name", style: textStyle),
          const SizedBox(height: 5),
          const _NameField(),

          /// Date
          const SizedBox(height: 15),
          Text("Date", style: textStyle),
          const SizedBox(height: 5),
          const _DateField(),

          /// Value
          const SizedBox(height: 15),
          Text("Value", style: textStyle),
          const SizedBox(height: 5),
          const _ValueField(),

          /// Category
          const SizedBox(height: 15),
          Text("Category", style: textStyle),
          const SizedBox(height: 5),
          const _CategoryField(),

          /// Note
          const SizedBox(height: 15),
          Text("Note", style: textStyle),
          const SizedBox(height: 5),
          const _NoteField(),

          /// Buttons
          const SizedBox(height: 30),
          FormButtons(
            onReset: () => context.read<TransactionFilterState>().clearSelections(),
            onSave: () => context.read<BulkEditorState>().save(),
            resetName: 'Clear',
          ),

          /// Error message
          const SizedBox(height: 10),
          if (state.errorMessage != null)
            SizedBox(
              width: 250,
              child: Text(
                state.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
            )
        ],
      ),
    );
  }
}

class _AccountField extends StatelessWidget {
  const _AccountField({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BulkEditorState>();
    return SizedBox(
      width: 250, // This is necessary for the popup menu size to be correct
      child: AccountSelectionFormField(
        height: 35,
        initial: state.initialAccount,
        nullText: "Various (keep original)",
        onSave: (it) => state.account = it,
        validator: (it) => null,
      ),
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BulkEditorState>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: LibraTextFormField(
        controller: state.nameController,
        hint: (state.initialName == null) ? "Various (keep original)" : null,
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({super.key});
  static final _dateFormat = DateFormat('MM/dd/yy');

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BulkEditorState>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: LibraTextFormField(
        controller: state.dateController,
        hint: (state.initialDate == null) ? "Various (keep original)" : null,
        validator: (String? value) {
          if (value == null || value.isEmpty) return null;
          if (_dateFormat.tryParse(value, true) == null) return '';
          return null;
        },
      ),
    );
  }
}

class _ValueField extends StatelessWidget {
  const _ValueField({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BulkEditorState>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: ValueField(
        controller: state.valueController,
        hint: (state.initialValue == null) ? "Various (keep original)" : null,
        validator: (String? text) {
          if (text == null || text.isEmpty) return null;
          final val = text.toIntDollar();
          if (val == null) return ''; // No message to not take up space
          return null;
        },
      ),
    );
  }
}

class _CategoryField extends StatelessWidget {
  const _CategoryField({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BulkEditorState>();
    var categories = [
      null,
      Category.ignore,
      Category.other,
      if (state.expenseType != ExpenseFilterType.all)
        ...context.watch<LibraAppState>().categories.flattenedCategories(state.expenseType)
    ];
    return SizedBox(
      width: 250,
      child: CategorySelectionFormField(
        height: 35,
        initial: state.initialCategory,
        categories: categories,
        nullText: "Various (keep original)",
        onSave: (it) => state.category = it,
        validator: (it) => null,
      ),
    );
  }
}

class _NoteField extends StatelessWidget {
  const _NoteField({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BulkEditorState>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: LibraTextFormField(
        controller: state.noteController,
        hint: (state.initialNote == null) ? "Various (keep original)" : null,
        validator: (it) => null,
      ),
    );
  }
}
