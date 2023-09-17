import 'package:flutter/material.dart';
import 'package:material_table_view/src/table_view_style.dart';

class PopulatedTableViewStyle extends TableViewStyle {
  @override
  PopulatedTableViewHorizontalDividersStyle get horizontalDividersStyle =>
      super.horizontalDividersStyle
          as PopulatedTableViewHorizontalDividersStyle;

  PopulatedTableViewVerticalDividersStyle get verticalDividersStyle =>
      super.verticalDividersStyle as PopulatedTableViewVerticalDividersStyle;

  PopulatedTableViewStyle({
    required PopulatedTableViewHorizontalDividersStyle horizontalDividersStyle,
    required PopulatedTableViewVerticalDividersStyle verticalDividersStyle,
  }) : super(
          horizontalDividersStyle: horizontalDividersStyle,
          verticalDividersStyle: verticalDividersStyle,
        );

  factory PopulatedTableViewStyle.of(
    BuildContext context, {
    required TableViewStyle? style,
  }) =>
      PopulatedTableViewStyle(
        horizontalDividersStyle: PopulatedTableViewHorizontalDividersStyle.of(
          context,
          style: style?.horizontalDividersStyle,
        ),
        verticalDividersStyle: PopulatedTableViewVerticalDividersStyle.of(
          context,
          style: style?.verticalDividersStyle,
        ),
      );
}

class PopulatedTableViewHorizontalDividersStyle
    extends TableViewHorizontalDividersStyle {
  @override
  PopulatedTableViewHorizontalDividerStyle get headerDividerStyle =>
      super.headerDividerStyle as PopulatedTableViewHorizontalDividerStyle;

  PopulatedTableViewHorizontalDividerStyle get footerDividerStyle =>
      super.footerDividerStyle as PopulatedTableViewHorizontalDividerStyle;

  PopulatedTableViewHorizontalDividersStyle({
    required PopulatedTableViewHorizontalDividerStyle headerDividerStyle,
    required PopulatedTableViewHorizontalDividerStyle footerDividerStyle,
  }) : super(
          headerDividerStyle: headerDividerStyle,
          footerDividerStyle: footerDividerStyle,
        );

  factory PopulatedTableViewHorizontalDividersStyle.of(
    BuildContext context, {
    required TableViewHorizontalDividersStyle? style,
  }) =>
      PopulatedTableViewHorizontalDividersStyle(
        headerDividerStyle: PopulatedTableViewHorizontalDividerStyle.of(
          context,
          style: style?.headerDividerStyle,
        ),
        footerDividerStyle: PopulatedTableViewHorizontalDividerStyle.of(
          context,
          style: style?.footerDividerStyle,
        ),
      );
}

class PopulatedTableViewHorizontalDividerStyle
    extends TableViewHorizontalDividerStyle {
  @override
  Color get color => super.color!;

  @override
  double get thickness => super.thickness!;

  PopulatedTableViewHorizontalDividerStyle({
    required Color color,
    required double thickness,
  }) : super(
          color: color,
          thickness: thickness,
        );

  factory PopulatedTableViewHorizontalDividerStyle.of(
    BuildContext context, {
    required TableViewHorizontalDividerStyle? style,
  }) {
    late final borderStyle = Divider.createBorderSide(context);
    return PopulatedTableViewHorizontalDividerStyle(
      color: style?.color ?? borderStyle.color,
      thickness: style?.thickness ?? borderStyle.width,
    );
  }
}

class PopulatedTableViewVerticalDividersStyle
    extends TableViewVerticalDividersStyle {
  @override
  PopulatedTableViewVerticalDividerStyle get leadingDividerStyle =>
      super.leadingDividerStyle as PopulatedTableViewVerticalDividerStyle;

  PopulatedTableViewVerticalDividerStyle get trailingDividerStyle =>
      super.trailingDividerStyle as PopulatedTableViewVerticalDividerStyle;

  PopulatedTableViewVerticalDividersStyle({
    required PopulatedTableViewVerticalDividerStyle leadingDividerStyle,
    required PopulatedTableViewVerticalDividerStyle trailingDividerStyle,
  }) : super(
          leadingDividerStyle: leadingDividerStyle,
          trailingDividerStyle: trailingDividerStyle,
        );

  factory PopulatedTableViewVerticalDividersStyle.of(
    BuildContext context, {
    required TableViewVerticalDividersStyle? style,
  }) =>
      PopulatedTableViewVerticalDividersStyle(
        leadingDividerStyle: PopulatedTableViewVerticalDividerStyle.of(
          context,
          style: style?.leadingDividerStyle,
        ),
        trailingDividerStyle: PopulatedTableViewVerticalDividerStyle.of(
          context,
          style: style?.trailingDividerStyle,
        ),
      );
}

class PopulatedTableViewVerticalDividerStyle
    extends TableViewVerticalDividerStyle {
  @override
  Color get color => super.color!;

  @override
  double get thickness => super.thickness!;

  @override
  int get wigglesPerRow => super.wigglesPerRow!;

  @override
  double get wiggleOffset => super.wiggleOffset!;

  PopulatedTableViewVerticalDividerStyle({
    required Color color,
    required double thickness,
    required int wigglesPerRow,
    required double wiggleOffset,
  }) : super(
          color: color,
          wigglesPerRow: wigglesPerRow,
          thickness: thickness,
          wiggleOffset: wiggleOffset,
        );

  factory PopulatedTableViewVerticalDividerStyle.of(
    BuildContext context, {
    required TableViewVerticalDividerStyle? style,
  }) {
    late final borderStyle = Divider.createBorderSide(context);
    return PopulatedTableViewVerticalDividerStyle(
      color: style?.color ?? borderStyle.color,
      thickness: style?.thickness ?? borderStyle.width,
      wigglesPerRow: style?.wigglesPerRow ?? 1,
      wiggleOffset: style?.wiggleOffset ?? 16.0,
    );
  }
}
