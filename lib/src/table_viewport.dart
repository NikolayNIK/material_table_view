import 'dart:math';

import 'package:flutter/material.dart';
import 'package:material_table_view/src/iterator_extensions.dart';
import 'package:material_table_view/src/listenable_builder.dart';
import 'package:material_table_view/src/scroll_dimensions_applicator.dart';
import 'package:material_table_view/src/table_column.dart';
import 'package:material_table_view/src/table_typedefs.dart';
import 'package:material_table_view/src/table_view_controller.dart';
import 'package:material_table_view/src/wiggly_divider_painter.dart';
import 'package:material_table_view/src/wiggly_row_clipper.dart';

/// TODO replace crude Widget implementation with a RenderBox one
class TableViewport extends StatelessWidget {
  final TableViewController controller;
  final List<TableColumn> columns;
  final double? minScrollableWidth;
  final double minScrollableWidthRatio;
  final int rowCount;
  final double rowHeight;
  final TableRowBuilder rowBuilder;
  final TablePlaceholderBuilder? placeholderBuilder;
  final TablePlaceholderContainerBuilder? placeholderContainerBuilder;
  final TableHeaderBuilder? headerBuilder;
  final double headerHeight;
  final double footerHeight;
  final TableFooterBuilder? footerBuilder;
  final double dividerRevealOffset;
  final EdgeInsets scrollPadding;

  const TableViewport({
    super.key,
    required this.controller,
    required this.columns,
    required this.minScrollableWidth,
    required this.minScrollableWidthRatio,
    required this.rowCount,
    required this.rowHeight,
    required this.rowBuilder,
    required this.placeholderBuilder,
    required this.placeholderContainerBuilder,
    required this.headerBuilder,
    required this.headerHeight,
    required this.footerHeight,
    required this.footerBuilder,
    required this.dividerRevealOffset,
    required this.scrollPadding,
  });

  @override
  Widget build(BuildContext context) => columns.isEmpty
      ? const SizedBox()
      : LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            final dividerThickness =
                Theme.of(context).dividerTheme.thickness ?? 2.0;
            final halfDividerThickness = dividerThickness / 2.0;
            final dividerColor = Theme.of(context).dividerTheme.color ??
                Theme.of(context).dividerColor;

            late final int freezePriority;
            {
              final minScrollableWidth = max(
                16.0,
                this.minScrollableWidth ?? minScrollableWidthRatio * width,
              );

              final priorities = columns
                  .map((e) => e.freezePriority)
                  .where((element) => element != 0)
                  .toSet()
                  .toList(growable: false)
                ..sort();

              int priority = 0;
              final iterator = priorities.iterator;
              while (true) {
                if (width -
                        columns
                            .where((element) => element.frozenAt(priority))
                            .fold<double>(
                                .0,
                                (previousValue, element) =>
                                    previousValue + element.width) >
                    minScrollableWidth) {
                  break;
                }

                if (iterator.moveNext()) {
                  priority = iterator.current;
                } else {
                  break;
                }
              }

              freezePriority = priority;
            }

            final columnsWidth = columns.fold<double>(
                .0, (previousValue, element) => previousValue + element.width);

            final horizontalScrollbarOffset = Offset(
              0,
              footerBuilder == null ? 0 : footerHeight,
            );

