import 'dart:math';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// This widget allows inserting box widget amids the sliver layout protocol
/// and then continue sliver layout protocol as if nothing happened.
@immutable
class SliverPassthrough extends SingleChildRenderObjectWidget {
  const SliverPassthrough({
    super.key,
    required this.minHeight,
    required Widget child,
  }) : super(child: child);

  final double minHeight;

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

class RenderSliverPassthrough extends RenderSliverSingleBoxAdapter {
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

    final sliverChild = _passthroughChild!.child!;

    // layout sliver passthrough descendant first
    sliverChild.layout(passthroughConstraints);

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
    childParentData.paintOffset = Offset(
      .0,
      childHeight > constraints.remainingPaintExtent || paintExtent > _minHeight
          ? .0
          : paintExtent - _minHeight,
    );
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
  const BoxToSliverPassthrough({
    super.key,
    required Widget sliver,
  }) : super(child: sliver);

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
  void markNeedsLayout() {
    super.markNeedsLayout();

    passthroughParent?.markNeedsLayout();
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) =>
      constraints.biggest;

  @override
  void performLayout() => child!.layout(
        passthroughParent!.constraints,
        parentUsesSize: true,
      );

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child!;
    if (!child.geometry!.visible) return;

    context.paintChild(child, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      child!.hitTest(
        SliverHitTestResult.wrap(result),
        mainAxisPosition: position.dy,
        crossAxisPosition: position.dx,
      );
}
