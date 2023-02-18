import 'package:flutter/widgets.dart';

@immutable
class TableContentDividerData {
  final Color color;
  final double wiggleOffset;

  TableContentDividerData({
    required this.color,
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

  TableContentColumnData({
    required this.indices,
    required this.positions,
    required this.widths,
  });
}

/// An immutable storage class that contains horizontal layout information of
/// a table.
@immutable
class TableContentLayoutData {
  final TableContentColumnData scrollableColumns, fixedColumns;

  final TableContentDividerData leftDivider, rightDivider;
  final double leftWidth, centerWidth;

  TableContentLayoutData({
    required this.scrollableColumns,
    required this.fixedColumns,
    required this.leftDivider,
    required this.rightDivider,
    required this.leftWidth,
    required this.centerWidth,
  });
}
