import 'package:flutter/widgets.dart';

/// Function used to build a widget for passed cell in a row.
typedef TableCellBuilder = Widget Function(BuildContext context, int column);

/// Function used to retrieve a [TableCellBuilder] for a specific row.
/// Returning null indicates the intent to replace that row with a placeholder.
typedef TableRowBuilder = TableCellBuilder? Function(int row);

/// Function used to wrap a given row widget for a specific row
/// in order to achieve some custom row behaviour.
typedef TableRowDecorator = Widget Function(Widget rowWidget, int rowIndex);

/// Function used to wrap a given placeholder row widget for a specific row
/// in order to achieve some custom row behaviour.
typedef TablePlaceholderDecorator = Widget Function(
  Widget placeholderWidget,
  int rowIndex,
);

/// Function used to wrap a given header row widget for a specific row
/// in order to achieve some custom row behaviour.
typedef TableHeaderDecorator = Widget Function(Widget headerWidget);

/// Function used to wrap a given footer row widget for a specific row
/// in order to achieve some custom row behaviour.
typedef TableFooterDecorator = Widget Function(Widget footerWidget);

/// Function used to wrap a given placeholder widget containing all visible
/// placeholders in order to achieve some custom behaviour.
typedef TablePlaceholderContainerBuilder = Widget Function(
  Widget placeholderContainer,
);
