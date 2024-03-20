import 'package:flutter/widgets.dart';
import 'package:material_table_view/src/sliver_table_reorderable_list.dart';
import 'package:material_table_view/src/table_row.dart';
import 'package:material_table_view/src/table_typedefs.dart';

/// This is a sliver widget that builds rows of a table.
class SliverTableViewBody extends StatelessWidget {
  final int rowCount;
  final double rowHeight;
  final TableRowBuilder rowBuilder;
  final TablePlaceholderBuilder placeholderBuilder;
  final TablePlaceholderRowBuilder? placeholderRowBuilder;
  final void Function(int a, int b)? onReorder;
  final bool useHigherScrollable;

  const SliverTableViewBody({
    super.key,
    required this.rowCount,
    required this.rowHeight,
    required this.rowBuilder,
    required this.placeholderBuilder,
    required this.placeholderRowBuilder,
    required this.useHigherScrollable,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    Widget? placeholder;

    if (onReorder != null) {
      return SliverTableReorderableList(
        itemBuilder: (context, index) =>
            rowBuilder(context, index, contentBuilder) ??
            placeholder ??
            placeholderRowBuilder?.call(
                context, index, placeholderContentBuilder) ??
            (placeholder ??=
                placeholderBuilder.call(context, placeholderContentBuilder)),
        itemCount: rowCount,
        onReorder: onReorder!,
        itemExtent: rowHeight,
        useHigherScrollable: useHigherScrollable,
      );
    }

    return SliverFixedExtentList(
      itemExtent: rowHeight,
      delegate: SliverChildBuilderDelegate(
        childCount: rowCount,
        addRepaintBoundaries: false,
        (context, index) =>
            rowBuilder(context, index, contentBuilder) ??
            placeholder ??
            placeholderRowBuilder?.call(
                context, index, placeholderContentBuilder) ??
            (placeholder ??=
                placeholderBuilder.call(context, placeholderContentBuilder)),
      ),
    );
  }
}
