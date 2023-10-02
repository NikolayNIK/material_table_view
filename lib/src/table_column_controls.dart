import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:material_table_view/src/table_column.dart';
import 'package:material_table_view/src/table_layout.dart';

PreferredSizeWidget _defaultResizeHandleBuilder(
  BuildContext context,
  bool leading,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
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
                    leading ? Icons.switch_right : Icons.switch_left,
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

typedef void ColumnResizeCallback(int index, TableColumn newColumn);

class TableColumnControls extends StatefulWidget {
  final List<TableColumn> columns;

  final ScrollController scrollController;

  final void Function(List<TableColumn> columns)? onColumnsChange;

  final ColumnResizeCallback onColumnResize;

  final Widget child;

  final Color? barrierColor;

  final PreferredSizeWidget Function(
    BuildContext context,
    bool leading,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  )? resizeHandleBuilder;

  TableColumnControls({
    super.key,
    required this.scrollController,
    required this.columns,
    this.onColumnsChange,
    required this.child,
    ColumnResizeCallback? onColumnResize,
    this.barrierColor,
    this.resizeHandleBuilder = _defaultResizeHandleBuilder,
  }) : onColumnResize = onColumnResize ??
            (onColumnsChange == null
                ? _defaultOnColumnResize
                : (index, column) {
                    final list = columns.toList(growable: false);
                    list[index] = column;
                    onColumnsChange(list);
                  });

  static void _defaultOnColumnResize(int _, TableColumn __) {}

  @override
  State<StatefulWidget> createState() => _TableColumnControlsState();

  static TableColumnControlsInterface of(BuildContext context) {
    final state = context.findAncestorStateOfType<_TableColumnControlsState>();
    assert(
      state != null,
      'Could not find TableColumnControls widget ancestor.'
      ' Make sure you used the right BuildContext and your TableView'
      ' is directly or indirectly contained within TableColumnControls widget.',
    );

    return TableColumnControlsInterface._(context, state!);
  }
}

class TableColumnControlsInterface {
  final BuildContext context;
  final _TableColumnControlsState _state;

  TableColumnControlsInterface._(
    this.context,
    this._state,
  );

  FutureOr<void> invoke(int columnIndex) => _state.invoke(context, columnIndex);
}

class _TableColumnControlsState extends State<TableColumnControls> {
  @override
  Widget build(BuildContext context) => Navigator(
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (context) => widget.child,
        ),
      );

  FutureOr<void> invoke(BuildContext context, int columnIndex) async {
    final tableContentLayoutState =
        context.findAncestorStateOfType<TableContentLayoutState>();
    if (tableContentLayoutState == null) return;

    final RenderBox ro;
    {
      final obj = context.findRenderObject();
      assert(obj is RenderBox);
      ro = obj as RenderBox;
    }

    await Navigator.of(context).push(
      _ControlsPopupRoute(
        barrierColor: widget.barrierColor,
        builder: (context, animation, secondaryAnimation) => _Widget(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          tableColumnControlsRenderObject:
              this.context.findRenderObject() as RenderBox,
          tableContentLayoutState: tableContentLayoutState,
          tableColumnControls: widget,
          cellRenderObject: ro,
          columnIndex: columnIndex,
        ),
      ),
    );
  }
}

class _ControlsPopupRoute extends ModalRoute<void> {
  final Color? barrierColor;

  final Widget Function(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) builder;

  _ControlsPopupRoute({
    required this.builder,
    required this.barrierColor,
  });

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => null;

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
          builder(
            context,
            animation,
            secondaryAnimation,
          ),
        ],
      );

  @override
  Duration get transitionDuration => const Duration(milliseconds: 200);

  @override
  bool get maintainState => false;

  @override
  bool get opaque => false;
}

class _Widget extends StatefulWidget {
  final Animation<double> animation, secondaryAnimation;
  final TableColumnControls tableColumnControls;
  final RenderBox tableColumnControlsRenderObject;
  final TableContentLayoutState tableContentLayoutState;
  final RenderBox cellRenderObject;
  final int columnIndex;

  const _Widget({
    required this.animation,
    required this.secondaryAnimation,
    required this.tableColumnControls,
    required this.tableColumnControlsRenderObject,
    required this.tableContentLayoutState,
    required this.cellRenderObject,
    required this.columnIndex,
  });

  @override
  State<_Widget> createState() => _WidgetState();
}

class _WidgetState extends State<_Widget> {
  late double width;
  late double minColumnWidth;
  bool popped = false;

