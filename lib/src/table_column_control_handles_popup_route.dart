import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:material_table_view/material_table_view.dart';
import 'package:material_table_view/sliver_table_view.dart';
import 'package:material_table_view/src/table_column_controls_controllable.dart';
import 'package:material_table_view/src/table_content_layout.dart';
import 'package:material_table_view/src/table_content_layout_data.dart';

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

Duration _defaultColumnTranslationDuration(double distance) => Duration(
    milliseconds: (pow(distance / 64, 1 / 3).toDouble() * 200).round());

typedef ColumnResizeCallback = void Function(
  int index,
  double newWidth,
);

typedef ColumnMoveCallback = void Function(
  int oldIndex,
  int newIndex,
);

typedef ColumnTranslateCallback = void Function(
  int index,
  double newTranslation,
);

typedef ResizeHandleBuilder = PreferredSizeWidget Function(
  BuildContext context,
  bool leading,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
);

typedef DragHandleBuilder = PreferredSizeWidget Function(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
);

typedef PopupBuilder = PreferredSizeWidget Function(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  double columnWidth,
);

typedef ColumnTranslationDurationFunctor = Duration Function(
  double distance,
);

const _movingColumnsWithoutKeyAssertionMessage =
    'When using column moving functionality make sure to instantiate column'
    ' list with a class that extends TableColumn and overrides key getter'
    ' with one returning unique non-null key';

/// Experimental modal route that can display control handles to resize/move a column and custom popup for that column.
///
/// The popup will remove itself whenever it detects that [RenderBox] of the target cell is offstage.
/// Keep in mind that in the case of route removal the [Future] returned by
/// a call to [Navigator.push] will not complete. Use [Future.orCancel] to
/// handle this case.
class TableColumnControlHandlesPopupRoute extends ModalRoute<void> {
  /// Contains [Listenable] that route widget will subscribe to in order to rebuild.
  /// The [null] value here will lead to controls not updating whenever the [TableView] or [SliverTableView] changes
  /// by something else other than the controls themselves; which might be ok if the controls are the only way the
  /// table changes.
  ///
  /// Can be changed at any time (except [SchedulerPhase.persistentCallbacks]).
  final ValueNotifier<Listenable?> tableViewChanged;

  /// Contains a callback that will be called whenever the width of a column needs to change.
  /// The [null] value here will result in resize handles not appearing on the screen.
  ///
  /// Internal logic assumes that the changes will get applied the next build-cycle.
  /// Failing to so will lead to unexpected behavior.
  ///
  /// Can be changed at any time (except [SchedulerPhase.persistentCallbacks]).
  final ValueNotifier<ColumnResizeCallback?> onColumnResize;

  /// Contains a callback that will be called whenever the position of a column needs to change.
  /// The [null] value here will result in move handle not appearing on the screen.
  ///
  /// Internal logic assumes that the changes will get applied the next build-cycle.
  /// Failing to so will lead to unexpected behavior.
  ///
  /// Can be changed at any time (except [SchedulerPhase.persistentCallbacks]).
  final ValueNotifier<ColumnMoveCallback?> onColumnMove;

  /// Contains a callback that will be called whenever the translation of a column needs to change.
  /// The [null] value here will result in column movement not animating.
  ///
  /// Internal logic assumes that the changes will get applied the next build-cycle.
  /// Failing to so will lead to unexpected behavior.
  ///
  /// Can be changed at any time (except [SchedulerPhase.persistentCallbacks]).
  final ValueNotifier<ColumnTranslateCallback?> onColumnTranslate;

  /// Contains a number of columns at the start of the screen (left) that other columns will not get moved past.
  /// Keep in mind, being within this range does not prevent a column from being moved by starting
  /// [TableColumnControlHandlesPopupRoute] for it.
  ///
  /// Can be changed at any time (except [SchedulerPhase.persistentCallbacks]).
  final ValueNotifier<int> leadingImmovableColumnCount;

  /// Contains a number of columns at the end of the screen (right) that other columns will not get moved past.
  /// Keep in mind, being within this range does not prevent a column from being moved by starting
  /// [TableColumnControlHandlesPopupRoute] for it.
  ///
  /// Can be changed at any time (except [SchedulerPhase.persistentCallbacks]).
  final ValueNotifier<int> trailingImmovableColumnCount;

  /// This name conflicts with [barrierColor] so I gotta think of something better.
  ///
  /// Can be changed at any time (except [SchedulerPhase.persistentCallbacks]).
  final ValueNotifier<Color?> _barrierColor;

