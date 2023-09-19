import 'package:material_table_view/src/table_column.dart';

extension ExpandedToTableColumnIterableExtension on Iterable<TableColumn> {
  /// Convenience method for expanding columns to fill the remaining width.
  ///
  /// Not ideal because the horizontal scrollPadding
  /// (more often not known to the caller)
  /// needs to be subtracted from the width passed
  /// to avoid horizontal scrollbar appearing.
  List<TableColumn> expandedTo(double width) {
    final columnWidth = fold<double>(
      .0,
      (previousValue, element) => previousValue + element.width,
    );

    if (columnWidth >= width) return this.toList();

    final factor = width / columnWidth;
    return [
      for (final column in this) column.copyWith(width: column.width * factor),
    ];
  }
}
