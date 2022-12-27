import 'package:flutter/material.dart';
import 'package:material_table_view/src/table_column.dart';
import 'package:material_table_view/src/table_view_controller.dart';
import 'package:material_table_view/src/table_viewport.dart';

const _defaultItemHeight = 56.0;

typedef TableCellBuilder = Widget Function(BuildContext context, int column);
typedef TableRowBuilder = TableCellBuilder Function(int row);

typedef TableRowDecorator = Widget Function(Widget rowWidget, int rowIndex);
typedef TableHeaderDecorator = Widget Function(Widget headerWidget);

class TableView extends StatefulWidget {
  final int rowCount;
  final double rowHeight;
  final List<TableColumn> columns;
  final TableViewController? controller;
  final TableRowBuilder rowBuilder;
  final TableRowDecorator? rowDecorator;
  final TableCellBuilder? headerBuilder;
  final double? headerHeight;
  final TableHeaderDecorator? headerDecorator;

  const TableView({
    super.key,
    this.controller,
    required this.columns,
    required this.rowCount,
    this.rowHeight = _defaultItemHeight,
    required this.rowBuilder,
    this.rowDecorator,
    this.headerBuilder,
    this.headerHeight,
    this.headerDecorator,
  }) : assert((headerBuilder == null) == (headerHeight == null));

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
        child: Scrollbar(
          controller: _controller.verticalScrollController,
          scrollbarOrientation: ScrollbarOrientation.right,
          thumbVisibility: true,
          trackVisibility: true,
          child: Scrollbar(
            controller: _controller.horizontalScrollController,
            scrollbarOrientation: ScrollbarOrientation.bottom,
            thumbVisibility: true,
            trackVisibility: true,
            child: Scrollable(
              axisDirection: AxisDirection.down,
              controller: _controller.verticalScrollController,
              viewportBuilder: (context, verticalOffset) => Scrollable(
                axisDirection: AxisDirection.right,
                controller: _controller.horizontalScrollController,
                viewportBuilder: (context, horizontalOffset) => TableViewport(
                  verticalOffset: verticalOffset,
                  horizontalOffset: horizontalOffset,
                  columns: widget.columns,
                  rowCount: widget.rowCount,
                  rowHeight: widget.rowHeight,
                  rowBuilder: widget.rowBuilder,
                  rowDecorator: widget.rowDecorator,
                  headerBuilder: widget.headerBuilder,
                  headerHeight: widget.headerHeight,
                  headerDecorator: widget.headerDecorator,
                ),
              ),
            ),
          ),
        ),
      );
}
