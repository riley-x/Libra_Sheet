import 'dart:math';

import 'package:flutter/material.dart';
import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/int_dollar.dart';
import 'package:libra_sheet/data/objects/account.dart';
import 'package:libra_sheet/data/objects/allocation.dart';
import 'package:libra_sheet/data/objects/category.dart';
import 'package:libra_sheet/data/enums.dart';
import 'package:libra_sheet/data/objects/category_rule.dart';
import 'package:libra_sheet/data/objects/reimbursement.dart';
import 'package:libra_sheet/data/objects/tag.dart';
import 'package:libra_sheet/data/objects/transaction.dart';

enum TransactionDetailActiveFocus { none, allocation, reimbursement }

/// This state handles the TransactionDetailsEditor, allowing editing the state of a single
/// transaction. Fields are initialized to [seed]. If null, assumes we're creating a new transaction
/// and fields are empty. If not null, assumes we're editing a transaction and fields are initialized
/// to the values in [seed].
class TransactionDetailsState extends ChangeNotifier {
  TransactionDetailsState(
    this.seed, {
    required this.appState,
    this.onSave,
    this.onSaveRule,
    this.onDelete,
    this.initialAccount,
  }) {
    _init();
    appState.transactions.addListener(reloadAfterTransactionUpdate);
  }

  @override
  void dispose() {
    _disposed = true;
    appState.transactions.removeListener(reloadAfterTransactionUpdate);
    super.dispose();
  }

  //---------------------------------------------------------------------------------------------
  // Config
  //---------------------------------------------------------------------------------------------
  final LibraAppState appState;
  final Function(Transaction? orig, Transaction updated)? onSave;
  final Function(CategoryRule rule)? onSaveRule;
  final Function(Transaction)? onDelete;
  bool _disposed = false; // needed for async callbacks
  bool seedStale = false;

  //---------------------------------------------------------------------------------------------
  // Form keys. These enable callbacks to the form state, like calling save() and reset().
  //---------------------------------------------------------------------------------------------
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final GlobalKey<FormState> allocationFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> reimbursementFormKey = GlobalKey<FormState>();
  final TextEditingController reimbursementValueController = TextEditingController();

  //---------------------------------------------------------------------------------------------
  // Initial values for the respective editors. Don't modify these; they're used to reset. When
  // [seed] is null, will use the [initial***] variables.
  //---------------------------------------------------------------------------------------------
  Transaction? seed;
  Allocation? focusedAllocation;
  Reimbursement? focusedReimbursement;

  Account? initialAccount;

  //---------------------------------------------------------------------------------------------
  // Updated values for the respective forms. These are used to save the values retrieved from
  // the various FormFields' onSave methods. They don't contain any UI state, so don't need to
  // notifyListeners.
  //---------------------------------------------------------------------------------------------
  /// Transaction editor
  Account? account;
  String? name;
  DateTime? date;
  int? value;
  Category? category;
  String? note;

  /// Reimbursement editor
  int reimbursementValue = 0;

  /// Allocation editor
  final Allocation updatedAllocation = Allocation(name: '', category: null, value: 0);

  //---------------------------------------------------------------------------------------------
  // These variables are the UI state for the relevant fields. They are used to finalize the output
  // transaction too. Must notifyListeners() on update.
  //---------------------------------------------------------------------------------------------

  /// This is used to determine which categories to show in the dropdown lists, and the intial
  /// filter state of the reimbursement targets. It is set on each [onValueChanged].
  ExpenseFilterType expenseType = ExpenseFilterType.all;
  TransactionDetailActiveFocus focus = TransactionDetailActiveFocus.none;
  String? errorMessage;
  String? reimbursementError;
  bool saveAsRule = false;

  final List<Tag> tags = [];
  final List<Allocation> allocations = [];
  List<Reimbursement> reimbursements = [];

  /// Current reimbursement target selected in the reimbursement editor.
  Transaction? reimburseTarget;

