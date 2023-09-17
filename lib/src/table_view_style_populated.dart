import 'package:flutter/material.dart';
import 'package:material_table_view/src/table_view_style.dart';

class PopulatedTableViewStyle extends TableViewStyle {
  @override
  PopulatedTableViewDividersStyle get dividers =>
      super.dividers as PopulatedTableViewDividersStyle;

  @override
  PopulatedTableViewScrollbarsStyle get scrollbars =>
      super.scrollbars as PopulatedTableViewScrollbarsStyle;

  PopulatedTableViewStyle({
    required PopulatedTableViewDividersStyle dividers,
    required PopulatedTableViewScrollbarsStyle scrollbars,
  }) : super(
          dividers: dividers,
          scrollbars: scrollbars,
        );

  factory PopulatedTableViewStyle.of(
    BuildContext context, {
    required TableViewStyle? style,
  }) {
    final base = Theme.of(context).extension<TableViewStyle>();
    return PopulatedTableViewStyle(
      dividers: PopulatedTableViewDividersStyle.of(
        context,
        base: base?.dividers,
        style: style?.dividers,
      ),
      scrollbars: PopulatedTableViewScrollbarsStyle.of(
        context,
        base: base?.scrollbars,
        style: style?.scrollbars,
      ),
    );
  }
}

class PopulatedTableViewDividersStyle extends TableViewDividersStyle {
  @override
  PopulatedTableViewHorizontalDividersStyle get horizontal =>
      super.horizontal as PopulatedTableViewHorizontalDividersStyle;

  PopulatedTableViewVerticalDividersStyle get vertical =>
      super.vertical as PopulatedTableViewVerticalDividersStyle;

  PopulatedTableViewDividersStyle({
    required PopulatedTableViewHorizontalDividersStyle horizontalDividersStyle,
    required PopulatedTableViewVerticalDividersStyle verticalDividersStyle,
  }) : super(
          horizontal: horizontalDividersStyle,
          vertical: verticalDividersStyle,
        );

  factory PopulatedTableViewDividersStyle.of(
    BuildContext context, {
    required TableViewDividersStyle? base,
    required TableViewDividersStyle? style,
  }) =>
      PopulatedTableViewDividersStyle(
        horizontalDividersStyle: PopulatedTableViewHorizontalDividersStyle.of(
          context,
          base: base?.horizontal,
          style: style?.horizontal,
        ),
        verticalDividersStyle: PopulatedTableViewVerticalDividersStyle.of(
          context,
          base: base?.vertical,
          style: style?.vertical,
        ),
      );
}

class PopulatedTableViewHorizontalDividersStyle
    extends TableViewHorizontalDividersStyle {
  @override
  PopulatedTableViewHorizontalDividerStyle get header =>
      super.header as PopulatedTableViewHorizontalDividerStyle;

  PopulatedTableViewHorizontalDividerStyle get footer =>
      super.footer as PopulatedTableViewHorizontalDividerStyle;

  PopulatedTableViewHorizontalDividersStyle({
    required PopulatedTableViewHorizontalDividerStyle headerDividerStyle,
    required PopulatedTableViewHorizontalDividerStyle footerDividerStyle,
  }) : super(
          header: headerDividerStyle,
          footer: footerDividerStyle,
        );

  factory PopulatedTableViewHorizontalDividersStyle.of(
    BuildContext context, {
    required TableViewHorizontalDividersStyle? base,
    required TableViewHorizontalDividersStyle? style,
  }) =>
      PopulatedTableViewHorizontalDividersStyle(
        headerDividerStyle: PopulatedTableViewHorizontalDividerStyle.of(
          context,
          base: base?.header,
          style: style?.header,
        ),
        footerDividerStyle: PopulatedTableViewHorizontalDividerStyle.of(
          context,
          base: base?.footer,
          style: style?.footer,
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
    required TableViewHorizontalDividerStyle? base,
    required TableViewHorizontalDividerStyle? style,
  }) {
    late final borderStyle = Divider.createBorderSide(context);
    return PopulatedTableViewHorizontalDividerStyle(
      color: style?.color ?? base?.color ?? borderStyle.color,
      thickness: style?.thickness ?? base?.thickness ?? borderStyle.width,
    );
  }
}

