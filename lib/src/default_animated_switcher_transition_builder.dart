import 'package:flutter/widgets.dart';
import 'package:material_table_view/src/table_row_fade_transition.dart';

/// This function is meant to reflect the behavior of the
/// [AnimatedSwitcher.defaultTransitionBuilder] with the only difference being
/// that is may only be used as a transition builder for [AnimatedSwitcher]s
/// wrapping [TableView] rows.
///
/// Keep in mind that the regular one will not work for that purpose.
const AnimatedSwitcherTransitionBuilder
    tableRowDefaultAnimatedSwitcherTransitionBuilder =
    _tableRowDefaultAnimatedSwitcherTransitionBuilder;

Widget _tableRowDefaultAnimatedSwitcherTransitionBuilder(
        Widget child, Animation<double> animation) =>
    TableRowFadeTransition(animation: animation, child: child);
