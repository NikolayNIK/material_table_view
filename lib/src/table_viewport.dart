import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:material_table_view/material_table_view.dart';
import 'package:material_table_view/src/iterator_extensions.dart';
import 'package:material_table_view/src/listenable_builder.dart';
import 'package:material_table_view/src/table_view.dart';
import 'package:material_table_view/src/table_view_controller.dart';
import 'package:material_table_view/src/scroll_dimensions_applicator.dart';

/// TODO replace crude Widget implementation to a RenderBox one
class TableViewport extends StatelessWidget {
  final TableViewController controller;
  final List<TableColumn> columns;
  final double? minScrollableWidth;
  final double minScrollableWidthRatio;
  final int rowCount;
  final double rowHeight;
  final TableRowBuilder rowBuilder;
  final TableRowDecorator rowDecorator;
  final TableCellBuilder? headerBuilder;
  final double headerHeight;
  final TableHeaderDecorator headerDecorator;
  final double footerHeight;
  final TableCellBuilder? footerBuilder;
  final TableFooterDecorator footerDecorator;
  final double dividerRevealOffset;

  const TableViewport({
    super.key,
    required this.controller,
    required this.columns,
    required this.minScrollableWidth,
    required this.minScrollableWidthRatio,
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
    required this.dividerRevealOffset,
  });

  @override
  Widget build(BuildContext context) => columns.isEmpty
      ? const SizedBox()
      : LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

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

