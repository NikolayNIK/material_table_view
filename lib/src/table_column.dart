import 'package:flutter/foundation.dart';

/// Description of a fixed-width column to be built by a [TableView] widget.
@immutable
class TableColumn {
  const TableColumn({
    required this.width,
    this.freezePriority = 0,
  }) : assert(freezePriority >= 0);

  /// Width of a column in a logical pixels.
  final double width;

  /// Priority of a column to be frozen on a screen instead of scrolling off.
  /// The larger the priority the more likely this column is to remain frozen
  /// in case of lacking space to freeze all the required columns. If zero,
  /// the column will never be frozen.
  final int freezePriority;

  /// Check whether or not the column is frozen at a given priority.
  bool frozenAt(int priority) => freezePriority > priority;
}
