import 'package:flutter/widgets.dart';

/// Function used to build a widget for passed cell in a row.
typedef TableCellBuilder = Widget Function(BuildContext context, int column);

/// Function used to build the inner content of a row of a table.
typedef TableRowContentBuilder = Widget Function(
  BuildContext context,
  TableCellBuilder cellBuilder,
);

/// Function used to build the final widget representing a row of a table.
typedef TableRowBuilder = Widget? Function(
  BuildContext context,
  int row,
  TableRowContentBuilder contentBuilder,
);

/// Function used to build the final widget representing the placeholder of a table.
typedef TablePlaceholderBuilder = Widget Function(
  BuildContext context,
  TableRowContentBuilder contentBuilder,
);

/// Function used to build the final widget representing the header of a table.
typedef TableHeaderBuilder = Widget Function(
  BuildContext context,
  TableRowContentBuilder contentBuilder,
);

/// Function used to build the final widget representing the footer of a table.
typedef TableFooterBuilder = TableHeaderBuilder;

/// Function used to wrap the body of a table.
typedef TableBodyContainerBuilder = Widget Function(
    BuildContext context, Widget bodyContainer);

/// Function used to wrap a given placeholder widget containing all visible
/// placeholders in order to achieve some custom behaviour.
typedef TablePlaceholderContainerBuilder = Widget Function(
  Widget placeholderContainer,
);
