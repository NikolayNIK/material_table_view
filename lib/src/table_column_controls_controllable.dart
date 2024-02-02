import 'package:flutter/widgets.dart';

abstract class TableColumnControlsControllable<T extends StatefulWidget>
    extends State<T> {
  Key? get key;

  ScrollController get horizontalScrollController;
}
