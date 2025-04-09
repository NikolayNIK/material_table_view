import 'dart:math';

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:material_table_view/src/table_column.dart';
import 'package:material_table_view/src/table_column_resolve_layout_extension.dart';

class TableLayoutBox extends RenderObjectWidget {
  const TableLayoutBox({
    super.key,
    required this.columns,
    required this.scrollPadding,
    required this.shrinkWrapHorizontal,
    required this.builder,
  });

  final bool shrinkWrapHorizontal;

  final EdgeInsets scrollPadding;

  final List<TableColumn> columns;

  final Widget Function(
    BuildContext context,
    List<TableColumn> resolvedColumns,
    double width,
  ) builder;

  @override
  RenderObjectElement createElement() => TableLayoutBoxElement(this);

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderTableLayoutBox();

  double get _intrinsicWidth =>
      columns.fold<double>(
        .0,
        (previousValue, element) => previousValue + element.width,
      ) +
      scrollPadding.horizontal;
}

class TableLayoutBoxElement extends RenderObjectElement {
  TableLayoutBoxElement(TableLayoutBox super.widget);

  Element? _child;

  @override
  BuildScope get buildScope => _buildScope;

  late final BuildScope _buildScope =
      BuildScope(scheduleRebuild: _scheduleRebuild);

  bool _deferredCallbackScheduled = false;

  void _scheduleRebuild() {
    if (_deferredCallbackScheduled) {
      return;
    }

    final bool deferMarkNeedsLayout =
        SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle ||
            SchedulerBinding.instance.schedulerPhase ==
                SchedulerPhase.postFrameCallbacks;

    if (!deferMarkNeedsLayout) {
      renderObject.markNeedsLayout();
      return;
    }

    _deferredCallbackScheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback(_frameCallback);
  }

  void _frameCallback(Duration timestamp) {
    _deferredCallbackScheduled = false;

    if (mounted) {
      renderObject.markNeedsLayout();
    }
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    if (_child != null) {
      visitor(_child!);
    }
  }

  @override
  void forgetChild(Element child) {
    assert(child == _child);
    _child = null;
    super.forgetChild(child);
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot); // Creates the renderObject.
    (renderObject as _RenderTableLayoutBox).updateElement(this);
  }

  @override
  void update(TableLayoutBox newWidget) {
    super.update(newWidget);

    (renderObject as _RenderTableLayoutBox).updateElement(this);

    _needsBuild = true;
    renderObject.markNeedsLayout();
  }

  @override
  void markNeedsBuild() {
    renderObject.markNeedsLayout();
    _needsBuild = true;
  }

  @override
  void performRebuild() {
    renderObject.markNeedsLayout();
    _needsBuild = true;
    super.performRebuild();
  }

  @override
  void unmount() {
    (renderObject as _RenderTableLayoutBox).updateElement(null);
    super.unmount();
  }

  double? _previousMaxWidth;
  bool _needsBuild = true;

  void _rebuildWithConstraints(BoxConstraints constraints) {
    @pragma('vm:notify-debugger-on-exception')
    void updateChildCallback() {
      final widget = this.widget as TableLayoutBox;
      final width = widget.shrinkWrapHorizontal
          ? min(
              constraints.maxWidth,
              widget._intrinsicWidth,
            )
          : constraints.maxWidth;

      final built = widget.builder(
          this,
          widget.shrinkWrapHorizontal
              ? widget.columns
              : widget.columns
                  .resolveLayout(width - widget.scrollPadding.horizontal),
          width);

      debugWidgetBuilderValue(widget, built);

      try {
        _child = updateChild(_child, built, null);
      } finally {
        _needsBuild = false;
        _previousMaxWidth = constraints.maxWidth;
      }
    }

    final VoidCallback? callback =
        _needsBuild || (constraints.maxWidth != _previousMaxWidth)
            ? updateChildCallback
            : null;
    owner!.buildScope(this, callback);
  }

  @override
  void insertRenderObjectChild(RenderBox child, Object? slot) =>
      (renderObject as _RenderTableLayoutBox).child = child;

  @override
  void moveRenderObjectChild(
    RenderObject child,
    Object? oldSlot,
    Object? newSlot,
  ) {
    assert(false);
  }

  @override
  void removeRenderObjectChild(RenderObject child, Object? slot) =>
      (renderObject as _RenderTableLayoutBox).child = null;
}

class _RenderTableLayoutBox extends RenderBox
    with RenderObjectWithChildMixin<RenderBox> {
  TableLayoutBoxElement? _element;

  void updateElement(TableLayoutBoxElement? value) {
    if (value == _element) {
      return;
    }
    _element = value;
    markNeedsLayout();
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      computeMaxIntrinsicWidth(height);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      (_element!.widget as TableLayoutBox)._intrinsicWidth;

  @override
  double computeMinIntrinsicHeight(double width) {
    // child typically ends up null here, so this is hopeless
    assert(_debugThrowIfNotCheckingIntrinsics());
    return child?.computeMinIntrinsicHeight(width) ?? .0;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    // child typically ends up null here, so this is hopeless
    assert(_debugThrowIfNotCheckingIntrinsics());
    return child?.computeMaxIntrinsicHeight(width) ?? .0;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    assert(
      debugCannotComputeDryLayout(
        reason:
            'Calculating the dry layout would require running the layout callback '
            'speculatively, which might mutate the live render object tree.',
      ),
    );
    return Size.zero;
  }

  @override
  double? computeDryBaseline(
      BoxConstraints constraints, TextBaseline baseline) {
    assert(
      debugCannotComputeDryLayout(
        reason:
            'Calculating the dry baseline would require running the layout callback '
            'speculatively, which might mutate the live render object tree.',
      ),
    );
    return null;
  }

  @override
  void performLayout() {
    invokeLayoutCallback(_element!._rebuildWithConstraints);

    final BoxConstraints constraints = this.constraints;
    if (child != null) {
      final widget = (_element!.widget as TableLayoutBox);
      final intrinsicWidth = widget._intrinsicWidth;
      child!.layout(
          widget.shrinkWrapHorizontal
              ? BoxConstraints(
                  minWidth: intrinsicWidth,
                  maxWidth: intrinsicWidth,
                  minHeight: constraints.minHeight,
                  maxHeight: constraints.maxHeight,
                )
              : constraints,
          parentUsesSize: true);
      size = child!.size;
    } else {
      size = constraints.biggest;
    }
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      child?.getDistanceToActualBaseline(baseline) ??
      super.computeDistanceToActualBaseline(baseline);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      child?.hitTest(result, position: position) ?? false;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      context.paintChild(child!, offset);
    }
  }

  bool _debugThrowIfNotCheckingIntrinsics() {
    assert(() {
      if (!RenderObject.debugCheckingIntrinsics) {
        throw FlutterError(
          'TableView does not support returning intrinsic height.',
        );
      }
      return true;
    }());

    return true;
  }
}
