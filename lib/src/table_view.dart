import 'package:flutter/material.dart';
import 'package:material_table_view/src/table_column.dart';
import 'package:material_table_view/src/table_typedefs.dart';
import 'package:material_table_view/src/table_view_controller.dart';
import 'package:material_table_view/src/table_viewport.dart';

const _defaultItemHeight = 56.0;
const _defaultDividerRevealOffset = 32.0;

class TableView extends StatefulWidget {
  final int rowCount;
  final double rowHeight;
  final List<TableColumn> columns;
  final TableViewController? controller;
  final TableRowBuilder rowBuilder;
  final TableRowDecorator? rowDecorator;
  final TableCellBuilder? placeholderBuilder;
  final TablePlaceholderDecorator? placeholderDecorator;
  final TablePlaceholderContainerBuilder? placeholderContainerBuilder;
  final TableCellBuilder? headerBuilder;
  final double? headerHeight;
  final TableHeaderDecorator? headerDecorator;
  final double? footerHeight;
  final TableCellBuilder? footerBuilder;
  final TableFooterDecorator? footerDecorator;
  final double? minScrollableWidth;
  final double minScrollableWidthRatio;
  final double dividerRevealOffset;

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