            return Transform.translate(
              offset: -horizontalScrollbarOffset,
              transformHitTests: false,
              child: Scrollbar(
                controller: controller.horizontalScrollController,
                interactive: true,
                trackVisibility: true,
                thumbVisibility: true,
                child: Transform.translate(
                  offset: horizontalScrollbarOffset,
                  transformHitTests: false,
                  child: Scrollable(
                    controller: controller.horizontalScrollController,
                    clipBehavior: Clip.none,
                    axisDirection: AxisDirection.right,
                    viewportBuilder: (context, horizontalOffset) =>
                        ScrollDimensionsApplicator(
                      position: controller.horizontalScrollController.position,
                      axis: Axis.horizontal,
                      scrollExtent: columnsWidth + scrollPadding.horizontal,
                      child: XListenableBuilder(
                        listenable: horizontalOffset,
                        builder: (context, _) {
                          final horizontalOffsetPixels =
                              horizontalOffset.pixels;

                          double foldColumnsWidth(
                                  double previousValue, int index) =>
                              previousValue + columns[index].width;

                          final columnsLeft = <int>[],
                              columnsCenter = <int>[],
                              columnsRight = <int>[];

                          final columnOffsetsLeft = <double>[],
                              columnOffsetsCenter = <double>[],
                              columnOffsetsRight = <double>[];

                          for (var i = 0,
                                  leftOffset = scrollPadding.left,
                                  centerOffset = -horizontalOffsetPixels,
                                  rightOffset = -scrollPadding.right;
                              i < columns.length;
                              i++) {
                            final column = columns[i];
                            if (column.frozenAt(freezePriority) &&
                                centerOffset.isNegative) {
                              columnsLeft.add(i);
                              columnOffsetsLeft.add(leftOffset);
                              leftOffset += column.width;
                            } else if (leftOffset +
                                    centerOffset +
                                    (column.frozenAt(freezePriority)
                                        ? column.width + scrollPadding.right
                                        : 0) <=
                                width) {
                              if (centerOffset >= -column.width) {
                                columnsCenter.add(i);
                                columnOffsetsCenter.add(centerOffset);
                              }
                              centerOffset += column.width;
                            } else {
                              i = max(0, i - 2);
                              for (int j = columns.length - 1; j > i; j--) {
                                final column = columns[j];
                                if (column.frozenAt(freezePriority)) {
                                  columnsRight.add(j);
                                  rightOffset -= column.width;
                                  columnOffsetsRight.add(rightOffset);

                                  final maxVisibleOffset =
                                      width - leftOffset + rightOffset;
                                  while (columnsCenter.isNotEmpty &&
                                      columnOffsetsCenter.last >
                                          maxVisibleOffset) {
                                    columnsCenter.removeLast();
                                    columnOffsetsCenter.removeLast();
                                    i--;
                                  }
                                }
                              }

                              break;
                            }
                          }

                          final leftWidth = columnsLeft.isEmpty
                              ? .0
                              : columnsLeft.fold<double>(.0, foldColumnsWidth) +
                                  scrollPadding.left;
                          final rightWidth = columnsRight.isEmpty
                              ? .0
                              : columnsRight.fold<double>(
                                      .0, foldColumnsWidth) +
                                  scrollPadding.right;
                          final centerWidth = width - leftWidth - rightWidth;

                          if (columnsLeft.isEmpty) {
                            for (var i = 0;
                                i < columnOffsetsCenter.length;
                                i++) {
                              columnOffsetsCenter[i] =
                                  columnOffsetsCenter[i] + scrollPadding.left;
                            }
                          }

                          final columnsFixed = columnsLeft
                              .followedBy(columnsRight)
                              .toList(growable: false);
                          final columnOffsetsFixed = columnOffsetsLeft
                              .followedBy(
                                  columnOffsetsRight.map((e) => width + e))
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

                          final Color leftDividerColor, rightDividerColor;
                          final double leftDividerWiggleOffset,
                              rightDividerWiggleOffset;
                          {
                            double leftDividerAnimationValue = .0;
                            if (columnsLeft.isNotEmpty) {
                              if (dividerRevealOffset == .0) {
                                leftDividerAnimationValue = 1.0;
                              } else {
                                final toFreeze =
                                    Iterable.generate(columnsCenter.length)
                                        .where((i) => columns[columnsCenter[i]]
                                            .frozenAt(freezePriority))
                                        .maybeFirst;

                                if (toFreeze == null) {
                                  leftDividerAnimationValue =
                                      columnsLeft.isEmpty ? .0 : 1.0;
                                } else {
                                  leftDividerAnimationValue = max(
                                      0.0,
                                      min(
                                          1.0,
                                          columnOffsetsCenter[toFreeze] /
                                              dividerRevealOffset));
                                }

                                if (columnsLeft.isNotEmpty &&
                                    columnsCenter.isNotEmpty &&
                                    columnsLeft.last + 1 ==
                                        columnsCenter.first) {
                                  leftDividerAnimationValue = min(
                                      leftDividerAnimationValue,
                                      max(
                                          .0,
                                          min(
                                              1.0,
                                              -columnOffsetsCenter.first /
                                                  dividerRevealOffset)));
                                }
                              }
                            }

                            leftDividerColor = dividerColor.withOpacity(
                                dividerColor.opacity *
                                    Curves.easeIn
                                        .transform(leftDividerAnimationValue));
                            leftDividerWiggleOffset = min(
                                16.0,
                                max(
                                    .0,
                                    leftDividerAnimationValue *
                                        dividerRevealOffset));

                            double rightDividerAnimationValue = .0;
                            if (columnsRight.isNotEmpty) {
                              if (dividerRevealOffset == 0) {
                                rightDividerAnimationValue = 1.0;
                              } else {
                                final toFreeze = Iterable.generate(
                                        columnsCenter.length,
                                        (index) =>
                                            columnsCenter.length - index - 1)
                                    .where((i) => columns[columnsCenter[i]]
                                        .frozenAt(freezePriority))
                                    .maybeFirst;

                                if (toFreeze == null) {
                                  rightDividerAnimationValue = 1.0;
                                } else {
                                  rightDividerAnimationValue = max(
                                      .0,
                                      min(
                                          1.0,
                                          (centerWidth -
                                                  columnOffsetsCenter[
                                                      toFreeze] -
                                                  columns[columnsCenter[
                                                          toFreeze]]
                                                      .width) /
                                              dividerRevealOffset));
                                }

                                if (columnsRight.isNotEmpty &&
                                    columnsCenter.isNotEmpty &&
                                    columnsRight.last - 1 ==
                                        columnsCenter.last) {
                                  rightDividerAnimationValue = min(
                                      rightDividerAnimationValue,
                                      max(
                                          .0,
                                          min(
                                              1.0,
                                              (-centerWidth +
                                                      columnOffsetsCenter.last +
                                                      columns[columnsCenter
                                                              .last]
                                                          .width) /
                                                  dividerRevealOffset)));
                                }
                              }
                            }

                            rightDividerColor = dividerColor.withOpacity(
                                dividerColor.opacity *
                                    Curves.easeIn
                                        .transform(rightDividerAnimationValue));
                            rightDividerWiggleOffset = min(
                                16.0,
                                max(
                                    .0,
                                    rightDividerAnimationValue *
                                        dividerRevealOffset));
                          }

                          final contentClipper = WigglyRowClipper(
                            wiggleLeftOffset: leftDividerWiggleOffset,
                            wiggleRightOffset: rightDividerWiggleOffset,
                          );

                          final TableRowContentBuilder contentBuilder =
                              (BuildContext context,
                                      TableCellBuilder cellBuilder) =>
                                  RepaintBoundary(
                                    child: Stack(
                                      fit: StackFit.expand,
                                      clipBehavior: Clip.none,
                                      children: [
                                        Positioned(
                                          key: const ValueKey<int>(-1),
                                          left: leftWidth,
                                          width: centerWidth,
                                          height: rowHeight,
                                          child: RepaintBoundary(
                                            child: ClipPath(
                                              clipper: contentClipper,
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

                          late int previousStartRowIndex, previousEndRowIndex;
                          late List<Widget?> previousRows, previousPlaceholders;
                          var hasCache = false;

                          final body = Material(
                            clipBehavior: Clip.hardEdge,
                            child: NotificationListener<OverscrollNotification>(
                              // Suppress OverscrollNotification events that escape from the inner scrollable
                              onNotification: (notification) => true,
                              child: Scrollbar(
                                controller: controller.verticalScrollController,
                                interactive: true,
                                thumbVisibility: true,
                                trackVisibility: true,
                                child: Scrollable(
                                  controller:
                                      controller.verticalScrollController,
                                  clipBehavior: Clip.none,
                                  axisDirection: AxisDirection.down,
                                  viewportBuilder: (context, verticalOffset) =>
                                      ScrollDimensionsApplicator(
                                    position: controller
                                        .verticalScrollController.position,
                                    axis: Axis.vertical,
                                    scrollExtent: rowCount * rowHeight +
                                        scrollPadding.vertical,
                                    child: RepaintBoundary(
                                      child: ClipRect(
                                        child: XListenableBuilder(
                                          listenable: verticalOffset,
                                          builder: (context, _) {
                                            final verticalOffsetPixels =
                                                verticalOffset.pixels -
                                                    scrollPadding.top;

                                            final startRowIndex =
                                                (verticalOffsetPixels /
                                                        rowHeight)
                                                    .floor();
                                            final endRowIndex = min<int>(
                                                rowCount,
                                                startRowIndex +
                                                    (height / rowHeight)
                                                        .ceil());

                                            final rows = List<Widget?>.filled(
                                                    endRowIndex - startRowIndex,
                                                    null),
                                                placeholders =
                                                    List<Widget?>.filled(
                                                        rows.length, null);

                                            final cacheIndexOffset = hasCache
                                                ? startRowIndex -
                                                    previousStartRowIndex
                                                : 0;

                                            final children = <Widget>[];
                                            {
                                              final placeholderChildren =
                                                  <Widget>[];

                                              double rowOffset =
                                                  -(verticalOffsetPixels %
                                                          rowHeight) -
                                                      (startRowIndex < 0
                                                          ? startRowIndex *
                                                              rowHeight
                                                          : 0);
                                              for (var rowIndex =
                                                      max(0, startRowIndex);
                                                  rowIndex < endRowIndex;
                                                  rowIndex++) {
                                                final screenIndex =
                                                    rowIndex - startRowIndex;
                                                final cachedIndex = hasCache
                                                    ? screenIndex +
                                                        cacheIndexOffset
                                                    : 0;
                                                // TODO try to split up cached into different loop to avoid checking every row
                                                final cached = hasCache &&
                                                    cachedIndex >= 0 &&
                                                    cachedIndex <
                                                        previousRows.length;

                                                final rowWidget =
                                                    rows[screenIndex] = cached
                                                        ? previousRows[
                                                            cachedIndex]
                                                        : rowBuilder(
                                                            context,
                                                            rowIndex,
                                                            contentBuilder);

                                                (rowWidget == null &&
                                                            placeholderContainerBuilder !=
                                                                null
                                                        ? placeholderChildren
                                                        : children)
                                                    .add(
                                                  Positioned(
                                                    key:
                                                        ValueKey<int>(rowIndex),
                                                    left: 0,
                                                    top: rowOffset,
                                                    width: width,
                                                    height: rowHeight,
                                                    child: placeholders[
                                                        screenIndex] = rowWidget !=
                                                            null
                                                        ? rowWidget
                                                        : cached
                                                            ? previousPlaceholders[
                                                                cachedIndex]!
                                                            : placeholderBuilder!(
                                                                context,
                                                                rowIndex,
                                                                contentBuilder),
                                                  ),
                                                );

                                                rowOffset += rowHeight;
                                              }

                                              if (placeholderChildren
                                                  .isNotEmpty) {
                                                Widget widget = Stack(
                                                  key: const ValueKey<int>(-1),
                                                  fit: StackFit.expand,
                                                  clipBehavior: Clip.none,
                                                  children: placeholderChildren,
                                                );

                                                if (placeholderContainerBuilder !=
                                                    null) {
                                                  widget =
                                                      placeholderContainerBuilder!
                                                          .call(widget);
                                                }

                                                children.add(widget);
                                              }
                                            }

                                            previousRows = rows;
                                            previousPlaceholders = placeholders;
                                            previousStartRowIndex =
                                                startRowIndex;
                                            previousEndRowIndex = endRowIndex;
                                            hasCache = true;

                                            return CustomPaint(
                                              foregroundPainter: WigglyDividerPainter(
                                                  leftLineColor:
                                                      leftDividerColor,
                                                  rightLineColor:
                                                      rightDividerColor,
                                                  leftLineX: leftWidth -
                                                      halfDividerThickness,
                                                  rightLineX: rightWidth -
                                                      halfDividerThickness,
                                                  lineWidth: dividerThickness,
                                                  patternHeight: rowHeight,
                                                  verticalOffset:
                                                      verticalOffsetPixels,
                                                  horizontalLeftOffset:
                                                      leftDividerWiggleOffset,
                                                  horizontalRightOffset:
                                                      rightDividerWiggleOffset),
                                              child: Stack(
                                                fit: StackFit.expand,
                                                clipBehavior: Clip.none,
                                                children: children,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
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
                                  child: RepaintBoundary(
                                    child: ClipRect(
                                      child: CustomPaint(
                                        foregroundPainter: WigglyDividerPainter(
                                            leftLineColor: leftDividerColor,
                                            rightLineColor: rightDividerColor,
                                            leftLineX: leftWidth -
                                                halfDividerThickness,
                                            rightLineX: rightWidth -
                                                halfDividerThickness,
                                            lineWidth: dividerThickness,
                                            patternHeight: headerHeight,
                                            verticalOffset: 0,
                                            horizontalLeftOffset:
                                                leftDividerWiggleOffset,
                                            horizontalRightOffset:
                                                rightDividerWiggleOffset),
                                        child: headerBuilder(
                                            context, contentBuilder),
                                      ),
                                    ),
                                  ),
                                ),
                                Divider(
                                  color: dividerColor,
                                  height: dividerThickness,
                                  thickness: dividerThickness,
                                ),
                              ],
                              Expanded(child: body),
                              if (footerBuilder != null) ...[
                                Divider(
                                  color: dividerColor,
                                  height: dividerThickness,
                                  thickness: dividerThickness,
                                ),
                                SizedBox(
                                  width: double.infinity,
                                  height: footerHeight,
                                  child: RepaintBoundary(
                                    child: ClipRect(
                                      child: CustomPaint(
                                        foregroundPainter: WigglyDividerPainter(
                                            leftLineColor: leftDividerColor,
                                            rightLineColor: rightDividerColor,
                                            leftLineX: leftWidth -
                                                halfDividerThickness,
                                            rightLineX: rightWidth -
                                                halfDividerThickness,
                                            lineWidth: dividerThickness,
                                            patternHeight: footerHeight,
                                            verticalOffset: 0,
                                            horizontalLeftOffset:
                                                leftDividerWiggleOffset,
                                            horizontalRightOffset:
                                                rightDividerWiggleOffset),
                                        child: footerBuilder(
                                            context, contentBuilder),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
}
