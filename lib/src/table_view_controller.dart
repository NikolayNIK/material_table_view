import 'package:flutter/widgets.dart';

/// Controller that holds the state for a [TableView] widget.
class TableViewController {
  /// Controller used to hold horizontal scroll state of a table.
  final horizontalScrollController = ScrollController();

  /// Controller used to hold vertical scroll state of a table.
  final verticalScrollController = ScrollController();

  final stickyHorizontalOffset = ValueNotifier<double>(0);

  /// Discards any resources used by the object. After this is called, the
  /// object is not in a usable state and should be discarded.
  ///
  /// This method should only be called by the object's owner.
  void dispose() {
    horizontalScrollController.dispose();
    verticalScrollController.dispose();
  }
}
