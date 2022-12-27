import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:material_table_view/material_table_view.dart';
import 'package:material_table_view/src/listenable_builder.dart';
import 'package:material_table_view/src/table_view.dart';

class TableViewport extends SingleChildRenderObjectWidget {
  final ViewportOffset verticalOffset, horizontalOffset;
  final List<TableColumn> columns;
  final int rowCount;
  final double rowHeight;

  TableViewport({
    super.key,
    required this.verticalOffset,
    required this.horizontalOffset,
    required this.columns,
    required this.rowCount,
    required this.rowHeight,
    required TableRowBuilder rowBuilder,
    required TableRowDecorator? rowDecorator,
    required TableCellBuilder? headerBuilder,
    required double? headerHeight,
    required TableHeaderDecorator? headerDecorator,
    required double? footerHeight,
    required TableCellBuilder? footerBuilder,
    required TableFooterDecorator? footerDecorator,
  }) : super(
          child: _TableViewportContent(
            verticalOffset: verticalOffset,
            horizontalOffset: horizontalOffset,
            columns: columns,
            rowCount: rowCount,
            rowHeight: rowHeight,
            rowBuilder: rowBuilder,
            rowDecorator: rowDecorator ?? _emptyRowDecorator,
            headerBuilder: headerBuilder,
            headerHeight: headerHeight ?? rowHeight,
            headerDecorator: headerDecorator ?? _emptyHeaderDecorator,
            footerHeight: footerHeight ?? rowHeight,
            footerBuilder: footerBuilder,
            footerDecorator: footerDecorator ?? _emptyHeaderDecorator,
          ),
        );

  @override
  RenderObject createRenderObject(BuildContext context) => RenderTableView(
        verticalOffset: verticalOffset,
        horizontalOffset: horizontalOffset,
        columns: columns,
        rowCount: rowCount,
        rowHeight: rowHeight,
      );

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderTableView renderObject) {
    super.updateRenderObject(context, renderObject);

    renderObject
      ..verticalOffset = verticalOffset
      ..horizontalOffset = horizontalOffset
      ..columns = columns
      ..rowCount = rowCount
      ..rowHeight = rowHeight
      ..markNeedsLayout();
  }
}

class RenderTableView extends RenderProxyBox {
  ViewportOffset verticalOffset, horizontalOffset;
  List<TableColumn> columns;
  int rowCount;
  double rowHeight;

  RenderTableView({
    required this.verticalOffset,
    required this.horizontalOffset,
    required this.columns,
    required this.rowCount,
    required this.rowHeight,
    RenderBox? child,
  }) : super(child);

  @override
  void performLayout() {
    super.performLayout();

    verticalOffset.applyViewportDimension(size.height);
    horizontalOffset.applyViewportDimension(size.width);

    verticalOffset.applyContentDimensions(
      0,
      max(0, rowCount * rowHeight - size.height),
    );
    horizontalOffset.applyContentDimensions(
      0,
      max(
          0,
          columns.fold<double>(
                  .0, (previousValue, column) => previousValue + column.width) -
              size.width),
    );
  }
}

Widget _emptyRowDecorator(Widget rowWidget, int _) => rowWidget;

Widget _emptyHeaderDecorator(Widget headerWidget) => headerWidget;

/// TODO replace crude Widget implementation to a RenderBox one
class _TableViewportContent extends StatelessWidget {
  final ViewportOffset verticalOffset, horizontalOffset;
  final List<TableColumn> columns;
  final int rowCount;
  final double rowHeight;
  final TableRowBuilder rowBuilder;
  final TableRowDecorator rowDecorator;
  final TableCellBuilder? headerBuilder;
  final double? headerHeight;
  final TableHeaderDecorator headerDecorator;
  final double? footerHeight;
  final TableCellBuilder? footerBuilder;
  final TableFooterDecorator footerDecorator;

  const _TableViewportContent({
    super.key,
    required this.verticalOffset,
    required this.horizontalOffset,
    required this.columns,
    required this.rowCount,
    required this.rowHeight,
    required this.rowBuilder,
    required this.rowDecorator,
    required this.headerBuilder,
    required this.headerHeight,
    required this.headerDecorator,
    required this.footerHeight,
    required this.footerBuilder,
    required this.footerDecorator,
  });