  //---------------------------------------------------------------------------------------------
  // Inits and resets
  //---------------------------------------------------------------------------------------------
  void _init() async {
    if (seed != null) {
      if (!seed!.relationsAreLoaded()) {
        await appState.transactions.loadRelations(seed!);
      }
      expenseType = _valToFilterType(seed?.value);
      tags.insertAll(0, seed?.tags ?? const []);
      allocations.insertAll(0, seed?.allocations ?? const []);
      reimbursements.insertAll(0, seed?.reimbursements ?? const []);
      notifyListeners();
    }
  }

  void replaceSeed(Transaction? t) {
    seed = t;
    reset();
  }

  /// Reset everything to the original [seed].
  void reset() {
    /// Reset manual state elements
    saveAsRule = false;
    errorMessage = null;
    reimbursementError = null;
    reimburseTarget = null;
    tags.clear();
    allocations.clear();
    reimbursements.clear();

    /// Reset form fields
    formKey.currentState?.reset();

    /// Reset focus
    clearFocus();

    /// Re-init from [seed]
    _init();
    notifyListeners();
  }

  /// Reset just the allocation editor.
  void resetAllocation() {
    allocationFormKey.currentState?.reset();
    notifyListeners();
  }

  /// Reset just the reimbursement editor.
  void resetReimbursement() {
    reimbursementFormKey.currentState?.reset();
    reimburseTarget = focusedReimbursement?.target;
    reimbursementValueController.text =
        focusedReimbursement?.value.dollarString(dollarSign: false) ?? '';
    reimbursementError = null;
    notifyListeners();
  }

  /// After changing any transaction, we need to reload the reimbursements in case one of them was
  /// changed. This is used as a [TransactionService] listener callback.
  void reloadAfterTransactionUpdate() async {
    /// Super important to reload the seed, because that's what will be used for save/delete.
    if (seed != null) {
      seedStale = true;
      seed = await appState.transactions.loadSingle(seed!.key);
      seedStale = false;
    }
    if (_disposed) return;

    /// Remove deleted tags
    tags.removeWhere((tag) => appState.tags.list.indexWhere((it) => it.key == tag.key) == -1);

    /// Collect the target keys
    Set<int> keys = {};
    if (reimburseTarget != null) {
      keys.add(reimburseTarget!.key);
    }
    for (final reimb in reimbursements) {
      keys.add(reimb.target.key);
    }

    /// Load the new transactions
    final transactions = await appState.transactions.loadByKey(keys);
    if (_disposed) return;

    /// Reset the reimbursements
    final newReimbs = <Reimbursement>[];
    for (final reimb in reimbursements) {
      final t = transactions[reimb.target.key];
      if (t == null) continue;
      newReimbs.add(
        Reimbursement(
          target: t,
          value: reimb.value,
          commitedValue: reimb.commitedValue, // TODO is this right?
        ),
      );
      if (reimb == focusedReimbursement) {
        focusedReimbursement = newReimbs.last;
      }
    }
    reimbursements = newReimbs;
    if (reimburseTarget != null) {
      reimburseTarget = transactions[reimburseTarget!.key];
    }

    notifyListeners();
  }

  //---------------------------------------------------------------------------------------------
  // Deleting
  //---------------------------------------------------------------------------------------------
  void delete() {
    if (seedStale) return;
    if (seed != null) onDelete?.call(seed!);
  }

  void deleteAllocation() {
    allocations.remove(focusedAllocation);
    clearFocus();
  }

  void deleteReimbursement() {
    reimbursements.remove(focusedReimbursement);
    reimburseTarget = null;
    clearFocus();
  }

