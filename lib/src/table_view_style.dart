import 'package:flutter/material.dart';

/// Defines a display style of a table.
@immutable
class TableViewStyle {
  /// Display style of horizontal dividers.
  final TableViewHorizontalDividersStyle? horizontalDividersStyle;

  /// Display style of vertical dividers.
  final TableViewVerticalDividersStyle? verticalDividersStyle;

  const TableViewStyle({
    this.horizontalDividersStyle,
    this.verticalDividersStyle,
  });
}

/// Defines a display style of horizontal dividers of a table.
@immutable
class TableViewHorizontalDividersStyle {
  /// Display style of a divider between a header row and the rest of a table.
  final TableViewHorizontalDividerStyle? headerDividerStyle;

  /// Display style of a divider between a footer row and the rest of a table.
  final TableViewHorizontalDividerStyle? footerDividerStyle;

  const TableViewHorizontalDividersStyle({
    this.headerDividerStyle,
    this.footerDividerStyle,
  });

  const TableViewHorizontalDividersStyle.symmetric(
    TableViewHorizontalDividerStyle style,
  )   : headerDividerStyle = style,
        footerDividerStyle = style;
}

/// Defines a display style of a particular horizontal divider of a table.
@immutable
class TableViewHorizontalDividerStyle {
  /// Color of the divider displayed.
  final Color? color;

  /// Thickness of the divider displayed. Affects layout.
  final double? thickness;

  const TableViewHorizontalDividerStyle({
    this.color,
    this.thickness,
  }) : assert(thickness == null || thickness >= 0);
}

/// Defines a display style of vertical dividers of a table.
@immutable
class TableViewVerticalDividersStyle {
  /// Display style of a divider separating
  /// frozen on the leading (left in left-to-right) edge columns
  /// from the rest of the columns.
  final TableViewVerticalDividerStyle? leadingDividerStyle;

  /// Display style of a divider separating
  /// frozen on the trailing (right in left-to-right) edge columns
  /// from the rest of the columns.
  final TableViewVerticalDividerStyle? trailingDividerStyle;

  const TableViewVerticalDividersStyle({
    this.leadingDividerStyle,
    this.trailingDividerStyle,
  });

  /// Initializes [leadingDividerStyle] and [trailingDividerStyle] using
  /// the same [TableViewVerticalDividerStyle].
  const TableViewVerticalDividersStyle.symmetric(
    TableViewVerticalDividerStyle style,
  )   : leadingDividerStyle = style,
        trailingDividerStyle = style;
}

/// Defines a display style of a particular vertical divider of a table.
@immutable
class TableViewVerticalDividerStyle {
  /// Color of the divider displayed.
  final Color? color;

  /// Thickness of the divider displayed. Affects clipping.
  final double? thickness;

  /// The amount of logical pixels the divider will wiggle horizontally.
  final double? wiggleOffset;

  const TableViewVerticalDividerStyle({
    this.color,
    this.thickness,
    this.wiggleOffset,
  })  : assert(thickness == null || thickness >= 0),
        assert(wiggleOffset == null || wiggleOffset >= 0);
}
