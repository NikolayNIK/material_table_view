import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:material_table_view/src/table_layout_data.dart';
import 'package:material_table_view/src/table_painting_context.dart';
import 'package:material_table_view/src/table_typedefs.dart';

class TableViewRow extends SingleChildRenderObjectWidget {
  TableViewRow({
    required TableCellBuilder cellBuilder,
    bool usePlaceholderLayers = false,
  }) : super(
          child: Builder(
            // this is temporary I swear
            builder: (context) {
              final data = TableContentLayoutData.of(context);

              Iterable<Widget> columnMapper(
                      TableContentColumnData columnData) =>
                  Iterable.generate(columnData.indices.length).map((i) {
                    final columnIndex = columnData.indices[i];
                    return Positioned(
                      key: ValueKey<int>(columnIndex),
                      width: columnData.widths[i],
                      height: data.rowHeight,
                      left: columnData.positions[i],
                      child: Builder(
                          builder: (context) =>
                              cellBuilder(context, columnIndex)),
                    );
                  });

              return Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    child: TablePaintingContextCollapse(
                      type: usePlaceholderLayers
                          ? TablePaintingContextLayerType.placeholderScrolled
                          : TablePaintingContextLayerType.regularScrolled,
                      child: Stack(
                        fit: StackFit.expand,
                        clipBehavior: Clip.none,
                        children: columnMapper(data.scrollableColumns)
                            .toList(growable: false),
                      ),
                    ),
                  ),
                  Positioned(
                    child: TablePaintingContextCollapse(
                      type: usePlaceholderLayers
                          ? TablePaintingContextLayerType.placeholderFixed
                          : TablePaintingContextLayerType.regularFixed,
                      child: Stack(
                        fit: StackFit.expand,
                        clipBehavior: Clip.none,
                        children: columnMapper(data.fixedColumns)
                            .toList(growable: false),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderTableViewRow();
}

class _RenderTableViewRow extends RenderProxyBox {
  /// Cut off compositing requirement here to let the children use compositing.
  ///
  /// Operations which may need to know the actual need for compositing
  /// are strictly forbidden in parent render objects by the
  /// [TablePaintingContext], usage of which ends here.
  @override
  bool get needsCompositing => false;
}
