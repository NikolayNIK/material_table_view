import 'package:flutter/widgets.dart';
import 'package:material_table_view/src/table_row.dart';
import 'package:material_table_view/src/table_typedefs.dart';

/// This is a sliver widget that builds rows of a table.
class SliverTableViewBody extends StatelessWidget {
  final int rowCount;
  final double rowHeight;
  final TableRowBuilder rowBuilder;
  final TablePlaceholderBuilder placeholderBuilder;

  const SliverTableViewBody({
    super.key,
    required this.rowCount,
    required this.rowHeight,
    required this.rowBuilder,
    required this.placeholderBuilder,
  });

  @override
  Widget build(BuildContext context) {
    late final placeholder = placeholderBuilder.call(
      context,
      (context, cellBuilder) => TableViewRow(
        cellBuilder: cellBuilder,
        usePlaceholderLayers: true,
      ),
    );

    return SliverFixedExtentList(
      itemExtent: rowHeight,
      delegate: SliverChildBuilderDelegate(
        childCount: rowCount,
        addRepaintBoundaries: false,
        (context, index) =>
            rowBuilder(context, index, contentBuilder) ?? placeholder,
      ),
    );
  }
}
