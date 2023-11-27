// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/objects/category_rule.dart';

/// Helper module for handling the category rules
class RuleState {
  //----------------------------------------------------------------------------
  // Fields
  //----------------------------------------------------------------------------
  LibraAppState appState;
  RuleState(this.appState);

  final List<CategoryRule> income = [];
  final List<CategoryRule> expense = [];

  //----------------------------------------------------------------------------
  // Modification Functions
  //----------------------------------------------------------------------------
  Future<void> load() async {
    // list.addAll(await getTags());
    // appState.notifyListeners();
  }

  Future<void> add(CategoryRule rule) async {
    // int key = await insertTag(tag);
    // tag = tag.copyWith(key: key);
    // list.insert(0, tag);
    // appState.notifyListeners();
  }

  Future<void> delete(CategoryRule rule) async {
    // list.removeWhere((it) => it.key == tag.key);
    // appState.notifyListeners();
    // await deleteTag(tag);
  }

  /// Tags are modified in place already. This function serves to notify listeners, and also update
  /// the database.
  Future<void> notifyUpdate(CategoryRule rule) async {
    // appState.notifyListeners();
    // await updateTag(tag);
  }
}
