import 'package:flutter/material.dart';
import 'package:material_table_view/src/table_view_style.dart';

double _guessScrollbarThickness(BuildContext context, bool vertical,
    ResolvedTableViewScrollbarStyle style) {
  if (!style.scrollPadding) return .0;

  final thickness = style.thickness?.resolve(const {});
  if (thickness != null) return thickness;

  // TODO determining paddings for the scrollbars based on a target platform seems stupid
  switch (Theme.of(context).platform) {
    case TargetPlatform.android:
      return 4.0;
    case TargetPlatform.iOS:
      return 6.0;
    default:
      return vertical ? 14.0 : 10.0;
  }
}

class ResolvedTableViewStyle extends TableViewStyle {
  @override
  ResolvedTableViewDividersStyle get dividers =>
      super.dividers as ResolvedTableViewDividersStyle;

  @override
  ResolvedTableViewScrollbarsStyle get scrollbars =>
      super.scrollbars as ResolvedTableViewScrollbarsStyle;

  @override
  EdgeInsets get scrollPadding => super.scrollPadding!;

  @override
  double get minScrollableWidthRatio => super.minScrollableWidthRatio!;

  const ResolvedTableViewStyle({
    required ResolvedTableViewDividersStyle dividers,
    required ResolvedTableViewScrollbarsStyle scrollbars,
    required EdgeInsets scrollPadding,
    required double minScrollableWidthRatio,
  }) : super(
          dividers: dividers,
          scrollbars: scrollbars,
          scrollPadding: scrollPadding,
          minScrollableWidthRatio: minScrollableWidthRatio,
        );

  factory ResolvedTableViewStyle.of(
    BuildContext context, {
    required TableViewStyle? style,
    required bool sliver,
  }) {
    final base = Theme.of(context).extension<TableViewStyle>();
    final scrollbars = ResolvedTableViewScrollbarsStyle.of(
      context,
      base: base?.scrollbars,
      style: style?.scrollbars,
      sliver: sliver,
    );

    return ResolvedTableViewStyle(
      dividers: ResolvedTableViewDividersStyle.of(
        context,
        base: base?.dividers,
        style: style?.dividers,
      ),
      scrollbars: scrollbars,
      scrollPadding: (style?.scrollPadding ??
              base?.scrollPadding ??
              EdgeInsets.zero) +
          EdgeInsets.only(
            right: sliver // we have no way of knowing the size of a scrollbar
                ? .0 // so we just give up
                : _guessScrollbarThickness(context, true, scrollbars.vertical),
            bottom:
                _guessScrollbarThickness(context, false, scrollbars.horizontal),
          ),
      minScrollableWidthRatio: style?.minScrollableWidthRatio ??
          base?.minScrollableWidthRatio ??
          .6180339887498547,
    );
  }
}

class ResolvedTableViewDividersStyle extends TableViewDividersStyle {
  @override
  ResolvedTableViewHorizontalDividersStyle get horizontal =>
      super.horizontal as ResolvedTableViewHorizontalDividersStyle;

  @override
  ResolvedTableViewVerticalDividersStyle get vertical =>
      super.vertical as ResolvedTableViewVerticalDividersStyle;

  const ResolvedTableViewDividersStyle({
    required ResolvedTableViewHorizontalDividersStyle horizontalDividersStyle,
    required ResolvedTableViewVerticalDividersStyle verticalDividersStyle,
  }) : super(
          horizontal: horizontalDividersStyle,
          vertical: verticalDividersStyle,
        );

  factory ResolvedTableViewDividersStyle.of(
    BuildContext context, {
    required TableViewDividersStyle? base,
    required TableViewDividersStyle? style,
  }) =>
      ResolvedTableViewDividersStyle(
        horizontalDividersStyle: ResolvedTableViewHorizontalDividersStyle.of(
          context,
          base: base?.horizontal,
          style: style?.horizontal,
        ),
        verticalDividersStyle: ResolvedTableViewVerticalDividersStyle.of(
          context,
          base: base?.vertical,
          style: style?.vertical,
        ),
      );
}

