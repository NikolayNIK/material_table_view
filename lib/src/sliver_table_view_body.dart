import 'package:flutter/widgets.dart';
import 'package:material_table_view/src/sliver_table_reorderable_list.dart';
import 'package:material_table_view/src/table_row.dart';
import 'package:material_table_view/src/table_row_reorder.dart';
import 'package:material_table_view/src/table_typedefs.dart';

/// This is a sliver widget that builds rows of a table.
class SliverTableViewBody extends StatelessWidget {
  final int rowCount;
  final double rowHeight;
  final TableRowBuilder rowBuilder;
  final TablePlaceholderBuilder placeholderBuilder;
  final TablePlaceholderRowBuilder? placeholderRowBuilder;
  final TableRowReorder? rowReorder;
  final bool addAutomaticKeepAlives;
  final bool useHigherScrollable;

  const SliverTableViewBody({
    super.key,
    required this.rowCount,
    required this.rowHeight,
    required this.rowBuilder,
    required this.placeholderBuilder,
    required this.placeholderRowBuilder,
    required this.addAutomaticKeepAlives,
    required this.useHigherScrollable,
    required this.rowReorder,
  });

  @override
  Widget build(BuildContext context) {
    Widget? placeholder;

    final rowReorder = this.rowReorder;
    if (rowReorder != null) {
      return SliverTableReorderableList(
        itemBuilder: (context, index) =>
            rowBuilder(context, index, contentBuilder) ??
            placeholder ??
            placeholderRowBuilder?.call(
                context, index, placeholderContentBuilder) ??
            (placeholder ??=
                placeholderBuilder.call(context, placeholderContentBuilder)),
        itemCount: rowCount,
        itemExtent: rowHeight,
        useHigherScrollable: useHigherScrollable,
        addAutomaticKeepAlives: addAutomaticKeepAlives,
        onReorder: rowReorder.onReorder,
        findChildIndexCallback: rowReorder.findChildIndexCallback,
        onReorderStart: rowReorder.onReorderStart,
        onReorderEnd: rowReorder.onReorderEnd,
        proxyDecorator: rowReorder.proxyDecorator,
      );
    }

    return SliverFixedExtentList(
      itemExtent: rowHeight,
      delegate: SliverChildBuilderDelegate(
        childCount: rowCount,
        addRepaintBoundaries: false,
        addAutomaticKeepAlives: addAutomaticKeepAlives,
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
