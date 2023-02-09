import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:material_table_view/src/table_layout_data.dart';
import 'package:material_table_view/src/table_painting_context.dart';
import 'package:material_table_view/src/table_placeholder_shader_configuration.dart';

class TableSection extends StatelessWidget {
  final ViewportOffset? verticalOffset;
  final double rowHeight;
  final TableViewPlaceholderShaderConfig? placeholderShaderConfig;
  final Widget child;

  TableSection({
    required this.verticalOffset,
    required this.rowHeight,
    required this.placeholderShaderConfig,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => _TableSection(
        verticalOffset: verticalOffset,
        rowHeight: rowHeight,
        layoutData: TableContentLayoutData.of(context),
        dividerThickness: DividerTheme.of(context).thickness ?? 2.0,
        placeholderShaderConfig: placeholderShaderConfig,
        child: child,
      );
}

class _TableSection extends SingleChildRenderObjectWidget {
  final ViewportOffset? verticalOffset;
  final double rowHeight;
  final TableContentLayoutData layoutData;
  final double dividerThickness;
  final TableViewPlaceholderShaderConfig? placeholderShaderConfig;

  _TableSection({
    required this.verticalOffset,
    required this.rowHeight,
    required this.layoutData,
    required this.dividerThickness,
    required this.placeholderShaderConfig,
    required Widget child,
  }) : super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderTableSection(
      verticalOffset: verticalOffset,
      rowHeight: rowHeight,
      layoutData: layoutData,
      dividerThickness: dividerThickness,
      placeholderShaderConfig: placeholderShaderConfig);

  @override
  void updateRenderObject(
      BuildContext context, covariant _RenderTableSection renderObject) {
    super.updateRenderObject(context, renderObject);

    renderObject.verticalOffset = verticalOffset;
    renderObject.rowHeight = rowHeight;
    renderObject.layoutData = layoutData;
    renderObject.dividerThickness = dividerThickness;
    renderObject.placeholderShaderConfig = placeholderShaderConfig;
  }
}

class _RenderTableSection extends RenderProxyBox {
  _RenderTableSection({
    required ViewportOffset? verticalOffset,
    required double rowHeight,
    required TableContentLayoutData layoutData,
    required double dividerThickness,
    required TableViewPlaceholderShaderConfig? placeholderShaderConfig,
  })  : _rowHeight = rowHeight,
        _layoutData = layoutData,
        _dividerThickness = dividerThickness,
        _placeholderShaderConfig = placeholderShaderConfig {
    _verticalOffset = verticalOffset;
    _verticalOffset?.addListener(_verticalOffsetChanged);
  }

  ViewportOffset? _verticalOffset;
  double _rowHeight;
  TableContentLayoutData _layoutData;
  double _dividerThickness;
  TableViewPlaceholderShaderConfig? _placeholderShaderConfig;

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

  set placeholderShaderConfig(
      TableViewPlaceholderShaderConfig? placeholderShaderConfig) {
    if (_placeholderShaderConfig != placeholderShaderConfig) {
      _placeholderShaderConfig = placeholderShaderConfig;
      markNeedsPaint();
    }
  }

  @override
  void dispose() {
    _verticalOffset?.removeListener(_verticalOffsetChanged);

    super.dispose();
  }

  void _verticalOffsetChanged() => markNeedsPaint();

  @override
  void paint(PaintingContext context, Offset offset) {
    final layoutData = _layoutData;

    final clipPath = Path(),
        leftDividerPath = Path(),
        rightDividerPath = Path();

    {
      final halfRowHeight = _rowHeight / 2;
      final double verticalOffsetPixels;
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

    final innerContext = TablePaintingContext(
      mainLayer: ContainerLayer(),
      context: context,
      scrolledClipPath: clipPath,
      placeholderShaderConfig: _placeholderShaderConfig,
      offset: offset,
      size: size,
    );

    super.paint(innerContext, offset);

    innerContext.stopRecordingIfNeeded();

    final dividerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _dividerThickness;

    context.canvas.save();
    context.canvas.clipRect(offset & size);

    context.canvas.drawPath(
      leftDividerPath,
      dividerPaint..color = layoutData.leftDivider.color,
    );

    context.canvas.drawPath(
      rightDividerPath,
      dividerPaint..color = layoutData.rightDivider.color,
    );

    context.canvas.restore();
  }

  @protected
  bool get alwaysNeedsCompositing => true;

  @override
  bool get isRepaintBoundary => true;
}