  //---------------------------------------------------------------------------------------------
  // Saving
  //---------------------------------------------------------------------------------------------
  String? _validate() {
    if (formKey.currentState?.validate() != true) return "";
    // Need to save the form first to get the values. This doesn't do anything other than set the
    // save sink members above.
    formKey.currentState?.save();

    if (name == null ||
        date == null ||
        value == null ||
        note == null ||
        category == null ||
        account == null) {
      debugPrint("TransactionDetailsState:_validate() ERROR found null values!");
      return "Null values";
    }

    // Same category type
    if (!expenseType.inclusiveEqual(category!.type)) {
      return "Specified value does not have the correct sign for category ${category!.name}.";
    }

    // Here we check to make sure the allocations and reimbursements don't exceed the total value,
    // or otherwise lead to negative category values.
    var totalAdjustments = 0;
    for (final alloc in allocations) {
      if (!expenseType.inclusiveEqual(alloc.category!.type)) {
        return "Allocation ${alloc.name} must be an ${expenseType.name} category.";
      }
      totalAdjustments += alloc.value;
    }
    for (final reimb in reimbursements) {
      if (reimb.target.key == seed?.key) {
        return "Cannot reimburse a transaction against itself.";
      }
      if (reimb.target.value * value! > 0) {
        const maxNameLength = 30;
        var name = reimb.target.name;
        if (name.length > maxNameLength) {
          name = '${name.substring(0, maxNameLength)}...';
        }
        return "Reimbursement $name must have a value of the opposite sign.";
      }
      totalAdjustments += reimb.value;
    }
    if (totalAdjustments > value!.abs()) {
      return "Total allocations and reimbursements (${totalAdjustments.dollarString()}) exceeds transaction value.";
    }

    return null;
  }

  void save() {
    if (seedStale) return;
    String? err = _validate();
    if (err != null) {
      errorMessage = err;
      notifyListeners();
    } else {
      var t = Transaction(
        key: seed?.key ?? 0,
        name: name!,
        date: date!,
        value: value!,
        category: category ?? Category.empty,
        account: account,
        note: note!,
        allocations: List.from(allocations),
        reimbursements: List.from(reimbursements),
        tags: List.from(tags),
      );
      onSave?.call(seed, t);
      if (saveAsRule) {
        final rule = CategoryRule(
          pattern: t.name,
          category: category,
          type: ExpenseType.from(value!),
        );
        appState.rules.add(rule);
        onSaveRule?.call(rule);
      }
    }
  }

  /// Save a single allocation from the allocation editor in [allocations]
  void saveAllocation() {
    if (allocationFormKey.currentState?.validate() ?? false) {
      allocationFormKey.currentState?.save();
      if (focusedAllocation == null) {
        allocations.add(updatedAllocation.copy());
      } else {
        for (int i = 0; i < allocations.length; i++) {
          if (allocations[i] == focusedAllocation) {
            allocations[i] = updatedAllocation.copy(key: allocations[i].key);
            break;
          }
        }
      }
      clearFocus();
    }
  }

  /// Validates the form for the reimbursement editor only. Returns an error message, or null on
  /// success.
  String? validateReimbursement() {
    if (reimbursementFormKey.currentState?.validate() != true) {
      // Value is the only thing in the form
      return 'Error in value field.';
    }

    /// Need to save the form first to get the values. This doesn't do anything other than set the
    /// save sink members above. Remember reimbursements are stored in DB as positive values always,
    /// and the editor saves the abs() value already.
    reimbursementFormKey.currentState?.save();

    if (reimburseTarget == null) {
      return "Please select a target transaction.";
    }
    if (reimburseTarget!.key == seed?.key) {
      return "Cannot reimburse a transaction with itself.";
    }
    if (_valToFilterType(reimburseTarget!.value) == expenseType) {
      return "Selected transaction must have the opposite sign.";
    }
    if (reimbursementValue > reimburseTarget!.value.abs()) {
      return "Value is greater than the selected transaction's value.";
      // p.s. We check the current transaction's value on the global validate().
    }
    for (final reimb in reimbursements) {
      if (reimb == focusedReimbursement) continue;
      if (reimb.target.key == reimburseTarget!.key) {
        return "A reimbursement between these two transactions exists already.";
      }
    }

    /// Check to make sure the reimbursement value doesn't cause the other transaction to become
    /// negative
    if (reimburseTarget!.totalReimbusrements > 0) {
      var valueRemaining = reimburseTarget!.value.abs() - reimburseTarget!.totalReimbusrements;
      if (focusedReimbursement?.target == reimburseTarget) {
        // We're updating an existing reimbursement, so add back original value
        valueRemaining += focusedReimbursement!.commitedValue;
      }
      if (reimbursementValue > valueRemaining) {
        return "Total reimbursements on the selected transaction exceeds its value.";
      }
    }

    return null;
  }