class ResolvedTableViewHorizontalDividersStyle
    extends TableViewHorizontalDividersStyle {
  @override
  ResolvedTableViewHorizontalDividerStyle get header =>
      super.header as ResolvedTableViewHorizontalDividerStyle;

  @override
  ResolvedTableViewHorizontalDividerStyle get footer =>
      super.footer as ResolvedTableViewHorizontalDividerStyle;

  double get space => header.space + footer.space;

  const ResolvedTableViewHorizontalDividersStyle({
    required ResolvedTableViewHorizontalDividerStyle headerDividerStyle,
    required ResolvedTableViewHorizontalDividerStyle footerDividerStyle,
  }) : super(
          header: headerDividerStyle,
          footer: footerDividerStyle,
        );

  factory ResolvedTableViewHorizontalDividersStyle.of(
    BuildContext context, {
    required TableViewHorizontalDividersStyle? base,
    required TableViewHorizontalDividersStyle? style,
  }) =>
      ResolvedTableViewHorizontalDividersStyle(
        headerDividerStyle: ResolvedTableViewHorizontalDividerStyle.of(
          context,
          base: base?.header,
          style: style?.header,
        ),
        footerDividerStyle: ResolvedTableViewHorizontalDividerStyle.of(
          context,
          base: base?.footer,
          style: style?.footer,
        ),
      );
}

class ResolvedTableViewHorizontalDividerStyle
    extends TableViewHorizontalDividerStyle {
  @override
  Color get color => super.color!;

  @override
  double get thickness => super.thickness!;

  @override
  double get space => super.space!;

  @override
  double get indent => super.indent!;

  @override
  double get endIndent => super.endIndent!;

  const ResolvedTableViewHorizontalDividerStyle({
    required super.enabled,
    required Color color,
    required double thickness,
    required double space,
    required double indent,
    required double endIndent,
  }) : super(
          color: color,
          thickness: thickness,
          space: space,
          indent: indent,
          endIndent: endIndent,
        );

  factory ResolvedTableViewHorizontalDividerStyle.of(
    BuildContext context, {
    required TableViewHorizontalDividerStyle? base,
    required TableViewHorizontalDividerStyle? style,
  }) {
    final enabled = style?.enabled ?? base?.enabled ?? true;

    late final borderStyle = Divider.createBorderSide(context);
    final thickness =
        enabled ? style?.thickness ?? base?.thickness ?? borderStyle.width : .0;
    return ResolvedTableViewHorizontalDividerStyle(
      enabled: enabled,
      color: enabled
          ? style?.color ?? base?.color ?? borderStyle.color
          : Colors.transparent,
      thickness: thickness,
      space: enabled ? style?.space ?? base?.space ?? thickness : .0,
      indent: enabled ? style?.indent ?? base?.indent ?? .0 : .0,
      endIndent: enabled ? style?.endIndent ?? base?.endIndent ?? .0 : .0,
    );
  }
}

class ResolvedTableViewVerticalDividersStyle
    extends TableViewVerticalDividersStyle {
  @override
  ResolvedTableViewVerticalDividerStyle get leading =>
      super.leading as ResolvedTableViewVerticalDividerStyle;

  @override
  ResolvedTableViewVerticalDividerStyle get trailing =>
      super.trailing as ResolvedTableViewVerticalDividerStyle;

  const ResolvedTableViewVerticalDividersStyle({
    required ResolvedTableViewVerticalDividerStyle leadingDividerStyle,
    required ResolvedTableViewVerticalDividerStyle trailingDividerStyle,
  }) : super(
          leading: leadingDividerStyle,
          trailing: trailingDividerStyle,
        );

  factory ResolvedTableViewVerticalDividersStyle.of(
    BuildContext context, {
    required TableViewVerticalDividersStyle? base,
    required TableViewVerticalDividersStyle? style,
  }) =>
      ResolvedTableViewVerticalDividersStyle(
        leadingDividerStyle: ResolvedTableViewVerticalDividerStyle.of(
          context,
          base: base?.leading,
          style: style?.leading,
        ),
        trailingDividerStyle: ResolvedTableViewVerticalDividerStyle.of(
          context,
          base: base?.trailing,
          style: style?.trailing,
        ),
      );
}

