import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:material_table_view/src/table_layout_data.dart';
import 'package:material_table_view/src/table_painting_context.dart';
import 'package:material_table_view/src/table_placeholder_shade.dart';

mixin RenderTableSectionMixin on RenderObject {
  ViewportOffset? _verticalOffset;
  double? _verticalOffsetPixels;
  double? _rowHeight;
  late TableContentLayoutData _layoutData;
  TablePlaceholderShade? _placeholderShade;

  /// Whether custom composition will be used to paint the table section
  bool _useTablePaintingContext = true;

  Path? _scrolledClipPath, _leftDividerPath, _rightDividerPath;

  Size get visibleSize;

  Path? get scrolledSectionClipPath => _scrolledClipPath;

  double get verticalOffsetPixels {
    final verticalOffset = _verticalOffset;
    if (verticalOffset == null) {
      return _verticalOffsetPixels ?? .0;
    } else {
      return verticalOffset.hasPixels ? verticalOffset.pixels : .0;
    }
  }

  bool get useTablePaintingContext => _useTablePaintingContext;

  set verticalOffsetPixels(double? verticalOffsetPixels) {
    if (_verticalOffsetPixels == verticalOffsetPixels) return;

    _verticalOffsetPixels = verticalOffsetPixels;
    _verticalOffsetChanged();
  }

  set verticalOffset(ViewportOffset? verticalOffset) {
    if (identical(_verticalOffset, verticalOffset)) return;

    _verticalOffset?.removeListener(_verticalOffsetChanged);
    _verticalOffset = verticalOffset;
    _verticalOffset?.addListener(_verticalOffsetChanged);
    _verticalOffsetChanged();
  }

  set rowHeight(double? rowHeight) {
    // this comparison should be fine
    if (_rowHeight != rowHeight) {
      _rowHeight = rowHeight;
      markNeedsLayout();
      markNeedsPaint();
    }
  }

  set layoutData(TableContentLayoutData layoutData) {
    if (!identical(_layoutData, layoutData)) {
      _layoutData = layoutData;
      markNeedsLayout();
      markNeedsPaint();
    }
  }

  set placeholderShade(TablePlaceholderShade? placeholderShade) {
    if (identical(_placeholderShade, placeholderShade)) return;

    _placeholderShade?.removeListener(_placeholderShaderChanged);
    _placeholderShade = placeholderShade;
    placeholderShade?.addListener(_placeholderShaderChanged);
    _placeholderShaderChanged();
  }

  set useTablePaintingContext(bool useTablePaintingContext) {
    if (_useTablePaintingContext != useTablePaintingContext) {
      _useTablePaintingContext = useTablePaintingContext;
      markNeedsLayout();
      markNeedsPaint();
    }
  }

  @override
  void dispose() {
    _verticalOffset?.removeListener(_verticalOffsetChanged);
    _placeholderShade?.removeListener(_placeholderShaderChanged);

    super.dispose();
  }

  void _verticalOffsetChanged() {
    markNeedsLayout();
    markNeedsPaint();
  }

  void _placeholderShaderChanged() => markNeedsPaint();

  @override
  void performLayout() {
    super.performLayout();

    // not sure if this should go here but it works well enough for now
    if (_useTablePaintingContext) _updatePaths();
  }

  void _updatePaths() {
    final clipPath = _scrolledClipPath = Path(),
        leftDividerPath = _leftDividerPath = Path(),
        rightDividerPath = _rightDividerPath = Path();

    final verticalOffsetPixels = this.verticalOffsetPixels;
    final layoutData = _layoutData;

    {
      // left side
      final dividerData = layoutData.leftDivider;
      final wiggleInterval = dividerData.wiggleInterval ?? _rowHeight;

      final double top;
      double bottom;
      if (wiggleInterval == null) {
        top = 0;
        bottom = visibleSize.height;
      } else {
        top = -(verticalOffsetPixels % wiggleInterval);
        bottom = visibleSize.height + wiggleInterval;
        bottom += -((bottom + verticalOffsetPixels) % wiggleInterval);
      }

      final halfDividerThickness = dividerData.thickness / 2;
      final wiggleEdge = layoutData.leftWidth;
      final dividerWiggleEdge = wiggleEdge - halfDividerThickness;
      final wiggleOut = wiggleEdge + dividerData.wiggleOffset;
      final dividerWiggleOut = wiggleOut - halfDividerThickness;

      leftDividerPath.moveTo(dividerWiggleEdge, top);
      clipPath.moveTo(wiggleEdge, top);

      if (wiggleInterval == null ||
          dividerData.wiggleCount == 0 ||
          dividerData.wiggleOffset == .0) {
        leftDividerPath.lineTo(dividerWiggleEdge, bottom);
        clipPath.lineTo(wiggleEdge, bottom);
      } else {
        final wiggleStep = wiggleInterval / (2 * dividerData.wiggleCount);

        for (var y = top + wiggleStep; y <= bottom;) {
          leftDividerPath.lineTo(dividerWiggleOut, y);
          clipPath.lineTo(wiggleOut, y);
          y += wiggleStep;

          leftDividerPath.lineTo(dividerWiggleEdge, y);
          clipPath.lineTo(wiggleEdge, y);
          y += wiggleStep;
        }
      }
    }

    {
      // right size

      final dividerData = layoutData.rightDivider;
      final wiggleInterval = dividerData.wiggleInterval ?? _rowHeight;

      final double top;
      double bottom;
      if (wiggleInterval == null) {
        top = 0;
        bottom = visibleSize.height;
      } else {
        top = -(verticalOffsetPixels % wiggleInterval);
        bottom = visibleSize.height + wiggleInterval;
        bottom += -((bottom + verticalOffsetPixels) % wiggleInterval);
      }

      final halfDividerThickness = dividerData.thickness / 2;
      final wiggleEdge = layoutData.leftWidth + layoutData.centerWidth;
      final dividerWiggleEdge = wiggleEdge + halfDividerThickness;
      final wiggleOut = wiggleEdge - dividerData.wiggleOffset;
      final dividerWiggleOut = wiggleOut + halfDividerThickness;

      rightDividerPath.moveTo(dividerWiggleEdge, bottom);
      clipPath.lineTo(wiggleEdge, bottom);

      if (wiggleInterval == null ||
          dividerData.wiggleCount == 0 ||
          dividerData.wiggleOffset == 0) {
        rightDividerPath.lineTo(dividerWiggleEdge, top);
        clipPath.lineTo(wiggleOut, top);
      } else {
        final wiggleStep = wiggleInterval / (2 * dividerData.wiggleCount);

        for (var y = bottom - wiggleStep; y >= top;) {
          rightDividerPath.lineTo(dividerWiggleOut, y);
          clipPath.lineTo(wiggleOut, y);
          y -= wiggleStep;

          rightDividerPath.lineTo(dividerWiggleEdge, y);
          clipPath.lineTo(wiggleEdge, y);
          y -= wiggleStep;
        }
      }
    }

    clipPath.close();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    assert(
      offset.distanceSquared < .01,
      'Hit testing logic assumes TableSection coordinates to be the origin.'
      ' Got an offset of $offset, 0 assumed',
    );

    (_useTablePaintingContext ? _customPaint : super.paint)(context, offset);
  }

  void _customPaint(PaintingContext context, Offset offset) {
    final layoutData = _layoutData;

    final clipPath = _scrolledClipPath,
        leftDividerPath = _leftDividerPath,
        rightDividerPath = _rightDividerPath;

    final verticalOffsetPixels = this.verticalOffsetPixels;

    final TablePaintingContext innerContext;
    {
      // layer creation
      final mainLayer = ContainerLayer();
      final regularFixed = ContainerLayer();
      final regularScrolled = ClipPathLayer(clipPath: clipPath);

      context.addLayer(mainLayer);
      context.addLayer(regularFixed);
      context.addLayer(regularScrolled);

      final regular = TablePaintingLayerPair(
          fixed: PaintingContext(regularFixed, context.estimatedBounds),
          scrolled: PaintingContext(regularScrolled, context.estimatedBounds));

      final TablePaintingLayerPair placeholder;
      final PaintingContext? placeholderShaderContext;
      final placeholderShade = _placeholderShade;

      if (placeholderShade == null) {
        placeholderShaderContext = null;
        placeholder = regular;
      } else {
        final layer = ShaderMaskLayer()
          ..blendMode = placeholderShade.blendMode
          ..maskRect = Offset.zero & visibleSize
          ..shader = placeholderShade.createShader(
            Offset.zero & visibleSize,
            verticalOffsetPixels,
          );

        final placeholderFixed = ContainerLayer();
        final placeholderScrolled = ClipPathLayer(clipPath: clipPath);

        placeholderShaderContext =
            PaintingContext(layer, context.estimatedBounds)
              ..addLayer(placeholderFixed)
              ..addLayer(placeholderScrolled);

        context.addLayer(layer);

        placeholder = TablePaintingLayerPair(
            fixed: PaintingContext(placeholderFixed, context.estimatedBounds),
            scrolled:
                PaintingContext(placeholderScrolled, context.estimatedBounds));
      }

      innerContext = TablePaintingContext(
        mainLayer: mainLayer,
        estimatedBounds: context.estimatedBounds,
        regular: regular,
        placeholder: placeholder,
        placeholderShaderContext: placeholderShaderContext,
      );
    }

    super.paint(innerContext, offset);

    _placeholderShade?.active = innerContext.placeholderLayersUsed;

    innerContext.stopRecordingIfNeeded();

    final dividerPaint = Paint()..style = PaintingStyle.stroke;

    // if we have vertical offset,
    // assume the dividers will get clipped
    // by whatever clips vertically offset content
    bool clipDividers = _verticalOffset == null;

    if (clipDividers) {
      context.canvas.save();
      context.canvas.clipRect(offset & visibleSize);
    }

    context.canvas.drawPath(
      leftDividerPath!,
      dividerPaint
        ..color = layoutData.leftDivider.color
        ..strokeWidth = layoutData.leftDivider.thickness,
    );

    context.canvas.drawPath(
      rightDividerPath!,
      dividerPaint
        ..color = layoutData.rightDivider.color
        ..strokeWidth = layoutData.rightDivider.thickness,
    );

    if (clipDividers) {
      context.canvas.restore();
    }
  }

  @override
  @protected
  bool get alwaysNeedsCompositing => true;

  @override
  bool get isRepaintBoundary => true;
}

