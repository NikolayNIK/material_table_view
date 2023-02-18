import 'package:flutter/widgets.dart';
import 'package:material_table_view/src/table_row_opacity.dart';

/// This widget is meant to provide the same functionality as a regular
/// [FadeTransition] widget. As a regular [FadeTransition] widget can not
/// be used to wrap an entire table row, this one should be used instead.
///
/// Note that this widget is considerably more expensive to paint compared to
/// already expensive regular counterpart. This widget is only meant for
/// animating relatively short transitions.
///
/// This widget will not work for any other purpose.
class TableRowFadeTransition extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const TableRowFadeTransition({
    super.key,
    required this.animation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<double>(
        valueListenable: animation,
        builder: (context, value, _) => TableRowOpacity(
          opacity: value,
          child: child,
        ),
      );
}
