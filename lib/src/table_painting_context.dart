import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:material_table_view/src/table_placeholder_shader_configuration.dart';

class TablePaintingLayerPair {
  final PaintingContext fixed, scrolled;

  TablePaintingLayerPair({
    required this.fixed,
    required this.scrolled,
  }) {
    fixed.setIsComplexHint();
    fixed.setWillChangeHint();

    scrolled.setIsComplexHint();
    scrolled.setWillChangeHint();
  }
}

class TablePaintingContext extends PaintingContext {
  TablePaintingContext({
    required ContainerLayer mainLayer,
    required PaintingContext context,
    required Path scrolledClipPath,
    required TableViewPlaceholderShaderConfig? placeholderShaderConfig,
    required Offset offset,
    required Size size,
  }) : super(mainLayer, context.estimatedBounds) {
    final regularFixed = mainLayer;
    final regularScrolled = ClipPathLayer(clipPath: scrolledClipPath);

    context.addLayer(regularFixed);
    context.addLayer(regularScrolled);

    regular = TablePaintingLayerPair(
        fixed: PaintingContext(regularFixed, context.estimatedBounds),
        scrolled: PaintingContext(regularScrolled, context.estimatedBounds));

    if (placeholderShaderConfig == null) {
      placeholderShaderContext = null;
      placeholder = regular;
    } else {
      final layer = ShaderMaskLayer()
        ..blendMode = placeholderShaderConfig.blendMode
        ..maskRect = offset & size
        ..shader = placeholderShaderConfig.shaderCallback(Offset.zero & size);

      final placeholderFixed = ContainerLayer();
      final placeholderScrolled = ClipPathLayer(clipPath: scrolledClipPath);

      placeholderShaderContext = PaintingContext(layer, context.estimatedBounds)
        ..addLayer(placeholderFixed)
        ..addLayer(placeholderScrolled);

      context.addLayer(layer);

      placeholder = TablePaintingLayerPair(
          fixed: PaintingContext(placeholderFixed, context.estimatedBounds),
          scrolled:
              PaintingContext(placeholderScrolled, context.estimatedBounds));
    }
  }

  late final TablePaintingLayerPair regular, placeholder;
  late final PaintingContext? placeholderShaderContext;

  @override
  VoidCallback addCompositionCallback(CompositionCallback callback) =>
      throw UnimplementedError();

  @override
  void addLayer(Layer layer) => throw UnimplementedError();

  @override
  void appendLayer(Layer layer) => throw UnimplementedError();

  @override
  void clipPathAndPaint(
          Path path, Clip clipBehavior, Rect bounds, VoidCallback painter) =>
      throw UnimplementedError();

  @override
  void clipRRectAndPaint(
          RRect rrect, Clip clipBehavior, Rect bounds, VoidCallback painter) =>
      throw UnimplementedError();

  @override
  void clipRectAndPaint(
          Rect rect, Clip clipBehavior, Rect bounds, VoidCallback painter) =>
      throw UnimplementedError();

  @override
  PaintingContext createChildContext(ContainerLayer childLayer, Rect bounds) =>
      throw UnimplementedError();

  @override
  void paintChild(RenderObject child, Offset offset) {
    assert(!child.isRepaintBoundary);
    assert(!child.needsCompositing);

    super.paintChild(child, offset);
  }

  @override
  ClipPathLayer? pushClipPath(bool needsCompositing, Offset offset, Rect bounds,
          Path clipPath, PaintingContextCallback painter,
          {Clip clipBehavior = Clip.antiAlias, ClipPathLayer? oldLayer}) =>
      throw UnimplementedError();

  @override
  ClipRRectLayer? pushClipRRect(bool needsCompositing, Offset offset,
          Rect bounds, RRect clipRRect, PaintingContextCallback painter,
          {Clip clipBehavior = Clip.antiAlias, ClipRRectLayer? oldLayer}) =>
      throw UnimplementedError();

  @override
  ClipRectLayer? pushClipRect(bool needsCompositing, Offset offset,
          Rect clipRect, PaintingContextCallback painter,
          {Clip clipBehavior = Clip.hardEdge, ClipRectLayer? oldLayer}) =>
      throw UnimplementedError();

  @override
  ColorFilterLayer pushColorFilter(Offset offset, ColorFilter colorFilter,
          PaintingContextCallback painter,
          {ColorFilterLayer? oldLayer}) =>
      throw UnimplementedError();

  @override
  void pushLayer(ContainerLayer childLayer, PaintingContextCallback painter,
          Offset offset,
          {Rect? childPaintBounds}) =>
      throw UnimplementedError();

  @override
  OpacityLayer pushOpacity(
          Offset offset, int alpha, PaintingContextCallback painter,
          {OpacityLayer? oldLayer}) =>
      throw UnimplementedError();

  @override
  TransformLayer? pushTransform(bool needsCompositing, Offset offset,
          Matrix4 transform, PaintingContextCallback painter,
          {TransformLayer? oldLayer}) =>
      throw UnimplementedError();

  @override
  void setIsComplexHint() {}

  @override
  void setWillChangeHint() {}

  @override
  void stopRecordingIfNeeded() {
    super.stopRecordingIfNeeded(); // this is unnecessary but whatever

    regular.fixed.stopRecordingIfNeeded();
    regular.scrolled.stopRecordingIfNeeded();
    placeholder.fixed.stopRecordingIfNeeded();
    placeholder.scrolled.stopRecordingIfNeeded();
    placeholderShaderContext?.stopRecordingIfNeeded();
  }
}

@Deprecated('replace')
enum TablePaintingContextLayerType {
  regularFixed,
  regularScrolled,
  placeholderFixed,
  placeholderScrolled,
}

@Deprecated('replace')
class TablePaintingContextCollapse extends SingleChildRenderObjectWidget {
  final TablePaintingContextLayerType type;

  TablePaintingContextCollapse({
    required this.type,
    required Widget child,
  }) : super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderTablePaintingContextCollapse(type: type);

  @override
  void updateRenderObject(BuildContext context,
      covariant _RenderTablePaintingContextCollapse renderObject) {
    super.updateRenderObject(context, renderObject);

    renderObject.type = type;
  }
}

class _RenderTablePaintingContextCollapse extends RenderProxyBox {
  _RenderTablePaintingContextCollapse({required this.type});

  TablePaintingContextLayerType type;

  @override
  void paint(PaintingContext context, Offset offset) {
    assert(context is TablePaintingContext);
    context = context as TablePaintingContext;

    switch (type) {
      case TablePaintingContextLayerType.regularFixed:
        context = context.regular.fixed;
        break;
      case TablePaintingContextLayerType.regularScrolled:
        context = context.regular.scrolled;
        break;
      case TablePaintingContextLayerType.placeholderFixed:
        context = context.placeholder.fixed;
        break;
      case TablePaintingContextLayerType.placeholderScrolled:
        context = context.placeholder.scrolled;
        break;
    }

    super.paint(context, offset);
  }
}
