import 'package:flutter/material.dart';
import 'package:material_table_view/src/table_view_style_populated.dart';

class TableHorizontalDivider extends StatelessWidget {
  final PopulatedTableViewHorizontalDividerStyle style;

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
