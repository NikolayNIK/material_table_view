import 'package:flutter/material.dart';
import 'package:material_table_view/src/table_view_style_resolved.dart';

class TableScrollbar extends StatelessWidget {
  final ScrollController controller;
  final ResolvedTableViewScrollbarStyle style;
  final Widget child;

  TableScrollbar({
    super.key,
    required this.controller,
    required this.style,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // this is going to cause state loss ;-;
    if (!style.effectivelyEnabled) {
      return child;
    }

    return Scrollbar(
      controller: controller,
      thickness: style.thickness,
      thumbVisibility: style.thumbVisibility,
      interactive: style.interactive,
      radius: style.radius,
      trackVisibility: style.trackVisibility,
      child: child,
    );
  }
}
