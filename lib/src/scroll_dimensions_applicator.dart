import 'dart:math';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// This widget provides a strait forward (dumb) way to set
/// known in advance dimensions of a [ScrollPosition].
class ScrollDimensionsApplicator extends SingleChildRenderObjectWidget {
  final ScrollPosition position;
  final Axis axis;
  final double scrollExtent;

  const ScrollDimensionsApplicator({
    super.key,
    required this.position,
    required this.axis,
    required this.scrollExtent,
    required Widget child,
  }) : super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderScrollDimensionsApplicator(
        position,
        axis,
        scrollExtent,
      );

  @override
  void updateRenderObject(BuildContext context,
      covariant RenderScrollDimensionsApplicator renderObject) {
    super.updateRenderObject(context, renderObject);

    renderObject
      ..position = position
      ..axis = axis
      ..scrollExtent = scrollExtent;
  }
}

class RenderScrollDimensionsApplicator extends RenderProxyBox {
  ScrollPosition position;
  Axis _axis;
  double _scrollExtent;

  RenderScrollDimensionsApplicator(
    this.position,
    this._axis,
    this._scrollExtent,
  );

  set axis(Axis value) {
    if (value != _axis) {
      _axis = value;
      markNeedsLayout();
    }
  }

  set scrollExtent(double value) {
    if (value != _scrollExtent) {
      _scrollExtent = value;
      markNeedsLayout();
    }
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  void performLayout() {
    super.performLayout();

    final viewportDimension = _axis == Axis.vertical ? size.height : size.width;
    position.applyViewportDimension(viewportDimension);
    position.applyContentDimensions(
      0,
      max(.0, _scrollExtent - viewportDimension),
    );
  }
}
