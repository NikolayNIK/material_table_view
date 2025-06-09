import 'package:flutter/widgets.dart';
import 'package:material_table_view/src/table_row_animated_size.dart';

/// Widget that provides seamless row expansion/shrinking animation.
class ExpandableTableRow extends StatelessWidget {
  const ExpandableTableRow({
    super.key,
    required this.vsync,
    required this.duration,
    this.curve = Curves.easeInOut,
    required this.expanded,
    required this.child,
    required this.expandedChild,
  });

  /// Ticker provider for the animation. Typically, [TickerProviderStateMixin].
  final TickerProvider vsync;

  /// The duration of the size animation performed when [expanded] is changed.
  final Duration duration;

  /// The animation curve. Defaults to [Curves.easeInOut].
  final Curve curve;

  /// Whether or not the expanded content is shown. The row will animate the
  /// size change whenever this value changes.
  final bool expanded;

  /// The main widget of the row which is shown regardless of whether the row
  /// is expanded or not. Typically, would contain a button that changes the
  /// value of the [expanded] among other content.
  final Widget child;

  /// Widget shown directly below the main widget whenever [expanded] is set to
  /// `true`.
  final Widget expandedChild;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          child,
          TableRowAnimatedSize(
            vsync: vsync,
            duration: duration,
            curve: curve,
            child: SizedBox(
              height: expanded ? null : .0,
              child: expandedChild,
            ),
          ),
        ],
      );
}
