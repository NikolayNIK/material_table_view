import 'package:material_table_view/src/table_column.dart';

const _eps = .01;

extension TableColumnResolveLayoutExtension on List<TableColumn> {
  List<TableColumn> resolveLayout(double availableWidth) {
    double columnWidth = .0;
    int columnFlex = 0;
    for (final column in this) {
      columnWidth += column.width;
      columnFlex += column.flex;
    }

    if (columnFlex == 0) return this;

    // we want to lower the space slightly to avoid scrollbar popping in and out
    // also helps with comparison
    final change = availableWidth - columnWidth - _eps;
    if (change < 0) return this;

    return [
      for (final column in this)
        column.flex == 0
            ? column
            : column.copyWith(
                width: column.width + change * column.flex / columnFlex,
              ),
    ];
  }
}
