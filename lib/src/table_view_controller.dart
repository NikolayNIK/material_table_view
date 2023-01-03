import 'package:flutter/widgets.dart';

/// Controller that holds the state for a [TableView] widget.
class TableViewController {
  /// Controller used to hold horizontal scroll state of a table.
  final horizontalScrollController = ScrollController();

  /// Controller used to hold vertical scroll state of a table.
  final verticalScrollController = ScrollController();
}
