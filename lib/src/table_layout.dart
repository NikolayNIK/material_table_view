import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:material_table_view/src/iterator_extensions.dart';
import 'package:material_table_view/src/listenable_builder.dart';
import 'package:material_table_view/src/table_column.dart';
import 'package:material_table_view/src/table_layout_data.dart';

const double _wiggleOffset = 16.0;

/// This widget calculates the horizontal layout of the table using the width
/// passed down to it, thus allowing it to be used in both box and sliver layout.
///
/// The [TableContentLayout.of] static method is used to retrieve layout data
/// and depend on its updates.
class TableContentLayout extends StatelessWidget {
  final double width;
  final ViewportOffset horizontalOffset;
  final List<TableColumn> columns;
  final double? minScrollableWidth;
  final double minScrollableWidthRatio;
  final EdgeInsets scrollPadding;
  final Widget child;

  const TableContentLayout({
    super.key,
    required this.width,
    required this.horizontalOffset,
    required this.columns,
    this.minScrollableWidth,
    required this.minScrollableWidthRatio,
    required this.scrollPadding,
    required this.child,
  });

  static TableContentLayoutData of(BuildContext context) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<_InheritedTableContentLayout>();
    assert(widget != null, 'No TableContentLayout found in ancestor hierarchy');
    return widget!.data;
  }

  @override
  Widget build(BuildContext context) {
    final dividerColor =
        Theme.of(context).dividerTheme.color ?? Theme.of(context).dividerColor;

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

    return XListenableBuilder(
      listenable: horizontalOffset,
      builder: (context, _) {
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
                leftOffset = scrollPadding.left,
                centerOffset = -horizontalOffsetPixels,
                rightOffset = -scrollPadding.right;
            i < columns.length;
            i++) {
          final column = columns[i];
          if (column.frozenAt(freezePriority) && centerOffset.isNegative) {
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

                final maxVisibleOffset = width - leftOffset + rightOffset;
                while (columnsCenter.isNotEmpty &&
                    columnOffsetsCenter.last > maxVisibleOffset) {
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
            : columnsRight.fold<double>(.0, foldColumnsWidth) +
                scrollPadding.right;
        final centerWidth = width - leftWidth - rightWidth;

        for (var i = 0; i < columnOffsetsCenter.length; i++)
          columnOffsetsCenter[i] += leftWidth;

        if (columnsLeft.isEmpty) {
          for (var i = 0; i < columnOffsetsCenter.length; i++) {
            columnOffsetsCenter[i] =
                columnOffsetsCenter[i] + scrollPadding.left;
          }
        }

        final columnsFixed =
            columnsLeft.followedBy(columnsRight).toList(growable: false);
        final columnOffsetsFixed = columnOffsetsLeft
            .followedBy(columnOffsetsRight.map((e) => width + e))
            .toList(growable: false);

        final Color leftDividerColor, rightDividerColor;
        final double leftDividerWiggleOffset, rightDividerWiggleOffset;
        {
          double leftDividerAnimationValue = .0;
          if (columnsLeft.isNotEmpty) {
            final toFreeze = Iterable.generate(columnsCenter.length)
                .where(
                    (i) => columns[columnsCenter[i]].frozenAt(freezePriority))
                .maybeFirst;

            if (toFreeze == null) {
              leftDividerAnimationValue = columnsLeft.isEmpty ? .0 : 1.0;
            } else {
              leftDividerAnimationValue = max(
                  0.0,
                  min(
                      1.0,
                      (columnOffsetsCenter[toFreeze] - leftWidth) /
                          _wiggleOffset));
            }

            if (columnsLeft.isNotEmpty &&
                columnsCenter.isNotEmpty &&
                columnsLeft.last + 1 == columnsCenter.first) {
              leftDividerAnimationValue = min(
                  leftDividerAnimationValue,
                  max(
                      .0,
                      min(
                          1.0,
                          -(columnOffsetsCenter.first - leftWidth) /
                              _wiggleOffset)));
            }
          }

          leftDividerColor = dividerColor.withOpacity(dividerColor.opacity *
              Curves.easeIn.transform(leftDividerAnimationValue));
          leftDividerWiggleOffset = min(_wiggleOffset,
              max(.0, leftDividerAnimationValue * _wiggleOffset));

          double rightDividerAnimationValue = .0;
          if (columnsRight.isNotEmpty) {
            final toFreeze = Iterable.generate(columnsCenter.length,
                    (index) => columnsCenter.length - index - 1)
                .where(
                    (i) => columns[columnsCenter[i]].frozenAt(freezePriority))
                .maybeFirst;

            if (toFreeze == null) {
              rightDividerAnimationValue = 1.0;
            } else {
              rightDividerAnimationValue = max(
                  .0,
                  min(
                      1.0,
                      (centerWidth -
                              (columnOffsetsCenter[toFreeze] - leftWidth) -
                              columns[columnsCenter[toFreeze]].width) /
                          _wiggleOffset));
            }

            if (columnsRight.isNotEmpty &&
                columnsCenter.isNotEmpty &&
                columnsRight.last - 1 == columnsCenter.last) {
              rightDividerAnimationValue = min(
                  rightDividerAnimationValue,
                  max(
                      .0,
                      min(
                          1.0,
                          (-centerWidth +
                                  (columnOffsetsCenter.last - leftWidth) +
                                  columns[columnsCenter.last].width) /
                              _wiggleOffset)));
            }
          }

          rightDividerColor = dividerColor.withOpacity(dividerColor.opacity *
              Curves.easeIn.transform(rightDividerAnimationValue));
          rightDividerWiggleOffset =
              min(16.0, max(.0, rightDividerAnimationValue * _wiggleOffset));
        }

        return _InheritedTableContentLayout(
          data: TableContentLayoutData(
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
          child: child,
        );
      },
    );
  }
}

class _InheritedTableContentLayout extends InheritedWidget {
  final TableContentLayoutData data;

  _InheritedTableContentLayout({
    required this.data,
    required super.child,
  });

  @override
  bool updateShouldNotify(covariant _InheritedTableContentLayout oldWidget) =>
      oldWidget.data != data;
}
