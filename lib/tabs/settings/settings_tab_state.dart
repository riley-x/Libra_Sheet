/// These classes store the state of the various submenus in the settings tab. They need to be stored
/// above the settings tab itself so that when the LayoutBuilder changes, their state is preserved.

import 'package:flutter/material.dart';
import 'package:libra_sheet/data/account.dart';
import 'package:libra_sheet/data/category.dart';
import 'package:libra_sheet/data/database/accounts.dart';
import 'package:libra_sheet/data/libra_app_state.dart';

/// State for the EditAccountsScreen
class EditAccountState extends ChangeNotifier {
  final LibraAppState appState;

  EditAccountState(this.appState);

  /// Accounts Screen
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool isFocused = false;
  Account? focused;

  /// We use the color in the class as the state of the color box though!
  MutableAccount saveSink = MutableAccount();

  void _init() {
    if (focused == null) {
      saveSink = MutableAccount(
        color: Colors.blue,
      );
    } else {
      saveSink = MutableAccount.copy(focused!);
    }
  }

  void reset() {
    formKey.currentState?.reset();
    _init();
    notifyListeners();
  }

  void setFocus(Account? it) {
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

  void delete() {
    // TODO
  }

  void save() {
    formKey.currentState?.save();
    if (focused == null) {
      saveSink.listIndex = appState.accounts.length;
    }
    final acc = saveSink.freeze();
    debugPrint("EditAccountState::save() $acc");

    if (focused == null) {
      appState.accounts.add(acc);
      appState.notifyListeners();
      insertAccount(acc);
    } else {
      for (int i = 0; i < appState.accounts.length; i++) {
        if (appState.accounts[i] == focused) {
          appState.accounts[i] = acc;
          appState.notifyListeners();
          // TODO updateAccount(acc)
          // Remember that the key of any new accounts will be 0!!!!
          break;
        }
      }
    }

    clearFocus();
  }
}

/// State for the EditCategoriesScreen
class EditCategoriesState extends ChangeNotifier {
  /// Accounts Screen
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool isFocused = false;

  /// Currently edited category. This also serves as the initial state for the FormFields.
  Category focused = Category.empty;

  /// Save sink for the FormFields
  String saveName = '';
  Category? parent;

  /// Active UI state for the displayed box, and the saved value
  Color color = Colors.deepPurple;

  void _init() {
    color = focused.color ?? Colors.deepPurple;
  }

  void reset() {
    formKey.currentState?.reset();
    _init();
    notifyListeners();
  }

  void setFocus(Category it) {
    focused = it;
    isFocused = true;
    _init();
    notifyListeners();
  }

  void clearFocus() {
    isFocused = false;
    notifyListeners();
  }

  void delete() {
    // TODO
  }

  void save() {
    if (formKey.currentState?.validate() ?? false) {
      formKey.currentState?.save();
      // TODO handle parents here
      final cat = Category(
        key: focused?.key ?? 0,
        name: saveName,
        level: 1,
        color: color,
      );
      print(cat);
      // TODO
    }
  }
}
