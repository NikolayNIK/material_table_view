import 'package:flutter/widgets.dart';

/// Controller that holds the state for a [TableView] widget.
class TableViewController {
  /// Controller used to hold horizontal scroll state of a table.
  final horizontalScrollController = ScrollController();

  /// Controller used to hold vertical scroll state of a table.
  final verticalScrollController = ScrollController();

  /// [Key] supplied to the horizontal [Scrollable].
  /// This may be used to persist (save & restore) the scroll position of the horizontal scroll using [PageStorageKey].
  final Key? horizontalScrollKey = null;

  /// [Key] supplied to the vertical [Scrollable].
  /// This may be used to persist (save & restore) the scroll position of the vertical scroll using [PageStorageKey].
  final Key? verticalScrollKey = null;

  /// Discards any resources used by the object. After this is called, the
  /// object is not in a usable state and should be discarded.
  ///
  /// This method should only be called by the object's owner.
  void dispose() {
    horizontalScrollController.dispose();
    verticalScrollController.dispose();
  }
}
