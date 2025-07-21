import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:material_table_view/src/iterator_extensions.dart';
import 'package:material_table_view/src/table_column.dart';
import 'package:material_table_view/src/table_content_layout_data.dart';
import 'package:material_table_view/src/table_view_style_resolved.dart';

/// This widget calculates the horizontal layout of the table using the width
/// passed down to it, thus allowing it to be used in both box and sliver layout.
///
/// The [TableContentLayout.of] static method is used to retrieve layout data
/// and depend on its updates.
class TableContentLayout extends StatefulWidget {
  final ResolvedTableViewVerticalDividersStyle verticalDividersStyle;
  final double width;
  final bool fixedRowHeight;
  final ViewportOffset horizontalOffset;
  final ValueNotifier<double> stickyHorizontalOffset;
  final List<TableColumn> columns;
  final double? minScrollableWidth;
  final double minScrollableWidthRatio;
  final TextDirection textDirection;
  final EdgeInsets scrollPadding;
  final bool shouldRenderColumnsLazy;
  final Widget child;

  const TableContentLayout({
    super.key,
    required this.verticalDividersStyle,
    required this.width,
    required this.fixedRowHeight,
    required this.horizontalOffset,
    required this.stickyHorizontalOffset,
    required this.columns,
    this.minScrollableWidth,
    required this.minScrollableWidthRatio,
    required this.textDirection,
    required this.scrollPadding,
    required this.child,
    required this.shouldRenderColumnsLazy,
  });

  static TableContentLayoutData of(BuildContext context) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<_InheritedTableContentLayout>();
    assert(widget != null, 'No TableContentLayout found in ancestor hierarchy');
    return widget!.data;
  }

  @override
  State<TableContentLayout> createState() => TableContentLayoutState();
}

