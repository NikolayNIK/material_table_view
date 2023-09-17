import 'dart:ui';

import 'package:flutter/material.dart';

/// Defines a display style of a table.
@immutable
class TableViewStyle extends ThemeExtension<TableViewStyle> {
  /// Display style of dividers in a table.
  final TableViewDividersStyle? dividers;

  const TableViewStyle({
    this.dividers,
  });

  @override
  TableViewStyle copyWith({
    TableViewDividersStyle? dividers,
  }) =>
      TableViewStyle(
        dividers: dividers ?? this.dividers,
      );

  @override
  TableViewStyle lerp(TableViewStyle other, double t) => TableViewStyle(
        dividers: dividers == null || other.dividers == null
            ? other.dividers
            : dividers!.lerp(other.dividers!, t),
      );
}

/// Defines a display style of dividers in a table.
@immutable
class TableViewDividersStyle {
  /// Display style of horizontal dividers.
  final TableViewHorizontalDividersStyle? horizontal;

  /// Display style of vertical dividers.
  final TableViewVerticalDividersStyle? vertical;

  const TableViewDividersStyle({
    this.horizontal,
    this.vertical,
  });

  TableViewDividersStyle copyWith({
    TableViewHorizontalDividersStyle? horizontal,
    TableViewVerticalDividersStyle? vertical,
  }) =>
      TableViewDividersStyle(
        horizontal: horizontal ?? this.horizontal,
        vertical: vertical ?? this.vertical,
      );

  TableViewDividersStyle lerp(TableViewDividersStyle other, double t) =>
      TableViewDividersStyle(
        horizontal: horizontal == null || other.horizontal == null
            ? other.horizontal
            : horizontal!.lerp(other.horizontal!, t),
        vertical: vertical == null || other.vertical == null
            ? other.vertical
            : vertical!.lerp(other.vertical!, t),
      );
}

/// Defines a display style of horizontal dividers of a table.
@immutable
class TableViewHorizontalDividersStyle {
  /// Display style of a divider between a header row and the rest of a table.
  final TableViewHorizontalDividerStyle? header;

  /// Display style of a divider between a footer row and the rest of a table.
  final TableViewHorizontalDividerStyle? footer;

  const TableViewHorizontalDividersStyle({
    this.header,
    this.footer,
  });

  /// Initializes [header] and [footer] using
  /// the same [TableViewHorizontalDividerStyle].
  const TableViewHorizontalDividersStyle.symmetric(
    TableViewHorizontalDividerStyle style,
  )   : header = style,
        footer = style;

  TableViewHorizontalDividersStyle copyWith({
    TableViewHorizontalDividerStyle? header,
    TableViewHorizontalDividerStyle? footer,
  }) =>
      TableViewHorizontalDividersStyle(
        header: header ?? this.header,
        footer: footer ?? this.footer,
      );

  TableViewHorizontalDividersStyle lerp(
          TableViewHorizontalDividersStyle other, double t) =>
      TableViewHorizontalDividersStyle(
        header: header == null || other.header == null
            ? other.header
            : header!.lerp(other.header!, t),
        footer: footer == null || other.footer == null
            ? other.footer
            : footer!.lerp(other.footer!, t),
      );
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

  TableViewHorizontalDividerStyle copyWith({
    Color? color,
    double? thickness,
  }) =>
      TableViewHorizontalDividerStyle(
        color: color ?? this.color,
        thickness: thickness ?? this.thickness,
      );

  TableViewHorizontalDividerStyle lerp(
          TableViewHorizontalDividerStyle other, double t) =>
      TableViewHorizontalDividerStyle(
        color: Color.lerp(color, other.color, t),
        thickness: lerpDouble(thickness, other.thickness, t),
      );
}

/// Defines a display style of vertical dividers of a table.
@immutable
class TableViewVerticalDividersStyle {
  /// Display style of a divider separating
  /// frozen on the leading (left in left-to-right) edge columns
  /// from the rest of the columns.
  final TableViewVerticalDividerStyle? leading;

  /// Display style of a divider separating
  /// frozen on the trailing (right in left-to-right) edge columns
  /// from the rest of the columns.
  final TableViewVerticalDividerStyle? trailing;

  const TableViewVerticalDividersStyle({
    this.leading,
    this.trailing,
  });

  /// Initializes [leading] and [trailing] using
  /// the same [TableViewVerticalDividerStyle].
  const TableViewVerticalDividersStyle.symmetric(
    TableViewVerticalDividerStyle style,
  )   : leading = style,
        trailing = style;

  TableViewVerticalDividersStyle copyWith({
    TableViewVerticalDividerStyle? leadingDividerStyle,
    TableViewVerticalDividerStyle? trailingDividerStyle,
  }) =>
      TableViewVerticalDividersStyle(
        leading: leadingDividerStyle ?? this.leading,
        trailing: trailingDividerStyle ?? this.trailing,
      );

  TableViewVerticalDividersStyle lerp(
          TableViewVerticalDividersStyle other, double t) =>
      TableViewVerticalDividersStyle(
        leading: leading == null || other.leading == null
            ? other.leading
            : leading!.lerp(other.leading!, t),
        trailing: trailing == null || other.trailing == null
            ? other.trailing
            : trailing!.lerp(other.trailing!, t),
      );
}

/// Defines a display style of a particular vertical divider of a table.
@immutable
class TableViewVerticalDividerStyle {
  /// Color of the divider displayed.
  final Color? color;

  /// Thickness of the divider displayed. Affects clipping.
  final double? thickness;

  /// The amount of times per row the divider displayed is going to wiggle.
  /// Increasing this value might worsen the performance.
  /// Prefer setting it to 0 when not using wiggling dividers.
  final int? wigglesPerRow;

  /// The amount of logical pixels the divider will wiggle horizontally.
  final double? wiggleOffset;

  const TableViewVerticalDividerStyle({
    this.color,
    this.thickness,
    this.wigglesPerRow,
    this.wiggleOffset,
  })  : assert(thickness == null || thickness >= 0),
        assert(wigglesPerRow == null || wigglesPerRow >= 0),
        assert(wiggleOffset == null || wiggleOffset >= 0);

  TableViewVerticalDividerStyle copyWith({
    Color? color,
    double? thickness,
    int? wigglesPerRow,
    double? wiggleOffset,
  }) =>
      TableViewVerticalDividerStyle(
        color: color ?? this.color,
        thickness: thickness ?? this.thickness,
        wigglesPerRow: wigglesPerRow ?? this.wigglesPerRow,
        wiggleOffset: wiggleOffset ?? this.wiggleOffset,
      );

  TableViewVerticalDividerStyle lerp(
          TableViewVerticalDividerStyle other, double t) =>
      TableViewVerticalDividerStyle(
        color: Color.lerp(color, other.color, t),
        thickness: lerpDouble(thickness, other.thickness, t),
        wigglesPerRow: // not sure about that
            lerpDouble(wigglesPerRow, other.wigglesPerRow, t)?.toInt(),
        wiggleOffset: lerpDouble(wiggleOffset, other.wiggleOffset, t),
      );
}