  double leadingResizeHandleCorrection = .0,
      trailingResizeHandleCorrection = .0;

  ScrollHoldController? scrollHold;

  @override
  void initState() {
    super.initState();

    widget.tableContentLayoutState.addListener(_parentDataChanged);
    widget.tableColumnControls.scrollController
        .addListener(_horizontalScrollChanged);
  }

  @override
  void didUpdateWidget(covariant _Widget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.tableContentLayoutState != widget.tableContentLayoutState) {
      oldWidget.tableContentLayoutState.removeListener(_parentDataChanged);
      widget.tableContentLayoutState.addListener(_parentDataChanged);
    }

    if (oldWidget.tableColumnControls.scrollController !=
        oldWidget.tableColumnControls.scrollController) {
      oldWidget.tableColumnControls.scrollController
          .removeListener(_horizontalScrollChanged);
      oldWidget.tableColumnControls.scrollController
          .addListener(_horizontalScrollChanged);
    }
  }

  @override
  void dispose() {
    widget.tableContentLayoutState.removeListener(_parentDataChanged);
    widget.tableColumnControls.scrollController
        .removeListener(_horizontalScrollChanged);
    scrollHold?.cancel();

    super.dispose();
  }

  void _horizontalScrollChanged() => setState(() {});

  void _parentDataChanged() =>
      SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
        if (mounted) setState(() {});
      });

  @override
  Widget build(BuildContext context) {
    if (!widget.cellRenderObject.attached ||
        !widget.tableColumnControlsRenderObject.attached ||
        !widget.tableContentLayoutState.mounted) {
      if (!popped) {
        popped = true;
        SchedulerBinding.instance
            .addPostFrameCallback((timeStamp) => Navigator.pop(context));
      }

      return SizedBox();
    }

    final leadingResizeHandleCorrection = this.leadingResizeHandleCorrection;
    final trailingResizeHandleCorrection = this.trailingResizeHandleCorrection;

    this.leadingResizeHandleCorrection = .0;
    this.trailingResizeHandleCorrection = .0;

    final leadingResizeHandle = widget.columnIndex == 0
        ? null
        : widget.tableColumnControls.resizeHandleBuilder
            ?.call(context, true, widget.animation, widget.secondaryAnimation);

    final trailingResizeHandle = widget.columnIndex + 1 ==
            widget.tableColumnControls.columns.length
        ? null
        : widget.tableColumnControls.resizeHandleBuilder
            ?.call(context, false, widget.animation, widget.secondaryAnimation);

    final offset = widget.tableColumnControlsRenderObject
        .globalToLocal(widget.cellRenderObject.localToGlobal(Offset.zero));

    minColumnWidth = .5 *
        ((leadingResizeHandle?.preferredSize.width ?? .0) +
            (trailingResizeHandle?.preferredSize.height ?? .0));

    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        fit: StackFit.expand,
        children: [
          if (leadingResizeHandle != null)
            Positioned(
              left: offset.dx +
                  leadingResizeHandleCorrection -
                  leadingResizeHandle.preferredSize.width / 2,
              top: offset.dy +
                  widget.cellRenderObject.size.height -
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
              left: offset.dx +
                  trailingResizeHandleCorrection +
                  widget.cellRenderObject.size.width -
                  trailingResizeHandle.preferredSize.width / 2,
              top: offset.dy +
                  widget.cellRenderObject.size.height -
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
        ],
      ),
    );
  }

  void _resizeStart(DragStartDetails details) {
    width = widget.tableColumnControls.columns[widget.columnIndex].width;
    scrollHold =
        widget.tableColumnControls.scrollController.position.hold(() {});
  }

  void _resizeUpdateLeading(DragUpdateDetails details) {
    final delta = _resizeUpdate(-details.delta.dx);

    leadingResizeHandleCorrection -= delta;

    final scrollPosition = widget.tableColumnControls.scrollController.position;
    scrollPosition.jumpTo(scrollPosition.pixels + delta);

    scrollHold?.cancel();
    scrollHold =
        widget.tableColumnControls.scrollController.position.hold(() {});
  }

  void _resizeUpdateTrailing(DragUpdateDetails details) {
    final delta = _resizeUpdate(details.delta.dx);

    trailingResizeHandleCorrection += delta;
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

  void _resizeUpdateColumns() => widget.tableColumnControls.onColumnResize(
      widget.columnIndex,
      widget.tableColumnControls.columns[widget.columnIndex]
          .copyWith(width: width));

  void _resizeEnd(DragEndDetails details) {
    scrollHold?.cancel();
    scrollHold = null;
  }
}