class TableContentLayoutState extends State<TableContentLayout>
    implements Listenable {
  final _lastLayoutData = ValueNotifier<TableContentLayoutData?>(null);

  double _minStickyHorizontalOffset = .0;
  double _maxStickyHorizontalOffset = .0;
  int freezePriority = 0;

  Key? foregroundColumnKey;

  TableContentLayoutData get lastLayoutData => _lastLayoutData.value!;

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
      widget.minScrollableWidth ??
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

  TableContentLayoutData calculateLayoutData(
    final List<TableColumn> columns,
    double? stickyOffset,
  ) {
    // this is quickly becoming a mess...

    final horizontalOffsetPixels = widget.horizontalOffset.pixels;

    double foldColumnsWidth(double previousValue, int index) =>
        previousValue + columns[index].width;

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
        i < columns.length;
        i++) {
      final column = columns[i];
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
        if (!widget.shouldRenderColumnsLazy || centerOffset >= -column.width) {
          columnsCenter.add(i);
          columnOffsetsCenter.add(centerOffset);
        }
        centerOffset += column.width;
      } else {
        sticky = true;
        i = max(0, i - 2);
        for (int j = columns.length - 1; j > i && j >= 0; j--) {
          final column = columns[j];
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

    // reinsert culled center columns that have translation at the edges
    // this is used by column controls
    if (columnsCenter.isNotEmpty) {
      var i = columnsCenter.first - 1;
      TableColumn column;
      while (i >= 0 &&
          (column = columns[i]).translation > .25 &&
          !columnsLeft.contains(i) &&
          !columnsRight.contains(i)) {
        columnsCenter.insert(0, i);
        columnOffsetsCenter.insert(0, columnOffsetsCenter.first - column.width);
        i--;
      }

      i = columnsCenter.last + 1;
      while (i < columns.length &&
          columns[i].translation < -.25 &&
          !columnsLeft.contains(i) &&
          !columnsRight.contains(i)) {
        columnOffsetsCenter
            .add(columnOffsetsCenter.last + columns[columnsCenter.last].width);
        columnsCenter.add(i);
        i++;
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
      return calculateLayoutData(columns, stickyOffset);
    }

    var leftWidth = columnsLeft.isEmpty
        ? .0
        : columnsLeft.fold<double>(.0, foldColumnsWidth) +
            widget.scrollPadding.left +
            stickyLeftOffset;
    var rightWidth = columnsRight.isEmpty
        ? .0
        : columnsRight.fold<double>(.0, foldColumnsWidth) +
            widget.scrollPadding.right -
            stickyRightOffset;
    final centerWidth = widget.width - leftWidth - rightWidth;

    for (var i = 0; i < columnOffsetsCenter.length; i++) {
      columnOffsetsCenter[i] += leftWidth;
    }

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
            .where((i) => columns[columnsCenter[i]].frozenAt(freezePriority))
            .maybeFirst;

        if (toFreeze == null) {
          leftDividerAnimationValue = columnsLeft.isEmpty ? .0 : 1.0;
        } else {
          leftDividerAnimationValue = max(
              0.0,
              min(
                  1.0,
                  (columnOffsetsCenter[toFreeze] - leftWidth) /
                      widget.verticalDividersStyle.leading.revealOffset));
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
                          widget.verticalDividersStyle.leading.revealOffset)));
        }
      }

      leftDividerAnimationValue = leftDividerAnimationValue.isNaN
          ? .0
          : min(1.0, max(.0, leftDividerAnimationValue));

      leftDividerColor = widget.verticalDividersStyle.leading.color.withValues(
          alpha: widget.verticalDividersStyle.leading.color.a *
              widget.verticalDividersStyle.leading.opacityRevealCurve
                  .transform(leftDividerAnimationValue));

      leftDividerWiggleOffset =
          widget.verticalDividersStyle.leading.wiggleOffset *
              widget.verticalDividersStyle.leading.wiggleRevealCurve
                  .transform(leftDividerAnimationValue);

      double rightDividerAnimationValue = .0;
      if (columnsRight.isNotEmpty) {
        final toFreeze = Iterable.generate(columnsCenter.length,
                (index) => columnsCenter.length - index - 1)
            .where((i) => columns[columnsCenter[i]].frozenAt(freezePriority))
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
                      widget.verticalDividersStyle.trailing.revealOffset));
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
                          widget.verticalDividersStyle.trailing.revealOffset)));
        }
      }

      rightDividerAnimationValue = rightDividerAnimationValue.isNaN
          ? .0
          : min(1.0, max(.0, rightDividerAnimationValue));

      rightDividerColor = widget.verticalDividersStyle.trailing.color
          .withValues(
              alpha: widget.verticalDividersStyle.trailing.color.a *
                  widget.verticalDividersStyle.trailing.opacityRevealCurve
                      .transform(rightDividerAnimationValue));

      rightDividerWiggleOffset =
          widget.verticalDividersStyle.trailing.wiggleOffset *
              widget.verticalDividersStyle.trailing.wiggleRevealCurve
                  .transform(rightDividerAnimationValue);
    }

    var leftDivider = TableContentDividerData(
      color: leftDividerColor,
      thickness: widget.verticalDividersStyle.leading.thickness,
      wiggleInterval: widget.verticalDividersStyle.leading.wiggleInterval,
      wiggleCount: widget.verticalDividersStyle.leading.wiggleCount,
      wiggleOffset: leftDividerWiggleOffset,
    );

    var rightDivider = TableContentDividerData(
      color: rightDividerColor,
      thickness: widget.verticalDividersStyle.trailing.thickness,
      wiggleInterval: widget.verticalDividersStyle.trailing.wiggleInterval,
      wiggleCount: widget.verticalDividersStyle.trailing.wiggleCount,
      wiggleOffset: rightDividerWiggleOffset,
    );

    if (widget.textDirection == TextDirection.ltr) {
      for (int i = 0; i < columnsFixed.length; i++) {
        columnOffsetsFixed[i] += columns[columnsFixed[i]].translation;
      }

      for (int i = 0; i < columnsCenter.length; i++) {
        columnOffsetsCenter[i] += columns[columnsCenter[i]].translation;
      }
    } else {
      for (int i = 0; i < columnsFixed.length; i++) {
        final column = columns[columnsFixed[i]];
        columnOffsetsFixed[i] = widget.width -
            columnOffsetsFixed[i] -
            column.width +
            column.translation;
      }

      for (int i = 0; i < columnsCenter.length; i++) {
        final column = columns[columnsCenter[i]];
        columnOffsetsCenter[i] = widget.width -
            columnOffsetsCenter[i] -
            column.width +
            column.translation;
      }

      final tmp = leftWidth;
      leftWidth = rightWidth;
      rightWidth = tmp;

      final tmp2 = leftDivider;
      leftDivider = rightDivider;
      rightDivider = tmp2;
    }

    final data = TableContentLayoutData(
      leftWidth: leftWidth,
      centerWidth: centerWidth,
      rightWidth: rightWidth,
      scrollableColumns: TableContentColumnData(
        indices: columnsCenter,
        positions: columnOffsetsCenter,
        widths:
            columnsCenter.map((e) => columns[e].width).toList(growable: false),
        keys: columnsCenter
            .map((e) => columns[e].key ?? _DefaultTableColumnKey(e))
            .toList(growable: false),
      ),
      fixedColumns: TableContentColumnData(
        indices: columnsFixed,
        positions: columnOffsetsFixed,
        widths:
            columnsFixed.map((e) => columns[e].width).toList(growable: false),
        keys: columnsFixed
            .map((e) => columns[e].key ?? _DefaultTableColumnKey(e))
            .toList(growable: false),
      ),
      foregroundColumnKey: foregroundColumnKey,
      leftDivider: leftDivider,
      rightDivider: rightDivider,
      fixedRowHeight: widget.fixedRowHeight,
    );

    _lastLayoutData.value = data;

    return data;
  }

  @override
  Widget build(BuildContext context) => _InheritedTableContentLayout(
        data: calculateLayoutData(widget.columns, null),
        child: widget.child,
      );

  @override
  void addListener(VoidCallback listener) =>
      _lastLayoutData.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      _lastLayoutData.removeListener(listener);
}

class _InheritedTableContentLayout extends InheritedWidget {
  final TableContentLayoutData data;

  const _InheritedTableContentLayout({
    required this.data,
    required super.child,
  });

  @override
  bool updateShouldNotify(covariant _InheritedTableContentLayout oldWidget) =>
      oldWidget.data != data;
}

class _DefaultTableColumnKey extends LocalKey {
  const _DefaultTableColumnKey(this.index);

  final int index;

  @override
  bool operator ==(Object other) =>
      other.runtimeType == runtimeType &&
      (other as _DefaultTableColumnKey).index == index;

  @override
  int get hashCode => index;

  @override
  String toString() => '[_DefaultTableColumnKey<$index>]';
}
