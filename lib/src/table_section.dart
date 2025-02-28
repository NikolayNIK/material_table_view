import 'package:flutter/material.dart';
import 'package:material_table_view/src/render_table_section.dart';
import 'package:material_table_view/src/table_content_layout.dart';
import 'package:material_table_view/src/table_content_layout_data.dart';
import 'package:material_table_view/src/table_placeholder_shade.dart';
import 'package:material_table_view/src/table_section_offset.dart';

/// This widget represents a single table section:
/// either a header, a body or a footer.
///
/// Using layout data provided by the [TableContentLayout] widget it:
/// - paints wiggly dividers separating scrolled and fixed sections;
/// - serves as a starting point of a custom painting composition process
/// (including clipping scrolled section, handling repainting, etc).
class TableSection extends SingleChildRenderObjectWidget {
  final TableSectionOffset verticalOffset;
  final double? rowHeight;
  final TablePlaceholderShade? placeholderShade;

  const TableSection({
    super.key,
    this.verticalOffset = TableSectionOffset.zero,
    required this.rowHeight,
    required this.placeholderShade,
    required super.child,
  });

  bool useTablePaintingContext(TableContentLayoutData layoutData) =>
      placeholderShade != null || layoutData.fixedColumns.indices.isNotEmpty;

  @override
  RenderObject createRenderObject(BuildContext context) {
    final layoutData = TableContentLayout.of(context);

    return RenderTableSection(
      verticalOffset: verticalOffset,
      rowHeight: rowHeight,
      layoutData: layoutData,
      placeholderShade: placeholderShade,
      useTablePaintingContext: useTablePaintingContext(layoutData),
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderTableSection renderObject,
  ) {
    super.updateRenderObject(context, renderObject);

    final layoutData = TableContentLayout.of(context);

    renderObject.verticalOffset = verticalOffset;
    renderObject.rowHeight = rowHeight;
    renderObject.layoutData = layoutData;
    renderObject.placeholderShade = placeholderShade;
    renderObject.useTablePaintingContext = useTablePaintingContext(layoutData);
  }
}