class RenderBoxTableSection extends RenderProxyBox
    with RenderTableSectionMixin {
  RenderBoxTableSection({
    required ViewportOffset? verticalOffset,
    required double? verticalOffsetPixels,
    required double? rowHeight,
    required TableContentLayoutData layoutData,
    required TablePlaceholderShade? placeholderShade,
    required bool useTablePaintingContext,
  }) {
    _rowHeight = rowHeight;
    _layoutData = layoutData;
    _placeholderShade = placeholderShade;
    _useTablePaintingContext = useTablePaintingContext;
    _verticalOffset = verticalOffset;
    _verticalOffset?.addListener(_verticalOffsetChanged);
    _placeholderShade?.addListener(_placeholderShaderChanged);
  }

  @override
  Size get visibleSize => size;
}

class RenderSliverTableSection extends RenderProxySliver
    with RenderTableSectionMixin {
  RenderSliverTableSection({
    required ViewportOffset? verticalOffset,
    required double? verticalOffsetPixels,
    required double? rowHeight,
    required TableContentLayoutData layoutData,
    required TablePlaceholderShade? placeholderShade,
    required bool useTablePaintingContext,
  }) {
    _rowHeight = rowHeight;
    _layoutData = layoutData;
    _placeholderShade = placeholderShade;
    _useTablePaintingContext = useTablePaintingContext;
    _verticalOffset = verticalOffset;
    _verticalOffset?.addListener(_verticalOffsetChanged);
    _placeholderShade?.addListener(_placeholderShaderChanged);
  }

  @override
  Size get visibleSize {
    final geometry = this.geometry!;
    return Size(
      geometry.crossAxisExtent!,
      geometry.paintExtent - geometry.paintOrigin,
    );
  }
}
