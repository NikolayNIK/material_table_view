import 'package:flutter/widgets.dart';

/// Holds properties to enable row reordering in a table.
class TableRowReorder {
  /// See [SliverReorderableList.findChildIndexCallback].
  final ChildIndexGetter? findChildIndexCallback;

  /// See [SliverReorderableList.onReorder].
  final ReorderCallback onReorder;

  /// See [SliverReorderableList.onReorderStart].
  final void Function(int)? onReorderStart;

  /// See [SliverReorderableList.onReorderEnd].
  final void Function(int)? onReorderEnd;

  /// See [SliverReorderableList.proxyDecorator].
  final ReorderItemProxyDecorator? proxyDecorator;

  /// See [SliverReorderableList.autoScrollerVelocityScalar].
  final double? autoScrollerVelocityScalar;

  TableRowReorder({
    required this.onReorder,
    this.onReorderStart,
    this.onReorderEnd,
    this.findChildIndexCallback,
    this.proxyDecorator,
    this.autoScrollerVelocityScalar,
  });
}
