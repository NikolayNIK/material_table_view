import 'package:flutter/widgets.dart';

abstract class TableViewHorizontalScrollControllerProvider<
    T extends StatefulWidget> extends State<T> {
  ScrollController get horizontalScrollController;
}
