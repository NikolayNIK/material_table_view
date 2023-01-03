import 'package:flutter/foundation.dart';

@immutable
class TableColumn {
  final double width;
  final int freezePriority;

  const TableColumn({
    required this.width,
    this.freezePriority = 0,
  }) : assert(freezePriority >= 0);

  bool frozenAt(int priority) => freezePriority > priority;
}
