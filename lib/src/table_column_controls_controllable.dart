import 'package:flutter/widgets.dart';
import 'package:material_table_view/src/table_column.dart';
import 'package:material_table_view/src/table_view.dart';

abstract class TableColumnControlsControllable<T extends TableView>
    extends State<T> {
  ScrollController get horizontalScrollController;

  List<TableColumn> get columns;

  TextDirection get textDirection;
}
