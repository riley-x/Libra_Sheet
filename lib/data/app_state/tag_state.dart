import 'package:libra_sheet/data/app_state/libra_app_state.dart';
import 'package:libra_sheet/data/database/tags.dart';
import 'package:libra_sheet/data/tag.dart';

/// Helper module for handling the tags
class TagState {
  //----------------------------------------------------------------------------
  // Fields
  //----------------------------------------------------------------------------
  LibraAppState appState;
  TagState(this.appState);

  final List<Tag> list = [];

  //----------------------------------------------------------------------------
  // Modification Functions
  //----------------------------------------------------------------------------
  Future<void> add(Tag tag) async {
    int key = await insertTag(tag);
    tag = tag.copyWith(key: key);
    list.add(tag);
    appState.notifyListeners();
  }

  Future<void> delete(Tag tag) async {
    list.removeWhere((it) => it.key == tag.key);
    appState.notifyListeners();
    // TODO
  }

  /// Tags are modified in place already. This function serves to notify listeners, and also update
  /// the database.
  Future<void> notifyUpdate(Tag tag) async {
    appState.notifyListeners();
    updateTag(tag);
  }
}