class ResolvedTableViewVerticalDividerStyle
    extends TableViewVerticalDividerStyle {
  @override
  Color get color => super.color!;

  @override
  double get thickness => super.thickness!;

  @override
  int get wiggleCount => super.wiggleCount!;

  @override
  double get wiggleOffset => super.wiggleOffset!;

  @override
  double get revealOffset => super.revealOffset!;

  @override
  Curve get opacityRevealCurve => super.opacityRevealCurve!;

  @override
  Curve get wiggleRevealCurve => super.wiggleRevealCurve!;

  const ResolvedTableViewVerticalDividerStyle({
    required Color color,
    required double thickness,
    required super.wiggleInterval,
    required int wiggleCount,
    required double wiggleOffset,
    required double revealOffset,
    required Curve opacityRevealCurve,
    required Curve wiggleRevealCurve,
  }) : super(
          color: color,
          wiggleCount: wiggleCount,
          thickness: thickness,
          wiggleOffset: wiggleOffset,
          revealOffset: revealOffset,
          opacityRevealCurve: opacityRevealCurve,
          wiggleRevealCurve: wiggleRevealCurve,
        );

  factory ResolvedTableViewVerticalDividerStyle.of(
    BuildContext context, {
    required TableViewVerticalDividerStyle? base,
    required TableViewVerticalDividerStyle? style,
  }) {
    late final borderStyle = Divider.createBorderSide(context);
    final wiggleOffset = style?.wiggleOffset ?? base?.wiggleOffset ?? 16.0;
    return ResolvedTableViewVerticalDividerStyle(
      color: style?.color ?? base?.color ?? borderStyle.color,
      thickness: style?.thickness ?? base?.thickness ?? borderStyle.width,
      wiggleInterval: style?.wiggleInterval ?? base?.wiggleInterval,
      wiggleCount: style?.wiggleCount ?? base?.wiggleCount ?? 1,
      wiggleOffset: wiggleOffset,
      revealOffset: style?.revealOffset ?? base?.revealOffset ?? wiggleOffset,
      opacityRevealCurve: style?.opacityRevealCurve ??
          base?.opacityRevealCurve ??
          Curves.easeIn,
      wiggleRevealCurve:
          style?.wiggleRevealCurve ?? base?.wiggleRevealCurve ?? Curves.linear,
    );
  }
}

class ResolvedTableViewScrollbarsStyle extends TableViewScrollbarsStyle {
  @override
  ResolvedTableViewScrollbarStyle get horizontal =>
      super.horizontal as ResolvedTableViewScrollbarStyle;

  @override
  ResolvedTableViewScrollbarStyle get vertical =>
      super.vertical as ResolvedTableViewScrollbarStyle;

  const ResolvedTableViewScrollbarsStyle({
    required ResolvedTableViewScrollbarStyle horizontal,
    required ResolvedTableViewScrollbarStyle? vertical,
  }) : super(
          horizontal: horizontal,
          vertical: vertical,
        );

  factory ResolvedTableViewScrollbarsStyle.of(
    BuildContext context, {
    required TableViewScrollbarsStyle? base,
    required TableViewScrollbarsStyle? style,
    required bool sliver,
  }) =>
      ResolvedTableViewScrollbarsStyle(
        horizontal: ResolvedTableViewScrollbarStyle.of(
          context,
          base: base?.horizontal,
          style: style?.horizontal,
        ),
        vertical: sliver
            ? null
            : ResolvedTableViewScrollbarStyle.of(
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

class ResolvedTableViewScrollbarStyle extends TableViewScrollbarStyle {
  final bool effectivelyEnabled;

  @override
  bool get scrollPadding => super.scrollPadding!;

  const ResolvedTableViewScrollbarStyle({
    required this.effectivelyEnabled,
    super.enabled,
    required bool scrollPadding,
    super.crossAxisMargin,
    super.interactive,
    super.mainAxisMargin,
    super.minThumbLength,
    super.radius,
    super.thickness,
    super.thumbColor,
    super.thumbVisibility,
    super.trackBorderColor,
    super.trackColor,
    super.trackVisibility,
  }) : super(
          scrollPadding: scrollPadding,
        );

  factory ResolvedTableViewScrollbarStyle.of(
    BuildContext context, {
    TableViewScrollbarStyle? base,
    TableViewScrollbarStyle? style,
  }) {
    final enabled =
        style?.enabled ?? base?.enabled ?? TableViewScrollbarEnabled.always;
    final effectivelyEnabled = _resolveEnabled(context, enabled);
    return ResolvedTableViewScrollbarStyle(
      enabled: enabled,
      effectivelyEnabled: effectivelyEnabled,
      scrollPadding: effectivelyEnabled &&
          (style?.scrollPadding ?? base?.scrollPadding ?? true),
      thumbVisibility: style?.thumbVisibility ?? base?.thumbVisibility,
      thickness: style?.thickness ?? base?.thickness,
      trackVisibility: style?.trackVisibility ?? base?.trackVisibility,
      interactive: style?.interactive ?? base?.interactive,
      radius: style?.radius ?? base?.radius,
      thumbColor: style?.thumbColor ?? base?.thumbColor,
      trackColor: style?.trackColor ?? base?.trackColor,
      trackBorderColor: style?.trackBorderColor ?? base?.trackBorderColor,
      crossAxisMargin: style?.crossAxisMargin ?? base?.crossAxisMargin,
      mainAxisMargin: style?.mainAxisMargin ?? base?.mainAxisMargin,
      minThumbLength: style?.minThumbLength ?? base?.minThumbLength,
    );
  }
}
