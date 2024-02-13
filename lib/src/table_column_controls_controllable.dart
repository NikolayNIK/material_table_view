import 'package:flutter/widgets.dart';
import 'package:material_table_view/src/table_view.dart';

abstract class TableColumnControlsControllable<T extends TableView>
    extends State<T> {
  Key? get key;

  ScrollController get horizontalScrollController;
}