            return Scrollbar(
              controller: controller.horizontalScrollController,
              interactive: true,
              trackVisibility: true,
              thumbVisibility: true,
              child: Scrollable(
                controller: controller.horizontalScrollController,
                axisDirection: AxisDirection.right,
                viewportBuilder: (context, horizontalOffset) =>
                    ScrollDimensionsApplicator(
                  position: controller.horizontalScrollController.position,
                  axis: Axis.horizontal,
                  scrollExtent: columnsWidth,
                  child: ListenableBuilder(
                    listenable: horizontalOffset,
                    builder: (context) {
                      final horizontalOffsetPixels = horizontalOffset.pixels;

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
                              leftOffset = .0,
                              centerOffset = -horizontalOffsetPixels,
                              rightOffset = .0;
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
                                    ? column.width
                                    : 0) <=
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
                            if (column.frozenAt(freezePriority)) {
                              columnsRight.add(j);
                              rightOffset -= column.width;
                              columnOffsetsRight.add(rightOffset);
                            }
                          }

                          final maxVisibleOffset =
                              width - leftOffset + rightOffset;
                          while (columnOffsetsCenter.last > maxVisibleOffset) {
                            columnsCenter.removeLast();
                            columnOffsetsCenter.removeLast();
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

                      const clipWiggleOffset = 16.0;
                      const clipWiggleOuterOffset = 8.0;
                      const clipWiggleInnerOffset =
                          clipWiggleOffset - clipWiggleOuterOffset;

                      final wiggleLeft = columnsLeft.isNotEmpty;
                      final wiggleRight = columnsRight.isNotEmpty;
                      final clipperHash =
                          (wiggleLeft ? 1 : 0) | (wiggleRight ? 2 : 0);
                      _RowPathClipper clipperFor(double height) {
                        final path = Path();
                        if (wiggleRight) {
                          path
                            ..moveTo(centerWidth - clipWiggleInnerOffset, 0)
                            ..lineTo(
                                centerWidth + clipWiggleOuterOffset, height / 2)
                            ..lineTo(
                                centerWidth - clipWiggleInnerOffset, height);
                        } else {
                          path
                            ..moveTo(centerWidth, 0)
                            ..lineTo(centerWidth, height);
                        }

                        if (wiggleLeft) {
                          path
                            ..lineTo(clipWiggleInnerOffset, height)
                            ..lineTo(-clipWiggleOuterOffset, height / 2)
                            ..lineTo(clipWiggleInnerOffset, 0);
                        } else {
                          path
                            ..lineTo(0, height)
                            ..lineTo(0, 0);
                        }

                        path.close();
                        return _RowPathClipper(path, clipperHash);
                      }

                      Widget buildRow(TableCellBuilder cellBuilder,
                              _RowPathClipper clipper) =>
                          Stack(
                            fit: StackFit.expand,
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(
                                key: const ValueKey<int>(-1),
                                left: leftWidth,
                                width: centerWidth,
                                height: rowHeight,
                                child: ClipPath(
                                  clipper: clipper,
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
                          );

                      final rowClipper = clipperFor(rowHeight);

                      final dividerThickness =
                          Theme.of(context).dividerTheme.thickness ?? 2.0;

                      final Color leftDividerColor, rightDividerColor;
                      {
                        final dividerColor =
                            Theme.of(context).dividerTheme.color ??
                                Theme.of(context).dividerColor;

                        double leftLineOpacity = .0;
                        if (columnsLeft.isNotEmpty) {
                          if (dividerRevealOffset == .0) {
                            leftLineOpacity = 1.0;
                          } else {
                            final toFreeze =
                                Iterable.generate(columnsCenter.length)
                                    .where((i) => columns[columnsCenter[i]]
                                        .frozenAt(freezePriority))
                                    .maybeFirst;

                            if (toFreeze == null) {
                              leftLineOpacity = columnsLeft.isEmpty ? .0 : 1.0;
                            } else {
                              leftLineOpacity = max(
                                  0.0,
                                  min(
                                      1.0,
                                      columnOffsetsCenter[toFreeze] /
                                          dividerRevealOffset));
                            }

                            if (columnsLeft.isNotEmpty &&
                                columnsCenter.isNotEmpty &&
                                columnsLeft.last + 1 == columnsCenter.first) {
                              leftLineOpacity = min(
                                  leftLineOpacity,
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
                            dividerColor.opacity * leftLineOpacity);

                        double rightLineOpacity = .0;
                        if (columnsRight.isNotEmpty) {
                          if (dividerRevealOffset == 0) {
                            rightLineOpacity = 1.0;
                          } else {
                            final toFreeze = Iterable.generate(
                                    columnsCenter.length,
                                    (index) => columnsCenter.length - index - 1)
                                .where((i) => columns[columnsCenter[i]]
                                    .frozenAt(freezePriority))
                                .maybeFirst;

                            if (toFreeze == null) {
                              rightLineOpacity = 1.0;
                            } else {
                              rightLineOpacity = max(
                                  .0,
                                  min(
                                      1.0,
                                      (centerWidth -
                                              columnOffsetsCenter[toFreeze] -
                                              columns[columnsCenter[toFreeze]]
                                                  .width) /
                                          dividerRevealOffset));
                            }

                            if (columnsRight.isNotEmpty &&
                                columnsCenter.isNotEmpty &&
                                columnsRight.last - 1 == columnsCenter.last) {
                              rightLineOpacity = min(
                                  rightLineOpacity,
                                  max(
                                      .0,
                                      min(
                                          1.0,
                                          (-centerWidth +
                                                  columnOffsetsCenter.last +
                                                  columns[columnsCenter.last]
                                                      .width) /
                                              dividerRevealOffset)));
                            }
                          }
                        }

                        rightDividerColor = dividerColor.withOpacity(
                            dividerColor.opacity * rightLineOpacity);
                      }

                      final body = Material(
                        clipBehavior: Clip.hardEdge,
                        child: Scrollbar(
                          controller: controller.verticalScrollController,
                          thumbVisibility: true,
                          trackVisibility: true,
                          child: Scrollable(
                            controller: controller.verticalScrollController,
                            axisDirection: AxisDirection.down,
                            viewportBuilder: (context, verticalOffset) =>
                                ScrollDimensionsApplicator(
                              position:
                                  controller.verticalScrollController.position,
                              axis: Axis.vertical,
                              scrollExtent: rowCount * rowHeight,
                              child: ListenableBuilder(
                                listenable: verticalOffset,
                                builder: (context) {
                                  final verticalOffsetPixels =
                                      verticalOffset.pixels;

                                  final startRowIndex = max(
                                      0,
                                      (verticalOffsetPixels / rowHeight)
                                          .floor());
                                  final endRowIndex = min(rowCount,
                                      startRowIndex + height / rowHeight);

                                  return ClipRect(
                                    child: CustomPaint(
                                      foregroundPainter: _WigglyBorderPainter(
                                          leftLineColor: leftDividerColor,
                                          rightLineColor: rightDividerColor,
                                          leftLineX: leftWidth,
                                          rightLineX: rightWidth,
                                          lineWidth: dividerThickness,
                                          patternHeight: rowHeight,
                                          verticalOffset: verticalOffsetPixels,
                                          horizontalInnerOffset:
                                              clipWiggleInnerOffset,
                                          horizontalOuterOffset:
                                              clipWiggleOuterOffset),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        clipBehavior: Clip.none,
                                        children: [
                                          // TODO why am i doing that loop like that
                                          for (var rowIndex = startRowIndex,
                                                  rowOffset =
                                                      -(verticalOffsetPixels %
                                                          rowHeight);
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
                                              child: RepaintBoundary(
                                                child: rowDecorator(
                                                    buildRow(
                                                        rowBuilder(rowIndex),
                                                        rowClipper),
                                                    rowIndex),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
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
                              child: ClipRect(
                                child: CustomPaint(
                                  foregroundPainter: _WigglyBorderPainter(
                                      leftLineColor: leftDividerColor,
                                      rightLineColor: rightDividerColor,
                                      leftLineX: leftWidth,
                                      rightLineX: rightWidth,
                                      lineWidth: dividerThickness,
                                      patternHeight: headerHeight,
                                      verticalOffset: 0,
                                      horizontalInnerOffset:
                                          clipWiggleInnerOffset,
                                      horizontalOuterOffset:
                                          clipWiggleOuterOffset),
                                  child: headerDecorator(buildRow(
                                      headerBuilder,
                                      headerHeight == rowHeight
                                          ? rowClipper
                                          : clipperFor(headerHeight))),
                                ),
                              ),
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
                              child: RepaintBoundary(
                                child: ClipRect(
                                  child: CustomPaint(
                                    foregroundPainter: _WigglyBorderPainter(
                                        leftLineColor: leftDividerColor,
                                        rightLineColor: rightDividerColor,
                                        leftLineX: leftWidth,
                                        rightLineX: rightWidth,
                                        lineWidth: dividerThickness,
                                        patternHeight: footerHeight,
                                        verticalOffset: 0,
                                        horizontalInnerOffset:
                                            clipWiggleInnerOffset,
                                        horizontalOuterOffset:
                                            clipWiggleOuterOffset),
                                    child: footerDecorator(buildRow(
                                        footerBuilder,
                                        footerHeight == rowHeight
                                            ? rowClipper
                                            : clipperFor(footerHeight))),
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
            );
          },
        );
}

class _RowPathClipper extends CustomClipper<Path> {
  final Path path;
  final int hash;

  _RowPathClipper(this.path, this.hash);

  @override
  Path getClip(Size size) => path;

  @override
  bool shouldReclip(covariant _RowPathClipper old) => old.hash != hash;
}

class _WigglyBorderPainter extends CustomPainter {
  final Color leftLineColor, rightLineColor;
  final double leftLineX, rightLineX;
  final double lineWidth;
  final double patternHeight;
  final double verticalOffset;
  final double horizontalInnerOffset, horizontalOuterOffset;

  _WigglyBorderPainter({
    required this.leftLineColor,
    required this.rightLineColor,
    required this.leftLineX,
    required this.rightLineX,
    required this.lineWidth,
    required this.patternHeight,
    required this.verticalOffset,
    required this.horizontalInnerOffset,
    required this.horizontalOuterOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (leftLineColor.alpha == 0 && rightLineColor.alpha == 0) return;

    final path = Path();
    {
      final halfPatternHeight = patternHeight / 2;
      double verticalOffset = -(this.verticalOffset % patternHeight);
      path.moveTo(horizontalInnerOffset, verticalOffset);

      final end = size.height + this.verticalOffset;
      while (verticalOffset < end) {
        path
          ..lineTo(-horizontalOuterOffset, verticalOffset += halfPatternHeight)
          ..lineTo(horizontalInnerOffset, verticalOffset += halfPatternHeight);
      }

      path.relativeLineTo(0, size.height + lineWidth);
    }

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth;

    if (leftLineColor.alpha != 0) {
      paint.color = leftLineColor;
      canvas
        ..save()
        ..translate(leftLineX, 0)
        ..drawPath(path, paint)
        ..restore();
    }

    if (rightLineColor.alpha != 0) {
      paint.color = rightLineColor;
      canvas
        ..save()
        ..scale(-1.0, 1.0)
        ..translate(rightLineX - size.width, 0)
        // ..translate(size.width, 0)
        ..drawPath(path, paint)
        ..restore();
    }
  }

  @override
  bool shouldRepaint(covariant _WigglyBorderPainter old) =>
      verticalOffset != old.verticalOffset ||
      leftLineColor != old.leftLineColor ||
      rightLineColor != old.rightLineColor ||
      leftLineX != old.leftLineX ||
      rightLineX != old.rightLineX ||
      lineWidth != old.lineWidth ||
      patternHeight != old.patternHeight ||
      horizontalInnerOffset != old.horizontalInnerOffset ||
      horizontalOuterOffset != old.horizontalOuterOffset;
}
