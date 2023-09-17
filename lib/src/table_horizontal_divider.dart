import 'package:flutter/material.dart';
import 'package:material_table_view/src/table_view_style_resolved.dart';

class TableHorizontalDivider extends StatelessWidget {
  final ResolvedTableViewHorizontalDividerStyle style;

  const TableHorizontalDivider({
    super.key,
    required this.style,
  });

  @override
  Widget build(BuildContext context) => Divider(
      height: style.thickness,
      thickness: style.thickness,
      color: style.color,
    );
}
