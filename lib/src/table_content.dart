import 'dart:math';

import 'package:flutter/material.dart';
import 'package:material_table_view/src/iterator_extensions.dart';
import 'package:material_table_view/src/listenable_builder.dart';
import 'package:material_table_view/src/scroll_dimensions_applicator.dart';
import 'package:material_table_view/src/sliver_table_view_body.dart';
import 'package:material_table_view/src/table_column.dart';
import 'package:material_table_view/src/table_layout_data.dart';
import 'package:material_table_view/src/table_placeholder_shader_configuration.dart';
import 'package:material_table_view/src/table_row.dart';
import 'package:material_table_view/src/table_section.dart';
import 'package:material_table_view/src/table_typedefs.dart';
import 'package:material_table_view/src/table_view_controller.dart';
import 'package:material_table_view/src/table_viewport.dart';

class TableContent extends StatelessWidget {
  final TableViewController controller;
  final List<TableColumn> columns;
  final double? minScrollableWidth;
  final double minScrollableWidthRatio;
  final int rowCount;
  final double rowHeight;
  final TableRowBuilder rowBuilder;
  final TablePlaceholderBuilder? placeholderBuilder;
  final TableViewPlaceholderShaderConfig? placeholderShaderConfig;
  final TableBodyContainerBuilder bodyContainerBuilder;
  final TableHeaderBuilder? headerBuilder;
  final double headerHeight;
  final double footerHeight;
  final TableFooterBuilder? footerBuilder;
  final double dividerRevealOffset;
  final EdgeInsets scrollPadding;

  const TableContent({
    super.key,
    required this.controller,
    required this.columns,
    required this.minScrollableWidth,
    required this.minScrollableWidthRatio,
    required this.rowCount,
    required this.rowHeight,
    required this.rowBuilder,
    required this.placeholderBuilder,
    required this.placeholderShaderConfig,
    required this.bodyContainerBuilder,
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

            final dividerThickness =
                Theme.of(context).dividerTheme.thickness ?? 2.0;
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

                          for (var i = 0; i < columnOffsetsCenter.length; i++)
                            columnOffsetsCenter[i] += leftWidth;

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
                                          (columnOffsetsCenter[toFreeze] -
                                                  leftWidth) /
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
                                              -(columnOffsetsCenter.first -
                                                      leftWidth) /
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
                                                  (columnOffsetsCenter[
                                                          toFreeze] -
                                                      leftWidth) -
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
                                                      (columnOffsetsCenter
                                                              .last -
                                                          leftWidth) +
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

                          Widget contentBuilder(BuildContext context,
                                  TableCellBuilder cellBuilder) =>
                              TableViewRow(cellBuilder: cellBuilder);

                          final body = bodyContainerBuilder(
                            context,
                            ClipRect(
                              child:
                                  NotificationListener<OverscrollNotification>(
                                // Suppress OverscrollNotification events that escape from the inner scrollable
                                onNotification: (notification) => true,
                                child: Scrollbar(
                                  controller:
                                      controller.verticalScrollController,
                                  interactive: true,
                                  thumbVisibility: true,
                                  trackVisibility: true,
                                  child: Scrollable(
                                    controller:
                                        controller.verticalScrollController,
                                    clipBehavior: Clip.none,
                                    axisDirection: AxisDirection.down,
                                    viewportBuilder:
                                        (context, verticalOffset) =>
                                            TableSection(
                                      verticalOffset: verticalOffset,
                                      rowHeight: rowHeight,
                                      placeholderShaderConfig:
                                          placeholderShaderConfig,
                                      child: TableViewport(
                                        clipBehavior: Clip.none,
                                        offset: verticalOffset,
                                        slivers: [
                                          SliverTableViewBody(
                                            rowCount: rowCount,
                                            rowHeight: rowHeight,
                                            rowBuilder: rowBuilder,
                                            placeholderBuilder:
                                                placeholderBuilder,
                                          ),
                                        ],
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

                          return InheritedTableContentLayout(
                            data: TableContentLayoutData(
                                rowHeight: rowHeight,
                                leftWidth: leftWidth,
                                centerWidth: centerWidth,
                                scrollableColumns: TableContentColumnData(
                                    indices: columnsCenter,
                                    positions: columnOffsetsCenter,
                                    widths: columnsCenter
                                        .map((e) => columns[e].width)
                                        .toList(growable: false)),
                                fixedColumns: TableContentColumnData(
                                    indices: columnsFixed,
                                    positions: columnOffsetsFixed,
                                    widths: columnsFixed
                                        .map((e) => columns[e].width)
                                        .toList(growable: false)),
                                leftDivider: TableContentDividerData(
                                    color: leftDividerColor,
                                    wiggleOffset: leftDividerWiggleOffset),
                                rightDivider: TableContentDividerData(
                                    color: rightDividerColor,
                                    wiggleOffset: rightDividerWiggleOffset)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (headerBuilder != null) ...[
                                  SizedBox(
                                    width: double.infinity,
                                    height: headerHeight,
                                    child: TableSection(
                                      verticalOffset: null,
                                      rowHeight: headerHeight,
                                      placeholderShaderConfig: null,
                                      child: headerBuilder(
                                          context, contentBuilder),
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
                                    child: TableSection(
                                      verticalOffset: null,
                                      rowHeight: footerHeight,
                                      placeholderShaderConfig: null,
                                      child: footerBuilder(
                                          context, contentBuilder),
                                    ),
                                  ),
                                ],
                              ],
                            ),
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
