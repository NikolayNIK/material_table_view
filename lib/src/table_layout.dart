import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:material_table_view/src/iterator_extensions.dart';
import 'package:material_table_view/src/table_column.dart';
import 'package:material_table_view/src/table_layout_data.dart';

const double _wiggleOffset = 16.0;

/// This widget calculates the horizontal layout of the table using the width
/// passed down to it, thus allowing it to be used in both box and sliver layout.
///
/// The [TableContentLayout.of] static method is used to retrieve layout data
/// and depend on its updates.
class TableContentLayout extends StatefulWidget {
  final double width;
  final ViewportOffset horizontalOffset;
  final ValueNotifier<double> stickyHorizontalOffset;
  final List<TableColumn> columns;
  final double? minScrollableWidth;
  final double minScrollableWidthRatio;
  final EdgeInsets scrollPadding;
  final Widget child;

  const TableContentLayout({
    super.key,
    required this.width,
    required this.horizontalOffset,
    required this.stickyHorizontalOffset,
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
  State<TableContentLayout> createState() => _TableContentLayoutState();
}

class _TableContentLayoutState extends State<TableContentLayout> {
  double _minStickyHorizontalOffset = .0;
  double _maxStickyHorizontalOffset = .0;
  int freezePriority = 0;

  @override
  void initState() {
    super.initState();

    _columnLayoutChanged();

    widget.horizontalOffset.addListener(_horizontalOffsetChanged);
    widget.stickyHorizontalOffset.addListener(_stickyHorizontalOffsetChanged);
  }

  @override
  void didUpdateWidget(covariant TableContentLayout oldWidget) {
    super.didUpdateWidget(oldWidget);

    _columnLayoutChanged();

    if (widget.horizontalOffset != oldWidget.horizontalOffset) {
      oldWidget.horizontalOffset.removeListener(_horizontalOffsetChanged);
      widget.horizontalOffset.addListener(_horizontalOffsetChanged);
    }

    if (widget.stickyHorizontalOffset != oldWidget.stickyHorizontalOffset) {
      oldWidget.stickyHorizontalOffset
          .removeListener(_stickyHorizontalOffsetChanged);
      widget.stickyHorizontalOffset.addListener(_stickyHorizontalOffsetChanged);
    }
  }

  @override
  void dispose() {
    widget.horizontalOffset.removeListener(_horizontalOffsetChanged);
    widget.stickyHorizontalOffset
        .removeListener(_stickyHorizontalOffsetChanged);

    super.dispose();
  }

  double? previousHorizontalOffsetPixels;

  void _horizontalOffsetChanged() => setState(() {
        if (!widget.horizontalOffset.hasPixels) {
          _maxStickyHorizontalOffset = .0;
          _minStickyHorizontalOffset = .0;
          widget.stickyHorizontalOffset.value = .0;
          return;
        }

        final previousHorizontalOffsetPixels =
            this.previousHorizontalOffsetPixels;
        final currentOffsetPixels = this.previousHorizontalOffsetPixels =
            widget.horizontalOffset.pixels;
        if (previousHorizontalOffsetPixels == null) {
          return;
        }

        widget.stickyHorizontalOffset.value = max(
            _minStickyHorizontalOffset,
            min(
                _maxStickyHorizontalOffset,
                widget.stickyHorizontalOffset.value +
                    (previousHorizontalOffsetPixels - currentOffsetPixels)));
      });

  void _stickyHorizontalOffsetChanged() => setState(() {
        final value = widget.stickyHorizontalOffset.value;
        if (value > _maxStickyHorizontalOffset) {
          widget.stickyHorizontalOffset.value = _maxStickyHorizontalOffset;
        } else if (value < _minStickyHorizontalOffset) {
          widget.stickyHorizontalOffset.value = _minStickyHorizontalOffset;
        }
      });

  void _columnLayoutChanged() {
    final minScrollableWidth = max(
      16.0,
      this.widget.minScrollableWidth ??
          widget.minScrollableWidthRatio * widget.width,
    );

    final priorities = widget.columns
        .map((e) => e.freezePriority)
        .where((element) => element != 0)
        .toSet()
        .toList(growable: false)
      ..sort();

    int priority = 0;
    final iterator = priorities.iterator;
    while (true) {
      if (widget.width -
              widget.columns
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

  TableContentLayoutData calculateLayoutData(double? stickyOffset) {
    // this is quickly becoming a mess...

    final dividerColor =
        Theme.of(context).dividerTheme.color ?? Theme.of(context).dividerColor;

    final horizontalOffsetPixels = widget.horizontalOffset.pixels;

    double foldColumnsWidth(double previousValue, int index) =>
        previousValue + widget.columns[index].width;

    final columnsLeft = <int>[],
        columnsCenter = <int>[],
        columnsRight = <int>[];

    final columnOffsetsLeft = <double>[],
        columnOffsetsCenter = <double>[],
        columnOffsetsRight = <double>[];

    var sticky = true;
    _minStickyHorizontalOffset = .0;
    _maxStickyHorizontalOffset = .0;

    stickyOffset ??= widget.stickyHorizontalOffset.value;
    final stickyLeftOffset = (stickyOffset < 0 ? stickyOffset : 0);
    final stickyRightOffset = (stickyOffset > 0 ? stickyOffset : 0);
    for (var i = 0,
            leftOffset = widget.scrollPadding.left + stickyLeftOffset,
            centerOffset = -horizontalOffsetPixels - stickyLeftOffset,
            rightOffset = -widget.scrollPadding.right + stickyRightOffset;
        i < widget.columns.length;
        i++) {
      final column = widget.columns[i];
      if (column.frozenAt(freezePriority) && centerOffset <= 0) {
        if (column.sticky && sticky) {
          _minStickyHorizontalOffset -= column.width;
        } else {
          sticky = false;
        }

        columnsLeft.add(i);
        columnOffsetsLeft.add(leftOffset);
        leftOffset += column.width;
      } else if (leftOffset +
              centerOffset +
              (column.frozenAt(freezePriority)
                  ? column.width + widget.scrollPadding.right
                  : 0) <=
          widget.width) {
        if (centerOffset >= -column.width) {
          columnsCenter.add(i);
          columnOffsetsCenter.add(centerOffset);
        }
        centerOffset += column.width;
      } else {
        sticky = true;
        i = max(0, i - 2);
        for (int j = widget.columns.length - 1; j > i; j--) {
          final column = widget.columns[j];
          if (column.frozenAt(freezePriority)) {
            if (column.sticky && sticky) {
              _maxStickyHorizontalOffset += column.width;
            } else {
              sticky = false;
            }

            columnsRight.add(j);
            rightOffset -= column.width;
            columnOffsetsRight.add(rightOffset);

            final maxVisibleOffset = widget.width - leftOffset + rightOffset;
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

    if (stickyOffset < _minStickyHorizontalOffset ||
        stickyOffset > _maxStickyHorizontalOffset) {
      stickyOffset = min(_maxStickyHorizontalOffset,
          max(_minStickyHorizontalOffset, stickyOffset));

      // we can't mutate the state here
      SchedulerBinding.instance.addPostFrameCallback(
        (timeStamp) => widget.stickyHorizontalOffset.value = stickyOffset!,
      );

      // restart the layout with the new sticky offset
      // let's just hope there won't be an infinite recursion here
      return calculateLayoutData(stickyOffset);
    }

    final leftWidth = columnsLeft.isEmpty
        ? .0
        : columnsLeft.fold<double>(.0, foldColumnsWidth) +
            widget.scrollPadding.left +
            stickyLeftOffset;
    final rightWidth = columnsRight.isEmpty
        ? .0
        : columnsRight.fold<double>(.0, foldColumnsWidth) +
            widget.scrollPadding.right -
            stickyRightOffset;
    final centerWidth = widget.width - leftWidth - rightWidth;

    for (var i = 0; i < columnOffsetsCenter.length; i++)
      columnOffsetsCenter[i] += leftWidth;

    if (columnsLeft.isEmpty) {
      for (var i = 0; i < columnOffsetsCenter.length; i++) {
        columnOffsetsCenter[i] =
            columnOffsetsCenter[i] + widget.scrollPadding.left;
      }
    }

    final columnsFixed =
        columnsLeft.followedBy(columnsRight).toList(growable: false);
    final columnOffsetsFixed = columnOffsetsLeft
        .followedBy(columnOffsetsRight.map((e) => widget.width + e))
        .toList(growable: false);

    final Color leftDividerColor, rightDividerColor;
    final double leftDividerWiggleOffset, rightDividerWiggleOffset;
    {
      double leftDividerAnimationValue = .0;
      if (columnsLeft.isNotEmpty) {
        final toFreeze = Iterable.generate(columnsCenter.length)
            .where((i) =>
                widget.columns[columnsCenter[i]].frozenAt(freezePriority))
            .maybeFirst;

        if (toFreeze == null) {
          leftDividerAnimationValue = columnsLeft.isEmpty ? .0 : 1.0;
        } else {
          leftDividerAnimationValue = max(
              0.0,
              min(1.0,
                  (columnOffsetsCenter[toFreeze] - leftWidth) / _wiggleOffset));
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
      leftDividerWiggleOffset = min(
          _wiggleOffset, max(.0, leftDividerAnimationValue * _wiggleOffset));

      double rightDividerAnimationValue = .0;
      if (columnsRight.isNotEmpty) {
        final toFreeze = Iterable.generate(columnsCenter.length,
                (index) => columnsCenter.length - index - 1)
            .where((i) =>
                widget.columns[columnsCenter[i]].frozenAt(freezePriority))
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
                          widget.columns[columnsCenter[toFreeze]].width) /
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
                              widget.columns[columnsCenter.last].width) /
                          _wiggleOffset)));
        }
      }

      rightDividerColor = dividerColor.withOpacity(dividerColor.opacity *
          Curves.easeIn.transform(rightDividerAnimationValue));
      rightDividerWiggleOffset =
          min(16.0, max(.0, rightDividerAnimationValue * _wiggleOffset));
    }

    return TableContentLayoutData(
      leftWidth: leftWidth,
      centerWidth: centerWidth,
      scrollableColumns: TableContentColumnData(
          indices: columnsCenter,
          positions: columnOffsetsCenter,
          widths: columnsCenter
              .map((e) => widget.columns[e].width)
              .toList(growable: false)),
      fixedColumns: TableContentColumnData(
          indices: columnsFixed,
          positions: columnOffsetsFixed,
          widths: columnsFixed
              .map((e) => widget.columns[e].width)
              .toList(growable: false)),
      leftDivider: TableContentDividerData(
          color: leftDividerColor, wiggleOffset: leftDividerWiggleOffset),
      rightDivider: TableContentDividerData(
          color: rightDividerColor, wiggleOffset: rightDividerWiggleOffset),
    );
  }

  @override
  Widget build(BuildContext context) => _InheritedTableContentLayout(
        data: calculateLayoutData(null),
        child: widget.child,
      );
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
