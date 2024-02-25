import 'package:flutter/widgets.dart';

@immutable
class TableContentDividerData {
  final Color color;
  final double thickness;
  final int wigglesPerRow;
  final double wiggleOffset;

  const TableContentDividerData({
    required this.color,
    required this.thickness,
    required this.wigglesPerRow,
    required this.wiggleOffset,
  });

  bool get visible => color.alpha != 0;

  @override
  bool operator ==(Object other) =>
      other is TableContentDividerData &&
      other.wiggleOffset == wiggleOffset &&
      other.wiggleOffset == wiggleOffset;

  @override
  int get hashCode => 1; // unused
}

@immutable
class TableContentColumnData {
  final List<int> indices;
  final List<double> positions;
  final List<double> widths;
  final List<Key> keys;

  const TableContentColumnData({
    required this.indices,
    required this.positions,
    required this.widths,
    required this.keys,
  });
}

/// An immutable storage class that contains horizontal layout information of
/// a table.
@immutable
class TableContentLayoutData {
  final TableContentColumnData scrollableColumns, fixedColumns;

  final TableContentDividerData leftDivider, rightDivider;
  final double leftWidth, centerWidth, rightWidth;

  const TableContentLayoutData({
    required this.scrollableColumns,
    required this.fixedColumns,
    required this.leftDivider,
    required this.rightDivider,
    required this.leftWidth,
    required this.centerWidth,
    required this.rightWidth,
  });
}
