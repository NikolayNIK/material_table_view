import 'package:flutter/foundation.dart';

@immutable
class TableColumn {
  final double width;
  final bool fixed;

  const TableColumn({
    required this.width,
    this.fixed = false,
  });
}
