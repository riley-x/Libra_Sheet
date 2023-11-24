/// These classes store the state of the various submenus in the settings tab. They need to be stored
/// above the settings tab itself so that when the LayoutBuilder changes, their state is preserved.

import 'package:flutter/material.dart';
import 'package:libra_sheet/data/account.dart';
import 'package:libra_sheet/data/category.dart';

/// State for the EditAccountsScreen
class EditAccountState extends ChangeNotifier {
  /// Accounts Screen
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool isFocused = false;
  Account? focused;

  /// We use the color in the class as the state of the color box though!
  MutableAccount saveSink = MutableAccount();

  void _init() {
    if (focused == null) {
      saveSink = MutableAccount();
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
    formKey.currentState?.save();
    final acc = saveSink.freeze();
    print(acc);
    // TODO
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