  /// Contains a builder function returning a [PreferredSizeWidget] that will be used for column resize handles.
  /// The handle will be laid out at exactly the preferred size. It must never be negative or infinite.
  ///
  /// Can be changed at any time (except [SchedulerPhase.persistentCallbacks]).
  final ValueNotifier<ResizeHandleBuilder> resizeHandleBuilder;

  /// Contains a builder function returning a [PreferredSizeWidget] that will be used for the column drag handle.
  /// The handle will be laid out at exactly the preferred size. It must never be negative or infinite.
  ///
  /// Can be changed at any time (except [SchedulerPhase.persistentCallbacks]).
  final ValueNotifier<DragHandleBuilder> dragHandleBuilder;

  /// Contains a builder function returning a [PreferredSizeWidget] that will be displayed close to the target cell.
  /// The popup will shrink in size if its preferred size is larger than the available space. Infinite preferred size
  /// will result in popup filling as much space as possible.
  ///
  /// Can be changed at any time (except [SchedulerPhase.persistentCallbacks]).
  final ValueNotifier<PopupBuilder?> popupBuilder;

  /// Contains a window margin for the popup. The popup widget will never get closer to the edge of the enclosing
  /// [Navigator] (edge of the screen for the application level [Navigator]).
  ///
  /// Can be changed at any time (except [SchedulerPhase.persistentCallbacks]).
  final ValueNotifier<EdgeInsets> popupPadding;

  /// Controls the duration of the following:
  /// - control handles enter/exit animations;
  /// - color barrier fade in/out animations;
  /// - popup fade in/out animations.
  @override
  final Duration transitionDuration;

  /// Contains a function that is called to determine a duration of the
  /// translation animation when a column gets moved. That allows for the
  /// duration to depend on the distance to travel.
  ///
  /// Can be changed at any time but ongoing animations will not respect
  /// the change.
  final ValueNotifier<ColumnTranslationDurationFunctor>
      columnTranslationDuration;

  /// Contains a [Curve] that is called to determine a rate of change of the
  /// translation animation when a column gets moved.
  ///
  /// Can be changed at any time but ongoing animations will not respect
  /// the change.
  final ValueNotifier<Curve> columnTranslationCurve;

