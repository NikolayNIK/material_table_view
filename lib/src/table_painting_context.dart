import 'package:flutter/rendering.dart';

extension RequireTablePaintingContext on PaintingContext {
  TablePaintingContext requireTablePaintingContext() {
    assert(
      this is TablePaintingContext,
      'This widget may only be used in a TableView row',
    );

    return this as TablePaintingContext;
  }
}

/// Storage class that holds a pair of layers to be used for cell painting.
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

/// A subclass of a [PaintingContext] used to implement custom painting
/// composition of a table.
class TablePaintingContext extends PaintingContext {
  TablePaintingContext({
    required ContainerLayer mainLayer,
    required this.regular,
    required TablePaintingLayerPair placeholder,
    required this.placeholderShaderContext,
    required Rect estimatedBounds,
  })  : _placeholder = placeholder,
        super(mainLayer, estimatedBounds);

  final TablePaintingLayerPair regular, _placeholder;
  final PaintingContext? placeholderShaderContext;

  var _placeholderLayersUsed = false;

  TablePaintingLayerPair get placeholder {
    _placeholderLayersUsed = true;
    return _placeholder;
  }

  bool get placeholderLayersUsed => _placeholderLayersUsed;

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
    _placeholder.fixed.stopRecordingIfNeeded();
    _placeholder.scrolled.stopRecordingIfNeeded();
    placeholderShaderContext?.stopRecordingIfNeeded();
  }

  void paintChildrenLayers(
    ContainerLayer Function() createLayer,
    void Function(PaintingContext context) painter,
  ) {
    final mainLayer = createLayer();
    final regularFixed = mainLayer;
    final regularScrolled = createLayer();

    regular.fixed.addLayer(regularFixed);
    regular.scrolled.addLayer(regularScrolled);
    final ContainerLayer placeholderFixed, placeholderScrolled;
    if (identical(_placeholder, regular)) {
      placeholderFixed = regularFixed;
      placeholderScrolled = regularScrolled;
    } else {
      placeholderFixed = createLayer();
      placeholderScrolled = createLayer();
      _placeholder.fixed.addLayer(placeholderFixed);
      _placeholder.scrolled.addLayer(placeholderScrolled);
    }

    final innerContext = TablePaintingContext(
      mainLayer: mainLayer,
      regular: TablePaintingLayerPair(
          fixed: PaintingContext(regularFixed, estimatedBounds),
          scrolled: PaintingContext(regularScrolled, estimatedBounds)),
      placeholder: TablePaintingLayerPair(
          fixed: PaintingContext(placeholderFixed, estimatedBounds),
          scrolled: PaintingContext(placeholderScrolled, estimatedBounds)),
      placeholderShaderContext: null,
      estimatedBounds: estimatedBounds,
    );

    painter(innerContext);
    innerContext.stopRecordingIfNeeded();
    _placeholderLayersUsed |= innerContext.placeholderLayersUsed;
  }
}
