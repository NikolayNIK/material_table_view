import 'package:flutter/foundation.dart';

/// Description of a fixed-width column to be built by a [TableView] widget.
@immutable
class TableColumn {
  const TableColumn({
    required this.width,
    this.freezePriority = 0,
    this.sticky = false,
    this.flex = 0,
    this.translation = 0,
    this.minResizeWidth,
    this.maxResizeWidth,
  })  : assert(freezePriority >= 0),
        assert(
          freezePriority != 0 || !sticky,
          'Only freezable columns can be sticky',
        ),
        assert(flex >= 0);

  /// Width of a column in a logical pixels.
  final double width;

  /// Priority of a column to be frozen on a screen instead of scrolling off.
  /// The larger the priority the more likely this column is to remain frozen
  /// in case of lacking space to freeze all the required columns. If zero,
  /// the column will never be frozen.
  final int freezePriority;

  /// When set to true, frozen column will be scrolled of the edge of the screen
  /// but will come back upon scrolling in the other direction.
  final bool sticky;

  /// When set higher than zero, column will expand to fill the remaining
  /// width in proportion to the total flex of all columns.
  final int flex;

  /// Horizontal (x) translation of the column. Does not affect the layout
  /// of other columns. Primarily used for animations.
  final double translation;

  /// Minimum width the column is allowed to resize to.
  final double? minResizeWidth;

  /// Maximum width the column is allowed to resize to.
  final double? maxResizeWidth;

  /// Check whether or not the column is frozen at a given priority.
  bool frozenAt(int priority) => freezePriority > priority;

  /// A key to identify the column. By default the column is identified by its
  /// index.
  ///
  /// A need to identify the column in a more concrete way may arise when
  /// the column is being moved around as its index changes but the column
  /// itself doesn't.
  Key? get key => null;

  TableColumn copyWith({
    double? width,
    int? freezePriority,
    bool? sticky,
    int? flex,
    double? translation,
    double? maxResizeWidth,
    double? minResizeWidth,
  }) =>
      TableColumn(
        width: width ?? this.width,
        freezePriority: freezePriority ?? this.freezePriority,
        sticky: sticky ?? this.sticky,
        flex: flex ?? this.flex,
        translation: translation ?? this.translation,
        maxResizeWidth: maxResizeWidth ?? this.maxResizeWidth,
        minResizeWidth: minResizeWidth ?? this.minResizeWidth,
      );
}