  /// Creates [TableColumnControlHandlesPopupRoute] that updates columns in realtime as soon as the gesture happens.
  /// Although this results in a better user experience, depending on the complexity of a table and the end platform,
  /// frequent rebuilds can cause performance issues.
  ///
  /// The position of the controls and [TableView]/[SliverTableView] to control are determined by the
  /// [controlCellBuildContext] passed. It is intended that the [BuildContext] passed to the cellBuilder function
  /// is used.
  ///
  /// [columnIndex] is the position of the controlled column.
  ///
  /// Other parameters are used as initial values for corresponding [ValueNotifier] properties of the route that
  /// can be changed later in the lifecycle of the route. Refer to their documentation comments for their usage.
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
    Duration transitionDuration = const Duration(milliseconds: 200),
    ColumnTranslationDurationFunctor columnTranslationDuration =
        _defaultColumnTranslationDuration,
    Curve columnTranslationCurve = Curves.fastOutSlowIn,
  }) {
    var tableContentLayoutState = controlCellBuildContext
        .findAncestorStateOfType<TableContentLayoutState>();
    assert(
      tableContentLayoutState != null,
      'No TableView ancestor found.'
      ' Make sure to pass a correct BuildContext.'
      ' It is intended to use a BuildContext passed to a cellBuilder function.',
    );

    var cellRenderObject = controlCellBuildContext.findRenderObject();
    assert(cellRenderObject is RenderBox);

    var state = controlCellBuildContext
        .findAncestorStateOfType<TableColumnControlsControllable>();
    assert(state != null, 'No TableView ancestor found');
    state = state!;

    assert(
      onColumnMove == null || state.columns[columnIndex].key != null,
      _movingColumnsWithoutKeyAssertionMessage,
    );

    controlCellBuildContext.findRenderObject() as RenderBox;

    return TableColumnControlHandlesPopupRoute._(
      state,
      tableContentLayoutState!,
      cellRenderObject as RenderBox,
      columnIndex,
      state.columns[columnIndex].key!,
      transitionDuration: transitionDuration,
      columnTranslationDuration: columnTranslationDuration,
      columnTranslationCurve: columnTranslationCurve,
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

  final Key _targetColumnKey;

  TableColumnControlHandlesPopupRoute._(
    this._tableViewState,
    this._tableContentLayoutState,
    this._targetCellRenderObject,
    this._targetColumnIndex,
    this._targetColumnKey, {
    required this.transitionDuration,
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
    required ColumnTranslationDurationFunctor columnTranslationDuration,
    required Curve columnTranslationCurve,
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
        popupPadding = ValueNotifier(popupPadding),
        columnTranslationDuration = ValueNotifier(columnTranslationDuration),
        columnTranslationCurve = ValueNotifier(columnTranslationCurve);

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
            child: const SizedBox(
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

// this needs cleaning up

class _WidgetState extends State<_Widget>
    with TickerProviderStateMixin<_Widget> {
  final clearBarrierCounter = ValueNotifier<int>(0);

  final continuousScroll = ValueNotifier<int>(0);

  Ticker? continuousScrollTicker;

  late double width;
  late double minColumnWidth;
  bool popped = false;

  late int columnIndex;
  double dragValue = .0;

  /// 1 for LTR, -1 for RTL
  late int indexIncrement;

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
      _recentlyChangedColumns ?? route._tableViewState.columns;

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

    continuousScroll.addListener(_continuousScrollChanged);

    assert(() {
      route.onColumnMove.addListener(() {
        assert(
          route.onColumnMove.value == null || columns[columnIndex].key != null,
          _movingColumnsWithoutKeyAssertionMessage,
        );
      });
      return true;
    }());

    route._tableContentLayoutState.foregroundColumnKey = route._targetColumnKey;
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

    if (dragValue != .0 && route.onColumnTranslate.value != null) {
      SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
        if (route._tableViewState.mounted) {
          route.onColumnTranslate.value!(columnIndex, .0);
        }
      });
    }

    continuousScrollTicker
      ?..stop()
      ..dispose();

    if (route._tableContentLayoutState.foregroundColumnKey ==
        route._targetColumnKey) {
      route._tableContentLayoutState.foregroundColumnKey = null;
    }

    super.dispose();
  }

  void _routeChanged() => setState(() {});

  void _horizontalScrollChanged() => setState(() {});

  void _continuousScrollChanged() {
    final value = continuousScroll.value;
    continuousScrollTicker
      ?..stop()
      ..dispose();
    continuousScrollTicker = null;

    if (value == 0) {
      return;
    }

    var lastElapsed = Duration.zero;
    continuousScrollTicker = createTicker((elapsed) {
      final deltaSeconds =
          (elapsed.inMicroseconds - lastElapsed.inMicroseconds) / 1000000;
      lastElapsed = elapsed;

      final deltaPixels = value * 384 * deltaSeconds;

      final position = horizontalScrollController.position;
      final pixelsBefore = position.pixels;
      if (scrollHold == null) {
        position.pointerScroll(deltaPixels);
      } else {
        scrollHold!.cancel();
        position.pointerScroll(deltaPixels);
        scrollHold = position.hold(() {});
      }

      dragValue += indexIncrement * (position.pixels - pixelsBefore);
      _calculateMovement();
      onColumnTranslate(columnIndex, dragValue);
    })
      ..start();
  }

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
      SchedulerBinding.instance.addPostFrameCallback(
          (timeStamp) => Navigator.removeRoute(context, route));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!route._targetCellRenderObject.attached ||
        !route._tableContentLayoutState.mounted ||
        columnIndex >= route._tableViewState.columns.length ||
        route._tableViewState.columns[columnIndex].key !=
            route._targetColumnKey) {
      abort();

      return const SizedBox();
    }

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
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
                    duration: route.transitionDuration,
                    child: clearBarrierCounter == 0
                        ? ColoredBox(
                            color: route._barrierColor.value!,
                            child: const SizedBox(
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
        SafeArea(
          key: const ValueKey('content'),
          child: Builder(builder: (context) => _build(context)),
        ),
      ],
    );
  }

  Widget _build(BuildContext context) {
    final RenderBox originRenderObject;
    {
      final ro = context.findRenderObject();
      if (ro == null) {
        SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
          if (mounted) setState(() {});
        });

        return const SizedBox();
      }

      originRenderObject = ro as RenderBox;
    }

    _recentlyChangedColumns = null;
    _recentlyChangedTableContentLayoutData = null;

    indexIncrement =
        route._tableViewState.textDirection == TextDirection.ltr ? 1 : -1;

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
            columnIndex + indexIncrement == columns.length
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
          if (route.popupBuilder.value != null)
            ValueListenableBuilder(
              key: const ValueKey('popup'),
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
                    duration: route.transitionDuration,
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

    if (route._tableViewState.textDirection == TextDirection.ltr) {
      final scrollPosition = horizontalScrollController.position;
      scrollPosition.jumpTo(scrollPosition.pixels + delta);

      scrollHold?.cancel();
      scrollHold = horizontalScrollController.position.hold(() {});
    }
  }

  void _resizeUpdateTrailing(DragUpdateDetails details) {
    final delta = _resizeUpdate(details.delta.dx);

    trailingResizeHandleCorrection += delta;
    moveHandleCorrection += delta / 2;

    if (route._tableViewState.textDirection == TextDirection.rtl) {
      final scrollPosition = horizontalScrollController.position;
      scrollPosition.jumpTo(scrollPosition.pixels + delta);

      scrollHold?.cancel();
      scrollHold = horizontalScrollController.position.hold(() {});
    }
  }

  double _resizeUpdate(double delta) {
    final column = columns[columnIndex];
    final width = this.width + delta;
    final minResizeWidth = column.minResizeWidth ?? minColumnWidth;
    final maxResizeWidth = column.maxResizeWidth;
    if (width < minResizeWidth) {
      this.width = minResizeWidth;
      delta += minResizeWidth - width;
    } else if (maxResizeWidth != null && width > maxResizeWidth) {
      this.width = maxResizeWidth;
      delta += maxResizeWidth - width;
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

    if (route.onColumnTranslate.value != null) {
      onColumnTranslate(columnIndex, dragValue);
      leadingResizeHandleCorrection += details.delta.dx;
      moveHandleCorrection += details.delta.dx;
      trailingResizeHandleCorrection += details.delta.dx;
    }
  }

  void _calculateMovement() {
    final columns = this.columns;

    final tableContentLayoutData = this.tableContentLayoutData;

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
        continuousScroll.value = 0;
        return;
      }

      targetColumnSection = foundSection;
      offset = foundOffset;
      width = foundWidth;
    }

    void updateContinuousScroll() {
      final leftDistance =
          tableContentLayoutData.leftWidth - offset - dragValue;

      final rightDistance = offset +
          dragValue +
          width -
          tableContentLayoutData.leftWidth -
          tableContentLayoutData.centerWidth;

      if (leftDistance >= 0 && leftDistance >= rightDistance) {
        continuousScroll.value = -indexIncrement;
      } else if (rightDistance >= 0) {
        continuousScroll.value = indexIncrement;
      } else {
        continuousScroll.value = 0;
      }
    }

    if (dragValue > 0) {
      if (route._tableViewState.textDirection == TextDirection.ltr) {
        final value = route.trailingImmovableColumnCount.value;
        assert(
          value >= 0,
        );
        if (indexIncrement >= columns.length - value) {
          continuousScroll.value = 0;
          return;
        }
      } else {
        final value = route.leadingImmovableColumnCount.value;
        assert(value >= 0);
        if (columnIndex <= value) {
          return;
        }
      }

      TableContentColumnData? closestColumnSection;
      int? closestColumnSectionIndex;
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
                section.indices[i] * indexIncrement >
                    columnIndex * indexIncrement &&
                (closestColumnDistance == null ||
                    distance < closestColumnDistance)) {
              closestColumnSectionIndex = i;
              closestColumnDistance = distance;
              closestColumnSection = section;
            }
          }
        }
      }

      if (closestColumnSectionIndex == null || closestColumnSection == null) {
        updateContinuousScroll();
        return;
      }

      final closestColumnGlobalIndex =
          closestColumnSection.indices[closestColumnSectionIndex];
      final closestColumn = columns[closestColumnGlobalIndex];

      if (identical(targetColumnSection, tableContentLayoutData.fixedColumns)) {
        if (closestColumnGlobalIndex != columnIndex + indexIncrement &&
            !identical(closestColumnSection, targetColumnSection)) {
          continuousScroll.value = 0;
          return;
        }
      } else {
        if (identical(
            closestColumnSection, tableContentLayoutData.fixedColumns)) {
          if (closestColumnGlobalIndex != columnIndex + indexIncrement) {
            updateContinuousScroll();
            return;
          }
        } else {
          if (closestColumnSection.positions[closestColumnSectionIndex] -
                  closestColumn.translation +
                  closestColumn.width >
              tableContentLayoutData.leftWidth +
                  tableContentLayoutData.centerWidth) {
            updateContinuousScroll();
            return;
          }
        }
      }

      final nextWidth = closestColumn.width;
      if (dragValue > nextWidth / 2) {
        _animateColumnTranslation(closestColumnGlobalIndex, width, null);
        onColumnMove(columnIndex, closestColumnGlobalIndex);
        dragValue -= nextWidth;
        columnIndex = closestColumnGlobalIndex;
        _layoutDataChanged();
        _calculateMovement();
        return;
      }
    } else if (dragValue < 0) {
      if (route._tableViewState.textDirection == TextDirection.ltr) {
        final value = route.leadingImmovableColumnCount.value;
        assert(value >= 0);
        if (columnIndex <= value) {
          return;
        }
      } else {
        final value = route.trailingImmovableColumnCount.value;
        assert(
          value >= 0,
        );
        if (indexIncrement >= columns.length - value) {
          continuousScroll.value = 0;
          return;
        }
      }

      TableContentColumnData? closestColumnSection;
      int? closestColumnSectionIndex;
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
                section.indices[i] * indexIncrement <
                    columnIndex * indexIncrement &&
                (closestColumnDistance == null ||
                    distance < closestColumnDistance)) {
              closestColumnDistance = distance;
              closestColumnSection = section;
              closestColumnSectionIndex = i;
            }
          }
        }
      }

      if (closestColumnSectionIndex == null || closestColumnSection == null) {
        updateContinuousScroll();
        return;
      }

      final closestColumnGlobalIndex =
          closestColumnSection.indices[closestColumnSectionIndex];
      final closestColumn = columns[closestColumnGlobalIndex];

      if (identical(targetColumnSection, tableContentLayoutData.fixedColumns)) {
        if (closestColumnGlobalIndex != columnIndex - 1 &&
            !identical(closestColumnSection, targetColumnSection)) {
          continuousScroll.value = 0;
          return;
        }
      } else {
        if (identical(
            closestColumnSection, tableContentLayoutData.fixedColumns)) {
          if (closestColumnGlobalIndex != columnIndex - 1) {
            updateContinuousScroll();
            return;
          }
        } else {
          if (closestColumnSection.positions[closestColumnSectionIndex] -
                  columns[closestColumnGlobalIndex].translation <
              tableContentLayoutData.leftWidth) {
            updateContinuousScroll();
            return;
          }
        }
      }

      final nextWidth = closestColumn.width;
      if (dragValue < nextWidth / -2) {
        _animateColumnTranslation(closestColumnGlobalIndex, -width, null);
        onColumnMove(columnIndex, closestColumnGlobalIndex);

        dragValue += nextWidth;
        columnIndex = closestColumnGlobalIndex;
        _layoutDataChanged();
        _calculateMovement();
        return;
      }
    }

    continuousScroll.value = 0;
  }

  void _dragEnd(DragEndDetails details) {
    clearBarrierCounter.value--;
    _animateColumnTranslation(
        columnIndex, dragValue, columns[columnIndex].key, false);
    continuousScroll.value = 0;
    dragValue = .0;
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

    late Ticker ticker;

    void stop() {
      ticker
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

    int currentGlobalIndex = globalIndex;
    double translationLeft = -translation;
    Duration lastElapsed = Duration.zero;

    int? findCurrentGlobalIndex() {
      if (currentGlobalIndex > columns.length ||
          (columns[currentGlobalIndex]).key != key) {
        for (var i = 0; i < columns.length; i++) {
          if (columns[i].key == key) {
            return currentGlobalIndex = i;
          }
        }

        return null;
      }

      return currentGlobalIndex;
    }

    void correctHandlesIfNecessary(TableColumn column, double correction) {
      if (correctHandles != null && column.key == correctHandles) {
        leadingResizeHandleCorrection += correction;
        trailingResizeHandleCorrection += correction;
        moveHandleCorrection += correction;
      }
    }

    final animationDuration =
        route.columnTranslationDuration.value(translation.abs());

    final curve = route.columnTranslationCurve.value;

    ticker = createTicker((elapsed) {
      final columns = this.columns;

      final index = findCurrentGlobalIndex();

      if (index == null) {
        stop();
        return;
      }

      final column = columns[index];

      if (elapsed >= animationDuration) {
        stop();
        return;
      }

      final valuePrev =
          lastElapsed.inMicroseconds / animationDuration.inMicroseconds;

      final valueNext =
          elapsed.inMicroseconds / animationDuration.inMicroseconds;

      final deltaTranslation = -translation *
          (curve.transform(valueNext) - curve.transform(valuePrev));

      lastElapsed = elapsed;

      translationLeft -= deltaTranslation;
      onColumnTranslate(index, column.translation + deltaTranslation);

      correctHandlesIfNecessary(column, deltaTranslation);
    });

    final onComplete = ticker.start();

    onComplete.orCancel.then((_) {
      final index = findCurrentGlobalIndex();
      if (index == null) return;
      final column = columns[index];
      onColumnTranslate(index, column.translation + translationLeft);
      correctHandlesIfNecessary(column, translationLeft);
    });
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
