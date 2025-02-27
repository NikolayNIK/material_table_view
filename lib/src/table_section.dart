import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:material_table_view/src/render_table_section.dart';
import 'package:material_table_view/src/table_content_layout.dart';
import 'package:material_table_view/src/table_content_layout_data.dart';
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
  final double? verticalOffsetPixels;
  final double? rowHeight;
  final TablePlaceholderShade? placeholderShade;
  final Widget child;

  const TableSection({
    super.key,
    required this.verticalOffset,
    this.verticalOffsetPixels,
    required this.rowHeight,
    required this.placeholderShade,
    required this.child,
  }) : assert(verticalOffset != null || verticalOffsetPixels != null);

  @override
  Widget build(BuildContext context) => _TableSection(
        verticalOffset: verticalOffset,
        verticalOffsetPixels: verticalOffsetPixels,
        rowHeight: rowHeight,
        layoutData: TableContentLayout.of(context),
        placeholderShade: placeholderShade,
        child: child,
      );
}

class _TableSection extends SingleChildRenderObjectWidget {
  final ViewportOffset? verticalOffset;
  final double? verticalOffsetPixels;
  final double? rowHeight;
  final TableContentLayoutData layoutData;
  final TablePlaceholderShade? placeholderShade;

  const _TableSection({
    required this.verticalOffset,
    required this.verticalOffsetPixels,
    required this.rowHeight,
    required this.layoutData,
    required this.placeholderShade,
    required Widget child,
  }) : super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) => RenderTableSection(
        verticalOffset: verticalOffset,
        verticalOffsetPixels: verticalOffsetPixels,
        rowHeight: rowHeight,
        layoutData: layoutData,
        placeholderShade: placeholderShade,
        useTablePaintingContext: useTablePaintingContext,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderTableSection renderObject,
  ) {
    super.updateRenderObject(context, renderObject);

    renderObject.verticalOffset = verticalOffset;
    renderObject.verticalOffsetPixels = verticalOffsetPixels;
    renderObject.rowHeight = rowHeight;
    renderObject.layoutData = layoutData;
    renderObject.placeholderShade = placeholderShade;
    renderObject.useTablePaintingContext = useTablePaintingContext;
  }

  bool get useTablePaintingContext =>
      placeholderShade != null || layoutData.fixedColumns.indices.isNotEmpty;
}
