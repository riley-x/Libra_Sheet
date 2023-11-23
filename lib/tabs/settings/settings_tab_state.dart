/// These classes store the state of the various submenus in the settings tab. They need to be stored
/// above the settings tab itself so that when the LayoutBuilder changes, their state is preserved.

import 'package:flutter/material.dart';
import 'package:libra_sheet/data/account.dart';

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