  /// Save a single reimbursement from the allocation editor in [reimbursements]
  void saveReimbursement() {
    reimbursementError = validateReimbursement();
    if (reimbursementError == null) {
      final reimb = Reimbursement(
        target: reimburseTarget!,
        value: reimbursementValue,
        commitedValue: focusedReimbursement?.commitedValue ?? 0,
      );

      if (focusedReimbursement == null) {
        reimbursements.add(reimb);
      } else {
        for (int i = 0; i < reimbursements.length; i++) {
          if (reimbursements[i] == focusedReimbursement) {
            reimbursements[i] = reimb;
            break;
          }
        }
      }
      clearFocus();
    }
    notifyListeners();
  }

  //---------------------------------------------------------------------------------------------
  // Navigation
  //---------------------------------------------------------------------------------------------
  void clearFocus() {
    focusedAllocation = null;
    focusedReimbursement = null;
    reimburseTarget = null;
    focus = TransactionDetailActiveFocus.none;
    notifyListeners();
  }

  void focusAllocation(Allocation? alloc) {
    if (focus == TransactionDetailActiveFocus.reimbursement) {
      focusedReimbursement = null;
    }
    focusedAllocation = alloc;
    focus = TransactionDetailActiveFocus.allocation;
    resetAllocation();
    // it's important to call reset() here so the forms don't keep stale data from previous focuses.
    // this is orthogonal to the Key(initial) used by the forms; if the initial state didn't change
    // (i.e. both null when adding accounts back to back), only the reset above will clear the form.
  }

  void focusReimbursement(Reimbursement? it) {
    if (focus == TransactionDetailActiveFocus.allocation) {
      focusedAllocation = null;
    }
    focusedReimbursement = it;
    reimburseTarget = it?.target;
    focus = TransactionDetailActiveFocus.reimbursement;
    resetReimbursement();
    // it's important to call reset() here so the forms don't keep stale data from previous focuses.
    // this is orthogonal to the Key(initial) used by the forms; if the initial state didn't change
    // (i.e. both null when adding accounts back to back), only the reset above will clear the form.
  }

  //---------------------------------------------------------------------------------------------
  // Callbacks
  //---------------------------------------------------------------------------------------------
  ExpenseFilterType _valToFilterType(int? val) {
    if (val == null || val == 0) {
      return ExpenseFilterType.all;
    } else if (val > 0) {
      return ExpenseFilterType.income;
    } else {
      return ExpenseFilterType.expense;
    }
  }

  void onValueChanged(int? val) {
    var newType = _valToFilterType(val);
    if (newType != expenseType) {
      expenseType = newType;
      notifyListeners();
    }
  }

  void onTagChanged(Tag tag, bool? selected) {
    if (selected == true) {
      tags.add(tag);
    } else {
      tags.remove(tag);
    }
    notifyListeners();
  }

  void setReimbursementTarget(Transaction? it) {
    reimburseTarget = it;
    if (reimburseTarget != null && seed != null && reimbursementValueController.text.isEmpty) {
      final val = min(it!.value.abs(), seed!.value.abs());
      reimbursementValueController.text = val.dollarString(dollarSign: false);
    }
    notifyListeners();
  }

  void toggleSaveRule() {
    saveAsRule = !saveAsRule;
    notifyListeners();
  }
}
