import 'package:libra_sheet/data/app_state/libra_app_state.dart';
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
    // TODO
  }

  Future<void> delete(Tag tag) async {
    // TODO
  }

  Future<void> update(Tag tag) async {
    // TODO
  }
}
