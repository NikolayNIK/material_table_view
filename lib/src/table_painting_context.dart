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

  static const _unsupportedCompositionMessage =
      'Composition may not be used to paint a TableView row.'
      ' For `Material` widgets make sure to specify the type `MaterialType.transparency`.'
      ' For `Column`, `Row` and `Flex` widgets make sure their children do not overflow.'
      ' Some widgets may not be used at all.'
      ' For more details please visit https://pub.dev/packages/material_table_view#row-wrapping-widgets-restriction';

  TablePaintingLayerPair get placeholder {
    _placeholderLayersUsed = true;
    return _placeholder;
  }

  bool get placeholderLayersUsed => _placeholderLayersUsed;

  @override
  VoidCallback addCompositionCallback(CompositionCallback callback) =>
      throw UnsupportedError(_unsupportedCompositionMessage);

  @override
  void addLayer(Layer layer) =>
      throw UnsupportedError(_unsupportedCompositionMessage);

  @override
  void appendLayer(Layer layer) =>
      throw UnsupportedError(_unsupportedCompositionMessage);

  @override
  void clipPathAndPaint(
          Path path, Clip clipBehavior, Rect bounds, VoidCallback painter) =>
      throw UnsupportedError(_unsupportedCompositionMessage);

  @override
  void clipRRectAndPaint(
          RRect rrect, Clip clipBehavior, Rect bounds, VoidCallback painter) =>
      throw UnsupportedError(_unsupportedCompositionMessage);

  @override
  void clipRectAndPaint(
          Rect rect, Clip clipBehavior, Rect bounds, VoidCallback painter) =>
      throw UnsupportedError(_unsupportedCompositionMessage);

  @override
  PaintingContext createChildContext(ContainerLayer childLayer, Rect bounds) =>
      throw UnsupportedError(_unsupportedCompositionMessage);

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
      throw UnsupportedError(_unsupportedCompositionMessage);

  @override
  ClipRRectLayer? pushClipRRect(bool needsCompositing, Offset offset,
          Rect bounds, RRect clipRRect, PaintingContextCallback painter,
          {Clip clipBehavior = Clip.antiAlias, ClipRRectLayer? oldLayer}) =>
      throw UnsupportedError(_unsupportedCompositionMessage);

  @override
  ClipRectLayer? pushClipRect(bool needsCompositing, Offset offset,
          Rect clipRect, PaintingContextCallback painter,
          {Clip clipBehavior = Clip.hardEdge, ClipRectLayer? oldLayer}) =>
      throw UnsupportedError(_unsupportedCompositionMessage);

  @override
  ColorFilterLayer pushColorFilter(Offset offset, ColorFilter colorFilter,
          PaintingContextCallback painter,
          {ColorFilterLayer? oldLayer}) =>
      throw UnsupportedError(_unsupportedCompositionMessage);

  @override
  void pushLayer(ContainerLayer childLayer, PaintingContextCallback painter,
          Offset offset,
          {Rect? childPaintBounds}) =>
      throw UnsupportedError(_unsupportedCompositionMessage);

  @override
  OpacityLayer pushOpacity(
          Offset offset, int alpha, PaintingContextCallback painter,
          {OpacityLayer? oldLayer}) =>
      throw UnsupportedError(_unsupportedCompositionMessage);

  @override
  TransformLayer? pushTransform(bool needsCompositing, Offset offset,
          Matrix4 transform, PaintingContextCallback painter,
          {TransformLayer? oldLayer}) =>
      throw UnsupportedError(_unsupportedCompositionMessage);

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
