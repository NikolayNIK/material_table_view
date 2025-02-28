import 'dart:math';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:material_table_view/src/table_section_vertical_scroll_offset.dart';

/// This widget allows inserting box widget amids the sliver layout protocol
/// and then continue sliver layout protocol as if nothing happened.
@immutable
class SliverPassthrough extends RenderObjectWidget {
  const SliverPassthrough({
    super.key,
    this.minHeight = .0,
    required this.builder,
  }) : super();

  final double minHeight;

  final Widget Function(
    BuildContext context,
    TableSectionOffset verticalOffset,
  ) builder;

  @override
  RenderObjectElement createElement() => _SliverPassthroughElement(this);

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderSliverPassthrough()..minHeight = minHeight;

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSliverPassthrough renderObject,
  ) {
    renderObject.minHeight = minHeight;
  }
}

class _SliverPassthroughElement extends RenderObjectElement {
  _SliverPassthroughElement(SliverPassthrough super.widget);

  ShiftedTableSectionOffset? _verticalOffset;

  Element? _child;

  ScrollPosition get _scrollablePosition =>
      Scrollable.of(this, axis: Axis.vertical).position;

  @override
  void visitChildren(ElementVisitor visitor) {
    if (_child != null) visitor(_child!);
  }

  @override
  void forgetChild(Element child) {
    assert(child == _child);
    _child = null;

    super.forgetChild(child);
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);

    _verticalOffset = ShiftedTableSectionOffset(_scrollablePosition);

    rebuild(force: true);
  }

  @override
  void update(SliverPassthrough newWidget) {
    super.update(newWidget);

    rebuild(force: true);
  }

  @override
  void performRebuild() {
    super.performRebuild();

    _verticalOffset!.offset = _scrollablePosition;
    (renderObject as RenderSliverPassthrough)._offsetCorrection =
        _verticalOffset!.shift;

    _updateChild();
  }

  void _updateChild() {
    _child = updateChild(
      _child,
      (widget as SliverPassthrough).builder(this, _verticalOffset!),
      null,
    );
  }

  @override
  void insertRenderObjectChild(RenderObject child, Object? slot) {
    final RenderObjectWithChildMixin<RenderObject> renderObject =
        this.renderObject as RenderObjectWithChildMixin<RenderObject>;
    assert(slot == null);
    assert(renderObject.debugValidateChild(child));
    renderObject.child = child;
    assert(renderObject == this.renderObject);
  }

  @override
  void moveRenderObjectChild(
      RenderObject child, Object? oldSlot, Object? newSlot) {
    assert(false);
  }

  @override
  void removeRenderObjectChild(RenderObject child, Object? slot) {
    final RenderObjectWithChildMixin<RenderObject> renderObject =
        this.renderObject as RenderObjectWithChildMixin<RenderObject>;
    assert(slot == null);
    assert(renderObject.child == child);
    renderObject.child = null;
    assert(renderObject == this.renderObject);
  }
}

class RenderSliverPassthrough extends RenderSliverSingleBoxAdapter {
  ValueNotifier<double>? _offsetCorrection;

  double _minHeight = .0;

  _RenderBoxToSliverPassthrough? _passthroughChild;

  get passthroughConstraints => constraints;

  set minHeight(double value) {
    if (_minHeight != value) {
      _minHeight = value;
      markNeedsLayout();
    }
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      geometry = SliverGeometry.zero;
      return;
    }

    final SliverConstraints constraints = this.constraints;

    final passthroughChild = _passthroughChild!;

    // layout sliver passthrough descendant first
    passthroughChild._performEarlyLayout();

    final sliverChild = _passthroughChild!.child!;
    final childGeometry = sliverChild.geometry!;

    // layout ourselves based on a sliver descendant
    final scrollExtent = childGeometry.scrollExtent + _minHeight;
    final paintExtent =
        calculatePaintOffset(constraints, from: .0, to: scrollExtent);

    geometry = SliverGeometry(
      scrollExtent: scrollExtent,
      paintExtent: paintExtent,
      cacheExtent:
          calculateCacheOffset(constraints, from: .0, to: scrollExtent),
      maxPaintExtent: scrollExtent,
    );

    // layout the box child based on sliver descendant information
    final childHeight = max(_minHeight, paintExtent);

    child.layout(
      BoxConstraints.tightFor(
        width: constraints.crossAxisExtent,
        height: childHeight,
      ),
    );

    final childParentData = child.parentData! as SliverPhysicalParentData;
    final correction = childHeight > constraints.remainingPaintExtent ||
            paintExtent > _minHeight
        ? .0
        : paintExtent - _minHeight;

    childParentData.paintOffset = Offset(.0, correction);
    _offsetCorrection?.value = correction;
  }

  @override
  bool hitTestChildren(SliverHitTestResult result,
          {required double mainAxisPosition,
          required double crossAxisPosition}) =>
      child!.hitTest(
        BoxHitTestResult.wrap(result),
        position: Offset(crossAxisPosition, mainAxisPosition),
      );
}

@immutable
class BoxToSliverPassthrough extends SingleChildRenderObjectWidget {
  BoxToSliverPassthrough({
    super.key,
    required Widget sliver,
  }) : super(child: _SliverPassthroughAdapter(sliver: sliver));

  @override
  RenderBox createRenderObject(BuildContext context) =>
      _RenderBoxToSliverPassthrough();
}

class _RenderBoxToSliverPassthrough extends RenderBox
    with RenderObjectWithChildMixin<RenderSliver> {
  _RenderBoxToSliverPassthrough();

  RenderSliverPassthrough? passthroughParent;

  @override
  bool get sizedByParent => true;

  RenderSliverPassthrough findPassthroughParent() {
    RenderObject? parent = this.parent;
    while (parent != null) {
      if (parent is RenderSliverPassthrough) {
        return parent;
      }

      parent = parent.parent;
    }

    throw AssertionError();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);

    (passthroughParent = findPassthroughParent())._passthroughChild = this;
  }

  @override
  void detach() {
    super.detach();

    passthroughParent?._passthroughChild = null;
    passthroughParent = null;
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) =>
      constraints.biggest;

  void _performEarlyLayout() => performLayout();

  @override
  void performLayout() => child!.layout(passthroughParent!.constraints);

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child!;
    if (!child.geometry!.visible) return;

    context.paintChild(child, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final child = this.child!;

    return child.geometry!.visible &&
        child.hitTest(
          SliverHitTestResult.wrap(result),
          mainAxisPosition: position.dy,
          crossAxisPosition: position.dx,
        );
  }
}

@immutable
class _SliverPassthroughAdapter extends SingleChildRenderObjectWidget {
  const _SliverPassthroughAdapter({required Widget sliver})
      : super(child: sliver);

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSliverPassthroughAdapter();
}

class _RenderSliverPassthroughAdapter extends RenderProxySliver {
  @override
  void markNeedsLayout() {
    super.markNeedsLayout();

    final parent = this.parent;
    if (parent != null) {
      (parent as _RenderBoxToSliverPassthrough)
          .passthroughParent
          ?.markNeedsLayout();
    }
  }
}
