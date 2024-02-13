import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:material_table_view/material_table_view.dart';
import 'package:material_table_view/src/table_column.dart';
import 'package:material_table_view/src/table_column_controls_controllable.dart';
import 'package:material_table_view/src/table_layout.dart';
import 'package:material_table_view/src/table_layout_data.dart';

PreferredSizeWidget _buildAnimatedIconButton(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  IconData icon,
) {
  final density = Theme.of(context).visualDensity;

  final border = Divider.createBorderSide(context);

  animation = CurvedAnimation(parent: animation, curve: Curves.easeInOut);

  final size = Size(
    48 + 8 * density.horizontal,
    48 + 8 * density.vertical,
  );

  return PreferredSize(
    preferredSize: size,
    child: Center(
      child: ListenableBuilder(
        listenable: animation,
        builder: (context, _) => SizedBox(
          width: animation.value * size.width,
          height: animation.value * size.height,
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            type: MaterialType.button,
            shape: CircleBorder(side: border),
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: 8 + density.vertical,
                horizontal: 8 + density.horizontal,
              ),
              child: Center(
                child: FittedBox(
                  child: Icon(
                    icon,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

PreferredSizeWidget _defaultResizeHandleBuilder(
  BuildContext context,
  bool leading,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
) =>
    _buildAnimatedIconButton(
      context,
      animation,
      secondaryAnimation,
      leading ? Icons.switch_right : Icons.switch_left,
    );

PreferredSizeWidget _defaultDragHandleBuilder(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
) =>
    _buildAnimatedIconButton(
      context,
      animation,
      secondaryAnimation,
      Icons.drag_indicator,
    );

typedef void ColumnResizeCallback(
  int index,
  double newWidth,
);

typedef void ColumnMoveCallback(
  int oldIndex,
  int newIndex,
);

typedef void ColumnTranslateCallback(
  int index,
  double newTranslation,
);

typedef PreferredSizeWidget ResizeHandleBuilder(
  BuildContext context,
  bool leading,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
);

typedef PreferredSizeWidget DragHandleBuilder(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
);

typedef PreferredSizeWidget PopupBuilder(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  double columnWidth,
);

class TableColumnControlHandlesPopupRoute extends ModalRoute<void> {
  final ValueNotifier<Listenable?> tableViewChanged;

  final ValueNotifier<ColumnResizeCallback?> onColumnResize;

  final ValueNotifier<ColumnMoveCallback?> onColumnMove;

  final ValueNotifier<ColumnTranslateCallback?> onColumnTranslate;

  final ValueNotifier<int> leadingImmovableColumnCount;

  final ValueNotifier<int> trailingImmovableColumnCount;

  final ValueNotifier<Color?> _barrierColor;

  final ValueNotifier<ResizeHandleBuilder> resizeHandleBuilder;

  final ValueNotifier<DragHandleBuilder> dragHandleBuilder;

  final ValueNotifier<PopupBuilder?> popupBuilder;

  final ValueNotifier<EdgeInsets> popupPadding;

  factory TableColumnControlHandlesPopupRoute.realtime({
    required BuildContext controlCellBuildContext,
    required int columnIndex,
    required Listenable? tableViewChanged,
    required ColumnResizeCallback? onColumnResize,
    required ColumnMoveCallback? onColumnMove,
    required ColumnTranslateCallback? onColumnTranslate,
    int leadingImmovableColumnCount = 0,
    int trailingImmovableColumnCount = 0,
    Color? barrierColor,
    ResizeHandleBuilder resizeHandleBuilder = _defaultResizeHandleBuilder,
    DragHandleBuilder dragHandleBuilder = _defaultDragHandleBuilder,
    PopupBuilder? popupBuilder,
    EdgeInsets popupPadding = const EdgeInsets.all(16.0),
  }) {
    var tableContentLayoutState = controlCellBuildContext
        .findAncestorStateOfType<TableContentLayoutState>();
    assert(tableContentLayoutState != null);

    var cellRenderObject = controlCellBuildContext.findRenderObject();
    assert(cellRenderObject is RenderBox);

    var state = controlCellBuildContext
        .findAncestorStateOfType<TableColumnControlsControllable>();
    assert(state != null, 'No TableView ancestor found');

    controlCellBuildContext.findRenderObject() as RenderBox;

    return TableColumnControlHandlesPopupRoute._(
      state!,
      tableContentLayoutState!,
      cellRenderObject as RenderBox,
      columnIndex,
      barrierColor: barrierColor,
      dragHandleBuilder: dragHandleBuilder,
      leadingImmovableColumnCount: leadingImmovableColumnCount,
      onColumnMove: onColumnMove,
      onColumnResize: onColumnResize,
      onColumnTranslate: onColumnTranslate,
      popupBuilder: popupBuilder,
      popupPadding: popupPadding,
      resizeHandleBuilder: resizeHandleBuilder,
      trailingImmovableColumnCount: trailingImmovableColumnCount,
      tableViewChanged: tableViewChanged,
    );
  }

  final TableColumnControlsControllable _tableViewState;

  final TableContentLayoutState _tableContentLayoutState;

  final RenderBox _targetCellRenderObject;

  int _targetColumnIndex;

  TableColumnControlHandlesPopupRoute._(
    this._tableViewState,
    this._tableContentLayoutState,
    this._targetCellRenderObject,
    this._targetColumnIndex, {
    required Listenable? tableViewChanged,
    required ColumnResizeCallback? onColumnResize,
    required ColumnMoveCallback? onColumnMove,
    required ColumnTranslateCallback? onColumnTranslate,
    required int leadingImmovableColumnCount,
    required int trailingImmovableColumnCount,
    required Color? barrierColor,
    required ResizeHandleBuilder resizeHandleBuilder,
    required DragHandleBuilder dragHandleBuilder,
    required PopupBuilder? popupBuilder,
    required EdgeInsets popupPadding,
  })  : tableViewChanged = ValueNotifier(tableViewChanged),
        onColumnResize = ValueNotifier(onColumnResize),
        onColumnMove = ValueNotifier(onColumnMove),
        onColumnTranslate = ValueNotifier(onColumnTranslate),
        leadingImmovableColumnCount =
            ValueNotifier(leadingImmovableColumnCount),
        trailingImmovableColumnCount =
            ValueNotifier(trailingImmovableColumnCount),
        _barrierColor = ValueNotifier(barrierColor),
        resizeHandleBuilder = ValueNotifier(resizeHandleBuilder),
        dragHandleBuilder = ValueNotifier(dragHandleBuilder),
        popupBuilder = ValueNotifier(popupBuilder),
        popupPadding = ValueNotifier(popupPadding) {}

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) =>
      Stack(
        children: [
          // this cancels pops the column controls out
          // as soon as the user tries to scroll the table
          // rather than requiring a full distinguished tap
          GestureDetector(
            onTapDown: (details) => Navigator.of(context).pop(),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          _Widget(
            route: this,
            animation: animation,
            secondaryAnimation: secondaryAnimation,
          ),
        ],
      );

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 200);

  @override
  bool get maintainState => false;

  @override
  bool get opaque => false;

  @override
  Color? get barrierColor => null;
}

class _Widget extends StatefulWidget {
  final TableColumnControlHandlesPopupRoute route;
  final Animation<double> animation, secondaryAnimation;

  const _Widget({
    required this.route,
    required this.animation,
    required this.secondaryAnimation,
  });

  @override
  State<_Widget> createState() => _WidgetState();
}

class _WidgetState extends State<_Widget>
    with TickerProviderStateMixin<_Widget> {
  final clearBarrierCounter = ValueNotifier<int>(0);

  late double width;
  late double minColumnWidth;
  bool popped = false;

  late int columnIndex;
  late double dragValue;

  double leadingResizeHandleCorrection = .0,
      trailingResizeHandleCorrection = .0,
      moveHandleCorrection = .0;

  ScrollHoldController? scrollHold;

  List<TableColumn>? _recentlyChangedColumns;
  TableContentLayoutData? _recentlyChangedTableContentLayoutData;

  TableColumnControlHandlesPopupRoute get route => widget.route;

  TableContentLayoutData get tableContentLayoutData =>
      _recentlyChangedTableContentLayoutData ??
      route._tableContentLayoutState.lastLayoutData;

  List<TableColumn> get columns =>
      _recentlyChangedColumns ?? route._tableViewState.widget.columns;

  List<Listenable> get _routeFieldToListenTo => [
        route.onColumnResize,
        route.onColumnMove,
        route.onColumnTranslate,
        route.leadingImmovableColumnCount,
        route.trailingImmovableColumnCount,
        route._barrierColor,
        route.resizeHandleBuilder,
        route.dragHandleBuilder,
        route.popupBuilder,
        route.popupPadding,
      ];

  late ScrollController horizontalScrollController;

  late Listenable? tableViewChanged;

  @override
  void initState() {
    super.initState();

    columnIndex = route._targetColumnIndex;
    route._tableContentLayoutState.addListener(_parentDataChanged);
    horizontalScrollController =
        route._tableViewState.horizontalScrollController;
    horizontalScrollController.addListener(_horizontalScrollChanged);

    for (final listenable in _routeFieldToListenTo) {
      listenable.addListener(_routeChanged);
    }

    route.tableViewChanged.addListener(_tableViewChangedChanged);

    tableViewChanged = route.tableViewChanged.value;
    tableViewChanged?.addListener(_tableViewChanged);
  }

  @override
  void didUpdateWidget(covariant _Widget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!identical(horizontalScrollController,
        route._tableViewState.horizontalScrollController)) {
      horizontalScrollController.removeListener(_horizontalScrollChanged);
      horizontalScrollController =
          route._tableViewState.horizontalScrollController;
      horizontalScrollController.addListener(_horizontalScrollChanged);
    }
  }

  @override
  void dispose() {
    route._tableContentLayoutState.removeListener(_parentDataChanged);
    horizontalScrollController.removeListener(_horizontalScrollChanged);
    scrollHold?.cancel();

    for (final listenable in _routeFieldToListenTo) {
      listenable.removeListener(_routeChanged);
    }

    tableViewChanged?.removeListener(_tableViewChanged);
    route.tableViewChanged.removeListener(_tableViewChangedChanged);

    super.dispose();
  }

  void _routeChanged() => setState(() {});

  void _horizontalScrollChanged() => setState(() {});

  void _tableViewChangedChanged() {
    if (!identical(tableViewChanged, route.tableViewChanged.value)) {
      tableViewChanged?.removeListener(_tableViewChanged);
      tableViewChanged = route.tableViewChanged.value;
      tableViewChanged?.addListener(_tableViewChanged);
      _routeChanged();
    }
  }

  void _tableViewChanged() => setState(() {});

  void _parentDataChanged() =>
      SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
        if (mounted) setState(() {});
      });

  void abort() {
    if (!popped) {
      popped = true;
      SchedulerBinding.instance
          .addPostFrameCallback((timeStamp) => Navigator.pop(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!route._targetCellRenderObject.attached ||
        !route._tableContentLayoutState.mounted) {
      abort();

      return SizedBox();
    }

    final RenderBox originRenderObject;
    {
      final ro = context.findRenderObject();
      if (ro == null) {
        SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
          if (mounted) setState(() {});
        });

        return SizedBox();
      }

      originRenderObject = ro as RenderBox;
    }

    _recentlyChangedColumns = null;
    _recentlyChangedTableContentLayoutData = null;

    final leadingResizeHandleCorrection = this.leadingResizeHandleCorrection;
    final trailingResizeHandleCorrection = this.trailingResizeHandleCorrection;
    final moveHandleCorrection = this.moveHandleCorrection;

    this.leadingResizeHandleCorrection = .0;
    this.trailingResizeHandleCorrection = .0;
    this.moveHandleCorrection = .0;

    final leadingResizeHandle = route.onColumnResize.value == null ||
            columnIndex == 0
        ? null
        : route.resizeHandleBuilder
            .value(context, true, widget.animation, widget.secondaryAnimation);

    final trailingResizeHandle = route.onColumnResize.value == null ||
            columnIndex + 1 == this.columns.length
        ? null
        : route.resizeHandleBuilder
            .value(context, false, widget.animation, widget.secondaryAnimation);

    final dragHandle = route.onColumnMove.value == null
        ? null
        : route.dragHandleBuilder
            .value(context, widget.animation, widget.secondaryAnimation);

    final offset = originRenderObject.globalToLocal(
        route._targetCellRenderObject.localToGlobal(Offset.zero));

    minColumnWidth = (dragHandle?.preferredSize.width ?? .0) +
        (((leadingResizeHandle?.preferredSize.width ?? .0) +
                (trailingResizeHandle?.preferredSize.height ?? .0))) /
            2;

    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        fit: StackFit.expand,
        children: [
          if (route._barrierColor.value != null)
            IgnorePointer(
              key: const ValueKey('barrier'),
              child: FadeTransition(
                opacity: widget.animation,
                child: ValueListenableBuilder(
                  valueListenable: clearBarrierCounter,
                  builder: (context, clearBarrierCounter, _) => SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: clearBarrierCounter == 0
                          ? ColoredBox(
                              color: route._barrierColor.value!,
                              child: SizedBox(
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          if (route.popupBuilder.value != null)
            ValueListenableBuilder(
              key: ValueKey('popup'),
              valueListenable: clearBarrierCounter,
              child: route.popupBuilder.value!.call(
                  context,
                  widget.animation,
                  widget.secondaryAnimation,
                  route._targetCellRenderObject.size.width),
              builder: (context, clearBarrierCounter, child) {
                child = child as PreferredSizeWidget;

                final margin = route.popupPadding.value;

                final maxWidth = constraints.maxWidth - margin.horizontal;
                final maxHeight = constraints.maxHeight - margin.vertical;

                var width = child.preferredSize.width;
                var height = child.preferredSize.height;

                double x;
                if (width.isInfinite) {
                  x = margin.left;
                  width = constraints.maxWidth - margin.horizontal;
                } else {
                  x = offset.dx +
                      route._targetCellRenderObject.size.width / 2 -
                      width / 2 +
                      moveHandleCorrection;

                  if (x < margin.left) {
                    if (width > maxWidth) {
                      x = margin.left;
                      width = maxWidth;
                    } else {
                      x = margin.left;
                    }
                  } else if (x + width > constraints.maxWidth - margin.right) {
                    x = constraints.maxWidth - margin.right - width;
                    if (x < 0) {
                      x = margin.left;
                      width = maxWidth;
                    }
                  }
                }

                double y =
                    offset.dy + 2 * route._targetCellRenderObject.size.height;
                if (height.isInfinite) {
                  height = maxHeight;
                }

                if (y + height > maxHeight) {
                  final invertedBottom = offset.dy;
                  final clampedHeight =
                      constraints.maxHeight - y - margin.bottom;
                  if (invertedBottom > clampedHeight) {
                    y = invertedBottom - height;
                    if (y < margin.top) {
                      y = margin.top;
                      height = invertedBottom - margin.top;
                    }
                  } else {
                    height = clampedHeight;
                  }
                }

                return Positioned(
                  left: x,
                  top: y,
                  width: width,
                  height: height,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: clearBarrierCounter == 0 ? 1.0 : .0,
                    child: child,
                  ),
                );
              },
            ),
          if (leadingResizeHandle != null)
            Positioned(
              key: const ValueKey('leftResizeHandle'),
              left: offset.dx +
                  leadingResizeHandleCorrection -
                  leadingResizeHandle.preferredSize.width / 2,
              top: offset.dy +
                  route._targetCellRenderObject.size.height -
                  leadingResizeHandle.preferredSize.height / 2,
              width: leadingResizeHandle.preferredSize.width,
              height: leadingResizeHandle.preferredSize.height,
              child: GestureDetector(
                onHorizontalDragStart: _resizeStart,
                onHorizontalDragUpdate: _resizeUpdateLeading,
                onHorizontalDragEnd: _resizeEnd,
                child: leadingResizeHandle,
              ),
            ),
          if (trailingResizeHandle != null)
            Positioned(
              key: const ValueKey('rightResizeHandle'),
              left: offset.dx +
                  trailingResizeHandleCorrection +
                  route._targetCellRenderObject.size.width -
                  trailingResizeHandle.preferredSize.width / 2,
              top: offset.dy +
                  route._targetCellRenderObject.size.height -
                  trailingResizeHandle.preferredSize.height / 2,
              width: trailingResizeHandle.preferredSize.width,
              height: trailingResizeHandle.preferredSize.height,
              child: GestureDetector(
                onHorizontalDragStart: _resizeStart,
                onHorizontalDragUpdate: _resizeUpdateTrailing,
                onHorizontalDragEnd: _resizeEnd,
                child: trailingResizeHandle,
              ),
            ),
          if (dragHandle != null)
            Positioned(
              key: const ValueKey('moveHandle'),
              left: moveHandleCorrection +
                  offset.dx +
                  route._targetCellRenderObject.size.width / 2 -
                  dragHandle.preferredSize.width / 2,
              top: offset.dy +
                  route._targetCellRenderObject.size.height -
                  dragHandle.preferredSize.height / 2,
              width: dragHandle.preferredSize.width,
              height: dragHandle.preferredSize.height,
              child: GestureDetector(
                onHorizontalDragStart: _dragStart,
                onHorizontalDragUpdate: _dragUpdate,
                onHorizontalDragEnd: _dragEnd,
                child: dragHandle,
              ),
            ),
        ],
      ),
    );
  }

  void _resizeStart(DragStartDetails details) {
    width = columns[columnIndex].width;
    scrollHold = horizontalScrollController.position.hold(() {});
    clearBarrierCounter.value++;
  }

  void _resizeUpdateLeading(DragUpdateDetails details) {
    final delta = _resizeUpdate(-details.delta.dx);

    leadingResizeHandleCorrection -= delta;
    moveHandleCorrection -= delta / 2;

    final scrollPosition = horizontalScrollController.position;
    scrollPosition.jumpTo(scrollPosition.pixels + delta);

    scrollHold?.cancel();
    scrollHold = horizontalScrollController.position.hold(() {});
  }

  void _resizeUpdateTrailing(DragUpdateDetails details) {
    final delta = _resizeUpdate(details.delta.dx);

    trailingResizeHandleCorrection += delta;
    moveHandleCorrection += delta / 2;
  }

  double _resizeUpdate(double delta) {
    final width = this.width + delta;
    if (width < minColumnWidth) {
      this.width = minColumnWidth;
      delta += minColumnWidth - width;
    } else {
      this.width = width;
    }

    _resizeUpdateColumns();

    return delta;
  }

  void _resizeUpdateColumns() => onColumnResize(columnIndex, width);

  void _resizeEnd(DragEndDetails details) {
    scrollHold?.cancel();
    scrollHold = null;
    clearBarrierCounter.value--;
  }

  void _dragStart(DragStartDetails details) {
    dragValue = 0;

    clearBarrierCounter.value++;
  }

  void _layoutDataChanged() {
    // Right now this relies on callbacks modifying the same instance of columns
    // list in order to calculate latest layout data.
    // It might be necessary to keep a list of columns with changes applied
    // until we get a new one with build cycle.
    _recentlyChangedTableContentLayoutData =
        route._tableContentLayoutState.calculateLayoutData(columns, null);
  }

  void _dragUpdate(DragUpdateDetails details) {
    dragValue += details.delta.dx;
    _calculateMovement();
    onColumnTranslate(columnIndex, dragValue);
    leadingResizeHandleCorrection += details.delta.dx;
    moveHandleCorrection += details.delta.dx;
    trailingResizeHandleCorrection += details.delta.dx;
  }

  void _calculateMovement() {
    final columns = this.columns;

    final sections = [
      tableContentLayoutData.fixedColumns,
      tableContentLayoutData.scrollableColumns
    ];

    final TableContentColumnData? targetColumnSection;
    final double offset, width;
    {
      TableContentColumnData? foundSection;
      double? foundOffset, foundWidth;

      for (final section in sections) {
        if (section.indices.isEmpty) {
          continue;
        }

        for (int i = 0; i < section.indices.length; i++) {
          if (section.indices[i] == columnIndex) {
            foundSection = section;
            foundOffset =
                section.positions[i] - columns[section.indices[i]].translation;
            foundWidth = section.widths[i];
            break; // breaking outer loop here causes web release build to freeze whenever section.indices is empty...
          }
        }
      }

      if (foundSection == null || foundOffset == null || foundWidth == null) {
        return;
      }

      targetColumnSection = foundSection;
      offset = foundOffset;
      width = foundWidth;
    }

    if (dragValue > 0) {
      {
        final value = route.trailingImmovableColumnCount.value;
        assert(
          value >= 0,
        );
        if (columnIndex + 1 >= columns.length - value) {
          return;
        }
      }

      TableContentColumnData? closestColumnSection;
      int? closestColumnGlobalIndex;
      {
        double? closestColumnDistance;
        for (final section in sections) {
          for (var i = 0; i < section.indices.length; i++) {
            if (section.indices[i] == columnIndex) {
              continue;
            }

            final distance = (section.positions[i] -
                    columns[section.indices[i]].translation) -
                offset;
            if (distance >= 0 &&
                section.indices[i] > columnIndex &&
                (closestColumnDistance == null ||
                    distance < closestColumnDistance)) {
              closestColumnDistance = distance;
              closestColumnSection = section;
              closestColumnGlobalIndex = section.indices[i];
            }
          }
        }
      }

      if (closestColumnGlobalIndex == null ||
          (closestColumnGlobalIndex != columnIndex + 1 &&
              !identical(closestColumnSection, targetColumnSection))) {
        // TODO scroll
        return;
      }

      final nextWidth = columns[closestColumnGlobalIndex].width;
      if (dragValue > nextWidth / 2) {
        _animateColumnTranslation(closestColumnGlobalIndex, width, null);
        onColumnMove(columnIndex, closestColumnGlobalIndex);
        dragValue -= nextWidth;
        columnIndex = closestColumnGlobalIndex;
        _layoutDataChanged();
        return;
      }
    } else if (dragValue < 0) {
      {
        final value = route.leadingImmovableColumnCount.value;
        assert(value >= 0);
        if (columnIndex <= value) return;
      }

      TableContentColumnData? closestColumnSection;
      int? closestColumnGlobalIndex;
      {
        double? closestColumnDistance;
        for (final section in sections) {
          for (var i = 0; i < section.indices.length; i++) {
            if (section.indices[i] == columnIndex) {
              continue;
            }

            final distance = offset -
                (section.positions[i] -
                    columns[section.indices[i]].translation);
            if (distance >= 0 &&
                section.indices[i] < columnIndex &&
                (closestColumnDistance == null ||
                    distance < closestColumnDistance)) {
              closestColumnDistance = distance;
              closestColumnSection = section;
              closestColumnGlobalIndex = section.indices[i];
            }
          }
        }
      }

      if (closestColumnGlobalIndex == null ||
          (closestColumnGlobalIndex != columnIndex - 1 &&
              !identical(closestColumnSection, targetColumnSection))) {
        // TODO scroll
        return;
      }

      final nextWidth = columns[closestColumnGlobalIndex].width;
      if (dragValue < nextWidth / -2) {
        _animateColumnTranslation(closestColumnGlobalIndex, -width, null);
        onColumnMove(columnIndex, closestColumnGlobalIndex);

        dragValue += nextWidth;
        columnIndex = closestColumnGlobalIndex;
        _layoutDataChanged();
        return;
      }
    }
  }

  void _dragEnd(DragEndDetails details) {
    clearBarrierCounter.value--;
    _animateColumnTranslation(
        columnIndex, dragValue, columns[columnIndex].key, false);
  }

  void _animateColumnTranslation(
    int globalIndex,
    double translation,
    Key? correctHandles, [
    bool back = true,
  ]) {
    if (route.onColumnTranslate.value == null) {
      return;
    }

    final ticker = <Ticker>[];

    void stop() {
      ticker[0]
        ..stop()
        ..dispose();
    }

    final Key key;
    {
      final column = columns[globalIndex];
      key = column.key!;
      if (back) {
        onColumnTranslate(globalIndex, column.translation + translation);
      }
    }

    final currentGlobalIndex = <int>[globalIndex];
    final translationLeft = <double>[-translation];
    final lastElapsed = <Duration>[Duration.zero];

    const animationDuration = Duration(milliseconds: 200);

    ticker.add(createTicker((elapsed) {
      final columns = this.columns;

      var index = currentGlobalIndex[0];
      TableColumn? column;
      if (index > columns.length ||
          (column = columns[currentGlobalIndex[0]]).key != key) {
        for (var i = 0; i < columns.length; i++) {
          if (columns[i].key == key) {
            column = columns[i];
            index = currentGlobalIndex[0] = i;
            break;
          }
        }
      }

      if (column == null) {
        stop();
        return;
      }

      void correctHandlesIfNecessary(double correction) {
        if (correctHandles != null && column!.key == correctHandles) {
          leadingResizeHandleCorrection += correction;
          trailingResizeHandleCorrection += correction;
          moveHandleCorrection += correction;
        }
      }

      if (elapsed >= animationDuration) {
        onColumnTranslate(index, column.translation + translationLeft[0]);
        correctHandlesIfNecessary(translationLeft[0]);
        stop();
        return;
      }

      final valuePrev =
          lastElapsed[0].inMicroseconds / animationDuration.inMicroseconds;

      final valueNext =
          elapsed.inMicroseconds / animationDuration.inMicroseconds;

      const curve = Curves.fastOutSlowIn;
      final deltaTranslation = -translation *
          (curve.transform(valueNext) - curve.transform(valuePrev));

      lastElapsed[0] = elapsed;

      translationLeft[0] -= deltaTranslation;
      onColumnTranslate(index, column.translation + deltaTranslation);

      correctHandlesIfNecessary(deltaTranslation);
    })
      ..start());
  }

  void onColumnResize(
    int index,
    double newWidth,
  ) {
    final callback = route.onColumnResize.value;
    if (callback == null) return;

    callback(index, newWidth);

    setState(() {});

    var columns = this.columns;
    if (_recentlyChangedColumns == null && columns[index].width == newWidth) {
      return;
    }

    columns = _recentlyChangedColumns ??= columns.toList();
    columns[index] = columns[index].copyWith(width: newWidth);
  }

  void onColumnMove(
    int oldIndex,
    int newIndex,
  ) {
    final callback = route.onColumnMove.value;
    if (callback == null) return;

    var columns = this.columns;
    final column = columns[oldIndex];

    callback(oldIndex, newIndex);

    setState(() {});

    if (_recentlyChangedColumns == null && columns[newIndex] == column) {
      return;
    }

    columns = _recentlyChangedColumns ??= columns.toList();
    columns.insert(newIndex, columns.removeAt(oldIndex));
  }

  void onColumnTranslate(
    int index,
    double newTranslation,
  ) {
    final callback = route.onColumnTranslate.value;
    if (callback == null) return;

    callback(index, newTranslation);

    setState(() {});

    var columns = this.columns;
    if (_recentlyChangedColumns == null &&
        columns[index].translation == newTranslation) {
      return;
    }

    columns = _recentlyChangedColumns ??= columns.toList();
    columns[index] = columns[index].copyWith(translation: newTranslation);
  }
}
