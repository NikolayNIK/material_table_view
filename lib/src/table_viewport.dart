import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class TableViewport extends Viewport {
  TableViewport({
    super.key,
    super.axisDirection = AxisDirection.down,
    super.crossAxisDirection,
    super.anchor = 0.0,
    required super.offset,
    super.center,
    super.cacheExtent,
    super.cacheExtentStyle = CacheExtentStyle.pixel,
    super.clipBehavior = Clip.hardEdge,
    super.slivers = const <Widget>[],
  });

  @override
  RenderViewport createRenderObject(BuildContext context) =>
      _RenderTableViewport(
        axisDirection: axisDirection,
        crossAxisDirection: crossAxisDirection ??
            Viewport.getDefaultCrossAxisDirection(context, axisDirection),
        anchor: anchor,
        offset: offset,
        cacheExtent: cacheExtent,
        cacheExtentStyle: cacheExtentStyle,
        clipBehavior: clipBehavior,
      );
}

class _RenderTableViewport extends RenderViewport {
  _RenderTableViewport({
    super.axisDirection,
    required super.crossAxisDirection,
    required super.offset,
    super.anchor = 0.0,
    super.cacheExtent,
    super.cacheExtentStyle,
    super.clipBehavior,
  });

  // All that crap is just for this.
  @override
  bool get isRepaintBoundary => false;
}
