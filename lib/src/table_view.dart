import 'package:flutter/material.dart';
import 'package:material_table_view/src/table_column.dart';
import 'package:material_table_view/src/table_content.dart';
import 'package:material_table_view/src/table_placeholder_shader_configuration.dart';
import 'package:material_table_view/src/table_typedefs.dart';
import 'package:material_table_view/src/table_view_controller.dart';

/// Material-style widget that displays its content in a both vertically and
/// horizontally scrollable table with fixed-width freezable columns.
///
/// This widget will try to expand to the highest constraints given.
class TableView extends StatefulWidget {
  const TableView.builder({
    super.key,
    required this.rowCount,
    required this.rowHeight,
    required this.columns,
    this.controller,
    required this.rowBuilder,
    this.placeholderBuilder,
    this.placeholderShaderConfig,
    this.bodyContainerBuilder = _defaultBodyContainerBuilder,
    this.headerBuilder,
    this.headerHeight,
    this.footerBuilder,
    this.footerHeight,
    this.minScrollableWidth,
    this.minScrollableWidthRatio = .6180339887498547,
    this.scrollPadding,
  })  : assert(rowCount >= 0),
        assert(rowHeight > 0),
        assert(headerHeight == null || headerHeight > 0),
        assert(footerHeight == null || footerHeight > 0),
        assert(minScrollableWidth == null || minScrollableWidth > 0),
        assert(minScrollableWidthRatio >= 0 && minScrollableWidthRatio <= 1);

  /// Count of fixed-height rows displayed in a table.
  final int rowCount;

  /// Height of each row displayed in a table.
  final double rowHeight;

  /// List of column descriptions to display in a table.
  final List<TableColumn> columns;

  /// Controller for the state of a table.
  final TableViewController? controller;

  /// A function that will be called on-demand for each row displayed
  /// in order to obtain a [TableCellBuilder] that will build a widget for
  /// a specified cell in that row.
  ///
  /// In case of this function returning null, the corresponding row will be
  // ignore: deprecated_member_use_from_same_package
  /// replaced with a placeholder, meaning that the [placeholderBuilder] must
  /// not be null. This enables additional behaviour described in a
  // ignore: deprecated_member_use_from_same_package
  /// [placeholderContainerBuilder] property.
  final TableRowBuilder rowBuilder;

  final TablePlaceholderBuilder? placeholderBuilder;

  final TableViewPlaceholderShaderConfig? placeholderShaderConfig;

  /// A function that will be called on-demand enabling wrapping vertically
  /// scrollable table body section that contains all visible rows including
  /// placeholders.
  ///
  /// This would usually wrap the body in [Material] widget.
  final TableBodyContainerBuilder bodyContainerBuilder;

  /// A function that will be called on-demand for each cell in a header
  /// in order to build a widget for that section of a header.
  ///
  /// If null, no header will be built.
  final TableHeaderBuilder? headerBuilder;

  /// Height of a header. If null, [rowHeight] will be used instead.
  final double? headerHeight;

  /// A function that will be called on-demand for each cell in a footer
  /// in order to build a widget for that section of a footer.
  ///
  /// If null, no footer will be built.
  final TableFooterBuilder? footerBuilder;

  /// Height of a footer. If null, [rowHeight] will be used instead.
  final double? footerHeight;

  /// Minimum scrollable width that may not be taken up by frozen columns.
  /// If a resulting scrollable width is less than this property, columns
  /// will be unfrozen according to freeze priority until scrollable width
  /// is greater than or equal to this property.
  ///
  /// If null, the [minScrollableWidthRatio] is used to calculate the minimum
  /// scrollable width, otherwise this property takes priority.
  final double? minScrollableWidth;

  /// Minimum scrollable width ratio in relation to the width of a table.
  /// Used to calculate [minScrollableWidth] depending on an overall table width
  /// if that property is null.
  final double minScrollableWidthRatio;

  /// Padding for the scrollable part of the table.
  /// Primarily used to leave space for the scrollbars.
  /// If null, predefined insets will be used based on a target platform.
  final EdgeInsets? scrollPadding;

  @override
  State<TableView> createState() => _TableViewState();
}

class _TableViewState extends State<TableView> {
  late TableViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = widget.controller ?? TableViewController();
  }

  @override
  void didUpdateWidget(covariant TableView oldWidget) {
    super.didUpdateWidget(oldWidget);

    _controller = widget.controller ?? _controller;
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: TableContent(
          controller: _controller,
          columns: widget.columns,
          minScrollableWidth: widget.minScrollableWidth,
          minScrollableWidthRatio: widget.minScrollableWidthRatio,
          rowCount: widget.rowCount,
          rowHeight: widget.rowHeight,
          rowBuilder: widget.rowBuilder,
          placeholderBuilder: widget.placeholderBuilder,
          placeholderShaderConfig: widget.placeholderShaderConfig,
          bodyContainerBuilder: widget.bodyContainerBuilder,
          headerBuilder: widget.headerBuilder,
          headerHeight: widget.headerHeight ?? widget.rowHeight,
          footerHeight: widget.footerHeight ?? widget.rowHeight,
          footerBuilder: widget.footerBuilder,
          scrollPadding:
              widget.scrollPadding ?? _determineScrollPadding(context),
        ),
      );

  EdgeInsets _determineScrollPadding(BuildContext context) {
    // TODO determining paddings for the scrollbars based on a target platform seems stupid
    switch (Theme.of(context).platform) {
      case TargetPlatform.android:
        return const EdgeInsets.only(right: 4.0, bottom: 4.0);
      case TargetPlatform.iOS:
        return const EdgeInsets.only(right: 6.0, bottom: 6.0);
      default:
        return const EdgeInsets.only(right: 14.0, bottom: 10.0);
    }
  }
}

Widget _defaultBodyContainerBuilder(
        BuildContext context, Widget bodyContainer) =>
    Material(child: bodyContainer);
