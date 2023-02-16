import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:material_table_view/src/table_painting_context.dart';

/// This widget is meant to provide the same functionality as a regular
/// [Opacity] widget. As a regular [Opacity] widget can not be used to wrap
/// an entire table row, this one should be used instead.
///
/// Note that this widget is considerably
/// more expensive to paint compared to already expensive regular counterpart.
/// This widget is only meant for animating relatively short transitions.
///
/// This widget will not work for any other purpose.
class TableRowOpacity extends SingleChildRenderObjectWidget {
  final double opacity;

  TableRowOpacity({
    super.key,
    required this.opacity,
    required super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderTableRowOpacity(opacity: opacity);

  @override
  void updateRenderObject(
      BuildContext context, covariant _RenderTableRowOpacity renderObject) {
    super.updateRenderObject(context, renderObject);

    renderObject.opacity = opacity;
  }
}

class _RenderTableRowOpacity extends RenderProxyBox {
  int _alpha;

  _RenderTableRowOpacity({required double opacity})
      : _alpha = ui.Color.getAlphaFromOpacity(opacity);

  set opacity(double opacity) {
    final alpha = ui.Color.getAlphaFromOpacity(opacity);
    if (alpha != _alpha) {
      _alpha = alpha;
      markNeedsPaint();
    }
  }

  void paint(PaintingContext context, Offset offset) {
    if (_alpha == 0) return;

    // do we just assume the color space here???
    if (_alpha == 255) {
      super.paint(context, offset);
      return;
    }

    context.requireTablePaintingContext().paintChildrenLayers(
          () => OpacityLayer(alpha: _alpha),
          (context) => super.paint(context, offset),
        );
  }
}
