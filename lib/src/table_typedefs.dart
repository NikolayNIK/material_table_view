import 'package:flutter/widgets.dart';

typedef TableCellBuilder = Widget Function(BuildContext context, int column);

typedef TableRowBuilder = TableCellBuilder? Function(int row);

typedef TableRowDecorator = Widget Function(Widget rowWidget, int rowIndex);

typedef TablePlaceholderDecorator = Widget Function(
  Widget placeholderWidget,
  int rowIndex,
);

typedef TableHeaderDecorator = Widget Function(Widget headerWidget);

typedef TableFooterDecorator = Widget Function(Widget footerWidget);

typedef TablePlaceholderContainerBuilder = Widget Function(
  Widget placeholderContainer,
);
