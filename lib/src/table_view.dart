import 'package:flutter/material.dart';
import 'package:material_table_view/src/table_column.dart';
import 'package:material_table_view/src/table_typedefs.dart';
import 'package:material_table_view/src/table_view_controller.dart';
import 'package:material_table_view/src/table_viewport.dart';

const _defaultItemHeight = 56.0;
const _defaultDividerRevealOffset = 32.0;

/// Material-style widget that displays its content in a both vertically and
/// horizontally scrollable table with fixed-width freezable columns.
///
/// This widget will try to expand to the highest constraints given.
class TableView extends StatefulWidget {
  const TableView({
    super.key,
    this.controller,
    required this.columns,
    this.minScrollableWidth,
    this.minScrollableWidthRatio = .6180339887498547,
    required this.rowCount,
    this.rowHeight = _defaultItemHeight,
    required this.rowBuilder,
    this.rowDecorator,
    this.placeholderBuilder,
    this.placeholderDecorator,
    this.placeholderContainerBuilder,
    this.headerBuilder,
    this.headerHeight,
    this.headerDecorator,
    this.footerHeight,
    this.footerBuilder,
    this.footerDecorator,
    this.dividerRevealOffset = _defaultDividerRevealOffset,
  });

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
  /// replaced with a placeholder, meaning that the [placeholderBuilder] must
  /// not be null. This enables additional behaviour described in a
  /// [placeholderContainerBuilder] property.
  final TableRowBuilder rowBuilder;

  /// A function that will be called on-demand for each row displayed
  /// in order to enable custom behaviour like row background or click handling
  /// by wrapping already built row widget passed as an argument in
  /// a [ColoredBox] or [InkWell], for example.
  final TableRowDecorator? rowDecorator;

  /// A function that will be called on-demand for each cell in a placeholder
  /// row in order to obtains a widget for that cell.
  final TableCellBuilder? placeholderBuilder;

  /// A function that will be called on-demand for each placeholder row displayed
  /// in order to enable custom behaviour like row background or click handling
  /// by wrapping already built row widget passed as an argument in
  /// a [ColoredBox] or [InkWell], for example.
  final TablePlaceholderDecorator? placeholderDecorator;

  /// A function that will be called on-demand in order to enable custom
  /// placeholder behaviour by wrapping already built widget that contains
  /// all visible placeholder rows with required offsets passed as an argument.
  ///
  /// For example, this can be used to wrap placeholders in a shimmer widget
  /// of your choice.
  final TablePlaceholderContainerBuilder? placeholderContainerBuilder;

  /// A function that will be called on-demand for each cell in a header
  /// in order to build a widget for that section of a header.
  ///
  /// If null, no header will be built.
  final TableCellBuilder? headerBuilder;

  /// Height of a header. If null, [rowHeight] will be used instead.
  final double? headerHeight;

  /// A function that will be called on-demand for a header row widget
  /// in order to enable custom behaviour like header background or click handling
  /// by wrapping already built header widget passed as an argument.
  final TableHeaderDecorator? headerDecorator;

  /// A function that will be called on-demand for each cell in a footer
  /// in order to build a widget for that section of a footer.
  ///
  /// If null, no footer will be built.
  final TableCellBuilder? footerBuilder;

  /// Height of a footer. If null, [rowHeight] will be used instead.
  final double? footerHeight;

  /// A function that will be called on-demand for a footer row widget
  /// in order to enable custom behaviour like footer background or click handling
  /// by wrapping already built footer widget passed as an argument.
  final TableFooterDecorator? footerDecorator;

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

  /// Horizontal offset required for the divider separating frozen and
  /// scrollable columns to fully appear.
  final double dividerRevealOffset;

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
        child: TableViewport(
          controller: _controller,
          columns: widget.columns,
          minScrollableWidth: widget.minScrollableWidth,
          minScrollableWidthRatio: widget.minScrollableWidthRatio,
          rowCount: widget.rowCount,
          rowHeight: widget.rowHeight,
          rowBuilder: widget.rowBuilder,
          rowDecorator: widget.rowDecorator ?? _emptyRowDecorator,
          placeholderBuilder: widget.placeholderBuilder,
          placeholderDecorator:
              widget.placeholderDecorator ?? _emptyRowDecorator,
          placeholderContainerBuilder: widget.placeholderContainerBuilder,
          headerBuilder: widget.headerBuilder,
          headerHeight: widget.headerHeight ?? widget.rowHeight,
          headerDecorator: widget.headerDecorator ?? _emptyHeaderDecorator,
          footerHeight: widget.footerHeight ?? widget.rowHeight,
          footerBuilder: widget.footerBuilder,
          footerDecorator: widget.footerDecorator ?? _emptyFooterDecorator,
          dividerRevealOffset: widget.dividerRevealOffset,
        ),
      );
}

Widget _emptyRowDecorator(Widget rowWidget, int _) => rowWidget;

Widget _emptyHeaderDecorator(Widget headerWidget) => headerWidget;

TableFooterDecorator _emptyFooterDecorator = _emptyHeaderDecorator;
