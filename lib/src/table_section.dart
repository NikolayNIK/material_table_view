import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:material_table_view/src/table_layout.dart';
import 'package:material_table_view/src/table_layout_data.dart';
import 'package:material_table_view/src/table_painting_context.dart';
import 'package:material_table_view/src/table_placeholder_shade.dart';

/// This widget represents a single table section:
/// either a header, a body or a footer.
///
/// Using layout data provided by the [TableContentLayout] widget it:
/// - paints wiggly dividers separating scrolled and fixed sections;
/// - serves as a starting point of a custom painting composition process
/// (including clipping scrolled section, handling repainting, etc).
class TableSection extends StatelessWidget {
  final ViewportOffset? verticalOffset;
  final double rowHeight;
  final TablePlaceholderShade? placeholderShade;
  final Widget child;

  TableSection({
    required this.verticalOffset,
    required this.rowHeight,
    required this.placeholderShade,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => _TableSection(
        verticalOffset: verticalOffset,
        rowHeight: rowHeight,
        layoutData: TableContentLayout.of(context),
        dividerThickness: DividerTheme.of(context).thickness ?? 2.0,
        placeholderShade: placeholderShade,
        child: child,
      );
}

class _TableSection extends SingleChildRenderObjectWidget {
  final ViewportOffset? verticalOffset;
  final double rowHeight;
  final TableContentLayoutData layoutData;
  final double dividerThickness;
  final TablePlaceholderShade? placeholderShade;

  _TableSection({
    required this.verticalOffset,
    required this.rowHeight,
    required this.layoutData,
    required this.dividerThickness,
    required this.placeholderShade,
    required Widget child,
  }) : super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderTableSection(
      verticalOffset: verticalOffset,
      rowHeight: rowHeight,
      layoutData: layoutData,
      dividerThickness: dividerThickness,
      placeholderShade: placeholderShade);

  @override
  void updateRenderObject(
      BuildContext context, covariant _RenderTableSection renderObject) {
    super.updateRenderObject(context, renderObject);

    renderObject.verticalOffset = verticalOffset;
    renderObject.rowHeight = rowHeight;
    renderObject.layoutData = layoutData;
    renderObject.dividerThickness = dividerThickness;
    renderObject.placeholderShade = placeholderShade;
  }
}

class _RenderTableSection extends RenderProxyBox {
  _RenderTableSection({
    required ViewportOffset? verticalOffset,
    required double rowHeight,
    required TableContentLayoutData layoutData,
    required double dividerThickness,
    required TablePlaceholderShade? placeholderShade,
  })  : _rowHeight = rowHeight,
        _layoutData = layoutData,
        _dividerThickness = dividerThickness,
        _placeholderShade = placeholderShade {
    _verticalOffset = verticalOffset;
    _verticalOffset?.addListener(_verticalOffsetChanged);
    _placeholderShade?.addListener(_placeholderShaderChanged);
  }

  ViewportOffset? _verticalOffset;
  double _rowHeight;
  TableContentLayoutData _layoutData;
  double _dividerThickness;
  TablePlaceholderShade? _placeholderShade;

  set verticalOffset(ViewportOffset? verticalOffset) {
    if (identical(_verticalOffset, verticalOffset)) return;

    _verticalOffset?.removeListener(_verticalOffsetChanged);
    _verticalOffset = verticalOffset;
    _verticalOffset?.addListener(_verticalOffsetChanged);
    markNeedsPaint();
  }

  set rowHeight(double rowHeight) {
    // this comparison should be fine
    if (_rowHeight != rowHeight) {
      _rowHeight = rowHeight;
      markNeedsPaint();
    }
  }

  set layoutData(TableContentLayoutData layoutData) {
    if (!identical(_layoutData, layoutData)) {
      _layoutData = layoutData;
      markNeedsPaint();
    }
  }

  set dividerThickness(double dividerThickness) {
    // this comparison should be fine
    if (_dividerThickness != dividerThickness) {
      _dividerThickness = dividerThickness;
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

  @override
  void dispose() {
    _verticalOffset?.removeListener(_verticalOffsetChanged);
    _placeholderShade?.removeListener(_placeholderShaderChanged);

    super.dispose();
  }

  void _verticalOffsetChanged() => markNeedsPaint();

  void _placeholderShaderChanged() => markNeedsPaint();

  @override
  void paint(PaintingContext context, Offset offset) {
    final layoutData = _layoutData;

    final clipPath = Path(),
        leftDividerPath = Path(),
        rightDividerPath = Path();

    final double verticalOffsetPixels;

    {
      final halfRowHeight = _rowHeight / 2;
      {
        final verticalOffset = _verticalOffset;
        if (verticalOffset != null && verticalOffset.hasPixels) {
          verticalOffsetPixels = verticalOffset.pixels;
        } else {
          verticalOffsetPixels = .0;
        }
      }

      final top = offset.dy - (verticalOffsetPixels % _rowHeight);
      var bottom = size.height + _rowHeight;
      bottom += offset.dy - ((bottom + verticalOffsetPixels) % _rowHeight);

      final halfDividerThickness = _dividerThickness / 2;

      {
        // left side

        final wiggleEdge = offset.dx + layoutData.leftWidth;
        final dividerWiggleEdge = wiggleEdge - halfDividerThickness;
        final wiggleMiddle = wiggleEdge + layoutData.leftDivider.wiggleOffset;
        final dividerWiggleMiddle = wiggleMiddle - halfDividerThickness;

        leftDividerPath.moveTo(dividerWiggleEdge, top);
        clipPath.moveTo(dividerWiggleEdge, top);

        for (var y = top + halfRowHeight; y <= bottom;) {
          leftDividerPath.lineTo(dividerWiggleMiddle, y);
          clipPath.lineTo(wiggleMiddle, y);
          y += halfRowHeight;

          leftDividerPath.lineTo(dividerWiggleEdge, y);
          clipPath.lineTo(wiggleEdge, y);
          y += halfRowHeight;
        }
      }

      {
        // right size

        final wiggleEdge =
            offset.dx + layoutData.leftWidth + layoutData.centerWidth;
        final dividerWiggleEdge = wiggleEdge + halfDividerThickness;
        final wiggleMiddle = wiggleEdge - layoutData.rightDivider.wiggleOffset;
        final dividerWiggleMiddle = wiggleMiddle + halfDividerThickness;

        rightDividerPath.moveTo(dividerWiggleEdge, bottom);
        clipPath.lineTo(dividerWiggleEdge, bottom);

        for (var y = bottom - halfRowHeight; y >= top;) {
          rightDividerPath.lineTo(dividerWiggleMiddle, y);
          clipPath.lineTo(wiggleMiddle, y);
          y -= halfRowHeight;

          rightDividerPath.lineTo(dividerWiggleEdge, y);
          clipPath.lineTo(wiggleEdge, y);
          y -= halfRowHeight;
        }
      }
    }

    clipPath.close();

    final TablePaintingContext innerContext;
    {
      // layer creation
      final mainLayer = ContainerLayer();
      final regularFixed = mainLayer;
      final regularScrolled = ClipPathLayer(clipPath: clipPath);

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
          ..maskRect = offset & size
          ..shader = placeholderShade.createShader(
            Offset.zero & size,
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

    final dividerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _dividerThickness;

    // if we have vertical offset,
    // assume the dividers will get clipped
    // by whatever clips vertically offset content
    bool clipDividers = _verticalOffset == null;

    if (clipDividers) {
      context.canvas.save();
      context.canvas.clipRect(offset & size);
    }

    context.canvas.drawPath(
      leftDividerPath,
      dividerPaint..color = layoutData.leftDivider.color,
    );

    context.canvas.drawPath(
      rightDividerPath,
      dividerPaint..color = layoutData.rightDivider.color,
    );

    if (clipDividers) {
      context.canvas.restore();
    }
  }

  @protected
  bool get alwaysNeedsCompositing => true;

  @override
  bool get isRepaintBoundary => true;
}
