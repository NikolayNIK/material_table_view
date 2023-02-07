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

@immutable
class TableContentRowLayoutData {
  final double rowHeight;
  final TableContentColumnData scrollableColumns, fixedColumns;

  TableContentRowLayoutData({
    required this.rowHeight,
    required this.scrollableColumns,
    required this.fixedColumns,
  });

  factory TableContentRowLayoutData.of(BuildContext context) =
      TableContentLayoutData.of;
}

@immutable
class TableContentLayoutData extends TableContentRowLayoutData {
  final TableContentDividerData leftDivider, rightDivider;
  final double leftWidth, centerWidth;

  TableContentLayoutData({
    required super.rowHeight,
    required super.scrollableColumns,
    required super.fixedColumns,
    required this.leftDivider,
    required this.rightDivider,
    required this.leftWidth,
    required this.centerWidth,
  });

  factory TableContentLayoutData.of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<InheritedTableContentLayout>()!
      .data;
}

class InheritedTableContentLayout extends InheritedWidget {
  final TableContentLayoutData data;

  InheritedTableContentLayout({
    required this.data,
    required super.child,
  });

  @override
  bool updateShouldNotify(covariant InheritedTableContentLayout oldWidget) =>
      oldWidget.data != data;
}