class PopulatedTableViewVerticalDividersStyle
    extends TableViewVerticalDividersStyle {
  @override
  PopulatedTableViewVerticalDividerStyle get leading =>
      super.leading as PopulatedTableViewVerticalDividerStyle;

  PopulatedTableViewVerticalDividerStyle get trailing =>
      super.trailing as PopulatedTableViewVerticalDividerStyle;

  PopulatedTableViewVerticalDividersStyle({
    required PopulatedTableViewVerticalDividerStyle leadingDividerStyle,
    required PopulatedTableViewVerticalDividerStyle trailingDividerStyle,
  }) : super(
          leading: leadingDividerStyle,
          trailing: trailingDividerStyle,
        );

  factory PopulatedTableViewVerticalDividersStyle.of(
    BuildContext context, {
    required TableViewVerticalDividersStyle? base,
    required TableViewVerticalDividersStyle? style,
  }) =>
      PopulatedTableViewVerticalDividersStyle(
        leadingDividerStyle: PopulatedTableViewVerticalDividerStyle.of(
          context,
          base: base?.leading,
          style: style?.leading,
        ),
        trailingDividerStyle: PopulatedTableViewVerticalDividerStyle.of(
          context,
          base: base?.trailing,
          style: style?.trailing,
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
    required TableViewVerticalDividerStyle? base,
    required TableViewVerticalDividerStyle? style,
  }) {
    late final borderStyle = Divider.createBorderSide(context);
    return PopulatedTableViewVerticalDividerStyle(
      color: style?.color ?? base?.color ?? borderStyle.color,
      thickness: style?.thickness ?? base?.thickness ?? borderStyle.width,
      wigglesPerRow: style?.wigglesPerRow ?? base?.wigglesPerRow ?? 1,
      wiggleOffset: style?.wiggleOffset ?? base?.wiggleOffset ?? 16.0,
    );
  }
}

class PopulatedTableViewScrollbarsStyle extends TableViewScrollbarsStyle {
  @override
  PopulatedTableViewScrollbarStyle get horizontal =>
      super.horizontal as PopulatedTableViewScrollbarStyle;

  @override
  PopulatedTableViewScrollbarStyle get vertical =>
      super.vertical as PopulatedTableViewScrollbarStyle;

  PopulatedTableViewScrollbarsStyle({
    required PopulatedTableViewScrollbarStyle horizontal,
    required PopulatedTableViewScrollbarStyle vertical,
  }) : super(
          horizontal: horizontal,
          vertical: vertical,
        );

  factory PopulatedTableViewScrollbarsStyle.of(
    BuildContext context, {
    required TableViewScrollbarsStyle? base,
    required TableViewScrollbarsStyle? style,
  }) =>
      PopulatedTableViewScrollbarsStyle(
        horizontal: PopulatedTableViewScrollbarStyle.of(
          context,
          base: base?.horizontal,
          style: style?.horizontal,
        ),
        vertical: PopulatedTableViewScrollbarStyle.of(
          context,
          base: base?.vertical,
          style: style?.vertical,
        ),
      );
}

bool _resolveEnabled(BuildContext context, TableViewScrollbarEnabled enabled) {
  switch (enabled) {
    case TableViewScrollbarEnabled.always:
      return true;
    case TableViewScrollbarEnabled.auto:
      return [
        TargetPlatform.linux,
        TargetPlatform.macOS,
        TargetPlatform.windows
      ].contains(Theme.of(context).platform);
    case TableViewScrollbarEnabled.never:
      return false;
  }
}

class PopulatedTableViewScrollbarStyle extends TableViewScrollbarStyle {
  final bool effectivelyEnabled;

  @override
  TableViewScrollbarEnabled get enabled => super.enabled!;

  @override
  bool get thumbVisibility => super.thumbVisibility!;

  @override
  bool get trackVisibility => super.trackVisibility!;

  @override
  bool get interactive => super.interactive!;

  const PopulatedTableViewScrollbarStyle({
    required this.effectivelyEnabled,
    required TableViewScrollbarEnabled enabled,
    required bool thumbVisibility,
    required bool trackVisibility,
    super.thickness,
    super.radius,
    required bool interactive,
  }) : super(
          enabled: enabled,
          thumbVisibility: thumbVisibility,
          trackVisibility: trackVisibility,
          interactive: interactive,
        );

  factory PopulatedTableViewScrollbarStyle.of(
    BuildContext context, {
    TableViewScrollbarStyle? base,
    TableViewScrollbarStyle? style,
  }) {
    final enabled =
        style?.enabled ?? base?.enabled ?? TableViewScrollbarEnabled.always;
    return PopulatedTableViewScrollbarStyle(
      enabled: enabled,
      effectivelyEnabled: _resolveEnabled(context, enabled),
      thumbVisibility: style?.thumbVisibility ?? base?.thumbVisibility ?? true,
      trackVisibility: style?.trackVisibility ?? base?.trackVisibility ?? true,
      thickness: style?.thickness ?? base?.thickness,
      radius: style?.radius ?? base?.radius,
      interactive: style?.interactive ?? base?.interactive ?? true,
    );
  }
}