  @override
  Widget build(BuildContext context) => columns.isEmpty
      ? const SizedBox()
      : LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            return ListenableBuilder(
              listenable: horizontalOffset,
              builder: (context) {
                final horizontalOffsetPixels = horizontalOffset.pixels;

                double foldColumnsWidth(double previousValue, int index) =>
                    previousValue + columns[index].width;

                final columnsLeft = <int>[],
                    columnsCenter = <int>[],
                    columnsRight = <int>[];

                final columnOffsetsLeft = <double>[],
                    columnOffsetsCenter = <double>[],
                    columnOffsetsRight = <double>[];

                for (var i = 0,
                        leftOffset = .0,
                        centerOffset = -horizontalOffsetPixels,
                        rightOffset = .0;
                    i < columns.length;
                    i++) {
                  final column = columns[i];
                  if (column.fixed && centerOffset.isNegative) {
                    columnsLeft.add(i);
                    columnOffsetsLeft.add(leftOffset);
                    leftOffset += column.width;
                  } else if (leftOffset +
                          centerOffset +
                          (column.fixed ? column.width : 0) <=
                      width) {
                    if (centerOffset >= -column.width) {
                      columnsCenter.add(i);
                      columnOffsetsCenter.add(centerOffset);
                    }
                    centerOffset += column.width;
                  } else {
                    for (int j = columns.length - 1;
                        j + columnsRight.length > i - 2;
                        j--) {
                      final column = columns[j];
                      if (column.fixed) {
                        columnsRight.add(j);
                        rightOffset -= column.width;
                        columnOffsetsRight.add(rightOffset);
                      }
                    }

                    break;
                  }
                }

                final leftWidth =
                    columnsLeft.fold<double>(.0, foldColumnsWidth);
                final rightWidth =
                    columnsRight.fold<double>(.0, foldColumnsWidth);
                final centerWidth = width - leftWidth - rightWidth;

                final columnsFixed = columnsLeft
                    .followedBy(columnsRight)
                    .toList(growable: false);
                final columnOffsetsFixed = columnOffsetsLeft
                    .followedBy(columnOffsetsRight.map((e) => width + e))
                    .toList(growable: false);

                Iterable<Widget> columnMapper(
                  List<int> columns,
                  List<double> offsets,
                  TableCellBuilder cellBuilder,
                ) =>
                    Iterable.generate(columns.length).map((i) {
                      final columnIndex = columns[i];
                      return Positioned(
                        key: ValueKey<int>(columnIndex),
                        width: this.columns[columnIndex].width,
                        height: rowHeight,
                        left: offsets[i],
                        child: Builder(
                            builder: (context) =>
                                cellBuilder(context, columnIndex)),
                      );
                    });

                Widget buildRow(TableCellBuilder cellBuilder) =>
                    RepaintBoundary(
                      child: Stack(
                        fit: StackFit.expand,
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            left: leftWidth,
                            width: centerWidth,
                            height: rowHeight,
                            child: ClipRect(
                              child: Stack(
                                fit: StackFit.expand,
                                clipBehavior: Clip.none,
                                children: columnMapper(
                                  columnsCenter,
                                  columnOffsetsCenter,
                                  cellBuilder,
                                ).toList(growable: false),
                              ),
                            ),
                          ),
                          if (columnsFixed.isNotEmpty)
                            ...columnMapper(
                              columnsFixed,
                              columnOffsetsFixed,
                              cellBuilder,
                            ),
                        ],
                      ),
                    );

                final body = Material(
                  clipBehavior: Clip.hardEdge,
                  child: ListenableBuilder(
                    listenable: verticalOffset,
                    builder: (context) {
                      final verticalOffsetPixels = verticalOffset.pixels;

                      final startRowIndex =
                          max(0, (verticalOffsetPixels / rowHeight).floor());
                      final endRowIndex =
                          min(rowCount, startRowIndex + height / rowHeight);

                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          // TODO why am i doing that loop like that
                          for (var rowIndex = startRowIndex,
                                  rowOffset =
                                      -(verticalOffsetPixels % rowHeight);
                              rowIndex < endRowIndex;
                              () {
                            rowIndex++;
                            rowOffset += rowHeight;
                          }())
                            Positioned(
                              key: ValueKey<int>(rowIndex),
                              left: 0,
                              top: rowOffset,
                              width: width,
                              height: rowHeight,
                              child: rowDecorator(
                                  buildRow(rowBuilder(rowIndex)), rowIndex),
                            ),
                        ],
                      );
                    },
                  ),
                );

                final headerBuilder = this.headerBuilder;
                final footerBuilder = this.footerBuilder;
                if (headerBuilder == null && footerBuilder == null) {
                  return SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: body,
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (headerBuilder != null) ...[
                      SizedBox(
                        width: double.infinity,
                        height: headerHeight,
                        child: headerDecorator(buildRow(headerBuilder)),
                      ),
                      const Divider(
                        height: 2.0,
                        thickness: 2.0,
                      ), // TODO height
                    ],
                    Expanded(child: body),
                    if (footerBuilder != null) ...[
                      const Divider(
                        height: 2.0,
                        thickness: 2.0,
                      ), // TODO height
                      SizedBox(
                        width: double.infinity,
                        height: footerHeight,
                        child: footerDecorator(buildRow(footerBuilder)),
                      ),
                    ],
                  ],
                );
              },
            );
          },
        );
}
